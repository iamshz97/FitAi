//
//  FitAiApp.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Environment Key for Client Provider

private struct ClientProviderKey: EnvironmentKey {
    static let defaultValue: SupabaseClientProviding = SupabaseClientProvider()
}

extension EnvironmentValues {
    var clientProvider: SupabaseClientProviding {
        get { self[ClientProviderKey.self] }
        set { self[ClientProviderKey.self] = newValue }
    }
}

@main
struct FitAiApp: App {
    
    // MARK: - Dependencies
    
    /// The Supabase client provider (single source of truth)
    private let clientProvider: SupabaseClientProviding
    
    /// The authentication service
    private let authService: AuthService
    
    /// The user profile service
    private let profileService: SupabaseUserProfileService
    
    /// The authentication view model (shared across the app)
    @StateObject private var authViewModel: AuthViewModel
    
    // MARK: - Initialization
    
    init() {
        // Create the dependency chain - SINGLE client provider
        let provider = SupabaseClientProvider()
        let authSvc = SupabaseAuthService(clientProvider: provider)
        let profileSvc = SupabaseUserProfileService(clientProvider: provider)
        let viewModel = AuthViewModel(authService: authSvc)
        
        // Store references
        self.clientProvider = provider
        self.authService = authSvc
        self.profileService = profileSvc
        self._authViewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            RootView(profileService: profileService)
                .environmentObject(authViewModel)
                .environment(\.clientProvider, clientProvider)
        }
    }
}
