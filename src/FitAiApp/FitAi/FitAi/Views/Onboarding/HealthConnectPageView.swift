//
//  HealthConnectPageView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/31/26.
//

import SwiftUI

// MARK: - Health Connect Page View

/// Onboarding page for connecting Apple Health.
/// This page appears before Personal Info to pre-fill user data.
struct HealthConnectPageView: View {
    
    // MARK: - State
    
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showPermissionDeniedAlert = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xxl) {
                Spacer(minLength: AppTheme.Spacing.xxl)
                
                // Hero Section
                heroSection
                
                // Benefits List
                benefitsList
                
                // Data Types Preview
                dataTypesSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .safeAreaInset(edge: .bottom) {
            bottomButtons
        }
        .alert("Health Access Denied", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Continue Without", role: .cancel) {
                Task {
                    await viewModel.nextStep()
                }
            }
        } message: {
            Text("To use Apple Health data, please enable access in Settings > Privacy > Health > FitAi")
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Apple Health Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.3), Color.pink.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Connect Apple Health")
                    .font(AppTheme.Typography.displayMedium())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Personalize your experience with your health data")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Benefits List
    
    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            BenefitRow(
                icon: "bolt.fill",
                iconColor: .orange,
                title: "Skip the typing",
                description: "Auto-fill your height, weight, and more"
            )
            
            BenefitRow(
                icon: "brain.head.profile",
                iconColor: AppTheme.Colors.accent,
                title: "Smarter AI predictions",
                description: "Our AI uses your real activity data"
            )
            
            BenefitRow(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .blue,
                title: "Track your progress",
                description: "See how your metrics improve over time"
            )
            
            BenefitRow(
                icon: "lock.shield.fill",
                iconColor: .green,
                title: "Private & secure",
                description: "Your data stays on your device and in your control"
            )
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    // MARK: - Data Types Section
    
    private var dataTypesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("WE'LL ACCESS")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                DataTypeChip(icon: "person.fill", label: "Profile")
                DataTypeChip(icon: "figure.walk", label: "Steps")
                DataTypeChip(icon: "flame.fill", label: "Calories")
                DataTypeChip(icon: "heart.fill", label: "Heart Rate")
                DataTypeChip(icon: "bed.double.fill", label: "Sleep")
                DataTypeChip(icon: "figure.run", label: "Workouts")
            }
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Connect Button
            Button(action: {
                Task {
                    await connectHealthKit()
                }
            }) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.background))
                    } else {
                        Image(systemName: "heart.fill")
                        Text("Connect Apple Health")
                    }
                }
            }
            .buttonStyle(AccentButtonStyle())
            .disabled(viewModel.isLoading)
            
            // Skip Button
            Button(action: {
                Task {
                    await viewModel.nextStep()
                }
            }) {
                Text("Skip for now")
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(.regularMaterial)
    }
    
    // MARK: - Connect HealthKit
    
    private func connectHealthKit() async {
        let success = await viewModel.connectHealthKit()
        
        if success {
            // Successfully connected, move to next step
            await viewModel.nextStep()
        } else if !viewModel.healthKitService.isAvailable {
            // HealthKit not available on this device
            await viewModel.nextStep()
        } else {
            // Permission was denied
            showPermissionDeniedAlert = true
        }
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text(description)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Data Type Chip

struct DataTypeChip: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.Colors.accent)
            
            Text(label)
                .font(AppTheme.Typography.labelSmall())
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(AppTheme.Colors.accent.opacity(0.08))
        .cornerRadius(AppTheme.CornerRadius.medium)
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
    
    return HealthConnectPageView(viewModel: viewModel)
        .appBackground()
}
