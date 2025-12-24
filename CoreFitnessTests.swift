//
//  CoreFitnessTests.swift
//  CoreFitnessTests
//
//  Created by Jeff Miller on 12/24/25.
//

import Testing
import SwiftData
@testable import CoreFitness

// MARK: - Auth Manager Tests
@Suite("Authentication Tests")
struct AuthManagerTests {
    
    @Test("Mock user is authenticated on init")
    @MainActor
    func mockUserAuthentication() async throws {
        let authManager = AuthManager()
        
        #expect(authManager.isAuthenticated == true)
        #expect(authManager.currentUser != nil)
        #expect(authManager.currentUser?.email == "demo@corefitness.app")
        #expect(authManager.currentUser?.subscriptionTier == .premium)
    }
    
    @Test("User can sign out")
    @MainActor
    func signOut() async throws {
        let authManager = AuthManager()
        
        authManager.signOut()
        
        #expect(authManager.isAuthenticated == false)
        #expect(authManager.currentUser == nil)
    }
    
    @Test("Premium user can generate AI workouts")
    @MainActor
    func aiWorkoutGeneration() async throws {
        let authManager = AuthManager()
        
        #expect(authManager.canGenerateAIWorkout() == true)
        #expect(authManager.currentUser?.aiGenerationsRemaining == 10)
    }
}

// MARK: - HealthKit Manager Tests
@Suite("HealthKit Manager Tests")
struct HealthKitManagerTests {
    
    @Test("HealthKit manager initializes")
    @MainActor
    func initialization() async throws {
        let healthKitManager = HealthKitManager()
        
        #expect(healthKitManager.isAuthorized == false)
        #expect(healthKitManager.isLoading == false)
        #expect(healthKitManager.healthData.heartRate == nil)
    }
    
    @Test("Calculate overall score with no data")
    @MainActor
    func scoreCalculationNoData() async throws {
        let healthKitManager = HealthKitManager()
        
        let score = healthKitManager.calculateOverallScore()
        
        // Base score should be 50 with no data
        #expect(score == 50)
    }
    
    @Test("Calculate overall score with optimal data")
    @MainActor
    func scoreCalculationOptimalData() async throws {
        let healthKitManager = HealthKitManager()
        
        // Set optimal health data
        healthKitManager.healthData = HealthData(
            heartRate: 70,
            restingHeartRate: 52, // < 55 = +15
            hrv: 60, // > 50 = +15
            sleepHours: 8, // 7-9 = +20
            steps: 10000,
            activeCalories: 500,
            lastUpdated: Date()
        )
        
        let score = healthKitManager.calculateOverallScore()
        
        // Base 50 + 15 (resting HR) + 15 (HRV) + 20 (sleep) = 100
        #expect(score == 100)
    }
}

// MARK: - Workout Manager Tests
@Suite("Workout Manager Tests")
struct WorkoutManagerTests {
    
    @Test("Workout manager initializes in idle state")
    @MainActor
    func initialization() async throws {
        let workoutManager = WorkoutManager()
        
        #expect(workoutManager.currentPhase == .idle)
        #expect(workoutManager.currentSession == nil)
        #expect(workoutManager.currentExerciseIndex == 0)
        #expect(workoutManager.elapsedTime == 0)
    }
    
    @Test("Formatted elapsed time displays correctly")
    @MainActor
    func timeFormatting() async throws {
        let workoutManager = WorkoutManager()
        
        workoutManager.elapsedTime = 0
        #expect(workoutManager.formattedElapsedTime == "0:00")
        
        workoutManager.elapsedTime = 65
        #expect(workoutManager.formattedElapsedTime == "1:05")
        
        workoutManager.elapsedTime = 3661
        #expect(workoutManager.formattedElapsedTime == "61:01")
    }
}

// MARK: - Workout Model Tests
@Suite("Workout Model Tests")
struct WorkoutModelTests {
    
    @Test("Exercise initialization")
    func exerciseCreation() async throws {
        let exercise = Exercise(
            name: "Bench Press",
            category: .chest,
            difficulty: .intermediate,
            equipmentNeeded: ["Barbell", "Bench"],
            primaryMuscles: ["Pectorals"],
            secondaryMuscles: ["Triceps", "Shoulders"],
            instructions: "Lie on bench and press weight up"
        )
        
        #expect(exercise.name == "Bench Press")
        #expect(exercise.category == .chest)
        #expect(exercise.difficulty == .intermediate)
        #expect(exercise.equipmentNeeded.count == 2)
    }
    
    @Test("Workout initialization")
    func workoutCreation() async throws {
        let workout = Workout(
            name: "Push Day",
            category: .strength,
            difficulty: .intermediate,
            estimatedDuration: 60,
            caloriesEstimate: 300
        )
        
        #expect(workout.name == "Push Day")
        #expect(workout.category == .strength)
        #expect(workout.estimatedDuration == 60)
        #expect(workout.exerciseCount == 0)
    }
}

// MARK: - Subscription Tier Tests
@Suite("Subscription Tier Tests")
struct SubscriptionTierTests {
    
    @Test("Free tier has 1 AI generation per week")
    func freeTierGenerations() async throws {
        let tier = SubscriptionTier.free
        
        #expect(tier.aiGenerationsPerWeek == 1)
        #expect(tier.displayName == "Free")
    }
    
    @Test("Basic tier has 3 AI generations per week")
    func basicTierGenerations() async throws {
        let tier = SubscriptionTier.basic
        
        #expect(tier.aiGenerationsPerWeek == 3)
        #expect(tier.displayName == "Basic")
    }
    
    @Test("Premium tier has 21 AI generations per week")
    func premiumTierGenerations() async throws {
        let tier = SubscriptionTier.premium
        
        #expect(tier.aiGenerationsPerWeek == 21)
        #expect(tier.displayName == "Premium")
    }
}

// MARK: - Health Data Tests
@Suite("Health Data Tests")
struct HealthDataTests {
    
    @Test("Health data initializes with nil values")
    func healthDataInitialization() async throws {
        let healthData = HealthData()
        
        #expect(healthData.heartRate == nil)
        #expect(healthData.restingHeartRate == nil)
        #expect(healthData.hrv == nil)
        #expect(healthData.sleepHours == nil)
        #expect(healthData.steps == nil)
        #expect(healthData.activeCalories == nil)
        #expect(healthData.lastUpdated == nil)
    }
    
    @Test("Health data can be initialized with values")
    func healthDataWithValues() async throws {
        let now = Date()
        let healthData = HealthData(
            heartRate: 72,
            restingHeartRate: 58,
            hrv: 45,
            sleepHours: 7.5,
            steps: 8500,
            activeCalories: 420,
            lastUpdated: now
        )
        
        #expect(healthData.heartRate == 72)
        #expect(healthData.restingHeartRate == 58)
        #expect(healthData.hrv == 45)
        #expect(healthData.sleepHours == 7.5)
        #expect(healthData.steps == 8500)
        #expect(healthData.activeCalories == 420)
        #expect(healthData.lastUpdated == now)
    }
}

// MARK: - Workout Phase Tests
@Suite("Workout Phase Tests")
struct WorkoutPhaseTests {
    
    @Test("Workout phases are equatable")
    func phaseEquality() async throws {
        #expect(WorkoutPhase.idle == WorkoutPhase.idle)
        #expect(WorkoutPhase.exercising == WorkoutPhase.exercising)
        #expect(WorkoutPhase.completed == WorkoutPhase.completed)
        #expect(WorkoutPhase.countdown(remaining: 3) == WorkoutPhase.countdown(remaining: 3))
        #expect(WorkoutPhase.resting(remaining: 60) == WorkoutPhase.resting(remaining: 60))
    }
    
    @Test("Different workout phases are not equal")
    func phaseInequality() async throws {
        #expect(WorkoutPhase.idle != WorkoutPhase.exercising)
        #expect(WorkoutPhase.countdown(remaining: 3) != WorkoutPhase.countdown(remaining: 2))
        #expect(WorkoutPhase.resting(remaining: 60) != WorkoutPhase.resting(remaining: 30))
    }
}
