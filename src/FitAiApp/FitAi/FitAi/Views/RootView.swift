//
//  RootView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - App State

enum AppState {
    case loading
    case unauthenticated
    case onboarding
    case authenticated
}

// MARK: - Root View

/// The root view of the app that handles navigation based on authentication and onboarding state.
struct RootView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Dependencies
    
    /// Profile service - passed from FitAiApp to ensure same Supabase client
    let profileService: SupabaseUserProfileService
    
    // MARK: - State
    
    @State private var appState: AppState = .loading
    @State private var onboardingComplete: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch appState {
            case .loading:
                loadingView
                
            case .unauthenticated:
                AuthScreen()
                
            case .onboarding:
                OnboardingContainerView(
                    profileService: profileService,
                    isOnboardingComplete: $onboardingComplete
                )
                
            case .authenticated:
                MainTabView()
            }
        }
        .task {
            await checkAuthState()
        }
        .onChange(of: authViewModel.user) { _, user in
            Task {
                if user != nil {
                    await checkOnboardingState()
                } else {
                    appState = .unauthenticated
                }
            }
        }
        .onChange(of: onboardingComplete) { _, complete in
            if complete {
                appState = .authenticated
            }
        }
    }
    
    // MARK: - Check Auth State
    
    private func checkAuthState() async {
        await authViewModel.loadCurrentUser()
        
        if authViewModel.user != nil {
            await checkOnboardingState()
        } else {
            appState = .unauthenticated
        }
    }
    
    // MARK: - Check Onboarding State
    
    private func checkOnboardingState() async {
        do {
            if let profile = try await profileService.fetchProfile() {
                if profile.onboardingCompleted {
                    appState = .authenticated
                } else {
                    appState = .onboarding
                }
            } else {
                // No profile exists yet - create one and start onboarding
                _ = try await profileService.createProfile()
                appState = .onboarding
            }
        } catch {
            // If we can't check profile, assume onboarding needed
            print("Error checking onboarding state: \(error)")
            appState = .onboarding
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
    let profileService = SupabaseUserProfileService(clientProvider: mockProvider)
    let viewModel = AuthViewModel(authService: authService)
    
    return RootView(profileService: profileService)
        .environmentObject(viewModel)
}
