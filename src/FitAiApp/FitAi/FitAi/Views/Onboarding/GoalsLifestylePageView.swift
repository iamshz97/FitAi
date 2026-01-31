//
//  GoalsLifestylePageView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/31/26.
//

import SwiftUI

// MARK: - Goals & Lifestyle Page View

/// Onboarding Page 4: Collects fitness goals (required), training constraints, and sleep pattern.
struct GoalsLifestylePageView: View {
    
    // MARK: - State
    
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: GoalsField?
    
    private enum GoalsField: Int, CaseIterable {
        case fitnessGoals = 0
        case constraints = 1
        
        var next: GoalsField? {
            GoalsField(rawValue: rawValue + 1)
        }
        
        var isLast: Bool {
            self == .constraints
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // Header
                    headerSection
                    
                    // Fitness Goals (Required)
                    fitnessGoalsSection
                        .id("fitnessGoals")
                    
                    // Training Constraints
                    constraintsSection
                        .id("constraints")
                    
                    // Sleep Pattern
                    sleepSection
                        .id("sleep")
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.xl)
            }
            .safeAreaInset(edge: .bottom) {
                bottomButtons
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    
                    if let field = focusedField, !field.isLast {
                        Button("Next") {
                            moveToNextField(from: field, proxy: proxy)
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button("Done") {
                            focusedField = nil
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onChange(of: focusedField) { _, newField in
                if let field = newField {
                    withAnimation {
                        proxy.scrollTo(fieldId(for: field), anchor: .center)
                    }
                }
            }
        }
    }
    
    private func fieldId(for field: GoalsField) -> String {
        switch field {
        case .fitnessGoals: return "fitnessGoals"
        case .constraints: return "constraints"
        }
    }
    
    private func moveToNextField(from current: GoalsField, proxy: ScrollViewProxy) {
        if let next = current.next {
            withAnimation {
                proxy.scrollTo(fieldId(for: next), anchor: .center)
            }
            focusedField = next
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "target")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.Colors.accent)
                
                Text("Your Goals")
                    .font(AppTheme.Typography.displayMedium())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            
            Text("Let's set you up for success! Tell us what you want to achieve.")
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Fitness Goals Section
    
    private var fitnessGoalsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Title row
            HStack(spacing: AppTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.Colors.accent)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Fitness Goals")
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Text("Required")
                            .font(AppTheme.Typography.labelSmall())
                            .foregroundStyle(AppTheme.Colors.accent)
                        
                        Text("•")
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                        
                        Text("\(viewModel.fitnessGoalsRemaining) chars left")
                            .font(AppTheme.Typography.labelSmall())
                            .foregroundStyle(viewModel.fitnessGoalsRemaining < 50 ? AppTheme.Colors.warning : AppTheme.Colors.textTertiary)
                    }
                }
                
                Spacer()
            }
            
            // Text editor
            TextEditor(text: $viewModel.fitnessGoalsText)
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100, maxHeight: 150)
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.background.opacity(0.5))
                .cornerRadius(AppTheme.CornerRadius.medium)
                .focused($focusedField, equals: .fitnessGoals)
                .overlay(
                    Group {
                        if viewModel.fitnessGoalsText.isEmpty && focusedField != .fitnessGoals {
                            Text("What do you want to achieve?\n\nExamples:\n• Lose 10kg in 6 months\n• Build muscle and get stronger\n• Run a 5K race\n• Improve my overall fitness")
                                .font(AppTheme.Typography.body())
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                                .padding(AppTheme.Spacing.md)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(viewModel.fitnessGoalsText.isEmpty ? AppTheme.Colors.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            LinearGradient(
                colors: [AppTheme.Colors.accent.opacity(0.05), AppTheme.Colors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    // MARK: - Constraints Section
    
    private var constraintsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Title row
            HStack(spacing: AppTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.warning.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.Colors.warning)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Training Constraints")
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    Text("Optional")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
            
            // Text editor
            TextEditor(text: $viewModel.trainingConstraints)
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 120)
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.background.opacity(0.5))
                .cornerRadius(AppTheme.CornerRadius.medium)
                .focused($focusedField, equals: .constraints)
                .overlay(
                    Group {
                        if viewModel.trainingConstraints.isEmpty && focusedField != .constraints {
                            Text("Tell us about your schedule & limitations (e.g., can only train 4 days/week, poor sleep, busy work schedule)")
                                .font(AppTheme.Typography.body())
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                                .padding(AppTheme.Spacing.md)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    // MARK: - Sleep Section
    
    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Title row
            HStack(spacing: AppTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.info.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.Colors.info)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Average Sleep Duration")
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    Text("Optional")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
            
            // Sleep options
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.sm) {
                ForEach(SleepPattern.allCases, id: \.self) { pattern in
                    SleepOptionChip(
                        pattern: pattern,
                        isSelected: viewModel.sleepPattern == pattern
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.sleepPattern = pattern
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Back button
            Button(action: {
                viewModel.previousStep()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(AppTheme.Typography.bodyMedium())
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .frame(maxWidth: 100)
            
            // Complete button
            Button(action: {
                focusedField = nil
                Task {
                    await viewModel.completeOnboarding()
                }
            }) {
                HStack(spacing: 6) {
                    Text("Complete Setup")
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .buttonStyle(AccentButtonStyle())
            .disabled(!viewModel.canProceedPage4)
            .opacity(viewModel.canProceedPage4 ? 1.0 : 0.5)
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(.regularMaterial)
    }
}

// MARK: - Sleep Option Chip

struct SleepOptionChip: View {
    let pattern: SleepPattern
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: pattern.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? AppTheme.Colors.background : AppTheme.Colors.textSecondary)
                
                Text(pattern.displayName)
                    .font(AppTheme.Typography.captionMedium())
                    .foregroundStyle(isSelected ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.background.opacity(0.5))
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.chipBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    let mockProvider = SupabaseClientProvider()
    let profileService = SupabaseUserProfileService(clientProvider: mockProvider)
    let healthKitService = HealthKitService()
    let viewModel = OnboardingViewModel(
        profileService: profileService,
        healthKitService: healthKitService
    )
    
    GoalsLifestylePageView(viewModel: viewModel)
        .appBackground()
}
