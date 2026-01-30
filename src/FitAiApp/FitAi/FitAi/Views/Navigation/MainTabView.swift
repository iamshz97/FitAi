//
//  MainTabView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Tab Item

/// Represents a tab in the main navigation.
enum TabItem: Int, CaseIterable, Identifiable {
    case home
    case food
    case plan
    case profile
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .food: return "Food"
        case .plan: return "Plan"
        case .profile: return "Profile"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .food: return "fork.knife"
        case .plan: return "chart.bar"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .food: return "fork.knife"
        case .plan: return "chart.bar.fill"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - Main Tab View

/// The main tab navigation view with native iOS glass tab bar.
struct MainTabView: View {
    
    // MARK: - State
    
    @State private var selectedTab: TabItem = .home
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Init
    
    init() {
        // Configure native tab bar appearance with glass effect
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        appearance.backgroundColor = UIColor(AppTheme.Colors.background.opacity(0.5))
        
        // Selected item color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.Colors.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.Colors.accent)
        ]
        
        // Unselected item color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppTheme.Colors.textTertiary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.Colors.textTertiary)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                HomeTabView()
                    .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            }
            .tabItem {
                Label(TabItem.home.title, systemImage: selectedTab == .home ? TabItem.home.selectedIcon : TabItem.home.icon)
            }
            .tag(TabItem.home)
            
            // Food Tab
            NavigationStack {
                FoodTabView()
                    .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            }
            .tabItem {
                Label(TabItem.food.title, systemImage: selectedTab == .food ? TabItem.food.selectedIcon : TabItem.food.icon)
            }
            .tag(TabItem.food)
            
            // Plan Tab
            NavigationStack {
                PlanTabView()
                    .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            }
            .tabItem {
                Label(TabItem.plan.title, systemImage: selectedTab == .plan ? TabItem.plan.selectedIcon : TabItem.plan.icon)
            }
            .tag(TabItem.plan)
            
            // Profile Tab
            NavigationStack {
                SettingsTabView()
                    .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            }
            .tabItem {
                Label(TabItem.profile.title, systemImage: selectedTab == .profile ? TabItem.profile.selectedIcon : TabItem.profile.icon)
            }
            .tag(TabItem.profile)
        }
        .tint(AppTheme.Colors.accent)
    }
}

// MARK: - Plan Tab View (Placeholder)

struct PlanTabView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
                // Header
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Your Plan")
                        .font(AppTheme.Typography.displayMedium())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    Text("Track your progress and stay on course.")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .padding(.top, AppTheme.Spacing.lg)
                
                // Placeholder content
                VStack(spacing: AppTheme.Spacing.lg) {
                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(AppTheme.Colors.accent.opacity(0.3))
                    
                    Text("Your fitness plan will appear here")
                        .font(AppTheme.Typography.body())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .appBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Plan")
                    .font(AppTheme.Typography.headlineSmall())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let mockProvider = SupabaseClientProvider()
    let authService = SupabaseAuthService(clientProvider: mockProvider)
    let viewModel = AuthViewModel(authService: authService)
    
    return MainTabView()
        .environmentObject(viewModel)
}
