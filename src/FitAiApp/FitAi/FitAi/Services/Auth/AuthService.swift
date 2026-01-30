//
//  AuthService.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation

// MARK: - Auth Error

/// Domain-specific authentication errors.
/// Maps backend errors to user-friendly error cases.
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case userAlreadyExists
    case weakPassword
    case invalidEmail
    case network
    case sessionExpired
    case cancelled
    case unknown(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .userAlreadyExists:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password is too weak. Please use at least 6 characters."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .network:
            return "Network error. Please check your connection."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .cancelled:
            return "Authentication was cancelled."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Auth User

/// Represents an authenticated user in the app.
/// This is a domain model that abstracts the Supabase User type.
struct AuthUser: Equatable, Identifiable {
    let id: String
    let email: String?
    let isAnonymous: Bool
    
    /// User's display name (derived from email if available)
    var displayName: String {
        if let email = email {
            return email.components(separatedBy: "@").first ?? email
        }
        return "User"
    }
}

// MARK: - Auth Service Protocol

/// Protocol that abstracts all authentication operations.
/// Views and ViewModels should depend on this protocol, not on Supabase directly.
protocol AuthService {
    /// Creates a new user account with email and password.
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (minimum 6 characters)
    /// - Returns: The newly created AuthUser
    /// - Throws: AuthError if sign up fails
    func signUp(email: String, password: String) async throws -> AuthUser
    
    /// Signs in an existing user with email and password.
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The authenticated AuthUser
    /// - Throws: AuthError if sign in fails
    func signIn(email: String, password: String) async throws -> AuthUser
    
    /// Signs out the current user.
    /// - Throws: AuthError if sign out fails
    func signOut() async throws
    
    /// Returns the currently authenticated user, if any.
    /// - Returns: The current AuthUser or nil if not authenticated
    func currentUser() async -> AuthUser?
    
    /// Refreshes the current session if needed.
    /// - Returns: The refreshed AuthUser or nil if no valid session
    /// - Throws: AuthError if refresh fails
    func refreshSessionIfNeeded() async throws -> AuthUser?
}
