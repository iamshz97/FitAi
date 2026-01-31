//
//  HealthKitSettingsView.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/31/26.
//

import SwiftUI

// MARK: - HealthKit Settings View

/// Settings view for managing Apple Health integration.
struct HealthKitSettingsView: View {
    
    // MARK: - Environment
    
    @Environment(\.healthKitService) private var healthKitService
    @Environment(\.healthDataSyncService) private var healthDataSyncService
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var isConnected: Bool = false
    @State private var isSyncing: Bool = false
    @State private var lastSyncDate: Date?
    @State private var showConnectionAlert: Bool = false
    @State private var connectionError: String?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // Connection Status Card
                    connectionStatusCard
                    
                    // Data Types Section
                    dataTypesSection
                    
                    // Sync Controls
                    if isConnected {
                        syncControlsSection
                    }
                    
                    // Info Section
                    infoSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.lg)
            }
            .appBackground()
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.Colors.accent)
                }
            }
        }
        .task {
            await checkConnectionStatus()
        }
        .alert("Connection Error", isPresented: $showConnectionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(connectionError ?? "Unable to connect to Apple Health. Please check your permissions in Settings.")
        }
    }
    
    // MARK: - Connection Status Card
    
    private var connectionStatusCard: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Icon and Status
            HStack(spacing: AppTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isConnected ? "Connected" : "Not Connected")
                        .font(AppTheme.Typography.headline())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    
                    Text(statusMessage)
                        .font(AppTheme.Typography.caption())
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
            }
            
            Divider()
                .background(AppTheme.Colors.chipBorder)
            
            // Connect/Disconnect Button
            Button(action: {
                Task {
                    if isConnected {
                        openHealthSettings()
                    } else {
                        await connectToHealthKit()
                    }
                }
            }) {
                HStack {
                    Image(systemName: isConnected ? "gear" : "link")
                    Text(isConnected ? "Manage in Settings" : "Connect Apple Health")
                }
                .font(AppTheme.Typography.bodyMedium())
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(AppTheme.Colors.accent.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    private var statusColor: Color {
        isConnected ? .green : AppTheme.Colors.textTertiary
    }
    
    private var statusMessage: String {
        if isConnected {
            if let date = lastSyncDate {
                return "Last synced \(date.formatted(.relative(presentation: .named)))"
            }
            return "Ready to sync"
        }
        return "Connect to import your health data"
    }
    
    // MARK: - Data Types Section
    
    private var dataTypesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("DATA WE ACCESS")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            VStack(spacing: 0) {
                DataTypeRow(icon: "person.fill", title: "Profile", description: "Height, weight, biological sex, date of birth", color: .blue)
                Divider().background(AppTheme.Colors.chipBorder)
                DataTypeRow(icon: "figure.walk", title: "Activity", description: "Steps, distance, active calories", color: .orange)
                Divider().background(AppTheme.Colors.chipBorder)
                DataTypeRow(icon: "heart.fill", title: "Heart", description: "Heart rate, resting heart rate", color: .red)
                Divider().background(AppTheme.Colors.chipBorder)
                DataTypeRow(icon: "bed.double.fill", title: "Sleep", description: "Sleep duration and quality", color: .purple)
                Divider().background(AppTheme.Colors.chipBorder)
                DataTypeRow(icon: "figure.run", title: "Workouts", description: "Exercise sessions and duration", color: .green)
            }
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.large)
        }
    }
    
    // MARK: - Sync Controls Section
    
    private var syncControlsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("SYNC")
                .font(AppTheme.Typography.label())
                .foregroundStyle(AppTheme.Colors.textSecondary)
            
            Button(action: {
                Task {
                    await syncNow()
                }
            }) {
                HStack {
                    if isSyncing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(isSyncing ? "Syncing..." : "Sync Now")
                }
                .font(AppTheme.Typography.bodyMedium())
                .foregroundStyle(isSyncing ? AppTheme.Colors.textSecondary : AppTheme.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.large)
            }
            .disabled(isSyncing)
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(AppTheme.Colors.accent)
                
                Text("Your health data stays private. We only use it to personalize your fitness experience and help our AI make better predictions for you.")
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.accent.opacity(0.08))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Actions
    
    private func checkConnectionStatus() async {
        let status = await healthKitService.authorizationStatus
        isConnected = status.isAuthorized
        
        // Load last sync date from UserDefaults
        lastSyncDate = UserDefaults.standard.object(forKey: "com.fitai.healthkit.lastSync") as? Date
    }
    
    private func connectToHealthKit() async {
        do {
            let authorized = try await healthKitService.requestAuthorization()
            isConnected = authorized
            
            if !authorized {
                connectionError = "Health data access was not granted."
                showConnectionAlert = true
            }
        } catch {
            connectionError = error.localizedDescription
            showConnectionAlert = true
        }
    }
    
    private func syncNow() async {
        isSyncing = true
        print("📍 [Settings] Sync Now button pressed")
        
        do {
            // Sync last 30 days of data + aggregates
            try await healthDataSyncService.syncRecentData(days: 30)
            try await healthDataSyncService.syncAllDailyAggregates(days: 30)
            
            print("✅ [Settings] Manual sync completed successfully")
            lastSyncDate = Date()
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } catch {
            print("❌ [Settings] Manual sync failed: \(error.localizedDescription)")
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        
        isSyncing = false
    }
    
    private func openHealthSettings() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Data Type Row

struct DataTypeRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Text(description)
                    .font(AppTheme.Typography.caption())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
    }
}

// MARK: - Preview

#Preview {
    HealthKitSettingsView()
}
