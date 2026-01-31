//
//  FitnessPlanService.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/31/26.
//

import Foundation
import Supabase
import os.log

// MARK: - Logger

private let logger = Logger(subsystem: "com.fitai.app", category: "FitnessPlanService")

// MARK: - Fitness Plan Service Protocol

/// Protocol for fetching and updating fitness plan data.
protocol FitnessPlanServiceProtocol {
    /// Fetch all activities (workouts + meals) for a specific date
    func fetchActivitiesForDate(_ date: Date) async throws -> DaySummary
    
    /// Fetch a workout with its exercises
    func fetchWorkoutWithExercises(workoutId: UUID) async throws -> WorkoutSession
    
    /// Update exercise completion status
    func updateExerciseCompletion(exerciseId: UUID, isCompleted: Bool) async throws
    
    /// Update workout session status
    func updateWorkoutStatus(workoutId: UUID, status: WorkoutStatus) async throws
    
    /// Update meal plan status
    func updateMealStatus(mealId: UUID, status: MealStatus) async throws
}

// MARK: - Fitness Plan Service Implementation

/// Service for fetching and updating workout/meal data from Supabase.
final class FitnessPlanService: FitnessPlanServiceProtocol {
    
    // MARK: - Properties
    
    private let supabaseClient: SupabaseClient
    
    // MARK: - Initialization
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
        logger.info("🟢 FitnessPlanService initialized")
    }
    
    // MARK: - Get Current User ID
    
    private func getCurrentUserId() async throws -> UUID {
        let session = try await supabaseClient.auth.session
        return session.user.id
    }
    
    // MARK: - Fetch Activities for Date
    
    func fetchActivitiesForDate(_ date: Date) async throws -> DaySummary {
        logger.info("📍 Fetching activities for \(date)")
        
        let userId = try await getCurrentUserId()
        
        // Get start and end of day in user's timezone
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw FitnessPlanError.invalidDate
        }
        
        let startISO = ISO8601DateFormatter().string(from: startOfDay)
        let endISO = ISO8601DateFormatter().string(from: endOfDay)
        
        // Fetch workouts for the day
        let workoutsResponse: [WorkoutSession] = try await supabaseClient
            .from("workout_sessions_v2")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("scheduled_for", value: startISO)
            .lt("scheduled_for", value: endISO)
            .order("scheduled_for", ascending: true)
            .execute()
            .value
        
        logger.debug("  Found \(workoutsResponse.count) workouts")
        
        // Fetch meals for the day
        let mealsResponse: [MealPlan] = try await supabaseClient
            .from("meal_plans_v2")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("scheduled_for", value: startISO)
            .lt("scheduled_for", value: endISO)
            .order("scheduled_for", ascending: true)
            .execute()
            .value
        
        logger.debug("  Found \(mealsResponse.count) meals")
        
        return DaySummary(date: date, workouts: workoutsResponse, meals: mealsResponse)
    }
    
    // MARK: - Fetch Workout with Exercises
    
    func fetchWorkoutWithExercises(workoutId: UUID) async throws -> WorkoutSession {
        logger.info("📍 Fetching workout \(workoutId) with exercises")
        
        // Fetch workout session
        let workoutResponse: [WorkoutSession] = try await supabaseClient
            .from("workout_sessions_v2")
            .select()
            .eq("id", value: workoutId.uuidString)
            .limit(1)
            .execute()
            .value
        
        guard var workout = workoutResponse.first else {
            throw FitnessPlanError.workoutNotFound
        }
        
        // Fetch exercises for this workout
        let exercisesResponse: [WorkoutExercise] = try await supabaseClient
            .from("workout_exercises_v2")
            .select()
            .eq("workout_session_id", value: workoutId.uuidString)
            .order("order_index", ascending: true)
            .execute()
            .value
        
        logger.debug("  Found \(exercisesResponse.count) exercises")
        
        workout.exercises = exercisesResponse
        return workout
    }
    
    // MARK: - Update Exercise Completion
    
    func updateExerciseCompletion(exerciseId: UUID, isCompleted: Bool) async throws {
        logger.info("📍 Updating exercise \(exerciseId) completion to \(isCompleted)")
        
        try await supabaseClient
            .from("workout_exercises_v2")
            .update(["is_completed": isCompleted])
            .eq("id", value: exerciseId.uuidString)
            .execute()
        
        logger.info("✅ Exercise completion updated")
    }
    
    // MARK: - Update Workout Status
    
    func updateWorkoutStatus(workoutId: UUID, status: WorkoutStatus) async throws {
        logger.info("📍 Updating workout \(workoutId) status to \(status.rawValue)")
        
        try await supabaseClient
            .from("workout_sessions_v2")
            .update(["status": status.rawValue])
            .eq("id", value: workoutId.uuidString)
            .execute()
        
        logger.info("✅ Workout status updated")
    }
    
    // MARK: - Update Meal Status
    
    func updateMealStatus(mealId: UUID, status: MealStatus) async throws {
        logger.info("📍 Updating meal \(mealId) status to \(status.rawValue)")
        
        try await supabaseClient
            .from("meal_plans_v2")
            .update(["status": status.rawValue])
            .eq("id", value: mealId.uuidString)
            .execute()
        
        logger.info("✅ Meal status updated")
    }
}

// MARK: - Fitness Plan Errors

enum FitnessPlanError: LocalizedError {
    case invalidDate
    case workoutNotFound
    case mealNotFound
    case updateFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidDate: return "Invalid date provided"
        case .workoutNotFound: return "Workout session not found"
        case .mealNotFound: return "Meal plan not found"
        case .updateFailed(let message): return "Update failed: \(message)"
        }
    }
}
