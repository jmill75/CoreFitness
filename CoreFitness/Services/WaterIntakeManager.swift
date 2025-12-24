import Foundation
import SwiftData
import Combine

/// Centralized manager for water intake data that syncs across all views
@MainActor
class WaterIntakeManager: ObservableObject {

    // MARK: - Published Properties
    @Published var totalOunces: Double = 0
    @Published var goalOunces: Double = 64
    @Published var lastAddedAmount: Double = 0

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
        // TODO: Calculate from historical data
        3
    }

    var goalsMetThisMonth: Int {
        // TODO: Calculate from historical data
        18
    }

    // MARK: - Private Properties
    private var modelContext: ModelContext?
    private var todayHealthData: DailyHealthData?

    // MARK: - Initialization
    init() {}

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadTodayData()
    }

    // MARK: - Data Loading
    func loadTodayData() {
        guard let context = modelContext else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<DailyHealthData>(
            predicate: #Predicate { data in
                data.date >= today && data.date < tomorrow
            }
        )

        if let existing = try? context.fetch(descriptor).first {
            todayHealthData = existing
            totalOunces = existing.waterIntake ?? 0
            goalOunces = existing.waterGoal ?? 64
        } else {
            // Create new entry for today
            let newData = DailyHealthData(date: today)
            newData.waterIntake = 0
            newData.waterGoal = goalOunces
            context.insert(newData)
            try? context.save()
            todayHealthData = newData
            totalOunces = 0
        }
    }

    // MARK: - Water Actions
    func addWater(ounces: Double) {
        lastAddedAmount = ounces
        totalOunces += ounces
        saveData()
    }

    func removeWater(ounces: Double) {
        totalOunces = max(0, totalOunces - ounces)
        saveData()
    }

    func resetToday() {
        totalOunces = 0
        saveData()
    }

    func updateGoal(_ newGoal: Double) {
        goalOunces = newGoal
        saveData()
    }

    // MARK: - Data Persistence
    private func saveData() {
        guard let context = modelContext else { return }

        if todayHealthData == nil {
            loadTodayData()
        }

        todayHealthData?.waterIntake = totalOunces
        todayHealthData?.waterGoal = goalOunces

        try? context.save()
    }

    // MARK: - Historical Data
    func getLast30DaysData() -> [Double] {
        guard let context = modelContext else {
            // Return sample data if no context
            return (0..<30).map { _ in Double.random(in: 20...80) }
        }

        let today = Calendar.current.startOfDay(for: Date())
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: today)!

        let descriptor = FetchDescriptor<DailyHealthData>(
            predicate: #Predicate { data in
                data.date >= thirtyDaysAgo && data.date <= today
            },
            sortBy: [SortDescriptor(\.date)]
        )

        if let data = try? context.fetch(descriptor) {
            return data.map { $0.waterIntake ?? 0 }
        }

        // Return sample data if no data found
        return (0..<30).map { _ in Double.random(in: 20...80) }
    }

    func getStatsForLast30Days() -> (total: Double, average: Double, maxValue: Double, goalsMetCount: Int) {
        let dailyData = getLast30DaysData()
        let total = dailyData.reduce(0, +)
        let average = dailyData.isEmpty ? 0 : total / Double(dailyData.count)
        let maxValue = dailyData.max() ?? 0
        let goalsMetCount = dailyData.filter { $0 >= goalOunces }.count

        return (total, average, maxValue, goalsMetCount)
    }
}
