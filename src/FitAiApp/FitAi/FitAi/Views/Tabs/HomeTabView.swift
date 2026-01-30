//
//  HomeTabView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Home Tab View

/// The home tab content view.
/// This is the main landing screen after authentication.
struct HomeTabView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Section
                    welcomeSection
                    
                    // Placeholder Content
                    placeholderContent
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Welcome Section
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let user = authViewModel.user {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(user.displayName)
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Placeholder Content
    
    private var placeholderContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.opacity(0.3))
            
            Text("Your fitness journey starts here")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("This is the home screen. Add your dashboard widgets, activity summaries, and quick actions here.")
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
    let mockProvider = SupabaseClientProvider()
    let authService = SupabaseAuthService(clientProvider: mockProvider)
    let viewModel = AuthViewModel(authService: authService)
    
    return HomeTabView()
        .environmentObject(viewModel)
}
