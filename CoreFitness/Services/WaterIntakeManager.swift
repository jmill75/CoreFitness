import Foundation
import SwiftData
import Combine

/// Centralized manager for water intake data that syncs with HealthKit
@MainActor
class WaterIntakeManager: ObservableObject {

    // MARK: - Published Properties
    @Published var totalOunces: Double = 0
    @Published var goalOunces: Double = 64
    @Published var lastAddedAmount: Double = 0
    @Published var isLoading: Bool = false
    @Published var hasCelebratedGoalToday: Bool = false

    // Track the date for which celebration status applies
    private var celebrationDate: Date?

    // MARK: - Computed Properties
    var progressPercentage: Double {
        guard goalOunces > 0 else { return 0 }
        return totalOunces / goalOunces
    }

    var ringProgress: Double {
        min(1.0, progressPercentage)
    }

    var remainingOunces: Int {
        max(0, Int(goalOunces - totalOunces))
    }

    var hasReachedGoal: Bool {
        totalOunces >= goalOunces
    }

    var currentStreak: Int {
        // Will be calculated from HealthKit history
        _currentStreak
    }

    var goalsMetThisMonth: Int {
        // Will be calculated from HealthKit history
        _goalsMetThisMonth
    }

    // MARK: - Private Properties
    private var healthKitManager: HealthKitManager?
    private var modelContext: ModelContext?
    private var _currentStreak: Int = 0
    private var _goalsMetThisMonth: Int = 0

    // MARK: - Initialization
    init() {}

    func setHealthKitManager(_ manager: HealthKitManager) {
        self.healthKitManager = manager
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadGoalFromLocalStorage()
    }

    // MARK: - Data Loading
    func loadTodayData() {
        Task {
            await loadTodayDataAsync()
        }
    }

    func loadTodayDataAsync() async {
        isLoading = true

        // Load water intake from HealthKit
        if let manager = healthKitManager {
            await manager.refreshData()
            if let waterFromHealthKit = manager.healthData.waterIntake {
                totalOunces = waterFromHealthKit
            }

            // Load historical data for streak calculation
            await calculateStreakAndGoals()
        }

        // Load goal from local storage (goals are stored locally)
        loadGoalFromLocalStorage()

        isLoading = false
    }

    private func loadGoalFromLocalStorage() {
        guard let context = modelContext else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<DailyHealthData>(
            predicate: #Predicate { data in
                data.date >= today && data.date < tomorrow
            }
        )

        if let existing = try? context.fetch(descriptor).first {
            goalOunces = existing.waterGoal ?? 64
        } else {
            // Create new entry for today with default goal
            let newData = DailyHealthData(date: today)
            newData.waterGoal = goalOunces
            context.insert(newData)
            try? context.save()
        }
    }

    // MARK: - Water Actions
    func addWater(ounces: Double) {
        lastAddedAmount = ounces

        Task {
            // Save to HealthKit
            if let manager = healthKitManager {
                let success = await manager.saveWaterIntake(ounces: ounces)
                if success {
                    // Update local total from HealthKit
                    if let waterFromHealthKit = manager.healthData.waterIntake {
                        totalOunces = waterFromHealthKit
                    } else {
                        // Fallback: add locally if HealthKit read fails
                        totalOunces += ounces
                    }
                } else {
                    // Fallback: add locally if HealthKit save fails
                    totalOunces += ounces
                }
            } else {
                // No HealthKit manager, just update locally
                totalOunces += ounces
            }

            // Notify listeners that water intake was updated
            await MainActor.run {
                NotificationCenter.default.post(name: .waterIntakeUpdated, object: nil)
            }
        }
    }

    func removeWater(ounces: Double) {
        Task {
            if let manager = healthKitManager {
                // Delete the last water sample from HealthKit
                let success = await manager.deleteLastWaterSample()
                if success {
                    // Refresh data from HealthKit
                    await manager.refreshData()
                    if let waterFromHealthKit = manager.healthData.waterIntake {
                        totalOunces = waterFromHealthKit
                    }
                }
            } else {
                totalOunces = max(0, totalOunces - ounces)
            }

            // Notify listeners that water intake was updated
            await MainActor.run {
                NotificationCenter.default.post(name: .waterIntakeUpdated, object: nil)
            }
        }
    }

    func resetToday() {
        // Note: This would require deleting all water samples for today from HealthKit
        // For now, just reset the local display
        totalOunces = 0
        // Also reset celebration status when resetting the day
        hasCelebratedGoalToday = false
        celebrationDate = nil
    }

    /// Mark the goal as celebrated for today - prevents multiple haptics on navigation
    func markGoalCelebrated() {
        let today = Calendar.current.startOfDay(for: Date())
        celebrationDate = today
        hasCelebratedGoalToday = true
    }

    /// Check if we should celebrate (goal reached and hasn't been celebrated today)
    var shouldCelebrateGoal: Bool {
        guard hasReachedGoal else { return false }

        let today = Calendar.current.startOfDay(for: Date())

        // If celebration date is not today, reset it (new day)
        if celebrationDate != today {
            hasCelebratedGoalToday = false
            celebrationDate = nil
        }

        return !hasCelebratedGoalToday
    }

    func updateGoal(_ newGoal: Double) {
        goalOunces = newGoal
        saveGoalToLocalStorage()
    }

    // MARK: - Goal Persistence (stored locally, not in HealthKit)
    private func saveGoalToLocalStorage() {
        guard let context = modelContext else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<DailyHealthData>(
            predicate: #Predicate { data in
                data.date >= today && data.date < tomorrow
            }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.waterGoal = goalOunces
        } else {
            let newData = DailyHealthData(date: today)
            newData.waterGoal = goalOunces
            context.insert(newData)
        }

        try? context.save()
    }

    // MARK: - Historical Data & Streaks
    private func calculateStreakAndGoals() async {
        guard let manager = healthKitManager else {
            _currentStreak = 0
            _goalsMetThisMonth = 0
            return
        }

        // Get last 30 days of water data from HealthKit
        let history = await manager.getWaterIntakeHistory(days: 30)

        // Calculate goals met this month
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        var goalsMetCount = 0
        for (date, ounces) in history {
            if date >= startOfMonth && ounces >= goalOunces {
                goalsMetCount += 1
            }
        }
        _goalsMetThisMonth = goalsMetCount

        // Calculate current streak (consecutive days meeting goal)
        var streak = 0
        let today = calendar.startOfDay(for: now)

        for dayOffset in 0..<30 {
            guard let checkDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { break }
            let dayStart = calendar.startOfDay(for: checkDate)

            if let ounces = history[dayStart], ounces >= goalOunces {
                streak += 1
            } else if dayOffset > 0 {
                // Break streak if a day is missed (but don't count today if not complete)
                break
            }
        }
        _currentStreak = streak
    }

    // MARK: - Historical Data for Charts

    /// Synchronous version - prefer getLast30DaysDataAsync() for accurate data
    func getLast30DaysData() -> [Double] {
        // Return zeros - caller should use async version for real data
        return Array(repeating: 0, count: 30)
    }

    /// Async version - fetches actual water intake history from HealthKit
    func getLast30DaysDataAsync() async -> [Double] {
        guard let manager = healthKitManager else {
            // No HealthKit manager - return zeros (no data available)
            return Array(repeating: 0, count: 30)
        }

        let history = await manager.getWaterIntakeHistory(days: 30)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var result: [Double] = []
        for dayOffset in (0..<30).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let dayStart = calendar.startOfDay(for: date)
                result.append(history[dayStart] ?? 0)
            }
        }

        // Return actual data - zeros for days with no intake is valid
        return result
    }

    /// Get last 7 days of water intake data
    func getLast7DaysDataAsync() async -> [Double] {
        guard let manager = healthKitManager else {
            return Array(repeating: 0, count: 7)
        }

        let history = await manager.getWaterIntakeHistory(days: 7)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var result: [Double] = []
        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let dayStart = calendar.startOfDay(for: date)
                result.append(history[dayStart] ?? 0)
            }
        }
        return result
    }

    /// Get hourly water intake data for today
    func getHourlyDataForTodayAsync() async -> [Double] {
        guard let manager = healthKitManager else {
            return Array(repeating: 0, count: 24)
        }

        let hourlyData = await manager.getHourlyWaterIntakeForToday()
        return hourlyData
    }

    /// Get monthly water intake totals for last 12 months
    func getLast12MonthsDataAsync() async -> [Double] {
        guard let manager = healthKitManager else {
            return Array(repeating: 0, count: 12)
        }

        let monthlyData = await manager.getMonthlyWaterIntakeHistory(months: 12)
        return monthlyData
    }

    func getStatsForLast30Days() async -> (total: Double, average: Double, maxValue: Double, goalsMetCount: Int) {
        let dailyData = await getLast30DaysDataAsync()
        let total = dailyData.reduce(0, +)
        let average = dailyData.isEmpty ? 0 : total / Double(dailyData.count)
        let maxValue = dailyData.max() ?? 0

        return (total, average, maxValue, _goalsMetThisMonth)
    }
}
