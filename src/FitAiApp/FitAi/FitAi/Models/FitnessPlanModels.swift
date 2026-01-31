//
//  FitnessPlanModels.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/31/26.
//

import Foundation

// MARK: - Workout Session

/// Represents a scheduled workout session from workout_sessions_v2.
struct WorkoutSession: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let scheduledFor: Date
    let durationMinutes: Int?
    let difficulty: String?
    var status: WorkoutStatus
    let createdAt: Date?
    
    /// Exercises for this workout (loaded separately)
    var exercises: [WorkoutExercise]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case scheduledFor = "scheduled_for"
        case durationMinutes = "duration_minutes"
        case difficulty
        case status
        case createdAt = "created_at"
    }
    
    /// Computed property for completion percentage
    var completionPercentage: Double {
        guard let exercises = exercises, !exercises.isEmpty else { return 0 }
        let completed = exercises.filter { $0.isCompleted }.count
        return Double(completed) / Double(exercises.count)
    }
    
    /// Whether all exercises are completed
    var isFullyCompleted: Bool {
        guard let exercises = exercises, !exercises.isEmpty else { return false }
        return exercises.allSatisfy { $0.isCompleted }
    }
}

// MARK: - Workout Status

enum WorkoutStatus: String, Codable {
    case pending
    case completed
    case skipped
}

// MARK: - Workout Exercise

/// Represents an exercise within a workout from workout_exercises_v2.
struct WorkoutExercise: Identifiable, Codable, Equatable {
    let id: UUID
    let workoutSessionId: UUID
    let exerciseName: String
    let sets: Int?
    let reps: Int?
    let weightKg: Double?
    let restSeconds: Int?
    let orderIndex: Int
    var isCompleted: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case workoutSessionId = "workout_session_id"
        case exerciseName = "exercise_name"
        case sets
        case reps
        case weightKg = "weight_kg"
        case restSeconds = "rest_seconds"
        case orderIndex = "order_index"
        case isCompleted = "is_completed"
        case createdAt = "created_at"
    }
    
    /// Display string for sets x reps
    var setsRepsDisplay: String {
        guard let sets = sets, let reps = reps else { return "" }
        return "\(sets) × \(reps)"
    }
    
    /// Display string for weight
    var weightDisplay: String? {
        guard let weight = weightKg, weight > 0 else { return nil }
        return "\(Int(weight)) kg"
    }
}

// MARK: - Meal Plan

/// Represents a scheduled meal from meal_plans_v2.
struct MealPlan: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let title: String
    let mealType: MealType
    let description: String?
    let scheduledFor: Date
    let calories: Int?
    let proteinG: Double?
    let carbsG: Double?
    let fatG: Double?
    var status: MealStatus
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case mealType = "meal_type"
        case description
        case scheduledFor = "scheduled_for"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case status
        case createdAt = "created_at"
    }
    
    /// Formatted macros string
    var macrosDisplay: String {
        var parts: [String] = []
        if let p = proteinG { parts.append("\(Int(p))g protein") }
        if let c = carbsG { parts.append("\(Int(c))g carbs") }
        if let f = fatG { parts.append("\(Int(f))g fat") }
        return parts.joined(separator: " • ")
    }
}

// MARK: - Meal Type

enum MealType: String, Codable {
    case breakfast
    case lunch
    case dinner
    case snack
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "sun.horizon.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "carrot.fill"
        }
    }
}

// MARK: - Meal Status

enum MealStatus: String, Codable {
    case pending
    case completed
    case skipped
    case deviated
}

// MARK: - Scheduled Activity

/// A unified type for displaying workouts and meals in a timeline.
enum ScheduledActivity: Identifiable, Equatable {
    case workout(WorkoutSession)
    case meal(MealPlan)
    
    var id: UUID {
        switch self {
        case .workout(let session): return session.id
        case .meal(let plan): return plan.id
        }
    }
    
    var scheduledFor: Date {
        switch self {
        case .workout(let session): return session.scheduledFor
        case .meal(let plan): return plan.scheduledFor
        }
    }
    
    var title: String {
        switch self {
        case .workout(let session): return session.title
        case .meal(let plan): return plan.title
        }
    }
    
    var isCompleted: Bool {
        switch self {
        case .workout(let session): return session.status == .completed
        case .meal(let plan): return plan.status == .completed
        }
    }
    
    var isPending: Bool {
        switch self {
        case .workout(let session): return session.status == .pending
        case .meal(let plan): return plan.status == .pending
        }
    }
    
    /// Time display (e.g., "7:00 AM")
    var timeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: scheduledFor)
    }
}

// MARK: - Day Summary

/// Summary of activities for a single day.
struct DaySummary {
    let date: Date
    let workouts: [WorkoutSession]
    let meals: [MealPlan]
    
    /// All activities sorted by scheduled time
    var activities: [ScheduledActivity] {
        let workoutActivities = workouts.map { ScheduledActivity.workout($0) }
        let mealActivities = meals.map { ScheduledActivity.meal($0) }
        return (workoutActivities + mealActivities).sorted { $0.scheduledFor < $1.scheduledFor }
    }
    
    /// Completion percentage for the day
    var completionPercentage: Double {
        let total = workouts.count + meals.count
        guard total > 0 else { return 0 }
        
        let completedWorkouts = workouts.filter { $0.status == .completed }.count
        let completedMeals = meals.filter { $0.status == .completed }.count
        
        return Double(completedWorkouts + completedMeals) / Double(total)
    }
    
    /// Total workouts completed
    var workoutsCompleted: Int {
        workouts.filter { $0.status == .completed }.count
    }
    
    /// Total meals logged
    var mealsCompleted: Int {
        meals.filter { $0.status == .completed }.count
    }
    
    /// Whether this is today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Formatted date display
    var dateDisplay: String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}
