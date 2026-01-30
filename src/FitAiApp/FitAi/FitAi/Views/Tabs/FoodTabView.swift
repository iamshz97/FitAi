//
//  FoodTabView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Food Tab View

/// The food/nutrition tab content view.
/// Track meals by capturing food photos and getting AI-powered nutritional analysis.
struct FoodTabView: View {
    
    // MARK: - State
    
    @StateObject private var viewModel: FoodCaptureViewModel
    @State private var showImageSourcePicker = false
    
    // MARK: - Initialization
    
    init() {
        // Create dependencies
        let clientProvider = SupabaseClientProvider()
        let storageService = SupabaseStorageService(clientProvider: clientProvider)
        let analysisService = MockFoodAnalysisService() // TODO: Replace with real API
        
        _viewModel = StateObject(wrappedValue: FoodCaptureViewModel(
            storageService: storageService,
            analysisService: analysisService
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content based on state
                contentForState
                
                // Floating capture button (only in idle state)
                if case .idle = viewModel.state {
                    captureButton
                }
            }
            .navigationTitle("Food")
            .navigationBarTitleDisplayMode(.large)
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
        ScrollView {
            VStack(spacing: 24) {
                // Placeholder Content
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green.opacity(0.3))
                    
                    Text("Track your nutrition")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Tap the camera button to take a photo of your meal and get instant nutritional information.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 60)
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Capture Button
    
    private var captureButton: some View {
        VStack {
            Spacer()
            
            Button(action: {
                showImageSourcePicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    Text("Capture Food")
                        .font(.headline)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: .green.opacity(0.4), radius: 10, y: 5)
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Captured Image View
    
    private func capturedImageView(_ image: UIImage) -> some View {
        VStack(spacing: 24) {
            // Image preview
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 400)
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding()
            
            Text("Ready to analyze your meal?")
                .font(.headline)
            
            // Buttons
            HStack(spacing: 16) {
                Button(action: {
                    viewModel.cancel()
                }) {
                    Text("Retake")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    Task {
                        await viewModel.confirmCapture()
                    }
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Analyze")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Processing View
    
    private func processingView(title: String, subtitle: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("Meal Logged!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your food has been added to your diary.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.reset()
            }) {
                Text("Try Again")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    FoodTabView()
}
