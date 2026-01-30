//
//  RootView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Root View

/// The root view of the app that handles navigation based on authentication state.
/// Shows AuthScreen when not logged in, MainTabView when logged in.
struct RootView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if authViewModel.isLoading && authViewModel.user == nil {
                // Initial loading state
                loadingView
            } else if authViewModel.user != nil {
                // Authenticated - show main tab view
                MainTabView()
            } else {
                // Not authenticated - show auth screen
                AuthScreen()
            }
        }
        .task {
            // Load current user session on app launch
            await authViewModel.loadCurrentUser()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview {
    let mockProvider = SupabaseClientProvider()
    let authService = SupabaseAuthService(clientProvider: mockProvider)
    let viewModel = AuthViewModel(authService: authService)
    
    return RootView()
        .environmentObject(viewModel)
}

