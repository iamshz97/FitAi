//
//  PersonalInfoPageView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Personal Info Page View

/// Onboarding Page 1: Collects birth year, sex, height, and weight.
struct PersonalInfoPageView: View {
    
    // MARK: - State
    
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showHeightPicker = false
    @State private var showWeightPicker = false
    @State private var showBodyFatPicker = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
                // Header
                headerSection
                
                // Birth Year
                birthYearSection
                
                // Sex at Birth
                sexSection
                
                // Height & Weight
                bodyMetricsSection
                
                // BMI Display
                bmiSection
                
                // Body Fat Percentage
                bodyFatSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.xxl)
        }
        .safeAreaInset(edge: .bottom) {
            bottomButton
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Tell us about yourself")
                .font(AppTheme.Typography.displayMedium())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            Text("This helps us personalize your experience.")
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Birth Year Section
    
    private var birthYearSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("BIRTH YEAR")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            // Year picker
            Picker("Birth Year", selection: $viewModel.birthYear) {
                ForEach((1940...2010).reversed(), id: \.self) { year in
                    Text(String(year))
                        .tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.large)
            
            // Age display
            if let age = viewModel.birthYear > 0 ? Calendar.current.component(.year, from: Date()) - viewModel.birthYear : nil {
                Text("You are \(age) years old")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.accent)
            }
        }
    }
    
    // MARK: - Sex Section
    
    private var sexSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("SEX AT BIRTH")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            // Selection chips
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                ForEach(SexAtBirth.allCases, id: \.self) { sex in
                    SelectionChip(
                        title: sex.displayName,
                        isSelected: viewModel.sexAtBirth == sex
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.sexAtBirth = sex
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Body Metrics Section
    
    private var bodyMetricsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("BODY METRICS")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            HStack(spacing: AppTheme.Spacing.md) {
                // Height
                MetricCard(
                    title: "Height",
                    value: String(format: "%.0f", viewModel.heightCm),
                    unit: "cm",
                    icon: "ruler"
                ) {
                    showHeightPicker = true
                }
                
                // Weight
                MetricCard(
                    title: "Weight",
                    value: String(format: "%.1f", viewModel.weightKg),
                    unit: "kg",
                    icon: "scalemass"
                ) {
                    showWeightPicker = true
                }
            }
        }
        .sheet(isPresented: $showHeightPicker) {
            HeightPickerSheet(heightCm: $viewModel.heightCm)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showWeightPicker) {
            WeightPickerSheet(weightKg: $viewModel.weightKg)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - BMI Section
    
    private var bmiSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("YOUR BMI")
                    .font(AppTheme.Typography.label())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs) {
                    Text(String(format: "%.1f", viewModel.calculatedBMI))
                        .font(AppTheme.Typography.statMedium())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    Text(viewModel.bmiCategory)
                        .font(AppTheme.Typography.captionMedium())
                        .foregroundStyle(bmiColor)
                }
            }
            
            Spacer()
            
            // BMI scale indicator
            ZStack {
                Circle()
                    .fill(bmiColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: bmiIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(bmiColor)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .background(
            LinearGradient(
                colors: [bmiColor.opacity(0.1), AppTheme.Colors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    private var bmiColor: Color {
        let bmi = viewModel.calculatedBMI
        switch bmi {
        case ..<18.5: return AppTheme.Colors.info
        case 18.5..<25: return AppTheme.Colors.accent
        case 25..<30: return AppTheme.Colors.warning
        default: return AppTheme.Colors.error
        }
    }
    
    private var bmiIcon: String {
        let bmi = viewModel.calculatedBMI
        switch bmi {
        case ..<18.5: return "arrow.down.circle.fill"
        case 18.5..<25: return "checkmark.circle.fill"
        case 25..<30: return "exclamationmark.circle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }
    
    // MARK: - Body Fat Section
    
    private var bodyFatSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text("BODY FAT")
                            .font(AppTheme.Typography.label())
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        
                        if viewModel.isBodyFatOverridden {
                            Text("(custom)")
                                .font(AppTheme.Typography.labelSmall())
                                .foregroundStyle(AppTheme.Colors.accent)
                        } else {
                            Text("(estimated)")
                                .font(AppTheme.Typography.labelSmall())
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs) {
                        Text(String(format: "%.1f", viewModel.bodyFatPercentage))
                            .font(AppTheme.Typography.statMedium())
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        
                        Text("%")
                            .font(AppTheme.Typography.body())
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Edit button
                Button(action: {
                    showBodyFatPicker = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(AppTheme.Typography.captionMedium())
                    .foregroundStyle(AppTheme.Colors.accent)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.accent.opacity(0.15))
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
            }
            
            // DEXA tip
            Text("💡 For accurate results, use a DEXA scan at your gym")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .sheet(isPresented: $showBodyFatPicker) {
            BodyFatPickerSheet(
                bodyFatOverride: $viewModel.bodyFatOverride,
                estimatedValue: viewModel.estimatedBodyFat
            )
            .presentationDetents([.height(350)])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Bottom Button
    
    private var bottomButton: some View {
        VStack(spacing: 0) {
            Button(action: {
                Task {
                    await viewModel.nextStep()
                }
            }) {
                Text("Continue")
            }
            .buttonStyle(AccentButtonStyle())
            .disabled(!viewModel.canProceedPage1)
            .opacity(viewModel.canProceedPage1 ? 1.0 : 0.5)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.lg)
        }
        .background(.regularMaterial)
    }
}

// MARK: - Selection Chip

struct SelectionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.bodyMedium())
                .foregroundStyle(isSelected ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.chipBorder, lineWidth: 1)
                )
        }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.Colors.accent)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(value)
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        
                        Text(unit)
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
                
                Text("Tap to edit")
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundStyle(AppTheme.Colors.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xl)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.large)
        }
    }
}

// MARK: - Height Picker Sheet

struct HeightPickerSheet: View {
    @Binding var heightCm: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Select Height")
                .font(AppTheme.Typography.headline())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            Picker("Height", selection: $heightCm) {
                ForEach(Array(stride(from: 120.0, to: 220.0, by: 1.0)), id: \.self) { cm in
                    Text("\(Int(cm)) cm")
                        .tag(cm)
                }
            }
            .pickerStyle(.wheel)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(AccentButtonStyle())
        }
        .padding(AppTheme.Spacing.xl)
        .appBackground()
    }
}

// MARK: - Weight Picker Sheet

struct WeightPickerSheet: View {
    @Binding var weightKg: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Select Weight")
                .font(AppTheme.Typography.headline())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            Picker("Weight", selection: $weightKg) {
                ForEach(Array(stride(from: 30.0, to: 200.0, by: 0.5)), id: \.self) { kg in
                    Text(String(format: "%.1f kg", kg))
                        .tag(kg)
                }
            }
            .pickerStyle(.wheel)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(AccentButtonStyle())
        }
        .padding(AppTheme.Spacing.xl)
        .appBackground()
    }
}

// MARK: - Body Fat Picker Sheet

struct BodyFatPickerSheet: View {
    @Binding var bodyFatOverride: Double?
    let estimatedValue: Double
    @Environment(\.dismiss) private var dismiss
    
    @State private var sliderValue: Double = 20
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Body Fat Percentage")
                .font(AppTheme.Typography.headline())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            // Current value display
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", sliderValue))
                    .font(AppTheme.Typography.displayMedium())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text("%")
                    .font(AppTheme.Typography.headline())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            // Slider
            VStack(spacing: AppTheme.Spacing.sm) {
                Slider(value: $sliderValue, in: 5...50, step: 0.5)
                    .accentColor(AppTheme.Colors.accent)
                
                HStack {
                    Text("5%")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                    Spacer()
                    Text("50%")
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
            
            // Reset to estimate button
            Button(action: {
                sliderValue = estimatedValue
                bodyFatOverride = nil
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset to Estimate (\(String(format: "%.1f", estimatedValue))%)")
                }
                .font(AppTheme.Typography.caption())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Button("Done") {
                bodyFatOverride = sliderValue
                dismiss()
            }
            .buttonStyle(AccentButtonStyle())
        }
        .padding(AppTheme.Spacing.xl)
        .appBackground()
        .onAppear {
            sliderValue = bodyFatOverride ?? estimatedValue
        }
    }
}

// MARK: - Preview

#Preview {
    let mockProvider = SupabaseClientProvider()
    let profileService = SupabaseUserProfileService(clientProvider: mockProvider)
    let viewModel = OnboardingViewModel(profileService: profileService)
    
    return PersonalInfoPageView(viewModel: viewModel)
        .appBackground()
}
