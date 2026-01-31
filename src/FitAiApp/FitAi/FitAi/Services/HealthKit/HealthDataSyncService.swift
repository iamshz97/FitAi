//
//  HealthDataSyncService.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/31/26.
//

import Foundation
import Supabase
import os.log

// MARK: - Logger

private let logger = Logger(subsystem: "com.fitai.app", category: "HealthDataSyncService")

// MARK: - Health Data Sync Service Protocol

/// Protocol for syncing HealthKit data to Supabase.
protocol HealthDataSyncServiceProtocol {
    /// Last successful sync date
    var lastSyncDate: Date? { get }
    
    /// Whether a sync is currently in progress
    var isSyncing: Bool { get }
    
    /// Sync recent health data (last N days)
    func syncRecentData(days: Int) async throws
    
    /// Sync daily aggregates for a specific date
    func syncDailyAggregates(for date: Date) async throws
    
    /// Sync all daily aggregates for the last N days
    func syncAllDailyAggregates(days: Int) async throws
}

// MARK: - Health Data Sync Service Implementation

/// Syncs HealthKit data to Supabase tables for AI predictions.
final class HealthDataSyncService: HealthDataSyncServiceProtocol {
    
    // MARK: - Properties
    
    private let healthKitService: HealthKitServiceProtocol
    private let supabaseClient: SupabaseClient
    private let userDefaults: UserDefaults
    
    private let lastSyncKey = "com.fitai.healthkit.lastSync"
    private let healthDataTable = "health_data"
    private let healthDailyTable = "health_data_daily"
    
    private(set) var isSyncing: Bool = false
    
    var lastSyncDate: Date? {
        get {
            userDefaults.object(forKey: lastSyncKey) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: lastSyncKey)
        }
    }
    
    // MARK: - Initialization
    
    init(
        healthKitService: HealthKitServiceProtocol,
        supabaseClient: SupabaseClient,
        userDefaults: UserDefaults = .standard
    ) {
        self.healthKitService = healthKitService
        self.supabaseClient = supabaseClient
        self.userDefaults = userDefaults
        logger.info("🟢 HealthDataSyncService initialized")
    }
    
    // MARK: - Get Current User ID
    
    private func getCurrentUserId() async throws -> UUID {
        let session = try await supabaseClient.auth.session
        return session.user.id
    }
    
    // MARK: - Sync Recent Data
    
    func syncRecentData(days: Int) async throws {
        guard !isSyncing else {
            logger.info("⚠️ Sync already in progress, skipping")
            return
        }
        
        logger.info("📍 Starting sync for last \(days) days...")
        isSyncing = true
        
        defer {
            isSyncing = false
        }
        
        do {
            let userId = try await getCurrentUserId()
            let metrics = try await healthKitService.fetchRecentMetrics(days: days)
            
            guard !metrics.isEmpty else {
                logger.info("ℹ️ No metrics to sync")
                lastSyncDate = Date()
                return
            }
            
            logger.info("🔄 Syncing \(metrics.count) metrics...")
            
            // Batch insert metrics
            let insertData = metrics.map { metric in
                HealthDataRow(
                    userId: userId.uuidString,
                    metricType: metric.type.rawValue,
                    value: metric.value,
                    unit: metric.unit,
                    startTime: metric.startDate,
                    endTime: metric.endDate,
                    sourceName: metric.sourceName,
                    sourceBundleId: metric.sourceBundleId
                )
            }
            
            // Use upsert to handle duplicates
            try await supabaseClient
                .from(healthDataTable)
                .upsert(insertData, onConflict: "user_id,metric_type,start_time,end_time")
                .execute()
            
            lastSyncDate = Date()
            logger.info("✅ Synced \(metrics.count) metrics successfully")
            
        } catch {
            logger.error("❌ Sync failed: \(error.localizedDescription)")
            throw HealthKitError.syncFailed(message: error.localizedDescription)
        }
    }
    
    // MARK: - Sync Daily Aggregates
    
    func syncDailyAggregates(for date: Date) async throws {
        logger.info("📍 Syncing daily aggregates for \(date)...")
        
        do {
            let userId = try await getCurrentUserId()
            let summary = try await healthKitService.fetchDailySummary(for: date)
            
            guard summary.hasData else {
                logger.info("ℹ️ No data for \(date)")
                return
            }
            
            let row = HealthDailyRow(
                userId: userId.uuidString,
                date: summary.date,
                stepsTotal: summary.stepsTotal,
                distanceMeters: summary.distanceMeters,
                activeCaloriesTotal: summary.activeCaloriesTotal,
                restingHeartRate: summary.restingHeartRate,
                avgHeartRate: summary.avgHeartRate,
                sleepHours: summary.sleepHours,
                workoutMinutes: summary.workoutMinutes,
                workoutCount: summary.workoutCount
            )
            
            try await supabaseClient
                .from(healthDailyTable)
                .upsert(row, onConflict: "user_id,date")
                .execute()
            
            logger.info("✅ Daily aggregates synced for \(date)")
            
        } catch {
            logger.error("❌ Daily sync failed: \(error.localizedDescription)")
            throw HealthKitError.syncFailed(message: error.localizedDescription)
        }
    }
    
    // MARK: - Sync All Daily Aggregates
    
    func syncAllDailyAggregates(days: Int) async throws {
        logger.info("📍 Syncing daily aggregates for last \(days) days...")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }
            
            do {
                try await syncDailyAggregates(for: date)
            } catch {
                // Log but continue with other days
                logger.warning("⚠️ Failed to sync \(date): \(error.localizedDescription)")
            }
        }
        
        logger.info("✅ Completed syncing daily aggregates")
    }
}

// MARK: - Database Row Models

/// Row model for health_data table.
private struct HealthDataRow: Encodable {
    let userId: String
    let metricType: String
    let value: Double
    let unit: String
    let startTime: Date
    let endTime: Date
    let sourceName: String?
    let sourceBundleId: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case metricType = "metric_type"
        case value
        case unit
        case startTime = "start_time"
        case endTime = "end_time"
        case sourceName = "source_name"
        case sourceBundleId = "source_bundle_id"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(metricType, forKey: .metricType)
        try container.encode(value, forKey: .value)
        try container.encode(unit, forKey: .unit)
        try container.encode(ISO8601DateFormatter().string(from: startTime), forKey: .startTime)
        try container.encode(ISO8601DateFormatter().string(from: endTime), forKey: .endTime)
        try container.encodeIfPresent(sourceName, forKey: .sourceName)
        try container.encodeIfPresent(sourceBundleId, forKey: .sourceBundleId)
    }
}

/// Row model for health_data_daily table.
private struct HealthDailyRow: Encodable {
    let userId: String
    let date: Date
    let stepsTotal: Int?
    let distanceMeters: Double?
    let activeCaloriesTotal: Double?
    let restingHeartRate: Double?
    let avgHeartRate: Double?
    let sleepHours: Double?
    let workoutMinutes: Int?
    let workoutCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case date
        case stepsTotal = "steps_total"
        case distanceMeters = "distance_meters"
        case activeCaloriesTotal = "active_calories_total"
        case restingHeartRate = "resting_heart_rate"
        case avgHeartRate = "avg_heart_rate"
        case sleepHours = "sleep_hours"
        case workoutMinutes = "workout_minutes"
        case workoutCount = "workout_count"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        
        // Format date as YYYY-MM-DD for PostgreSQL DATE type
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        try container.encode(dateFormatter.string(from: date), forKey: .date)
        
        try container.encodeIfPresent(stepsTotal, forKey: .stepsTotal)
        try container.encodeIfPresent(distanceMeters, forKey: .distanceMeters)
        try container.encodeIfPresent(activeCaloriesTotal, forKey: .activeCaloriesTotal)
        try container.encodeIfPresent(restingHeartRate, forKey: .restingHeartRate)
        try container.encodeIfPresent(avgHeartRate, forKey: .avgHeartRate)
        try container.encodeIfPresent(sleepHours, forKey: .sleepHours)
        try container.encodeIfPresent(workoutMinutes, forKey: .workoutMinutes)
        try container.encodeIfPresent(workoutCount, forKey: .workoutCount)
    }
}
