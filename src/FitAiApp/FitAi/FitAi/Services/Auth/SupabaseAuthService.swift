//
//  SupabaseAuthService.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation
import Supabase
import Auth

// MARK: - Supabase Auth Service Implementation

/// Concrete implementation of AuthService using Supabase.
/// All Supabase-specific logic is contained within this class.
final class SupabaseAuthService: AuthService {
    
    // MARK: - Properties
    
    private let client: SupabaseClient
    
    // MARK: - Initialization
    
    /// Creates a new SupabaseAuthService.
    /// - Parameter clientProvider: Provider for the Supabase client
    init(clientProvider: SupabaseClientProviding) {
        self.client = clientProvider.client
    }
    
    // MARK: - AuthService Implementation
    
    func signUp(email: String, password: String) async throws -> AuthUser {
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            return mapToAuthUser(response.user)
        } catch {
            throw mapError(error)
        }
    }
    
    func signIn(email: String, password: String) async throws -> AuthUser {
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            return mapToAuthUser(session.user)
        } catch {
            throw mapError(error)
        }
    }
    
    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw mapError(error)
        }
    }
    
    func currentUser() async -> AuthUser? {
        do {
            let session = try await client.auth.session
            return mapToAuthUser(session.user)
        } catch {
            return nil
        }
    }
    
    func refreshSessionIfNeeded() async throws -> AuthUser? {
        do {
            let session = try await client.auth.refreshSession()
            return mapToAuthUser(session.user)
        } catch {
            throw mapError(error)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Maps a Supabase User to our domain AuthUser model.
    private func mapToAuthUser(_ user: User) -> AuthUser {
        AuthUser(
            id: user.id.uuidString,
            email: user.email,
            isAnonymous: user.isAnonymous
        )
    }
    
    /// Maps Supabase/network errors to our domain AuthError.
    private func mapError(_ error: Error) -> AuthError {
        // Check for specific Supabase auth errors
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("invalid login credentials") ||
           errorMessage.contains("invalid email or password") {
            return .invalidCredentials
        }
        
        if errorMessage.contains("user already registered") ||
           errorMessage.contains("already exists") {
            return .userAlreadyExists
        }
        
        if errorMessage.contains("password") && errorMessage.contains("weak") {
            return .weakPassword
        }
        
        if errorMessage.contains("invalid email") ||
           errorMessage.contains("email") && errorMessage.contains("invalid") {
            return .invalidEmail
        }
        
        if errorMessage.contains("network") ||
           errorMessage.contains("connection") ||
           errorMessage.contains("offline") {
            return .network
        }
        
        if errorMessage.contains("session") && errorMessage.contains("expired") {
            return .sessionExpired
        }
        
        if errorMessage.contains("cancel") {
            return .cancelled
        }
        
        // Return unknown error with original message
        return .unknown(message: error.localizedDescription)
    }
}

// MARK: - Testing Notes

/*
 To unit test SupabaseAuthService:
 
 1. Create a mock SupabaseClientProviding that returns a configured test client
 2. Use Supabase's test/development environment
 3. Mock the auth responses using dependency injection
 
 Example:
 
 class MockSupabaseClientProvider: SupabaseClientProviding {
     let client: SupabaseClient
     
     init() {
         // Create a client pointing to a test Supabase instance
         self.client = SupabaseClient(
             supabaseURL: URL(string: "https://test.supabase.co")!,
             supabaseKey: "test-key"
         )
     }
 }
 
 let mockProvider = MockSupabaseClientProvider()
 let authService = SupabaseAuthService(clientProvider: mockProvider)
 */
