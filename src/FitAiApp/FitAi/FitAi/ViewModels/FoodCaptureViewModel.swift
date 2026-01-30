//
//  FoodCaptureViewModel.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation
import UIKit
import Combine

// MARK: - Capture State

/// Represents the current state of the food capture flow.
enum FoodCaptureState: Equatable {
    case idle
    case captured(UIImage)
    case uploading
    case analyzing
    case review(FoodAnalysisResult)
    case submitting
    case success
    case error(String)
    
    static func == (lhs: FoodCaptureState, rhs: FoodCaptureState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.uploading, .uploading), (.analyzing, .analyzing),
             (.submitting, .submitting), (.success, .success):
            return true
        case (.captured(_), .captured(_)):
            return true
        case (.review(_), .review(_)):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// MARK: - Food Capture View Model

/// ViewModel for the food capture and analysis flow.
@MainActor
final class FoodCaptureViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var state: FoodCaptureState = .idle
    @Published var showCamera = false
    @Published var showPhotoLibrary = false
    @Published var capturedImage: UIImage?
    @Published var analysisResult: FoodAnalysisResult?
    @Published var editableFoodEntries: [FoodEntry] = []
    @Published var imageURL: String?
    
    // MARK: - Dependencies
    
    private let storageService: StorageService
    private let analysisService: FoodAnalysisService
    
    // MARK: - Initialization
    
    init(storageService: StorageService, analysisService: FoodAnalysisService) {
        self.storageService = storageService
        self.analysisService = analysisService
    }
    
    // MARK: - Actions
    
    /// Opens the camera to capture a food image.
    func openCamera() {
        showCamera = true
    }
    
    /// Opens the photo library to select a food image.
    func openPhotoLibrary() {
        showPhotoLibrary = true
    }
    
    /// Called when an image is captured or selected.
    func onImageCaptured(_ image: UIImage) {
        capturedImage = image
        state = .captured(image)
        print("📷 [FoodCapture] Image captured: \(image.size)")
    }
    
    /// Confirms the captured image and starts the upload + analysis flow.
    func confirmCapture() async {
        guard let image = capturedImage else { return }
        
        // Step 1: Upload image
        state = .uploading
        print("📤 [FoodCapture] Starting upload...")
        
        do {
            let url = try await storageService.uploadImage(image, path: nil)
            self.imageURL = url
            print("✅ [FoodCapture] Image uploaded successfully!")
            print("🔗 [FoodCapture] Public URL: \(url)")
            
            // Step 2: Analyze food
            state = .analyzing
            print("🔍 [FoodCapture] Starting food analysis...")
            
            let result = try await analysisService.analyzeFood(imageURL: url)
            self.analysisResult = result
            self.editableFoodEntries = result.entries
            
            print("✅ [FoodCapture] Analysis complete!")
            print("📊 [FoodCapture] Detected \(result.entries.count) food items")
            print("🔥 [FoodCapture] Total calories: \(result.totalCalories)")
            
            state = .review(result)
            
        } catch {
            print("❌ [FoodCapture] Error: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        }
    }
    
    /// Updates a food entry (user editing).
    func updateFoodEntry(at index: Int, with entry: FoodEntry) {
        guard index < editableFoodEntries.count else { return }
        editableFoodEntries[index] = entry
    }
    
    /// Removes a food entry.
    func removeFoodEntry(at index: Int) {
        guard index < editableFoodEntries.count else { return }
        editableFoodEntries.remove(at: index)
    }
    
    /// Confirms the food entries and submits to database.
    func submitFoodEntries() async {
        state = .submitting
        print("💾 [FoodCapture] Submitting \(editableFoodEntries.count) food entries...")
        
        // TODO: Submit to Supabase database
        // For now, simulate submission
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            print("✅ [FoodCapture] Food entries submitted successfully!")
            for entry in editableFoodEntries {
                print("   - \(entry.name): \(entry.calories) kcal")
            }
            
            state = .success
            
            // Reset after short delay
            try await Task.sleep(nanoseconds: 2_000_000_000)
            reset()
            
        } catch {
            print("❌ [FoodCapture] Submission failed: \(error.localizedDescription)")
            state = .error(error.localizedDescription)
        }
    }
    
    /// Resets the capture flow.
    func reset() {
        state = .idle
        capturedImage = nil
        analysisResult = nil
        editableFoodEntries = []
        imageURL = nil
    }
    
    /// Cancels the current capture and returns to idle.
    func cancel() {
        reset()
    }
    
    // MARK: - Computed Properties
    
    /// Total calories from editable entries.
    var totalCalories: Int {
        editableFoodEntries.reduce(0) { $0 + $1.calories }
    }
    
    /// Total protein from editable entries.
    var totalProtein: Double {
        editableFoodEntries.reduce(0) { $0 + $1.protein }
    }
    
    /// Total carbs from editable entries.
    var totalCarbs: Double {
        editableFoodEntries.reduce(0) { $0 + $1.carbs }
    }
    
    /// Total fat from editable entries.
    var totalFat: Double {
        editableFoodEntries.reduce(0) { $0 + $1.fat }
    }
}
