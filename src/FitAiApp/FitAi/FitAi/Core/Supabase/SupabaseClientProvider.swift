//
//  SupabaseClientProvider.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation
import Supabase

// MARK: - Protocol for Dependency Injection

/// Protocol that abstracts the Supabase client for testability.
/// Use this protocol for dependency injection instead of directly using SupabaseClient.
protocol SupabaseClientProviding {
    var client: SupabaseClient { get }
}

// MARK: - Concrete Implementation

/// Provides a configured SupabaseClient instance.
/// This is the single source of truth for the Supabase client in the app.
final class SupabaseClientProvider: SupabaseClientProviding {
    
    // MARK: - Configuration
    
    /// Supabase project URL
    private static let supabaseURL = "https://bqpsbblymplqnmpzkler.supabase.co"
    
    /// Supabase anonymous/public key
    private static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxcHNiYmx5bXBscW5tcHprbGVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk3NzAwNDAsImV4cCI6MjA4NTM0NjA0MH0.R19G0D0f1A9VVZ0j-2HeauWMmmzIYcsLUos1oXlI6OE"
    
    // MARK: - Properties
    
    /// The configured Supabase client instance
    let client: SupabaseClient
    
    // MARK: - Initialization
    
    init() {
        guard let url = URL(string: Self.supabaseURL) else {
            fatalError("Invalid Supabase URL. Please check your configuration.")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Self.supabaseKey
        )
    }
}

// MARK: - Mock Provider for Testing

/// A mock client provider for unit testing.
/// Usage: Create a mock SupabaseClient and inject it via this provider.
#if DEBUG
final class MockSupabaseClientProvider: SupabaseClientProviding {
    let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
}
#endif
