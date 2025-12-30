import SwiftUI
import SwiftData

struct DailyCheckInView: View {

    // MARK: - Environment
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userProfileManager: UserProfileManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Queries
    @Query(filter: #Predicate<Challenge> { $0.isActive })
    private var allActiveChallenges: [Challenge]

    private var activeChallenges: [Challenge] {
        allActiveChallenges.filter { !$0.isCompleted }
    }

    // MARK: - State
    @State private var currentStep = 0
    @State private var mood: Int = 3
    @State private var energy: Int = 3
    @State private var soreness: Int = 2
    @State private var todayFocus: TodayFocus = .workout
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var direction: TransitionDirection = .forward
    @State private var shareToChallenge = false
    @State private var shareWithFriends = false

    private let totalSteps = 5

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private var hasCheckedInToday: Bool {
        userProfileManager.lastCheckInDateString == todayString
    }

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Hey there"
        }
    }

    // Gradient based on time of day
    private var ambientGradient: LinearGradient {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<8: // Early morning - soft sunrise
            return LinearGradient(
                colors: [Color(hex: "fef3c7"), Color(hex: "fde68a"), Color(hex: "fbbf24")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 8..<12: // Morning - energetic
            return LinearGradient(
                colors: [Color(hex: "dbeafe"), Color(hex: "93c5fd"), Color(hex: "3b82f6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 12..<17: // Afternoon - warm
            return LinearGradient(
                colors: [Color(hex: "fed7aa"), Color(hex: "fdba74"), Color(hex: "f97316")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 17..<21: // Evening - sunset
            return LinearGradient(
                colors: [Color(hex: "fecaca"), Color(hex: "f87171"), Color(hex: "ef4444")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default: // Night - calm
            return LinearGradient(
                colors: [Color(hex: "c7d2fe"), Color(hex: "a5b4fc"), Color(hex: "6366f1")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        ZStack {
            // Background
            backgroundView

            if hasCheckedInToday && !showSuccess {
                // Already checked in view
                AlreadyCheckedInView(
                    mood: Int(userProfileManager.lastCheckInMood),
                    energy: Int(userProfileManager.lastCheckInEnergy),
                    soreness: Int(userProfileManager.lastCheckInSoreness),
                    streak: userProfileManager.checkInStreak,
                    onDismiss: { dismiss() }
                )
                .transition(.opacity)
            } else if showSuccess {
                // Success celebration
                CheckInSuccessView(streak: userProfileManager.checkInStreak) {
                    dismiss()
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .opacity
                ))
            } else {
                // Check-in wizard
                VStack(spacing: 0) {
                    // Header with progress and close
                    headerView

                    // Step content
                    TabView(selection: $currentStep) {
                        // Step 0: Welcome + Mood
                        moodStep
                            .tag(0)

                        // Step 1: Energy
                        energyStep
                            .tag(1)

                        // Step 2: Soreness
                        sorenessStep
                            .tag(2)

                        // Step 3: Today's Focus
                        focusStep
                            .tag(3)

                        // Step 4: Share
                        shareStep
                            .tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)

                    // Navigation buttons
                    navigationButtons
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }

    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            // Subtle gradient overlay at top
            VStack {
                ambientGradient
                    .opacity(0.15)
                    .frame(height: 300)
                    .blur(radius: 60)
                Spacer()
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 16) {
            // Close button and streak
            HStack {
                Button {
                    themeManager.lightImpact()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }

                Spacer()

                // Streak badge
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(userProfileManager.checkInStreak)")
                        .fontWeight(.bold)
                    Text("day streak")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Progress bar
            ProgressBar(progress: Double(currentStep + 1) / Double(totalSteps))
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Step 0: Mood
    private var moodStep: some View {
        CheckInStepView(
            greeting: timeGreeting,
            title: "How are you feeling?",
            subtitle: "Your mood affects your workout performance"
        ) {
            MoodSelector(selected: $mood)
        }
    }

    // MARK: - Step 1: Energy
    private var energyStep: some View {
        CheckInStepView(
            title: "Energy level?",
            subtitle: "How charged up are you today?"
        ) {
            EnergySelector(selected: $energy)
        }
    }

    // MARK: - Step 2: Soreness
    private var sorenessStep: some View {
        CheckInStepView(
            title: "Any soreness?",
            subtitle: "This helps us adjust your workout intensity"
        ) {
            SorenessSelector(selected: $soreness)
        }
    }

    // MARK: - Step 3: Focus
    private var focusStep: some View {
        CheckInStepView(
            title: "Today's focus?",
            subtitle: "What's your main goal for today?"
        ) {
            FocusSelector(selected: $todayFocus)
        }
    }

    // MARK: - Step 4: Share
    private var shareStep: some View {
        CheckInStepView(
            title: "Share your check-in?",
            subtitle: "Let others know you're staying consistent"
        ) {
            VStack(spacing: 16) {
                // Share to Challenge option (if active challenge exists)
                if let challenge = activeChallenges.first {
                    ShareOptionCard(
                        isSelected: $shareToChallenge,
                        icon: "trophy.fill",
                        title: "Share to Challenge",
                        subtitle: challenge.name,
                        accentColor: Color(hex: "fbbf24")
                    )
                }

                // Share with Friends option
                ShareOptionCard(
                    isSelected: $shareWithFriends,
                    icon: "person.2.fill",
                    title: "Share with Friends",
                    subtitle: "Post to your activity feed",
                    accentColor: Color(hex: "3b82f6")
                )

                // Skip hint
                Text("You can skip this step if you prefer")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button (only shown after first step)
            if currentStep > 0 {
                Button {
                    themeManager.lightImpact()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        direction = .backward
                        currentStep -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 56, height: 56)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }

            // Next/Complete button
            Button {
                themeManager.mediumImpact()
                if currentStep < totalSteps - 1 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        direction = .forward
                        currentStep += 1
                    }
                } else {
                    saveCheckIn()
                }
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentStep == totalSteps - 1 ? "Complete" : "Next")
                            .fontWeight(.semibold)
                        Image(systemName: currentStep == totalSteps - 1 ? "checkmark" : "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: currentStep == 0 ? 200 : .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "10b981"), Color(hex: "059669")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
            }
            .disabled(isSaving)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 32)
        .padding(.top, 16)
    }

    // MARK: - Save
    private func saveCheckIn() {
        isSaving = true

        // Update streak
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayString = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: yesterday)
        }()

        if userProfileManager.lastCheckInDateString == yesterdayString {
            userProfileManager.checkInStreak += 1
        } else if userProfileManager.lastCheckInDateString != todayString {
            userProfileManager.checkInStreak = 1
        }

        // Save to UserProfileManager (synced via iCloud)
        userProfileManager.lastCheckInDateString = todayString
        userProfileManager.lastCheckInMood = Double(mood)
        userProfileManager.lastCheckInEnergy = Double(energy)
        userProfileManager.lastCheckInSoreness = Double(soreness)

        // Save MoodEntry to SwiftData
        let moodEntry = MoodEntry(
            date: Date(),
            mood: moodFromValue(mood),
            energyLevel: energy * 2,
            stressLevel: (5 - mood) * 2, // Inverse of mood
            notes: nil
        )
        modelContext.insert(moodEntry)

        // Save DailyHealthData
        saveDailyHealthData()

        // Share to Challenge if selected
        if shareToChallenge, let challenge = activeChallenges.first {
            shareCheckInToChallenge(challenge)
        }

        // Share with Friends if selected
        if shareWithFriends {
            shareCheckInWithFriends()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            themeManager.notifySuccess()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showSuccess = true
            }

            NotificationCenter.default.post(name: .dailyCheckInSaved, object: nil)
        }
    }

    private func shareCheckInToChallenge(_ challenge: Challenge) {
        guard let userId = authManager.currentUser?.id,
              let participant = challenge.participants?.first(where: { $0.ownerId == userId }) else {
            return
        }

        // Calculate day number in challenge
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.startOfDay(for: challenge.startDate)
        let dayNumber = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0

        // Check if already logged today
        if let existingLog = participant.dayLogs?.first(where: { $0.dayNumber == dayNumber }) {
            // Update existing log with check-in data
            existingLog.notes = "Check-in: \(moodFromValue(mood).rawValue), Energy: \(energy)/5, Focus: \(todayFocus.rawValue)"
            if existingLog.activityData == nil {
                let activityData = ChallengeActivityData()
                activityData.stressLevel = (5 - mood) * 2
                activityData.dayLog = existingLog
                existingLog.activityData = activityData
                modelContext.insert(activityData)
            } else {
                existingLog.activityData?.stressLevel = (5 - mood) * 2
            }
        } else {
            // Create new day log
            let dayLog = ChallengeDayLog(dayNumber: dayNumber, isCompleted: true)
            dayLog.notes = "Check-in: \(moodFromValue(mood).rawValue), Energy: \(energy)/5, Focus: \(todayFocus.rawValue)"
            dayLog.participant = participant

            // Create activity data with wellness stats
            let activityData = ChallengeActivityData()
            activityData.stressLevel = (5 - mood) * 2
            activityData.dayLog = dayLog
            dayLog.activityData = activityData

            modelContext.insert(dayLog)
            modelContext.insert(activityData)

            // Update participant stats
            participant.logDay(day: dayNumber, completed: true, activityData: activityData)
        }

        try? modelContext.save()

        // Post notification for challenge updates
        NotificationCenter.default.post(name: .challengeDataUpdated, object: nil)
    }

    private func shareCheckInWithFriends() {
        // Post a notification that the check-in was shared
        // This could be picked up by an activity feed or social features
        NotificationCenter.default.post(
            name: .dailyCheckInSaved,
            object: nil,
            userInfo: [
                "shared": true,
                "mood": mood,
                "energy": energy,
                "focus": todayFocus.rawValue,
                "streak": userProfileManager.checkInStreak
            ]
        )
    }

    private func moodFromValue(_ value: Int) -> Mood {
        switch value {
        case 5: return .amazing
        case 4: return .good
        case 3: return .okay
        case 2: return .tired
        default: return .stressed
        }
    }

    private func saveDailyHealthData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<DailyHealthData>(
            predicate: #Predicate { data in
                data.date >= today
            }
        )

        do {
            let existingData = try modelContext.fetch(descriptor)

            if let todayData = existingData.first {
                todayData.energyLevel = energy * 2
                todayData.stressLevel = (5 - mood) * 2
            } else {
                let healthData = DailyHealthData(date: today)
                healthData.energyLevel = energy * 2
                healthData.stressLevel = (5 - mood) * 2
                modelContext.insert(healthData)
            }
        } catch {
            print("Error saving daily health data: \(error)")
        }
    }
}

// MARK: - Transition Direction
enum TransitionDirection {
    case forward, backward
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 6)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "10b981"), Color(hex: "059669")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Check-In Step View
struct CheckInStepView<Content: View>: View {
    var greeting: String? = nil
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
                .frame(height: 20)

            // Title section
            VStack(spacing: 12) {
                if let greeting = greeting {
                    Text(greeting)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            // Content
            content()
                .padding(.horizontal, 20)

            Spacer()
        }
    }
}

// MARK: - Mood Selector (Premium Design)
struct MoodSelector: View {
    @Binding var selected: Int
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private let moods: [(icon: String, label: String, color: Color, gradient: [Color])] = [
        ("cloud.rain.fill", "Rough", Color(hex: "ef4444"), [Color(hex: "ef4444"), Color(hex: "dc2626")]),
        ("cloud.fill", "Meh", Color(hex: "f97316"), [Color(hex: "f97316"), Color(hex: "ea580c")]),
        ("cloud.sun.fill", "Okay", Color(hex: "eab308"), [Color(hex: "eab308"), Color(hex: "ca8a04")]),
        ("sun.max.fill", "Good", Color(hex: "22c55e"), [Color(hex: "22c55e"), Color(hex: "16a34a")]),
        ("sparkles", "Amazing", Color(hex: "10b981"), [Color(hex: "10b981"), Color(hex: "059669")])
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Selected mood display - large and prominent
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                moods[selected - 1].color.opacity(0.4),
                                moods[selected - 1].color.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)

                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f5f5f5"),
                                colorScheme == .dark ? Color(hex: "0d0d0d") : Color(hex: "e5e5e5")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: moods[selected - 1].color.opacity(0.3), radius: 20, x: 0, y: 0)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: moods[selected - 1].gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )

                // Icon
                Image(systemName: moods[selected - 1].icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: moods[selected - 1].gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: moods[selected - 1].color.opacity(0.5), radius: 10, x: 0, y: 0)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selected)

            // Label
            Text(moods[selected - 1].label)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(moods[selected - 1].color)
                .animation(.easeInOut(duration: 0.2), value: selected)

            // Mood selector pills
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { index in
                    MoodIconPill(
                        icon: moods[index - 1].icon,
                        color: moods[index - 1].color,
                        gradient: moods[index - 1].gradient,
                        isSelected: selected == index,
                        colorScheme: colorScheme
                    ) {
                        themeManager.mediumImpact()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selected = index
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Mood Icon Pill Button (Professional, no emoji)
struct MoodIconPill: View {
    let icon: String
    let color: Color
    let gradient: [Color]
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected
                            ? LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color(hex: "1f1f1f"), Color(hex: "171717")]
                                    : [Color(hex: "f0f0f0"), Color(hex: "e5e5e5")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: isSelected
                                        ? [Color.clear, Color.clear]
                                        : (colorScheme == .dark
                                            ? [Color.white.opacity(0.1), Color.white.opacity(0.05)]
                                            : [Color.white.opacity(0.8), Color.white.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isSelected ? color.opacity(0.4) : .clear,
                        radius: isSelected ? 8 : 0,
                        x: 0,
                        y: isSelected ? 4 : 0
                    )

                // Icon
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 24 : 20, weight: .medium))
                    .foregroundStyle(isSelected ? .white : color)
                    .shadow(color: isSelected ? .black.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .scaleEffect(isPressed ? 0.92 : (isSelected ? 1.08 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(MoodPillButtonStyle(isPressed: $isPressed))
    }
}

// Custom button style for press feedback
struct MoodPillButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Energy Selector (Premium Design)
struct EnergySelector: View {
    @Binding var selected: Int
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private let levels: [(icon: String, label: String, color: Color, gradient: [Color])] = [
        ("battery.0", "Drained", Color(hex: "ef4444"), [Color(hex: "ef4444"), Color(hex: "dc2626")]),
        ("battery.25", "Low", Color(hex: "f97316"), [Color(hex: "f97316"), Color(hex: "ea580c")]),
        ("battery.50", "Okay", Color(hex: "eab308"), [Color(hex: "eab308"), Color(hex: "ca8a04")]),
        ("battery.75", "Good", Color(hex: "22c55e"), [Color(hex: "22c55e"), Color(hex: "16a34a")]),
        ("battery.100.bolt", "Charged", Color(hex: "10b981"), [Color(hex: "10b981"), Color(hex: "059669")])
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Central hero display
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                levels[selected - 1].color.opacity(0.4),
                                levels[selected - 1].color.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)

                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f5f5f5"),
                                colorScheme == .dark ? Color(hex: "0d0d0d") : Color(hex: "e5e5e5")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: levels[selected - 1].color.opacity(0.3), radius: 20, x: 0, y: 0)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: levels[selected - 1].gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )

                // Battery icon
                Image(systemName: levels[selected - 1].icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: levels[selected - 1].gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: levels[selected - 1].color.opacity(0.5), radius: 10, x: 0, y: 0)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selected)

            // Label
            Text(levels[selected - 1].label)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(levels[selected - 1].color)
                .animation(.easeInOut(duration: 0.2), value: selected)

            // Energy level pills
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { index in
                    EnergyPill(
                        icon: levels[index - 1].icon,
                        color: levels[index - 1].color,
                        gradient: levels[index - 1].gradient,
                        isSelected: selected == index,
                        colorScheme: colorScheme
                    ) {
                        themeManager.mediumImpact()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selected = index
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Energy Pill Button
struct EnergyPill: View {
    let icon: String
    let color: Color
    let gradient: [Color]
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected
                            ? LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color(hex: "1f1f1f"), Color(hex: "171717")]
                                    : [Color(hex: "f0f0f0"), Color(hex: "e5e5e5")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: isSelected
                                        ? [Color.clear, Color.clear]
                                        : (colorScheme == .dark
                                            ? [Color.white.opacity(0.1), Color.white.opacity(0.05)]
                                            : [Color.white.opacity(0.8), Color.white.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isSelected ? color.opacity(0.4) : .clear,
                        radius: isSelected ? 8 : 0,
                        x: 0,
                        y: isSelected ? 4 : 0
                    )

                Image(systemName: icon)
                    .font(.system(size: isSelected ? 24 : 20, weight: .medium))
                    .foregroundStyle(isSelected ? .white : color)
                    .shadow(color: isSelected ? .black.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .scaleEffect(isPressed ? 0.92 : (isSelected ? 1.08 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(MoodPillButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Soreness Selector (Premium Design)
struct SorenessSelector: View {
    @Binding var selected: Int
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private let levels: [(icon: String, label: String, description: String, color: Color, gradient: [Color])] = [
        ("figure.strengthtraining.traditional", "None", "Fresh and ready", Color(hex: "10b981"), [Color(hex: "10b981"), Color(hex: "059669")]),
        ("hand.thumbsup.fill", "Mild", "Slight tightness", Color(hex: "22c55e"), [Color(hex: "22c55e"), Color(hex: "16a34a")]),
        ("minus.circle.fill", "Moderate", "Manageable", Color(hex: "eab308"), [Color(hex: "eab308"), Color(hex: "ca8a04")]),
        ("exclamationmark.triangle.fill", "Sore", "Needs attention", Color(hex: "f97316"), [Color(hex: "f97316"), Color(hex: "ea580c")]),
        ("bandage.fill", "Very Sore", "Recovery mode", Color(hex: "ef4444"), [Color(hex: "ef4444"), Color(hex: "dc2626")])
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Central hero display
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                levels[selected - 1].color.opacity(0.4),
                                levels[selected - 1].color.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)

                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f5f5f5"),
                                colorScheme == .dark ? Color(hex: "0d0d0d") : Color(hex: "e5e5e5")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: levels[selected - 1].color.opacity(0.3), radius: 20, x: 0, y: 0)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: levels[selected - 1].gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )

                // Icon
                Image(systemName: levels[selected - 1].icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: levels[selected - 1].gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: levels[selected - 1].color.opacity(0.5), radius: 10, x: 0, y: 0)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selected)

            // Labels
            VStack(spacing: 4) {
                Text(levels[selected - 1].label)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(levels[selected - 1].color)

                Text(levels[selected - 1].description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .animation(.easeInOut(duration: 0.2), value: selected)

            // Soreness level pills
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { index in
                    SorenessIconPill(
                        icon: levels[index - 1].icon,
                        color: levels[index - 1].color,
                        gradient: levels[index - 1].gradient,
                        isSelected: selected == index,
                        colorScheme: colorScheme
                    ) {
                        themeManager.mediumImpact()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selected = index
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Soreness Icon Pill Button (Professional, no emoji)
struct SorenessIconPill: View {
    let icon: String
    let color: Color
    let gradient: [Color]
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected
                            ? LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color(hex: "1f1f1f"), Color(hex: "171717")]
                                    : [Color(hex: "f0f0f0"), Color(hex: "e5e5e5")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: isSelected
                                        ? [Color.clear, Color.clear]
                                        : (colorScheme == .dark
                                            ? [Color.white.opacity(0.1), Color.white.opacity(0.05)]
                                            : [Color.white.opacity(0.8), Color.white.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isSelected ? color.opacity(0.4) : .clear,
                        radius: isSelected ? 8 : 0,
                        x: 0,
                        y: isSelected ? 4 : 0
                    )

                Image(systemName: icon)
                    .font(.system(size: isSelected ? 24 : 20, weight: .medium))
                    .foregroundStyle(isSelected ? .white : color)
                    .shadow(color: isSelected ? .black.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .scaleEffect(isPressed ? 0.92 : (isSelected ? 1.08 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(MoodPillButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Today's Focus
enum TodayFocus: String, CaseIterable {
    case workout = "Strength"
    case cardio = "Cardio"
    case recovery = "Recovery"
    case flexibility = "Flexibility"

    var icon: String {
        switch self {
        case .workout: return "dumbbell.fill"
        case .cardio: return "figure.run"
        case .recovery: return "bed.double.fill"
        case .flexibility: return "figure.yoga"
        }
    }

    var color: Color {
        switch self {
        case .workout: return Color(hex: "f97316")
        case .cardio: return Color(hex: "10b981")
        case .recovery: return Color(hex: "6366f1")
        case .flexibility: return Color(hex: "ec4899")
        }
    }

    var description: String {
        switch self {
        case .workout: return "Build muscle & strength"
        case .cardio: return "Heart health & endurance"
        case .recovery: return "Rest & rejuvenate"
        case .flexibility: return "Stretch & mobility"
        }
    }
}

struct FocusSelector: View {
    @Binding var selected: TodayFocus
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 12) {
            ForEach(TodayFocus.allCases, id: \.self) { focus in
                Button {
                    themeManager.lightImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = focus
                    }
                } label: {
                    HStack(spacing: 16) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(focus.color.opacity(selected == focus ? 1 : 0.15))
                                .frame(width: 50, height: 50)

                            Image(systemName: focus.icon)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(selected == focus ? .white : focus.color)
                        }

                        // Labels
                        VStack(alignment: .leading, spacing: 4) {
                            Text(focus.rawValue)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(focus.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Checkmark
                        if selected == focus {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(focus.color)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selected == focus ? focus.color.opacity(0.1) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(selected == focus ? focus.color : .clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Share Option Card
struct ShareOptionCard: View {
    @Binding var isSelected: Bool
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button {
            themeManager.lightImpact()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isSelected.toggle()
            }
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(isSelected ? 1 : 0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : accentColor)
                }

                // Labels
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Checkbox
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? accentColor : Color(.systemGray3), lineWidth: 2)
                        .frame(width: 26, height: 26)

                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Success View
struct CheckInSuccessView: View {
    let streak: Int
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false
    @State private var ringProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Confetti for milestones
            if showConfetti && (streak == 7 || streak == 30 || streak == 100 || streak % 50 == 0) {
                ConfettiContainer()
            }

            VStack(spacing: 32) {
                Spacer()

                // Animated ring with checkmark
                ZStack {
                    Circle()
                        .stroke(Color.accentGreen.opacity(0.2), lineWidth: 8)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "10b981"), Color(hex: "059669")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(Color.accentGreen)
                        .scaleEffect(showContent ? 1 : 0)
                }

                VStack(spacing: 12) {
                    Text("Check-In Complete!")
                        .font(.title)
                        .fontWeight(.bold)

                    // Streak celebration
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(streak) Day Streak")
                            .fontWeight(.semibold)
                    }
                    .font(.title3)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())

                    Text(streakMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "10b981"), Color(hex: "059669")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                ringProgress = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showContent = true
                }
                showConfetti = true
            }
        }
    }

    private var streakMessage: String {
        switch streak {
        case 1: return "Great start! Keep it going tomorrow."
        case 7: return "One week strong! You're building a habit."
        case 14: return "Two weeks! This is becoming routine."
        case 30: return "One month! You're unstoppable!"
        case 100: return "100 days! You're a legend!"
        default:
            if streak % 50 == 0 {
                return "\(streak) days! Incredible dedication!"
            }
            return "Keep up the great work!"
        }
    }
}

// MARK: - Confetti Container
struct ConfettiContainer: View {
    @State private var pieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiView(piece: piece, screenHeight: geo.size.height)
                }
            }
            .onAppear {
                pieces = (0..<50).map { _ in
                    ConfettiPiece(
                        id: UUID(),
                        x: CGFloat.random(in: 0...geo.size.width),
                        color: [.red, .orange, .yellow, .green, .blue, .purple, .pink].randomElement()!,
                        size: CGFloat.random(in: 8...14),
                        rotation: Double.random(in: 0...360),
                        delay: Double.random(in: 0...0.5)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Already Checked In View
struct AlreadyCheckedInView: View {
    let mood: Int
    let energy: Int
    let soreness: Int
    let streak: Int
    let onDismiss: () -> Void

    private let moodIcons = ["", "cloud.rain.fill", "cloud.fill", "cloud.sun.fill", "sun.max.fill", "sparkles"]
    private let moodColors: [Color] = [.clear, Color(hex: "ef4444"), Color(hex: "f97316"), Color(hex: "eab308"), Color(hex: "22c55e"), Color(hex: "10b981")]
    private let energyLabels = ["", "Drained", "Low", "Okay", "Good", "Charged"]
    private let sorenessIcons = ["", "figure.strengthtraining.traditional", "hand.thumbsup.fill", "minus.circle.fill", "exclamationmark.triangle.fill", "bandage.fill"]
    private let sorenessColors: [Color] = [.clear, Color(hex: "10b981"), Color(hex: "22c55e"), Color(hex: "eab308"), Color(hex: "f97316"), Color(hex: "ef4444")]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success indicator
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentGreen)
            }

            VStack(spacing: 12) {
                Text("Already Checked In")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You've completed today's check-in. Come back tomorrow!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Today's summary
            VStack(spacing: 16) {
                Text("Today's Summary")
                    .font(.headline)

                HStack(spacing: 24) {
                    SummaryIconItem(icon: moodIcons[mood], label: "Mood", color: moodColors[mood])
                    SummaryIconItem(icon: "bolt.fill", label: energyLabels[energy], color: Color(hex: "eab308"))
                    SummaryIconItem(icon: sorenessIcons[soreness], label: "Soreness", color: sorenessColors[soreness])
                }

                // Streak
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(streak) Day Streak")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
            }
            .padding(24)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 20)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Close")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}

struct SummaryIconItem: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Confetti Piece (reused from original)
struct ConfettiPiece: Identifiable {
    let id: UUID
    let x: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let delay: Double
}

struct ConfettiView: View {
    let piece: ConfettiPiece
    let screenHeight: CGFloat

    @State private var yPosition: CGFloat = -20
    @State private var currentRotation: Double = 0
    @State private var opacity: Double = 1
    @State private var xOffset: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 0.6)
            .rotationEffect(.degrees(currentRotation))
            .position(x: piece.x + xOffset, y: yPosition)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 2.5).delay(piece.delay)) {
                    yPosition = screenHeight + 50
                    opacity = 0
                }
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false).delay(piece.delay)) {
                    currentRotation = piece.rotation + 720
                }
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(piece.delay)) {
                    xOffset = CGFloat.random(in: -30...30)
                }
            }
    }
}

#Preview {
    DailyCheckInView()
        .environmentObject(ThemeManager())
        .environmentObject(UserProfileManager())
}
