import Foundation
import Combine
import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let dailyCheckInSaved = Notification.Name("dailyCheckInSaved")
    static let waterIntakeUpdated = Notification.Name("waterIntakeUpdated")
    static let workoutStarted = Notification.Name("workoutStarted")
    static let workoutCompleted = Notification.Name("workoutCompleted")
    static let healthDataUpdated = Notification.Name("healthDataUpdated")
    static let challengeDataUpdated = Notification.Name("challengeDataUpdated")
    static let personalRecordAchieved = Notification.Name("personalRecordAchieved")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}

// MARK: - Data Refresh Service
@MainActor
class DataRefreshService: ObservableObject {
    static let shared = DataRefreshService()

    @Published var lastMoodUpdate: Date = Date()
    @Published var lastWaterUpdate: Date = Date()
    @Published var lastHealthUpdate: Date = Date()
    @Published var lastWorkoutUpdate: Date = Date()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .dailyCheckInSaved)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.lastMoodUpdate = Date()
                self?.lastHealthUpdate = Date()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .waterIntakeUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.lastWaterUpdate = Date()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .workoutStarted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.lastWorkoutUpdate = Date()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .workoutCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.lastWorkoutUpdate = Date()
                self?.lastHealthUpdate = Date()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .healthDataUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.lastHealthUpdate = Date()
            }
            .store(in: &cancellables)
    }

    // MARK: - Manual Refresh Triggers

    func triggerMoodRefresh() {
        lastMoodUpdate = Date()
        NotificationCenter.default.post(name: .dailyCheckInSaved, object: nil)
    }

    func triggerWaterRefresh() {
        lastWaterUpdate = Date()
        NotificationCenter.default.post(name: .waterIntakeUpdated, object: nil)
    }

    func triggerHealthRefresh() {
        lastHealthUpdate = Date()
        NotificationCenter.default.post(name: .healthDataUpdated, object: nil)
    }

    func triggerWorkoutRefresh() {
        lastWorkoutUpdate = Date()
        NotificationCenter.default.post(name: .workoutCompleted, object: nil)
    }

    func triggerFullRefresh() {
        let now = Date()
        lastMoodUpdate = now
        lastWaterUpdate = now
        lastHealthUpdate = now
        lastWorkoutUpdate = now
    }
}
