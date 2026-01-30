//
//  AuthScreen.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Auth Screen

/// The authentication screen with premium dark green design.
/// Supports both sign in and sign up modes.
struct AuthScreen: View {
    
    // MARK: - State
    
    @EnvironmentObject private var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case email
        case password
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xxxl) {
                Spacer(minLength: 60)
                
                // Logo & Header
                headerSection
                
                // Form
                formSection
                
                // Action Button
                actionButton
                
                // Toggle Mode
                toggleModeButton
                
                Spacer(minLength: 60)
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
        }
        .appBackground()
        .onTapGesture {
            focusedField = nil
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // App Icon
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accent.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "figure.run")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.accent)
            }
            
            // Title
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("FitAi")
                    .font(AppTheme.Typography.displayLarge())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text(viewModel.authMode == .signIn ? "Welcome back" : "Create your account")
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Email Field
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Email")
                    .font(AppTheme.Typography.captionMedium())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                TextField("", text: $viewModel.email, prompt: Text("Enter your email").foregroundStyle(AppTheme.Colors.textTertiary))
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(
                                focusedField == .email ? AppTheme.Colors.accent : AppTheme.Colors.chipBorder,
                                lineWidth: 1
                            )
                    )
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Password")
                    .font(AppTheme.Typography.captionMedium())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                SecureField("", text: $viewModel.password, prompt: Text("Enter your password").foregroundStyle(AppTheme.Colors.textTertiary))
                    .font(AppTheme.Typography.body())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .textContentType(viewModel.authMode == .signIn ? .password : .newPassword)
                    .focused($focusedField, equals: .password)
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(
                                focusedField == .password ? AppTheme.Colors.accent : AppTheme.Colors.chipBorder,
                                lineWidth: 1
                            )
                    )
            }
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(errorMessage)
                }
                .font(AppTheme.Typography.caption())
                .foregroundStyle(AppTheme.Colors.error)
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.error.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.small)
            }
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button(action: {
            focusedField = nil
            Task {
                if viewModel.authMode == .signIn {
                    await viewModel.signIn()
                } else {
                    await viewModel.signUp()
                }
            }
        }) {
            HStack(spacing: AppTheme.Spacing.sm) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.background))
                } else {
                    Text(viewModel.authMode == .signIn ? "Sign In" : "Create Account")
                }
            }
        }
        .buttonStyle(AccentButtonStyle())
        .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
        .opacity(viewModel.email.isEmpty || viewModel.password.isEmpty ? 0.6 : 1.0)
    }
    
    // MARK: - Toggle Mode Button
    
    private var toggleModeButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.toggleAuthMode()
            }
        }) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Text(viewModel.authMode == .signIn ? "Don't have an account?" : "Already have an account?")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                Text(viewModel.authMode == .signIn ? "Sign Up" : "Sign In")
                    .foregroundStyle(AppTheme.Colors.accent)
                    .fontWeight(.semibold)
            }
            .font(AppTheme.Typography.body())
        }
        .disabled(viewModel.isLoading)
    }
}

// MARK: - Preview

#Preview {
    let mockProvider = SupabaseClientProvider()
    let authService = SupabaseAuthService(clientProvider: mockProvider)
    let viewModel = AuthViewModel(authService: authService)
    
    return AuthScreen()
        .environmentObject(viewModel)
}
