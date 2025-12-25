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
    var waterIntake: Double? // in fluid ounces
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

        // Dietary Water
        if let water = HKObjectType.quantityType(forIdentifier: .dietaryWater) {
            types.insert(water)
        }

        return types
    }()

    private let writeTypes: Set<HKSampleType> = {
        var types = Set<HKSampleType>()

        // Workouts
        types.insert(HKObjectType.workoutType())

        // Active Energy Burned (for workout data)
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }

        // Dietary Water
        if let water = HKObjectType.quantityType(forIdentifier: .dietaryWater) {
            types.insert(water)
        }

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
        async let water = fetchTodayWaterIntake()

        let (hr, rhr, hrvValue, sleepHours, stepCount, cals, waterOz) = await (
            heartRate, restingHR, hrv, sleep, steps, calories, water
        )

        healthData = HealthData(
            heartRate: hr,
            restingHeartRate: rhr,
            hrv: hrvValue,
            sleepHours: sleepHours,
            steps: stepCount,
            activeCalories: cals,
            waterIntake: waterOz,
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

    // MARK: - Fetch Today's Water Intake
    private func fetchTodayWaterIntake() async -> Double? {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: waterType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                // HealthKit stores water in liters, convert to fluid ounces
                if let liters = statistics?.sumQuantity()?.doubleValue(for: HKUnit.liter()) {
                    let fluidOunces = liters * 33.814 // 1 liter = 33.814 fl oz
                    continuation.resume(returning: fluidOunces)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Save Water Intake to HealthKit
    func saveWaterIntake(ounces: Double) async -> Bool {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            return false
        }

        // Convert fluid ounces to liters for HealthKit
        let liters = ounces / 33.814
        let quantity = HKQuantity(unit: HKUnit.liter(), doubleValue: liters)
        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: Date(),
            end: Date()
        )

        do {
            try await healthStore.save(sample)
            // Refresh data after saving
            await fetchTodayData()
            return true
        } catch {
            print("Failed to save water intake: \(error)")
            return false
        }
    }

    // MARK: - Delete Water Sample (for undo functionality)
    func deleteLastWaterSample() async -> Bool {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            return false
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: waterType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, _ in
                guard let sample = samples?.first else {
                    continuation.resume(returning: false)
                    return
                }

                self?.healthStore.delete(sample) { success, error in
                    if let error = error {
                        print("Failed to delete water sample: \(error)")
                    }
                    continuation.resume(returning: success)
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Get Water Intake for Date Range
    func getWaterIntakeHistory(days: Int) async -> [Date: Double] {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            return [:]
        }

        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now))!

        var interval = DateComponents()
        interval.day = 1

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: waterType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, _ in
                var waterByDate: [Date: Double] = [:]

                results?.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                    if let liters = statistics.sumQuantity()?.doubleValue(for: HKUnit.liter()) {
                        let fluidOunces = liters * 33.814
                        waterByDate[statistics.startDate] = fluidOunces
                    }
                }

                continuation.resume(returning: waterByDate)
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
