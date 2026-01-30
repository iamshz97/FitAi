//
//  PreferencesPageView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Preferences Page View

/// Onboarding Page 2: Collects goal, activity level, schedule, and equipment.
struct PreferencesPageView: View {
    
    // MARK: - State
    
    @ObservedObject var viewModel: OnboardingViewModel
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
                // Header
                headerSection
                
                // Goal Selection
                goalSection
                
                // Activity Level
                activitySection
                
                // Schedule
                scheduleSection
                
                // Equipment
                equipmentSection
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.xxl)
        }
        .safeAreaInset(edge: .bottom) {
            bottomButtons
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Your fitness journey")
                .font(AppTheme.Typography.displayMedium())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            Text("Let's set up your goals and preferences.")
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Goal Section
    
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("PRIMARY GOAL")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: viewModel.goal == goal
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.goal = goal
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("CURRENT ACTIVITY LEVEL")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    ActivityLevelRow(
                        level: level,
                        isSelected: viewModel.activityLevel == level
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.activityLevel = level
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Schedule Section
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("WORKOUT SCHEDULE")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            HStack(spacing: AppTheme.Spacing.md) {
                // Days per week
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Days/Week")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    
                    Stepper(value: $viewModel.daysPerWeek, in: 1...7) {
                        HStack {
                            Spacer()
                            Text("\(viewModel.daysPerWeek)")
                                .font(AppTheme.Typography.statMedium())
                                .foregroundStyle(AppTheme.Colors.accent)
                            Spacer()
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .frame(maxWidth: .infinity)
                
                // Minutes per session
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Minutes/Session")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    
                    Stepper(value: $viewModel.minutesPerSession, in: 15...120, step: 15) {
                        HStack {
                            Spacer()
                            Text("\(viewModel.minutesPerSession)")
                                .font(AppTheme.Typography.statMedium())
                                .foregroundStyle(AppTheme.Colors.accent)
                            Spacer()
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Equipment Section
    
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("EQUIPMENT ACCESS")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(EquipmentContext.allCases, id: \.self) { equipment in
                    EquipmentRow(
                        equipment: equipment,
                        isSelected: viewModel.equipmentContext == equipment
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.equipmentContext = equipment
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Back button
            Button(action: {
                viewModel.previousStep()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .frame(width: 50, height: 50)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
            
            // Complete button
            Button(action: {
                Task {
                    await viewModel.nextStep()
                }
            }) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.background))
                    } else {
                        Text("Complete Setup")
                        Image(systemName: "checkmark.circle.fill")
                    }
                }
            }
            .buttonStyle(AccentButtonStyle())
            .disabled(!viewModel.canProceedPage2 || viewModel.isLoading)
            .opacity(viewModel.canProceedPage2 ? 1.0 : 0.5)
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(.regularMaterial)
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: goal.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? AppTheme.Colors.background : AppTheme.Colors.accent)
                
                Text(goal.displayName)
                    .font(AppTheme.Typography.captionMedium())
                    .foregroundStyle(isSelected ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xl)
            .background(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.chipBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Activity Level Row

struct ActivityLevelRow: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.lg) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.chipBorder, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(AppTheme.Colors.accent)
                            .frame(width: 12, height: 12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    Text(level.description)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
            .background(isSelected ? AppTheme.Colors.accent.opacity(0.1) : AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.accent : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Equipment Row

struct EquipmentRow: View {
    let equipment: EquipmentContext
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.lg) {
                // Icon
                Image(systemName: equipment.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.textSecondary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(equipment.displayName)
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    Text(equipment.description)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Check indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.Colors.accent)
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(isSelected ? AppTheme.Colors.accent.opacity(0.1) : AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.accent : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    let mockProvider = SupabaseClientProvider()
    let profileService = SupabaseUserProfileService(clientProvider: mockProvider)
    let viewModel = OnboardingViewModel(profileService: profileService)
    
    return PreferencesPageView(viewModel: viewModel)
        .appBackground()
}
