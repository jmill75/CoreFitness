import SwiftUI
import SwiftData
import Combine

/// Centralized manager for tracking active workouts and programs across all views.
/// This ensures HomeView, ProgramsView, and ProgressView all show consistent data.
@MainActor
class ActiveProgramManager: ObservableObject {
    static let shared = ActiveProgramManager()

    // MARK: - Published State (UI will react to these)

    /// The currently active/next workout to do
    @Published private(set) var currentWorkout: Workout?

    /// The active program the user is following
    @Published private(set) var activeProgram: UserProgram?

    /// All user's workouts (for My Programs section)
    @Published private(set) var userWorkouts: [Workout] = []

    /// All imported program templates
    @Published private(set) var importedPrograms: [ProgramTemplate] = []

    /// Loading state
    @Published private(set) var isLoading = false

    // MARK: - Private

    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?
    private var lastRefreshTime: Date = .distantPast
    private let minimumRefreshInterval: TimeInterval = 0.3 // Debounce: min 300ms between refreshes

    private init() {
        setupNotificationObservers()
    }

    // MARK: - Setup

    /// Call this once from the app's main view to provide the model context
    func configure(with context: ModelContext) {
        self.modelContext = context
        refreshNow() // Initial load - no debounce
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        // Refresh when workout starts
        NotificationCenter.default.publisher(for: .workoutStarted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        // Refresh when workout completes
        NotificationCenter.default.publisher(for: .workoutCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        // Refresh when workout is saved
        NotificationCenter.default.publisher(for: .workoutSaved)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        // Refresh when program is imported
        NotificationCenter.default.publisher(for: NSNotification.Name("ProgramImported"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        // NOTE: We do NOT listen to "DataChanged" to avoid notification loops
    }

    // MARK: - Public Methods

    /// Refresh data with debouncing to prevent rapid successive calls
    func refresh() {
        let now = Date()
        let timeSinceLastRefresh = now.timeIntervalSince(lastRefreshTime)

        // If we recently refreshed, schedule a delayed refresh instead
        if timeSinceLastRefresh < minimumRefreshInterval {
            scheduleDelayedRefresh()
            return
        }

        refreshNow()
    }

    /// Force immediate refresh (bypasses debouncing)
    func refreshNow() {
        refreshTask?.cancel()
        refreshTask = nil

        guard let context = modelContext else {
            print("ActiveProgramManager: No model context configured")
            return
        }

        lastRefreshTime = Date()

        // Fetch current/active workout
        fetchCurrentWorkout(context: context)

        // Fetch active program
        fetchActiveProgram(context: context)

        // Fetch all user workouts
        fetchUserWorkouts(context: context)

        // Fetch imported programs
        fetchImportedPrograms(context: context)
    }

    private func scheduleDelayedRefresh() {
        // Cancel any pending refresh
        refreshTask?.cancel()

        // Schedule new refresh after the minimum interval
        refreshTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(minimumRefreshInterval * 1_000_000_000))

            guard !Task.isCancelled else { return }

            refreshNow()
        }
    }

    /// Set a workout as the current/active workout
    func setCurrentWorkout(_ workout: Workout?) {
        // Deactivate previous workout if different
        if let current = currentWorkout, current.id != workout?.id {
            current.isActive = false
        }

        // Activate new workout
        workout?.isActive = true
        currentWorkout = workout

        try? modelContext?.save()
    }

    /// Start following a program
    func startProgram(_ template: ProgramTemplate) {
        guard let context = modelContext else { return }

        // End any existing active program
        if let existing = activeProgram {
            existing.status = .paused
        }

        // Create new user program
        let userProgram = UserProgram(template: template)
        context.insert(userProgram)

        activeProgram = userProgram

        try? context.save()
    }

    /// Complete/end the active program
    func completeProgram() {
        activeProgram?.status = .completed
        activeProgram?.actualEndDate = Date()
        activeProgram = nil

        try? modelContext?.save()
    }

    /// Advance to the next workout in the program after completing the current one
    func advanceToNextWorkout() {
        guard let context = modelContext,
              let current = currentWorkout,
              let programId = current.sourceProgramId else { return }

        // Mark current workout as not active (it should be completed)
        current.isActive = false

        // Find the next workout in the program sequence
        let nextSessionNumber = current.programSessionNumber + 1
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> {
                $0.sourceProgramId == programId &&
                $0.programSessionNumber == nextSessionNumber &&
                $0.statusRaw != "completed"
            }
        )

        if let workouts = try? context.fetch(descriptor), let nextWorkout = workouts.first {
            nextWorkout.isActive = true
            currentWorkout = nextWorkout

            // Update the UserProgram's currentWeek and currentDay
            if let activeProgram = activeProgram {
                activeProgram.currentWeek = nextWorkout.programWeekNumber
                activeProgram.currentDay = nextWorkout.programDayNumber
            }
        } else {
            // No more workouts - program might be complete
            currentWorkout = nil
        }

        try? context.save()
    }

    // MARK: - Private Fetch Methods

    private func fetchCurrentWorkout(context: ModelContext) {
        // First, check for an active workout (isActive = true)
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.isActive == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        if let workouts = try? context.fetch(descriptor), let active = workouts.first {
            if currentWorkout?.id != active.id {
                currentWorkout = active
            }
            return
        }

        // If no active workout, find the next program workout in sequence
        // Look for the first incomplete workout ordered by programSessionNumber
        let programDescriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> {
                $0.statusRaw != "completed" && $0.sourceProgramId != nil
            },
            sortBy: [SortDescriptor(\.programSessionNumber, order: .forward)]
        )

        if let programWorkouts = try? context.fetch(programDescriptor),
           let nextProgramWorkout = programWorkouts.first {
            if currentWorkout?.id != nextProgramWorkout.id {
                currentWorkout = nextProgramWorkout
            }
            return
        }

        // If no program workouts, get any non-completed workout
        descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.statusRaw != "completed" },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        if let workouts = try? context.fetch(descriptor), let next = workouts.first {
            if currentWorkout?.id != next.id {
                currentWorkout = next
            }
            return
        }

        // No workouts at all
        if currentWorkout != nil {
            currentWorkout = nil
        }
    }

    private func fetchActiveProgram(context: ModelContext) {
        var descriptor = FetchDescriptor<UserProgram>(
            predicate: #Predicate<UserProgram> { $0.statusRaw == "Active" },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        if let programs = try? context.fetch(descriptor), let active = programs.first {
            if activeProgram?.id != active.id {
                activeProgram = active
            }
        } else if activeProgram != nil {
            activeProgram = nil
        }
    }

    private func fetchUserWorkouts(context: ModelContext) {
        var descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 50 // Limit to prevent loading too many

        if let workouts = try? context.fetch(descriptor) {
            // Only update if changed (compare IDs to avoid unnecessary updates)
            let newIds = Set(workouts.map { $0.id })
            let oldIds = Set(userWorkouts.map { $0.id })
            if newIds != oldIds {
                userWorkouts = workouts
            }
        }
    }

    private func fetchImportedPrograms(context: ModelContext) {
        // Fetch user programs: imported, AI-generated, or user-created (not seeded)
        let userSourceType = ProgramSourceType.userCreated.rawValue
        let aiSourceType = ProgramSourceType.aiGenerated.rawValue
        let importedSourceType = ProgramSourceType.imported.rawValue

        var descriptor = FetchDescriptor<ProgramTemplate>(
            predicate: #Predicate<ProgramTemplate> {
                $0.sourceTypeRaw == userSourceType ||
                $0.sourceTypeRaw == aiSourceType ||
                $0.sourceTypeRaw == importedSourceType
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 50 // Limit to prevent loading too many

        if let programs = try? context.fetch(descriptor) {
            // Only update if changed
            let newIds = Set(programs.map { $0.id })
            let oldIds = Set(importedPrograms.map { $0.id })
            if newIds != oldIds {
                importedPrograms = programs
            }
        }
    }

    // MARK: - Computed Properties

    var hasCurrentWorkout: Bool {
        currentWorkout != nil
    }

    var hasActiveProgram: Bool {
        activeProgram != nil
    }

    var currentWorkoutName: String {
        currentWorkout?.name ?? "No Workout"
    }

    var activeProgramName: String {
        activeProgram?.template?.name ?? "No Program"
    }

    var workoutCount: Int {
        userWorkouts.count
    }

    var importedProgramCount: Int {
        importedPrograms.count
    }
}
