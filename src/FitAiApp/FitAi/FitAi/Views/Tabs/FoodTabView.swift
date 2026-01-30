//
//  FoodTabView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Food Tab View

/// The food/nutrition tab content view with premium dark green design.
struct FoodTabView: View {
    
    // MARK: - State
    
    @StateObject private var viewModel: FoodCaptureViewModel
    @State private var showImageSourcePicker = false
    
    // MARK: - Initialization
    
    init() {
        let clientProvider = SupabaseClientProvider()
        let storageService = SupabaseStorageService(clientProvider: clientProvider)
        let analysisService = MockFoodAnalysisService()
        
        _viewModel = StateObject(wrappedValue: FoodCaptureViewModel(
            storageService: storageService,
            analysisService: analysisService
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main content based on state
            contentForState
            
            // Floating capture button (only in idle state)
            if case .idle = viewModel.state {
                captureButton
            }
        }
        .appBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Food")
                    .font(AppTheme.Typography.headlineSmall())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
        .confirmationDialog(
            "Add Food Photo",
            isPresented: $showImageSourcePicker,
            titleVisibility: .visible
        ) {
            if ImagePicker.isCameraAvailable {
                Button("Take Photo") {
                    viewModel.openCamera()
                }
            }
            Button("Choose from Library") {
                viewModel.openPhotoLibrary()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $viewModel.showCamera) {
            ImagePicker(sourceType: .camera) { image in
                viewModel.onImageCaptured(image)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.showPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary) { image in
                viewModel.onImageCaptured(image)
            }
        }
    }
    
    // MARK: - Content for State
    
    @ViewBuilder
    private var contentForState: some View {
        switch viewModel.state {
        case .idle:
            idleView
        case .captured(let image):
            capturedImageView(image)
        case .uploading:
            processingView(title: "Uploading Image...", subtitle: "Saving to cloud storage")
        case .analyzing:
            processingView(title: "Analyzing Food...", subtitle: "AI is detecting your meal")
        case .review:
            FoodReviewView(viewModel: viewModel)
        case .submitting:
            processingView(title: "Logging Meal...", subtitle: "Saving to your food diary")
        case .success:
            successView
        case .error(let message):
            errorView(message: message)
        }
    }
    
    // MARK: - Idle View
    
    private var idleView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xxl) {
                // Today's Summary Card
                todaySummaryCard
                
                // Recent Meals Section
                recentMealsSection
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.lg)
        }
    }
    
    // MARK: - Today's Summary Card
    
    private var todaySummaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("TODAY'S NUTRITION")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            HStack(spacing: AppTheme.Spacing.xxl) {
                NutritionStatView(
                    value: "1,245",
                    label: "Calories",
                    progress: 0.62,
                    color: AppTheme.Colors.warning
                )
                
                NutritionStatView(
                    value: "85g",
                    label: "Protein",
                    progress: 0.7,
                    color: AppTheme.Colors.error
                )
                
                NutritionStatView(
                    value: "130g",
                    label: "Carbs",
                    progress: 0.5,
                    color: AppTheme.Colors.info
                )
                
                NutritionStatView(
                    value: "45g",
                    label: "Fat",
                    progress: 0.55,
                    color: AppTheme.Colors.accent
                )
            }
        }
        .padding(AppTheme.Spacing.xl)
        .cardStyle()
    }
    
    // MARK: - Recent Meals Section
    
    private var recentMealsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Recent Meals")
                .font(AppTheme.Typography.headline())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            // Empty state
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.Colors.accent.opacity(0.3))
                
                Text("No meals logged today")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                Text("Tap the camera button to log your first meal")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xxxl)
            .cardStyle()
        }
    }
    
    // MARK: - Capture Button
    
    private var captureButton: some View {
        VStack {
            Spacer()
            
            Button(action: {
                showImageSourcePicker = true
            }) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Capture Food")
                        .font(AppTheme.Typography.bodyMedium())
                }
                .foregroundStyle(AppTheme.Colors.background)
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(AppTheme.Colors.accent)
                .clipShape(Capsule())
                .shadow(color: AppTheme.Shadows.buttonGlow, radius: 15, y: 5)
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Captured Image View
    
    private func capturedImageView(_ image: UIImage) -> some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            Spacer()
            
            // Image preview
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 350)
                .cornerRadius(AppTheme.CornerRadius.large)
                .shadow(color: .black.opacity(0.3), radius: 20)
                .padding(.horizontal, AppTheme.Spacing.xl)
            
            Text("Ready to analyze your meal?")
                .font(AppTheme.Typography.headline())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            // Buttons
            VStack(spacing: AppTheme.Spacing.md) {
                Button(action: {
                    Task {
                        await viewModel.confirmCapture()
                    }
                }) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "sparkles")
                        Text("Analyze Food")
                    }
                }
                .buttonStyle(AccentButtonStyle())
                
                Button(action: {
                    viewModel.cancel()
                }) {
                    Text("Retake Photo")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            
            Spacer()
        }
    }
    
    // MARK: - Processing View
    
    private func processingView(title: String, subtitle: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                .scaleEffect(1.5)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(AppTheme.Typography.headline())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.Colors.accent)
            
            Text("Meal Logged!")
                .font(AppTheme.Typography.displayMedium())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            Text("Your food has been added to your diary.")
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            Spacer()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.Colors.error)
            
            Text("Something went wrong")
                .font(AppTheme.Typography.headline())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            Text(message)
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
            
            Button("Try Again") {
                viewModel.reset()
            }
            .buttonStyle(AccentButtonStyle(isFullWidth: false))
            
            Spacer()
        }
    }
}

// MARK: - Nutrition Stat View

struct NutritionStatView: View {
    let value: String
    let label: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text(value)
                    .font(AppTheme.Typography.captionMedium())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            .frame(width: 55, height: 55)
            
            Text(label)
                .font(AppTheme.Typography.labelSmall())
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FoodTabView()
    }
}
