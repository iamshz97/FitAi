//
//  SettingsTabView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Settings Tab View

/// The profile/settings tab with premium dark green design.
struct SettingsTabView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - State
    
    @State private var showHealthKitSettings: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xxl) {
                // Profile Header
                profileHeader
                
                // Settings Sections
                accountSection
                appSettingsSection
                supportSection
                
                // Sign Out
                signOutSection
                
                // Version
                versionInfo
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.lg)
        }
        .appBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(AppTheme.Typography.headlineSmall())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accent.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Text(authViewModel.user?.displayName.prefix(1).uppercased() ?? "U")
                    .font(AppTheme.Typography.displayMedium())
                    .foregroundStyle(AppTheme.Colors.accent)
            }
            
            // User Info
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(authViewModel.user?.displayName ?? "User")
                    .font(AppTheme.Typography.headline())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                if let email = authViewModel.user?.email {
                    Text(email)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            
            // Edit Profile Button
            Button(action: {}) {
                Text("Edit Profile")
                    .font(AppTheme.Typography.captionMedium())
                    .foregroundStyle(AppTheme.Colors.accent)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.accent.opacity(0.15))
                    .cornerRadius(AppTheme.CornerRadius.pill)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        SettingsSection(title: "Account") {
            SettingsRow(icon: "person.fill", title: "Personal Info", color: AppTheme.Colors.accent)
            SettingsRow(icon: "target", title: "Goals", color: AppTheme.Colors.warning)
            SettingsRow(icon: "chart.line.uptrend.xyaxis", title: "Progress", color: AppTheme.Colors.info)
        }
    }
    
    // MARK: - App Settings Section
    
    private var appSettingsSection: some View {
        SettingsSection(title: "Settings") {
            // Apple Health
            Button(action: {
                showHealthKitSettings = true
            }) {
                SettingsRowContent(icon: "heart.fill", title: "Apple Health", color: .red)
            }
            .sheet(isPresented: $showHealthKitSettings) {
                HealthKitSettingsView()
            }
            
            SettingsRow(icon: "bell.fill", title: "Notifications", color: AppTheme.Colors.error)
            SettingsRow(icon: "moon.fill", title: "Appearance", color: AppTheme.Colors.accentSecondary)
            SettingsRow(icon: "lock.fill", title: "Privacy", color: AppTheme.Colors.textSecondary)
            SettingsRow(icon: "globe", title: "Language", color: AppTheme.Colors.info)
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        SettingsSection(title: "Support") {
            SettingsRow(icon: "questionmark.circle.fill", title: "Help Center", color: AppTheme.Colors.accent)
            SettingsRow(icon: "envelope.fill", title: "Contact Us", color: AppTheme.Colors.warning)
            SettingsRow(icon: "star.fill", title: "Rate App", color: AppTheme.Colors.warning)
        }
    }
    
    // MARK: - Sign Out Section
    
    private var signOutSection: some View {
        Button(action: {
            Task {
                await authViewModel.signOut()
            }
        }) {
            HStack {
                Spacer()
                
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.error))
                } else {
                    Text("Sign Out")
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundStyle(AppTheme.Colors.error)
                }
                
                Spacer()
            }
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(AppTheme.Colors.error.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .disabled(authViewModel.isLoading)
    }
    
    // MARK: - Version Info
    
    private var versionInfo: some View {
        Text("FitAi v1.0.0")
            .font(AppTheme.Typography.caption())
            .foregroundStyle(AppTheme.Colors.textTertiary)
            .padding(.top, AppTheme.Spacing.lg)
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(title.uppercased())
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(.leading, AppTheme.Spacing.sm)
            
            VStack(spacing: 0) {
                content
            }
            .cardStyle()
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            SettingsRowContent(icon: icon, title: title, color: color)
        }
    }
}

// MARK: - Settings Row Content

/// Reusable row content for settings items (can be used with custom buttons)
struct SettingsRowContent: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 28)
            
            Text(title)
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.lg)
    }
}

// MARK: - Preview

#Preview {
    let mockProvider = SupabaseClientProvider()
    let authService = SupabaseAuthService(clientProvider: mockProvider)
    let viewModel = AuthViewModel(authService: authService)
    
    return NavigationStack {
        SettingsTabView()
            .environmentObject(viewModel)
    }
}
