//
//  FoodTabView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Food Tab View

/// The food/nutrition tab content view.
/// Track meals, calories, and nutritional information here.
struct FoodTabView: View {
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Placeholder Content
                    placeholderContent
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Food")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Placeholder Content
    
    private var placeholderContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green.opacity(0.3))
            
            Text("Track your nutrition")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("This is the food tracking screen. Add meal logging, calorie tracking, and nutritional insights here.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview {
    FoodTabView()
}
