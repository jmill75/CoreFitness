import SwiftUI
import HealthKit

// MARK: - Health Data
struct HealthData {
    var heartRate: Double?
    var restingHeartRate: Double?
    var hrv: Double?
    var sleepHours: Double?
    var steps: Int?
    var activeCalories: Double?
    var lastUpdated: Date?
}

// MARK: - HealthKit Manager
@MainActor
class HealthKitManager: ObservableObject {

    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var healthData = HealthData()
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let healthStore = HKHealthStore()

    // MARK: - Health Types
    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()

        // Heart Rate
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }

        // Resting Heart Rate
        if let restingHR = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHR)
        }

        // HRV
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrv)
        }

        // Sleep
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }

        // Steps
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }

        // Active Calories
        if let calories = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(calories)
        }

        return types
    }()

    private let writeTypes: Set<HKSampleType> = {
        var types = Set<HKSampleType>()

        // Workouts
        types.insert(HKObjectType.workoutType())

        return types
    }()

    // MARK: - Authorization
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device"
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
            await fetchTodayData()
        } catch {
            errorMessage = error.localizedDescription
            isAuthorized = false
        }
    }

    /// Refresh data - call this on view appear
    func refreshData() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        isAuthorized = true  // Assume authorized if we're refreshing
        await fetchTodayData()
    }

    // MARK: - Fetch Today's Data
    func fetchTodayData() async {
        isLoading = true

        async let heartRate = fetchLatestHeartRate()
        async let restingHR = fetchRestingHeartRate()
        async let hrv = fetchHRV()
        async let sleep = fetchSleepData()
        async let steps = fetchSteps()
        async let calories = fetchActiveCalories()

        let (hr, rhr, hrvValue, sleepHours, stepCount, cals) = await (
            heartRate, restingHR, hrv, sleep, steps, calories
        )

        healthData = HealthData(
            heartRate: hr,
            restingHeartRate: rhr,
            hrv: hrvValue,
            sleepHours: sleepHours,
            steps: stepCount,
            activeCalories: cals,
            lastUpdated: Date()
        )

        isLoading = false
    }

    // MARK: - Fetch Latest Heart Rate
    private func fetchLatestHeartRate() async -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Resting Heart Rate
    private func fetchRestingHeartRate() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                let value = statistics?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Fetch HRV
    private func fetchHRV() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Sleep Data
    private func fetchSleepData() async -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                var totalSleep: TimeInterval = 0
                for sample in samples {
                    if sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                        totalSleep += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }

                let hours = totalSleep / 3600
                continuation.resume(returning: hours > 0 ? hours : nil)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Steps
    private func fetchSteps() async -> Int? {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let value = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count())
                continuation.resume(returning: value != nil ? Int(value!) : nil)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Active Calories
    private func fetchActiveCalories() async -> Double? {
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: caloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                let value = statistics?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Calculate Overall Score
    func calculateOverallScore() -> Int {
        var score = 50 // Base score

        // Adjust based on HRV (higher is better)
        if let hrv = healthData.hrv {
            if hrv > 50 { score += 15 }
            else if hrv > 30 { score += 10 }
            else if hrv > 20 { score += 5 }
        }

        // Adjust based on resting heart rate (lower is better)
        if let rhr = healthData.restingHeartRate {
            if rhr < 55 { score += 15 }
            else if rhr < 65 { score += 10 }
            else if rhr < 75 { score += 5 }
        }

        // Adjust based on sleep (7-9 hours is optimal)
        if let sleep = healthData.sleepHours {
            if sleep >= 7 && sleep <= 9 { score += 20 }
            else if sleep >= 6 && sleep <= 10 { score += 10 }
        }

        return min(100, max(0, score))
    }
}
