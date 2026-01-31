//
//  WorkoutDetailView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/31/26.
//

import SwiftUI

// MARK: - Workout Detail View

/// Detail view for a workout session with exercise tracking.
struct WorkoutDetailView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: DashboardViewModel
    let workout: WorkoutSession
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // Header Card
                    headerCard
                    
                    // Progress Section
                    progressSection
                    
                    // Exercises List
                    exercisesSection
                    
                    // Action Buttons
                    actionButtons
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.lg)
            }
            .appBackground()
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title)
                        .font(AppTheme.Typography.headline())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    if let description = workout.description {
                        Text(description)
                            .font(AppTheme.Typography.body())
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Workout icon
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.warning.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "figure.run")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.Colors.warning)
                }
            }
            
            // Stats row
            HStack(spacing: AppTheme.Spacing.xl) {
                if let duration = workout.durationMinutes {
                    StatBadge(icon: "clock", value: "\(duration)", unit: "min")
                }
                
                if let difficulty = workout.difficulty {
                    StatBadge(icon: "flame", value: difficulty.capitalized, unit: "")
                }
                
                if let exerciseCount = workout.exercises?.count {
                    StatBadge(icon: "list.bullet", value: "\(exerciseCount)", unit: "exercises")
                }
            }
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("PROGRESS")
                    .font(AppTheme.Typography.label())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                Text("\(completedCount)/\(totalCount) exercises")
                    .font(AppTheme.Typography.captionMedium())
                    .foregroundStyle(AppTheme.Colors.accent)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.chipBorder)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.accent)
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                        .animation(.spring(response: 0.3), value: progressPercentage)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var completedCount: Int {
        workout.exercises?.filter { $0.isCompleted }.count ?? 0
    }
    
    private var totalCount: Int {
        workout.exercises?.count ?? 0
    }
    
    private var progressPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    // MARK: - Exercises Section
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("EXERCISES")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            VStack(spacing: 0) {
                if let exercises = workout.exercises {
                    ForEach(exercises) { exercise in
                        ExerciseRowView(
                            exercise: exercise,
                            onToggle: {
                                Task {
                                    await viewModel.toggleExerciseCompletion(exercise)
                                }
                            }
                        )
                        
                        if exercise.id != exercises.last?.id {
                            Divider()
                                .background(AppTheme.Colors.chipBorder)
                        }
                    }
                }
            }
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.large)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Complete button
            Button(action: {
                Task {
                    await viewModel.completeWorkout(workout)
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete Workout")
                }
                .font(AppTheme.Typography.bodyMedium())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(AppTheme.Colors.accent)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            
            // Skip button
            Button(action: {
                Task {
                    await viewModel.skipWorkout(workout)
                }
            }) {
                Text("Skip Workout")
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Exercise Row View

struct ExerciseRowView: View {
    let exercise: WorkoutExercise
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            exercise.isCompleted ? AppTheme.Colors.accent : AppTheme.Colors.chipBorder,
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)
                    
                    if exercise.isCompleted {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.Colors.accent)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            
            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundStyle(
                        exercise.isCompleted
                            ? AppTheme.Colors.textSecondary
                            : AppTheme.Colors.textPrimary
                    )
                    .strikethrough(exercise.isCompleted)
                
                HStack(spacing: AppTheme.Spacing.md) {
                    Text(exercise.setsRepsDisplay)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                    
                    if let weight = exercise.weightDisplay {
                        Text(weight)
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                    
                    if let rest = exercise.restSeconds {
                        Text("\(rest)s rest")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            // Order number
            Text("\(exercise.orderIndex + 1)")
                .font(AppTheme.Typography.captionMedium())
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .frame(width: 24, height: 24)
                .background(AppTheme.Colors.chipBorder)
                .cornerRadius(12)
        }
        .padding(AppTheme.Spacing.lg)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            
            Text(value)
                .font(AppTheme.Typography.captionMedium())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            if !unit.isEmpty {
                Text(unit)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.chipBorder.opacity(0.5))
        .cornerRadius(AppTheme.CornerRadius.small)
    }
}
