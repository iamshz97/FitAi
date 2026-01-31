//
//  HomeTabView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Home Tab View

/// The home tab content view with What's Next experience.
struct HomeTabView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: DashboardViewModel
    
    // MARK: - Initialization
    
    init(fitnessPlanService: FitnessPlanServiceProtocol) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(fitnessPlanService: fitnessPlanService))
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
                // Header
                headerSection
                
                // Day Selector
                daySelectorSection
                
                // Progress Card
                progressCard
                
                // What's Next Timeline
                whatsNextSection
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.lg)
        }
        .appBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("FitAi")
                    .font(AppTheme.Typography.headlineSmall())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.goToToday()
                }) {
                    Text("Today")
                        .font(AppTheme.Typography.captionMedium())
                        .foregroundStyle(AppTheme.Colors.accent)
                }
            }
        }
        .task {
            await viewModel.loadActivities()
        }
        .refreshable {
            await viewModel.loadActivities()
        }
        .sheet(isPresented: $viewModel.showWorkoutDetail) {
            if let workout = viewModel.selectedWorkout {
                WorkoutDetailView(viewModel: viewModel, workout: workout)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            if let user = authViewModel.user {
                Text("Hey, \(user.displayName) 👋")
                    .font(AppTheme.Typography.displayMedium())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            } else {
                Text("Hey there 👋")
                    .font(AppTheme.Typography.displayMedium())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            
            Text("Here's your plan for \(viewModel.dateDisplay.lowercased())")
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(.top, AppTheme.Spacing.lg)
    }
    
    // MARK: - Day Selector Section
    
    private var daySelectorSection: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Previous button
            Button(action: viewModel.goToPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(viewModel.canGoPrevious ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .disabled(!viewModel.canGoPrevious)
            
            // Date display
            VStack(spacing: 4) {
                Text(viewModel.dateDisplay)
                    .font(AppTheme.Typography.headline())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text(formattedFullDate)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            
            // Next button
            Button(action: viewModel.goToNextDay) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(viewModel.canGoNext ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .disabled(!viewModel.canGoNext)
        }
    }
    
    private var formattedFullDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: viewModel.selectedDate)
    }
    
    // MARK: - Progress Card
    
    private var progressCard: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.chipBorder, lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: viewModel.completionPercentage)
                    .stroke(AppTheme.Colors.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5), value: viewModel.completionPercentage)
                
                Text("\(Int(viewModel.completionPercentage * 100))%")
                    .font(AppTheme.Typography.headlineSmall())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            
            // Stats
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Day Progress")
                    .font(AppTheme.Typography.captionMedium())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                HStack(spacing: AppTheme.Spacing.xl) {
                    // Workouts
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.Colors.warning)
                            Text("Workouts")
                                .font(AppTheme.Typography.caption())
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        Text("\(viewModel.workoutsCompleted)/\(viewModel.totalWorkouts)")
                            .font(AppTheme.Typography.bodyMedium())
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    }
                    
                    // Meals
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.Colors.accent)
                            Text("Meals")
                                .font(AppTheme.Typography.caption())
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        Text("\(viewModel.mealsCompleted)/\(viewModel.totalMeals)")
                            .font(AppTheme.Typography.bodyMedium())
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    // MARK: - What's Next Section
    
    private var whatsNextSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack {
                Text("What's Next")
                    .font(AppTheme.Typography.headline())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                }
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.error)
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.error.opacity(0.1))
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
            
            ActivityTimelineView(
                activities: viewModel.activities,
                onWorkoutTap: { workout in
                    viewModel.selectWorkout(workout)
                },
                onWorkoutSkip: { workout in
                    Task {
                        await viewModel.skipWorkoutFromTimeline(workout)
                    }
                },
                onMealComplete: { meal in
                    Task {
                        await viewModel.completeMeal(meal)
                    }
                },
                onMealSkip: { meal in
                    Task {
                        await viewModel.skipMeal(meal)
                    }
                }
            )
        }
    }
}

// MARK: - Preview

#Preview {
    let mockProvider = SupabaseClientProvider()
    let authService = SupabaseAuthService(clientProvider: mockProvider)
    let fitnessPlanService = FitnessPlanService(supabaseClient: mockProvider.client)
    let viewModel = AuthViewModel(authService: authService)
    
    return NavigationStack {
        HomeTabView(fitnessPlanService: fitnessPlanService)
            .environmentObject(viewModel)
    }
}
