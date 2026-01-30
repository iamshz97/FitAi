//
//  HomeTabView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Home Tab View

/// The home tab content view with premium dark green design.
struct HomeTabView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
                // Header
                headerSection
                
                // Weekly Stats Card
                weeklyStatsCard
                
                // Quick Actions
                quickActionsSection
                
                // Insights Card
                insightsCard
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.lg)
        }
        .appBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("FitAi")
                    .font(AppTheme.Typography.headlineSmall())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Welcome back,")
                .font(AppTheme.Typography.displayMedium())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            if let user = authViewModel.user {
                Text(user.displayName)
                    .font(AppTheme.Typography.displayMedium())
                    .foregroundStyle(AppTheme.Colors.accent)
            }
            
            Text("Let's make today count towards your goals.")
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(.top, AppTheme.Spacing.xs)
        }
        .padding(.top, AppTheme.Spacing.lg)
    }
    
    // MARK: - Weekly Stats Card
    
    private var weeklyStatsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack {
                Text("WEEKLY PROGRESS")
                    .font(AppTheme.Typography.label())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                    Text("+12%")
                        .font(AppTheme.Typography.captionMedium())
                }
                .foregroundStyle(AppTheme.Colors.success)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs) {
                Text("68%")
                    .font(AppTheme.Typography.statLarge())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text("/ 100% target")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            
            // Progress bars
            HStack(alignment: .bottom, spacing: AppTheme.Spacing.sm) {
                ForEach(0..<7, id: \.self) { index in
                    let heights: [CGFloat] = [0.4, 0.6, 0.8, 1.0, 0.7, 0.5, 0.3]
                    let colors: [Color] = [
                        AppTheme.Colors.chartBar1,
                        AppTheme.Colors.chartBar2,
                        AppTheme.Colors.chartBar2,
                        AppTheme.Colors.chartBar4,
                        AppTheme.Colors.chartBar3,
                        AppTheme.Colors.chartBar2,
                        AppTheme.Colors.error.opacity(0.7)
                    ]
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colors[index])
                        .frame(height: 80 * heights[index])
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)
        }
        .padding(AppTheme.Spacing.xl)
        .cardStyle()
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Quick Actions")
                .font(AppTheme.Typography.headline())
                .foregroundStyle(AppTheme.Colors.textPrimary)
            
            HStack(spacing: AppTheme.Spacing.md) {
                QuickActionCard(
                    icon: "flame.fill",
                    title: "Log Workout",
                    color: AppTheme.Colors.warning
                )
                
                QuickActionCard(
                    icon: "fork.knife",
                    title: "Log Meal",
                    color: AppTheme.Colors.accent
                )
                
                QuickActionCard(
                    icon: "drop.fill",
                    title: "Log Water",
                    color: AppTheme.Colors.info
                )
            }
        }
    }
    
    // MARK: - Insights Card
    
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.Colors.warning)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Daily Insight")
                        .font(AppTheme.Typography.captionMedium())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            
            Text("\"Consistency beats intensity. A small step every day builds lasting habits.\"")
                .font(AppTheme.Typography.body())
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .italic()
        }
        .padding(AppTheme.Spacing.xl)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.Colors.accent.opacity(0.15),
                    AppTheme.Colors.cardBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.CornerRadius.large)
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            
            Text(title)
                .font(AppTheme.Typography.caption())
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
        .cardStyle()
    }
}

// MARK: - Preview

#Preview {
    let mockProvider = SupabaseClientProvider()
    let authService = SupabaseAuthService(clientProvider: mockProvider)
    let viewModel = AuthViewModel(authService: authService)
    
    return NavigationStack {
        HomeTabView()
            .environmentObject(viewModel)
    }
}
