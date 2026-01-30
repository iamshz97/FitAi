//
//  FoodReviewView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Food Review View

/// View for reviewing and editing detected food entries before submission.
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
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            // Food entries list
            ScrollView {
                VStack(spacing: 16) {
                    // Summary card
                    summaryCard
                    
                    // Food entries
                    ForEach(Array(viewModel.editableFoodEntries.enumerated()), id: \.element.id) { index, entry in
                        FoodEntryCard(
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
                    
                    // Add more hint
                    if viewModel.editableFoodEntries.isEmpty {
                        emptyStateView
                    }
                }
                .padding()
            }
            
            // Bottom buttons
            bottomButtons
        }
        .sheet(isPresented: $showEditSheet) {
            if let entry = editingEntry,
               let index = viewModel.editableFoodEntries.firstIndex(where: { $0.id == entry.id }) {
                FoodEntryEditSheet(
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
        VStack(spacing: 12) {
            Text("Meal Summary")
                .font(.headline)
            
            HStack(spacing: 24) {
                MacroItem(label: "Calories", value: "\(viewModel.totalCalories)", unit: "kcal", color: .orange)
                MacroItem(label: "Protein", value: String(format: "%.0f", viewModel.totalProtein), unit: "g", color: .red)
                MacroItem(label: "Carbs", value: String(format: "%.0f", viewModel.totalCarbs), unit: "g", color: .blue)
                MacroItem(label: "Fat", value: String(format: "%.0f", viewModel.totalFat), unit: "g", color: .yellow)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No food items detected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // Confirm button
            Button(action: {
                Task {
                    await viewModel.submitFoodEntries()
                }
            }) {
                HStack {
                    if case .submitting = viewModel.state {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Confirm & Log Meal")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.editableFoodEntries.isEmpty ? Color.gray : Color.green)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.editableFoodEntries.isEmpty || viewModel.state == .submitting)
            
            // Cancel button
            Button(action: {
                viewModel.cancel()
            }) {
                Text("Cancel")
                    .foregroundStyle(.red)
            }
            .disabled(viewModel.state == .submitting)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Macro Item

struct MacroItem: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Food Entry Card

struct FoodEntryCard: View {
    let entry: FoodEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Food icon
            Image(systemName: "fork.knife.circle.fill")
                .font(.title)
                .foregroundStyle(.green)
            
            // Food details
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.headline)
                Text(entry.macrosSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Calories
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.calories)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Food Entry Edit Sheet

struct FoodEntryEditSheet: View {
    @State var entry: FoodEntry
    let onSave: (FoodEntry) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Details") {
                    TextField("Name", text: $entry.name)
                }
                
                Section("Nutrition") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("", value: $entry.calories, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("kcal")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("", value: $entry.protein, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Carbs")
                        Spacer()
                        TextField("", value: $entry.carbs, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Fat")
                        Spacer()
                        TextField("", value: $entry.fat, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Fiber")
                        Spacer()
                        TextField("", value: $entry.fiber, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $entry.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(entry)
                    }
                }
            }
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
    
    // Set up mock data
    viewModel.editableFoodEntries = FoodEntry.samples
    
    return FoodReviewView(viewModel: viewModel)
}
