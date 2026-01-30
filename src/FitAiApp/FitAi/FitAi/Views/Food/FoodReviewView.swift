//
//  FoodReviewView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Food Review View

/// View for reviewing and editing detected food entries with premium dark green design.
struct FoodReviewView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: FoodCaptureViewModel
    @State private var editingEntry: FoodEntry?
    @State private var showEditSheet = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with image
            if let image = viewModel.capturedImage {
                ZStack(alignment: .bottom) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [.clear, AppTheme.Colors.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                }
            }
            
            // Food entries list
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Summary card
                    summaryCard
                    
                    // Section header
                    HStack {
                        Text("Detected Foods")
                            .font(AppTheme.Typography.headline())
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(viewModel.editableFoodEntries.count) items")
                            .font(AppTheme.Typography.caption())
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    
                    // Food entries
                    ForEach(Array(viewModel.editableFoodEntries.enumerated()), id: \.element.id) { index, entry in
                        FoodEntryCardStyled(
                            entry: entry,
                            onEdit: {
                                editingEntry = entry
                                showEditSheet = true
                            },
                            onDelete: {
                                withAnimation {
                                    viewModel.removeFoodEntry(at: index)
                                }
                            }
                        )
                    }
                    
                    // Empty state
                    if viewModel.editableFoodEntries.isEmpty {
                        emptyStateView
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.lg)
            }
            
            // Bottom buttons
            bottomButtons
        }
        .appBackground()
        .sheet(isPresented: $showEditSheet) {
            if let entry = editingEntry,
               let index = viewModel.editableFoodEntries.firstIndex(where: { $0.id == entry.id }) {
                FoodEntryEditSheetStyled(
                    entry: entry,
                    onSave: { updatedEntry in
                        viewModel.updateFoodEntry(at: index, with: updatedEntry)
                        showEditSheet = false
                    },
                    onCancel: {
                        showEditSheet = false
                    }
                )
            }
        }
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("MEAL SUMMARY")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            HStack(spacing: AppTheme.Spacing.xl) {
                MacroItemStyled(label: "Calories", value: "\(viewModel.totalCalories)", unit: "kcal", color: AppTheme.Colors.warning)
                
                Divider()
                    .frame(height: 40)
                    .background(AppTheme.Colors.chipBorder)
                
                MacroItemStyled(label: "Protein", value: String(format: "%.0f", viewModel.totalProtein), unit: "g", color: AppTheme.Colors.error)
                
                Divider()
                    .frame(height: 40)
                    .background(AppTheme.Colors.chipBorder)
                
                MacroItemStyled(label: "Carbs", value: String(format: "%.0f", viewModel.totalCarbs), unit: "g", color: AppTheme.Colors.info)
                
                Divider()
                    .frame(height: 40)
                    .background(AppTheme.Colors.chipBorder)
                
                MacroItemStyled(label: "Fat", value: String(format: "%.0f", viewModel.totalFat), unit: "g", color: AppTheme.Colors.accent)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .cardStyle()
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            
            Text("No food items detected")
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(.vertical, AppTheme.Spacing.xxxl)
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Confirm button
            Button(action: {
                Task {
                    await viewModel.submitFoodEntries()
                }
            }) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    if case .submitting = viewModel.state {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.background))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Confirm & Log Meal")
                    }
                }
            }
            .buttonStyle(AccentButtonStyle())
            .disabled(viewModel.editableFoodEntries.isEmpty || viewModel.state == .submitting)
            .opacity(viewModel.editableFoodEntries.isEmpty ? 0.5 : 1.0)
            
            // Cancel button
            Button(action: {
                viewModel.cancel()
            }) {
                Text("Cancel")
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundStyle(AppTheme.Colors.error)
            }
            .disabled(viewModel.state == .submitting)
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.Colors.backgroundSecondary)
    }
}

// MARK: - Macro Item Styled

struct MacroItemStyled: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppTheme.Typography.headline())
                    .foregroundStyle(color)
                
                Text(unit)
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            
            Text(label)
                .font(AppTheme.Typography.labelSmall())
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Food Entry Card Styled

struct FoodEntryCardStyled: View {
    let entry: FoodEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Food icon
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accent.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.Colors.accent)
            }
            
            // Food details
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(entry.name)
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text(entry.macrosSummary)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            // Calories
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.calories)")
                    .font(AppTheme.Typography.headline())
                    .foregroundStyle(AppTheme.Colors.warning)
                
                Text("kcal")
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            
            // Actions
            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
}

// MARK: - Food Entry Edit Sheet Styled

struct FoodEntryEditSheetStyled: View {
    @State var entry: FoodEntry
    let onSave: (FoodEntry) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // Food Name
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Food Name")
                            .font(AppTheme.Typography.captionMedium())
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        
                        TextField("", text: $entry.name)
                            .font(AppTheme.Typography.body())
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .padding(AppTheme.Spacing.lg)
                            .background(AppTheme.Colors.cardBackground)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                    
                    // Nutrition
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        Text("Nutrition")
                            .font(AppTheme.Typography.captionMedium())
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        
                        NutritionInputRow(label: "Calories", value: $entry.calories, unit: "kcal", color: AppTheme.Colors.warning)
                        NutritionInputRowDouble(label: "Protein", value: $entry.protein, unit: "g", color: AppTheme.Colors.error)
                        NutritionInputRowDouble(label: "Carbs", value: $entry.carbs, unit: "g", color: AppTheme.Colors.info)
                        NutritionInputRowDouble(label: "Fat", value: $entry.fat, unit: "g", color: AppTheme.Colors.accent)
                        NutritionInputRowDouble(label: "Fiber", value: $entry.fiber, unit: "g", color: AppTheme.Colors.accentSecondary)
                    }
                }
                .padding(AppTheme.Spacing.xl)
            }
            .appBackground()
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(entry)
                    }
                    .foregroundStyle(AppTheme.Colors.accent)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(AppTheme.Colors.backgroundSecondary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Nutrition Input Row

struct NutritionInputRow: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            HStack(spacing: AppTheme.Spacing.sm) {
                TextField("", value: $value, format: .number)
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundStyle(color)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                
                Text(unit)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                    .frame(width: 35, alignment: .leading)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
        }
    }
}

struct NutritionInputRowDouble: View {
    let label: String
    @Binding var value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            HStack(spacing: AppTheme.Spacing.sm) {
                TextField("", value: $value, format: .number)
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundStyle(color)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                
                Text(unit)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                    .frame(width: 35, alignment: .leading)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
        }
    }
}

// MARK: - Preview

#Preview {
    let mockStorageService = MockStorageService()
    let mockAnalysisService = MockFoodAnalysisService()
    let viewModel = FoodCaptureViewModel(
        storageService: mockStorageService,
        analysisService: mockAnalysisService
    )
    
    viewModel.editableFoodEntries = FoodEntry.samples
    
    return FoodReviewView(viewModel: viewModel)
}
