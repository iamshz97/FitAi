//
//  FitAiApp.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

@main
struct FitAiApp: App {
    
    // MARK: - Dependencies
    
    /// The Supabase client provider (single source of truth)
    private let clientProvider: SupabaseClientProviding
    
    /// The authentication service
    private let authService: AuthService
    
    /// The authentication view model (shared across the app)
    @StateObject private var authViewModel: AuthViewModel
    
    // MARK: - Initialization
    
    init() {
        // Create the dependency chain
        let provider = SupabaseClientProvider()
        let service = SupabaseAuthService(clientProvider: provider)
        let viewModel = AuthViewModel(authService: service)
        
        // Store references
        self.clientProvider = provider
        self.authService = service
        self._authViewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}
