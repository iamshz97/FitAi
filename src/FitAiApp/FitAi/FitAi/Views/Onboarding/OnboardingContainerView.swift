//
//  OnboardingContainerView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Onboarding Container View

/// Main container view for the onboarding flow with step indicator.
struct OnboardingContainerView: View {
    
    // MARK: - State
    
    @StateObject private var viewModel: OnboardingViewModel
    @Binding var isOnboardingComplete: Bool
    
    // MARK: - Initialization
    
    init(profileService: UserProfileService, isOnboardingComplete: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(profileService: profileService))
        _isOnboardingComplete = isOnboardingComplete
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Step Indicator
            stepIndicator
                .padding(.top, AppTheme.Spacing.xl)
                .padding(.horizontal, AppTheme.Spacing.xl)
            
            // Content
            TabView(selection: $viewModel.currentStep) {
                PersonalInfoPageView(viewModel: viewModel)
                    .tag(OnboardingStep.personalInfo)
                
                PreferencesPageView(viewModel: viewModel)
                    .tag(OnboardingStep.preferences)
                
                HealthBackgroundPageView(viewModel: viewModel)
                    .tag(OnboardingStep.healthBackground)
                
                GoalsLifestylePageView(viewModel: viewModel)
                    .tag(OnboardingStep.goalsLifestyle)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        }
        .appBackground()
        .task {
            await viewModel.loadProfile()
        }
        .onChange(of: viewModel.isComplete) { _, complete in
            if complete {
                isOnboardingComplete = true
            }
        }
    }
    
    // MARK: - Step Indicator
    
    private var stepIndicator: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.cardBackground)
                        .frame(height: 4)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.accent)
                        .frame(width: geometry.size.width * viewModel.progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                }
            }
            .frame(height: 4)
            
            // Step labels
            HStack {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                    HStack(spacing: AppTheme.Spacing.xs) {
                        // Step number
                        ZStack {
                            Circle()
                                .fill(step.rawValue <= viewModel.currentStep.rawValue ?
                                      AppTheme.Colors.accent : AppTheme.Colors.cardBackground)
                                .frame(width: 24, height: 24)
                            
                            if step.rawValue < viewModel.currentStep.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.Colors.background)
                            } else {
                                Text("\(step.rawValue + 1)")
                                    .font(AppTheme.Typography.labelSmall())
                                    .foregroundStyle(step.rawValue <= viewModel.currentStep.rawValue ?
                                                     AppTheme.Colors.background : AppTheme.Colors.textTertiary)
                            }
                        }
                        
                        // Step title
                        Text(step.title)
                            .font(AppTheme.Typography.captionMedium())
                            .foregroundStyle(step == viewModel.currentStep ?
                                             AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                    }
                    
                    if step != OnboardingStep.allCases.last {
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let mockProvider = SupabaseClientProvider()
    let profileService = SupabaseUserProfileService(clientProvider: mockProvider)
    
    return OnboardingContainerView(
        profileService: profileService,
        isOnboardingComplete: .constant(false)
    )
}
