//
//  RootView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Root View

/// The root view of the app that handles navigation based on authentication state.
/// Shows AuthScreen when not logged in, HomeView when logged in.
struct RootView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if authViewModel.isLoading && authViewModel.user == nil {
                // Initial loading state
                loadingView
            } else if let user = authViewModel.user {
                // Authenticated - show home
                HomeView(user: user)
            } else {
                // Not authenticated - show auth screen
                AuthScreen()
            }
        }
        .task {
            // Load current user session on app launch
            await authViewModel.loadCurrentUser()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Home View (Placeholder)

/// A placeholder home view shown after successful authentication.
/// This will be replaced with the actual app content.
struct HomeView: View {
    
    // MARK: - Properties
    
    let user: AuthUser
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // User Info
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    
                    Text("Welcome, \(user.displayName)!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let email = user.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Sign Out Button
                Button(action: {
                    Task {
                        await authViewModel.signOut()
                    }
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(authViewModel.isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("FitAi")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

#Preview {
    let mockProvider = SupabaseClientProvider()
    let authService = SupabaseAuthService(clientProvider: mockProvider)
    let viewModel = AuthViewModel(authService: authService)
    
    return RootView()
        .environmentObject(viewModel)
}
