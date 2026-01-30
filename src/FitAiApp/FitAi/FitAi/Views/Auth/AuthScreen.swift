//
//  AuthScreen.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Auth Screen

/// The main authentication screen for sign in and sign up.
/// This view is designed to be minimal and easily extensible.
struct AuthScreen: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?
    
    // MARK: - Field Focus
    
    private enum Field {
        case email
        case password
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection
                
                // Form Fields
                formSection
                
                // Action Button
                actionButton
                
                // Toggle Auth Mode
                toggleModeButton
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
        }
        .background(Color(.systemBackground))
        .onTapGesture {
            focusedField = nil
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // App Icon/Logo placeholder
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.blue)
            
            Text("FitAi")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(viewModel.authMode.title)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 16) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("Enter your email", text: $viewModel.email)
                    .textFieldStyle(.plain)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                SecureField("Enter your password", text: $viewModel.password)
                    .textFieldStyle(.plain)
                    .textContentType(viewModel.authMode == .signUp ? .newPassword : .password)
                    .focused($focusedField, equals: .password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                
                // Password hint for sign up
                if viewModel.showPasswordHint {
                    Text("Password must be at least 6 characters")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button(action: {
            focusedField = nil
            Task {
                await viewModel.performCurrentAction()
            }
        }) {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(viewModel.authMode.buttonTitle)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isFormValid ? Color.blue : Color.gray)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
    }
    
    // MARK: - Toggle Mode Button
    
    private var toggleModeButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.toggleAuthMode()
            }
        }) {
            Text(viewModel.authMode.alternateTitle)
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .disabled(viewModel.isLoading)
    }
}

// MARK: - Preview

#Preview {
    // Create a mock auth service for preview
    let mockProvider = SupabaseClientProvider()
    let authService = SupabaseAuthService(clientProvider: mockProvider)
    let viewModel = AuthViewModel(authService: authService)
    
    return AuthScreen()
        .environmentObject(viewModel)
}
