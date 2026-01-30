//
//  FoodEntry.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation

// MARK: - Food Entry

/// Represents a food entry with nutritional information.
/// This model is used for both the analysis result and database storage.
struct FoodEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var calories: Int
    var protein: Double  // grams
    var carbs: Double    // grams
    var fat: Double      // grams
    var fiber: Double    // grams
    var imageURL: String?
    var timestamp: Date = Date()
    var notes: String = ""
    
    // MARK: - Computed Properties
    
    /// Formatted calorie string
    var caloriesText: String {
        "\(calories) kcal"
    }
    
    /// Summary of macros
    var macrosSummary: String {
        "P: \(Int(protein))g • C: \(Int(carbs))g • F: \(Int(fat))g"
    }
}

// MARK: - Food Analysis Result

/// The result from food image analysis (from API or mock).
struct FoodAnalysisResult {
    let entries: [FoodEntry]
    let confidence: Double  // 0.0 to 1.0
    let rawResponse: String? // For debugging
    
    /// Total calories from all entries
    var totalCalories: Int {
        entries.reduce(0) { $0 + $1.calories }
    }
}

// MARK: - Sample Data

extension FoodEntry {
    /// Sample food entries for previews and testing
    static let samples: [FoodEntry] = [
        FoodEntry(
            name: "Grilled Chicken Breast",
            calories: 165,
            protein: 31,
            carbs: 0,
            fat: 3.6,
            fiber: 0
        ),
        FoodEntry(
            name: "Brown Rice",
            calories: 216,
            protein: 5,
            carbs: 45,
            fat: 1.8,
            fiber: 3.5
        ),
        FoodEntry(
            name: "Mixed Vegetables",
            calories: 50,
            protein: 2,
            carbs: 10,
            fat: 0.5,
            fiber: 4
        )
    ]
}
