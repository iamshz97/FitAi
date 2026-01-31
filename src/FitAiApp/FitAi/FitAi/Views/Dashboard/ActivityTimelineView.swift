//
//  ActivityTimelineView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/31/26.
//

import SwiftUI

// MARK: - Activity Timeline View

/// Displays a chronological list of workouts and meals for the day.
struct ActivityTimelineView: View {
    
    // MARK: - Properties
    
    let activities: [ScheduledActivity]
    let onWorkoutTap: (WorkoutSession) -> Void
    let onWorkoutSkip: (WorkoutSession) -> Void
    let onMealComplete: (MealPlan) -> Void
    let onMealSkip: (MealPlan) -> Void
    
    /// The next upcoming activity based on current time (only future activities)
    private var upNextActivity: ScheduledActivity? {
        let now = Date()
        // Only return activities that are AFTER current time and still pending
        return activities.first { activity in
            activity.isPending && activity.scheduledFor > now
        }
        // NO FALLBACK - if everything is past, nothing is "up next"
    }
    
    // MARK: - Body
    
    var body: some View {
        if activities.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                ForEach(activities) { activity in
                    ActivityRowView(
                        activity: activity,
                        isUpNext: activity.id == upNextActivity?.id,
                        onWorkoutTap: onWorkoutTap,
                        onWorkoutSkip: onWorkoutSkip,
                        onMealComplete: onMealComplete,
                        onMealSkip: onMealSkip
                    )
                    
                    if activity.id != activities.last?.id {
                        timelineConnector
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            
            Text("No activities scheduled")
                .font(AppTheme.Typography.headline())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            Text("Your workout and meal plan will appear here")
                .font(AppTheme.Typography.caption())
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppTheme.Spacing.xxxl)
    }
    
    // MARK: - Timeline Connector
    
    private var timelineConnector: some View {
        HStack {
            Rectangle()
                .fill(AppTheme.Colors.chipBorder)
                .frame(width: 2, height: 24)
                .padding(.leading, 23)
            Spacer()
        }
    }
}

// MARK: - Activity Row View

struct ActivityRowView: View {
    
    // MARK: - Properties
    
    let activity: ScheduledActivity
    let isUpNext: Bool
    let onWorkoutTap: (WorkoutSession) -> Void
    let onWorkoutSkip: (WorkoutSession) -> Void
    let onMealComplete: (MealPlan) -> Void
    let onMealSkip: (MealPlan) -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.lg) {
            // Timeline dot
            timelineDot
            
            // Content card
            contentCard
        }
    }
    
    // MARK: - Timeline Dot
    
    private var timelineDot: some View {
        ZStack {
            Circle()
                .fill(dotColor.opacity(0.2))
                .frame(width: 48, height: 48)
            
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundStyle(dotColor)
        }
    }
    
    private var dotColor: Color {
        if activity.isCompleted {
            return AppTheme.Colors.success
        }
        
        if isUpNext {
            return AppTheme.Colors.info // Highlight up next in blue
        }
        
        switch activity {
        case .workout: return AppTheme.Colors.warning
        case .meal: return AppTheme.Colors.accent
        }
    }
    
    private var iconName: String {
        if activity.isCompleted {
            return "checkmark.circle.fill"
        }
        
        switch activity {
        case .workout: return "figure.run"
        case .meal(let meal): return meal.mealType.icon
        }
    }
    
    /// Check if this activity is past its scheduled time but still pending
    private var isOverdue: Bool {
        activity.isPending && activity.scheduledFor < Date()
    }
    
    // MARK: - Content Card
    
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Time and status
            HStack {
                Text(activity.timeDisplay)
                    .font(AppTheme.Typography.captionMedium())
                    .foregroundStyle(isOverdue ? AppTheme.Colors.error : AppTheme.Colors.textTertiary)
                
                if isUpNext && activity.isPending {
                    Text("UP NEXT")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.Colors.info)
                        .cornerRadius(4)
                } else if isOverdue {
                    Text("OVERDUE")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.Colors.error)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                statusBadge
            }
            
            // Title
            Text(activity.title)
                .font(AppTheme.Typography.bodyMedium())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            // Details based on type
            detailsView
            
            // Action buttons
            if activity.isPending {
                actionButtons
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
    }
    
    // MARK: - Status Badge
    
    private var statusBadge: some View {
        Group {
            if activity.isCompleted {
                Text("Completed")
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundStyle(AppTheme.Colors.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.Colors.success.opacity(0.15))
                    .cornerRadius(4)
            } else {
                switch activity {
                case .workout(let workout) where workout.status == .skipped:
                    Text("Skipped")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.Colors.chipBorder)
                        .cornerRadius(4)
                case .meal(let meal) where meal.status == .skipped:
                    Text("Skipped")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.Colors.chipBorder)
                        .cornerRadius(4)
                default:
                    EmptyView()
                }
            }
        }
    }
    
    // MARK: - Details View
    
    @ViewBuilder
    private var detailsView: some View {
        switch activity {
        case .workout(let workout):
            HStack(spacing: AppTheme.Spacing.md) {
                if let duration = workout.durationMinutes {
                    Label("\(duration) min", systemImage: "clock")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                if let difficulty = workout.difficulty {
                    Label(difficulty.capitalized, systemImage: "flame")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            
        case .meal(let meal):
            VStack(alignment: .leading, spacing: 4) {
                if let calories = meal.calories {
                    Label("\(calories) kcal", systemImage: "flame")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                if !meal.macrosDisplay.isEmpty {
                    Text(meal.macrosDisplay)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            switch activity {
            case .workout(let workout):
                Button(action: handleTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                        Text("Start")
                    }
                    .font(AppTheme.Typography.captionMedium())
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.warning)
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
                
                Button(action: { onWorkoutSkip(workout) }) {
                    Text("Skip")
                        .font(AppTheme.Typography.captionMedium())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.chipBorder)
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
                
            case .meal(let meal):
                Button(action: { onMealComplete(meal) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Done")
                    }
                    .font(AppTheme.Typography.captionMedium())
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.accent)
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
                
                Button(action: { onMealSkip(meal) }) {
                    Text("Skip")
                        .font(AppTheme.Typography.captionMedium())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.chipBorder)
                        .cornerRadius(AppTheme.CornerRadius.small)
                }
            }
        }
        .padding(.top, AppTheme.Spacing.sm)
    }
    
    // MARK: - Handle Tap
    
    private func handleTap() {
        switch activity {
        case .workout(let workout):
            onWorkoutTap(workout)
        case .meal:
            break // Meals don't have detail view
        }
    }
}
