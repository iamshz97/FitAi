//
//  FoodAnalysisService.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation

// MARK: - Food Analysis Error

enum FoodAnalysisError: Error, LocalizedError {
    case analysisFailed(message: String)
    case invalidResponse
    case noFoodDetected
    
    var errorDescription: String? {
        switch self {
        case .analysisFailed(let message):
            return "Analysis failed: \(message)"
        case .invalidResponse:
            return "Invalid response from analysis service."
        case .noFoodDetected:
            return "No food detected in the image."
        }
    }
}

// MARK: - Food Analysis Service Protocol

/// Protocol for food image analysis.
/// This will be swapped with an actual API implementation later.
protocol FoodAnalysisService {
    /// Analyzes a food image and returns nutritional information.
    /// - Parameter imageURL: Public URL of the food image
    /// - Returns: Analysis result with food entries
    func analyzeFood(imageURL: String) async throws -> FoodAnalysisResult
}

// MARK: - Mock Food Analysis Service

/// Mock implementation that returns realistic sample data.
/// Replace this with actual API implementation later.
final class MockFoodAnalysisService: FoodAnalysisService {
    
    func analyzeFood(imageURL: String) async throws -> FoodAnalysisResult {
        print("🔍 [FoodAnalysis] Analyzing image: \(imageURL)")
        
        // Simulate API delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Mock food detection - returns random sample foods
        let mockFoods = generateMockFoodEntries(imageURL: imageURL)
        
        let result = FoodAnalysisResult(
            entries: mockFoods,
            confidence: Double.random(in: 0.85...0.98),
            rawResponse: """
            {
                "status": "success",
                "image_url": "\(imageURL)",
                "detected_foods": \(mockFoods.count),
                "mock": true
            }
            """
        )
        
        print("✅ [FoodAnalysis] Analysis complete!")
        print("   - Detected \(result.entries.count) food items")
        print("   - Total calories: \(result.totalCalories)")
        print("   - Confidence: \(String(format: "%.1f", result.confidence * 100))%")
        
        return result
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockFoodEntries(imageURL: String) -> [FoodEntry] {
        // Randomly select 1-3 food items from sample data
        let numberOfItems = Int.random(in: 1...3)
        let allSamples = [
            FoodEntry(name: "Grilled Chicken Breast", calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0, imageURL: imageURL),
            FoodEntry(name: "Brown Rice (1 cup)", calories: 216, protein: 5, carbs: 45, fat: 1.8, fiber: 3.5, imageURL: imageURL),
            FoodEntry(name: "Mixed Salad", calories: 50, protein: 2, carbs: 10, fat: 0.5, fiber: 4, imageURL: imageURL),
            FoodEntry(name: "Salmon Fillet", calories: 208, protein: 20, carbs: 0, fat: 13, fiber: 0, imageURL: imageURL),
            FoodEntry(name: "Avocado (half)", calories: 161, protein: 2, carbs: 9, fat: 15, fiber: 7, imageURL: imageURL),
            FoodEntry(name: "Banana", calories: 105, protein: 1.3, carbs: 27, fat: 0.4, fiber: 3.1, imageURL: imageURL),
            FoodEntry(name: "Greek Yogurt", calories: 100, protein: 17, carbs: 6, fat: 0.7, fiber: 0, imageURL: imageURL),
            FoodEntry(name: "Pasta with Sauce", calories: 350, protein: 12, carbs: 65, fat: 5, fiber: 4, imageURL: imageURL),
            FoodEntry(name: "Caesar Salad", calories: 180, protein: 8, carbs: 12, fat: 11, fiber: 3, imageURL: imageURL),
            FoodEntry(name: "Steak (6oz)", calories: 350, protein: 42, carbs: 0, fat: 18, fiber: 0, imageURL: imageURL)
        ]
        
        return Array(allSamples.shuffled().prefix(numberOfItems))
    }
}

// MARK: - API Food Analysis Service (Placeholder)

/// Placeholder for real API implementation.
/// TODO: Replace with actual API calls (e.g., OpenAI Vision, Clarifai, etc.)
final class APIFoodAnalysisService: FoodAnalysisService {
    
    private let apiEndpoint: String
    private let apiKey: String
    
    init(apiEndpoint: String, apiKey: String) {
        self.apiEndpoint = apiEndpoint
        self.apiKey = apiKey
    }
    
    func analyzeFood(imageURL: String) async throws -> FoodAnalysisResult {
        print("🌐 [API] Calling food analysis API...")
        print("   - Endpoint: \(apiEndpoint)")
        print("   - Image URL: \(imageURL)")
        
        // TODO: Implement actual API call
        // For now, fall back to mock
        let mockService = MockFoodAnalysisService()
        return try await mockService.analyzeFood(imageURL: imageURL)
    }
}
