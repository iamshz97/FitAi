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
        VStack(spacing: AppTheme.Spacing.xl) {
            // App Logo
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accent.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "figure.run")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.accent)
            }
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                .scaleEffect(1.2)
            
            Text("Loading...")
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appBackground()
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
