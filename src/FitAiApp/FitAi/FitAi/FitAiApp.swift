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

// MARK: - Environment Key for HealthKit Service

private struct HealthKitServiceKey: EnvironmentKey {
    static let defaultValue: HealthKitServiceProtocol = HealthKitService()
}

extension EnvironmentValues {
    var healthKitService: HealthKitServiceProtocol {
        get { self[HealthKitServiceKey.self] }
        set { self[HealthKitServiceKey.self] = newValue }
    }
}

// MARK: - Environment Key for Health Data Sync Service

private struct HealthDataSyncServiceKey: EnvironmentKey {
    static let defaultValue: HealthDataSyncServiceProtocol = HealthDataSyncService(
        healthKitService: HealthKitService(),
        supabaseClient: SupabaseClientProvider().client
    )
}

extension EnvironmentValues {
    var healthDataSyncService: HealthDataSyncServiceProtocol {
        get { self[HealthDataSyncServiceKey.self] }
        set { self[HealthDataSyncServiceKey.self] = newValue }
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
    
    /// The HealthKit service
    private let healthKitService: HealthKitServiceProtocol
    
    /// The health data sync service
    private let healthDataSyncService: HealthDataSyncServiceProtocol
    
    /// The authentication view model (shared across the app)
    @StateObject private var authViewModel: AuthViewModel
    
    // MARK: - Initialization
    
    init() {
        // Create the dependency chain - SINGLE client provider
        let provider = SupabaseClientProvider()
        let authSvc = SupabaseAuthService(clientProvider: provider)
        let profileSvc = SupabaseUserProfileService(clientProvider: provider)
        let viewModel = AuthViewModel(authService: authSvc)
        
        // Create HealthKit services
        let healthKit = HealthKitService()
        let healthSync = HealthDataSyncService(
            healthKitService: healthKit,
            supabaseClient: provider.client
        )
        
        // Store references
        self.clientProvider = provider
        self.authService = authSvc
        self.profileService = profileSvc
        self.healthKitService = healthKit
        self.healthDataSyncService = healthSync
        self._authViewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            RootView(
                profileService: profileService,
                healthKitService: healthKitService
            )
            .environmentObject(authViewModel)
            .environment(\.clientProvider, clientProvider)
            .environment(\.healthKitService, healthKitService)
            .environment(\.healthDataSyncService, healthDataSyncService)
        }
    }
}
