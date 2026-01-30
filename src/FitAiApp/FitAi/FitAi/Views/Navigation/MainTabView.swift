//
//  MainTabView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import SwiftUI

// MARK: - Tab Item

/// Represents a tab in the main navigation.
/// Add new cases here to extend the tab bar.
enum TabItem: Int, CaseIterable, Identifiable {
    case home
    case food
    case settings
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .food: return "Food"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .food: return "fork.knife"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Main Tab View

/// The main tab navigation view shown after authentication.
/// Uses SwiftUI's TabView with the latest iOS design patterns.
struct MainTabView: View {
    
    // MARK: - State
    
    @State private var selectedTab: TabItem = .home
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabItem.allCases) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .tint(.blue)
    }
    
    // MARK: - Tab Content
    
    /// Returns the appropriate view for each tab.
    /// Extend this method to add more complex views.
    @ViewBuilder
    private func tabContent(for tab: TabItem) -> some View {
        switch tab {
        case .home:
            HomeTabView()
        case .food:
            FoodTabView()
        case .settings:
            SettingsTabView()
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
