//
//  DashboardViewModel.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/31/26.
//

import Foundation
import SwiftUI
import Combine
import os.log

// MARK: - Logger

private let logger = Logger(subsystem: "com.fitai.app", category: "DashboardViewModel")

// MARK: - Dashboard View Model

/// ViewModel for the home dashboard with day-by-day navigation.
@MainActor
final class DashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently selected date
    @Published var selectedDate: Date = Date()
    
    /// Day summary with activities
    @Published var daySummary: DaySummary?
    
    /// Loading state
    @Published var isLoading: Bool = false
    
    /// Error message
    @Published var errorMessage: String?
    
    /// Currently selected workout for detail view
    @Published var selectedWorkout: WorkoutSession?
    
    /// Whether workout detail sheet is shown
    @Published var showWorkoutDetail: Bool = false
    
    // MARK: - Dependencies
    
    private let fitnessPlanService: FitnessPlanServiceProtocol
    
    // MARK: - Computed Properties
    
    /// Activities for current day sorted by time
    var activities: [ScheduledActivity] {
        daySummary?.activities ?? []
    }
    
    /// Day completion percentage (0-1)
    var completionPercentage: Double {
        daySummary?.completionPercentage ?? 0
    }
    
    /// Formatted date display
    var dateDisplay: String {
        daySummary?.dateDisplay ?? "Today"
    }
    
    /// Number of workouts completed today
    var workoutsCompleted: Int {
        daySummary?.workoutsCompleted ?? 0
    }
    
    /// Total workouts today
    var totalWorkouts: Int {
        daySummary?.workouts.count ?? 0
    }
    
    /// Number of meals completed today
    var mealsCompleted: Int {
        daySummary?.mealsCompleted ?? 0
    }
    
    /// Total meals today
    var totalMeals: Int {
        daySummary?.meals.count ?? 0
    }
    
    /// Whether we can go to previous day
    var canGoPrevious: Bool {
        // Allow going back up to 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return selectedDate > thirtyDaysAgo
    }
    
    /// Whether we can go to next day
    var canGoNext: Bool {
        // Allow going forward up to 14 days
        let twoWeeksAhead = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        return selectedDate < twoWeeksAhead
    }
    
    // MARK: - Initialization
    
    init(fitnessPlanService: FitnessPlanServiceProtocol) {
        self.fitnessPlanService = fitnessPlanService
        logger.info("🟢 DashboardViewModel initialized")
    }
    
    // MARK: - Actions
    
    /// Load activities for the selected date
    func loadActivities() async {
        logger.info("📍 Loading activities for \(self.selectedDate)")
        isLoading = true
        errorMessage = nil
        
        do {
            daySummary = try await fitnessPlanService.fetchActivitiesForDate(selectedDate)
            logger.info("✅ Loaded \(self.daySummary?.activities.count ?? 0) activities")
        } catch {
            logger.error("❌ Failed to load activities: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Navigate to previous day
    func goToPreviousDay() {
        guard canGoPrevious else { return }
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        Task {
            await loadActivities()
        }
    }
    
    /// Navigate to next day
    func goToNextDay() {
        guard canGoNext else { return }
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        Task {
            await loadActivities()
        }
    }
    
    /// Go to today
    func goToToday() {
        selectedDate = Date()
        Task {
            await loadActivities()
        }
    }
    
    /// Select a workout and show detail view
    func selectWorkout(_ workout: WorkoutSession) {
        Task {
            do {
                selectedWorkout = try await fitnessPlanService.fetchWorkoutWithExercises(workoutId: workout.id)
                showWorkoutDetail = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Toggle exercise completion
    func toggleExerciseCompletion(_ exercise: WorkoutExercise) async {
        let newValue = !exercise.isCompleted
        
        do {
            try await fitnessPlanService.updateExerciseCompletion(
                exerciseId: exercise.id,
                isCompleted: newValue
            )
            
            // Update local state
            if var workout = selectedWorkout,
               let index = workout.exercises?.firstIndex(where: { $0.id == exercise.id }) {
                workout.exercises?[index].isCompleted = newValue
                selectedWorkout = workout
                
                // Check if all exercises are complete
                if workout.isFullyCompleted {
                    try await fitnessPlanService.updateWorkoutStatus(
                        workoutId: workout.id,
                        status: .completed
                    )
                    // Refresh the day summary
                    await loadActivities()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Mark workout as complete
    func completeWorkout(_ workout: WorkoutSession) async {
        do {
            // Mark all exercises as complete
            if let exercises = workout.exercises {
                for exercise in exercises where !exercise.isCompleted {
                    try await fitnessPlanService.updateExerciseCompletion(
                        exerciseId: exercise.id,
                        isCompleted: true
                    )
                }
            }
            
            // Update workout status
            try await fitnessPlanService.updateWorkoutStatus(
                workoutId: workout.id,
                status: .completed
            )
            
            showWorkoutDetail = false
            await loadActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Skip workout
    func skipWorkout(_ workout: WorkoutSession) async {
        do {
            try await fitnessPlanService.updateWorkoutStatus(
                workoutId: workout.id,
                status: .skipped
            )
            showWorkoutDetail = false
            await loadActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Mark meal as complete
    func completeMeal(_ meal: MealPlan) async {
        do {
            try await fitnessPlanService.updateMealStatus(mealId: meal.id, status: .completed)
            await loadActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Skip meal
    func skipMeal(_ meal: MealPlan) async {
        do {
            try await fitnessPlanService.updateMealStatus(mealId: meal.id, status: .skipped)
            await loadActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Skip workout directly from timeline (without opening detail view)
    func skipWorkoutFromTimeline(_ workout: WorkoutSession) async {
        do {
            try await fitnessPlanService.updateWorkoutStatus(
                workoutId: workout.id,
                status: .skipped
            )
            await loadActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
