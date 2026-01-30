//
//  SettingsTabView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Settings Tab View

/// The settings tab content view.
/// Manage app preferences, account settings, and sign out.
struct SettingsTabView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                accountSection
                
                // App Settings Section
                appSettingsSection
                
                // Sign Out Section
                signOutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        Section("Account") {
            if let user = authViewModel.user {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .font(.headline)
                        
                        if let email = user.email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            NavigationLink {
                Text("Edit Profile")
                    .navigationTitle("Edit Profile")
            } label: {
                Label("Edit Profile", systemImage: "pencil")
            }
        }
    }
    
    // MARK: - App Settings Section
    
    private var appSettingsSection: some View {
        Section("App Settings") {
            NavigationLink {
                Text("Notifications Settings")
                    .navigationTitle("Notifications")
            } label: {
                Label("Notifications", systemImage: "bell.fill")
            }
            
            NavigationLink {
                Text("Appearance Settings")
                    .navigationTitle("Appearance")
            } label: {
                Label("Appearance", systemImage: "paintbrush.fill")
            }
            
            NavigationLink {
                Text("Privacy Settings")
                    .navigationTitle("Privacy")
            } label: {
                Label("Privacy", systemImage: "lock.fill")
            }
        }
    }
    
    // MARK: - Sign Out Section
    
    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                Task {
                    await authViewModel.signOut()
                }
            } label: {
                HStack {
                    Spacer()
                    if authViewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign Out")
                    }
                    Spacer()
                }
            }
            .disabled(authViewModel.isLoading)
        }
    }
}

// MARK: - Preview

#Preview {
    let mockProvider = SupabaseClientProvider()
    let authService = SupabaseAuthService(clientProvider: mockProvider)
    let viewModel = AuthViewModel(authService: authService)
    
    return SettingsTabView()
        .environmentObject(viewModel)
}
