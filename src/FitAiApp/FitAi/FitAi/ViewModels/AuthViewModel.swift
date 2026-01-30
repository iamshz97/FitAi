//
//  AuthViewModel.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation
import Combine

// MARK: - Auth Mode

/// Represents the current authentication mode.
enum AuthMode {
    case signIn
    case signUp
    
    var title: String {
        switch self {
        case .signIn: return "Sign In"
        case .signUp: return "Sign Up"
        }
    }
    
    var alternateTitle: String {
        switch self {
        case .signIn: return "Don't have an account? Sign Up"
        case .signUp: return "Already have an account? Sign In"
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .signIn: return "Sign In"
        case .signUp: return "Create Account"
        }
    }
    
    mutating func toggle() {
        self = self == .signIn ? .signUp : .signIn
    }
}

// MARK: - Auth ViewModel

/// ViewModel for authentication screens.
/// Handles all auth-related state and actions.
/// Uses dependency injection for the AuthService.
@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// User's email input
    @Published var email: String = ""
    
    /// User's password input
    @Published var password: String = ""
    
    /// Current authentication mode (sign in or sign up)
    @Published var authMode: AuthMode = .signIn
    
    /// Loading state for async operations
    @Published var isLoading: Bool = false
    
    /// Error message to display to user
    @Published var errorMessage: String?
    
    /// Currently authenticated user
    @Published var user: AuthUser?
    
    // MARK: - Dependencies
    
    private let authService: AuthService
    
    // MARK: - Initialization
    
    /// Creates a new AuthViewModel.
    /// - Parameter authService: The auth service to use for authentication
    init(authService: AuthService) {
        self.authService = authService
    }
    
    // MARK: - Computed Properties
    
    /// Whether the form inputs are valid
    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        password.count >= 6
    }
    
    /// Whether to show the password requirement hint
    var showPasswordHint: Bool {
        !password.isEmpty && password.count < 6
    }
    
    // MARK: - Actions
    
    /// Performs sign up with current email and password.
    func signUp() async {
        await performAuthAction {
            try await self.authService.signUp(
                email: self.email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: self.password
            )
        }
    }
    
    /// Performs sign in with current email and password.
    func signIn() async {
        await performAuthAction {
            try await self.authService.signIn(
                email: self.email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: self.password
            )
        }
    }
    
    /// Performs the current auth action based on mode.
    func performCurrentAction() async {
        switch authMode {
        case .signIn:
            await signIn()
        case .signUp:
            await signUp()
        }
    }
    
    /// Signs out the current user.
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signOut()
            user = nil
            clearForm()
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Loads the current user session (if any).
    /// Call this on app launch to restore session.
    func loadCurrentUser() async {
        isLoading = true
        user = await authService.currentUser()
        isLoading = false
    }
    
    /// Toggles between sign in and sign up modes.
    func toggleAuthMode() {
        authMode.toggle()
        errorMessage = nil
    }
    
    /// Clears any error message.
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Helpers
    
    /// Performs an auth action with proper loading and error handling.
    private func performAuthAction(_ action: @escaping () async throws -> AuthUser) async {
        guard isFormValid else {
            if password.count < 6 {
                errorMessage = "Password must be at least 6 characters."
            } else {
                errorMessage = "Please enter a valid email and password."
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            user = try await action()
            clearForm()
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Clears the form inputs.
    private func clearForm() {
        email = ""
        password = ""
    }
}
