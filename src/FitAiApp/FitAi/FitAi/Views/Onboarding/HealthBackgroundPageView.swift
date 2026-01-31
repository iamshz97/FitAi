//
//  HealthBackgroundPageView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/31/26.
//

import SwiftUI

// MARK: - Health Background Page View

/// Onboarding Page 3: Collects optional medical history, family history, and injuries.
struct HealthBackgroundPageView: View {
    
    // MARK: - State
    
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: HealthField?
    
    private enum HealthField: Int, CaseIterable {
        case medical = 0
        case family = 1
        case injuries = 2
        
        var next: HealthField? {
            HealthField(rawValue: rawValue + 1)
        }
        
        var isLast: Bool {
            self == .injuries
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // Header
                    headerSection
                    
                    // Medical History
                    healthCard(
                        id: "medical",
                        icon: "cross.case.fill",
                        iconColor: AppTheme.Colors.error,
                        title: "Medical History",
                        placeholder: "Any conditions or medications? (e.g., diabetes, asthma, blood pressure meds)",
                        text: $viewModel.medicalHistory,
                        field: .medical
                    )
                    
                    // Family Medical History
                    healthCard(
                        id: "family",
                        icon: "person.2.fill",
                        iconColor: AppTheme.Colors.info,
                        title: "Family Medical History",
                        placeholder: "Relevant family health conditions (e.g., heart disease, diabetes)",
                        text: $viewModel.familyMedicalHistory,
                        field: .family
                    )
                    
                    // Current Injuries
                    healthCard(
                        id: "injuries",
                        icon: "bandage.fill",
                        iconColor: AppTheme.Colors.warning,
                        title: "Injuries or Physical Limitations",
                        placeholder: "Any injuries, pain, or mobility issues? (e.g., lower back pain, knee injury)",
                        text: $viewModel.currentInjuries,
                        field: .injuries
                    )
                    
                    // Optional note
                    optionalNote
                    
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
    
    private func fieldId(for field: HealthField) -> String {
        switch field {
        case .medical: return "medical"
        case .family: return "family"
        case .injuries: return "injuries"
        }
    }
    
    private func moveToNextField(from current: HealthField, proxy: ScrollViewProxy) {
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
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.Colors.accent)
                
                Text("Health Background")
                    .font(AppTheme.Typography.displayMedium())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            
            Text("Help us understand your health better so we can create a safe and effective plan for you.")
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Health Card
    
    private func healthCard(
        id: String,
        icon: String,
        iconColor: Color,
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: HealthField
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Title row
            HStack(spacing: AppTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    Text("Optional")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
            
            // Text editor
            TextEditor(text: text)
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 120)
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.background.opacity(0.5))
                .cornerRadius(AppTheme.CornerRadius.medium)
                .focused($focusedField, equals: field)
                .overlay(
                    Group {
                        if text.wrappedValue.isEmpty && focusedField != field {
                            Text(placeholder)
                                .font(AppTheme.Typography.body())
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                                .padding(AppTheme.Spacing.md)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
        .id(id)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    // MARK: - Optional Note
    
    private var optionalNote: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            
            Text("All fields on this page are optional. Share what you're comfortable with.")
                .font(AppTheme.Typography.caption())
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground.opacity(0.5))
        .cornerRadius(AppTheme.CornerRadius.medium)
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
            
            // Continue button
            Button(action: {
                focusedField = nil
                Task {
                    await viewModel.nextStep()
                }
            }) {
                Text("Continue")
            }
            .buttonStyle(AccentButtonStyle())
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(.regularMaterial)
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
    
    HealthBackgroundPageView(viewModel: viewModel)
        .appBackground()
}
