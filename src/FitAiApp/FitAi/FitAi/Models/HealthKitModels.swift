//
//  HealthKitModels.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/31/26.
//

import Foundation
import HealthKit

// MARK: - HealthKit User Data

/// User characteristic data fetched from HealthKit (profile information).
struct HealthKitUserData: Equatable {
    var biologicalSex: HKBiologicalSex?
    var dateOfBirth: DateComponents?
    var heightCm: Double?
    var weightKg: Double?
    
    /// Computed birth year from date of birth
    var birthYear: Int? {
        dateOfBirth?.year
    }
    
    /// Check if we have any useful data
    var hasData: Bool {
        biologicalSex != nil || dateOfBirth != nil || heightCm != nil || weightKg != nil
    }
}

// MARK: - Health Metric Type

/// Types of health metrics that can be synced.
enum HealthMetricType: String, Codable, CaseIterable {
    case steps
    case distance
    case activeCalories
    case heartRate
    case restingHeartRate
    case sleep
    case workout
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .distance: return "Distance"
        case .activeCalories: return "Active Calories"
        case .heartRate: return "Heart Rate"
        case .restingHeartRate: return "Resting Heart Rate"
        case .sleep: return "Sleep"
        case .workout: return "Workouts"
        }
    }
    
    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .distance: return "figure.run"
        case .activeCalories: return "flame.fill"
        case .heartRate: return "heart.fill"
        case .restingHeartRate: return "heart.text.square.fill"
        case .sleep: return "bed.double.fill"
        case .workout: return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Health Metric

/// A single health metric sample from HealthKit.
struct HealthMetric: Codable, Equatable, Identifiable {
    let id: UUID
    let type: HealthMetricType
    let value: Double
    let unit: String
    let startDate: Date
    let endDate: Date
    let sourceName: String?
    let sourceBundleId: String?
    
    init(
        id: UUID = UUID(),
        type: HealthMetricType,
        value: Double,
        unit: String,
        startDate: Date,
        endDate: Date,
        sourceName: String? = nil,
        sourceBundleId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.unit = unit
        self.startDate = startDate
        self.endDate = endDate
        self.sourceName = sourceName
        self.sourceBundleId = sourceBundleId
    }
}

// MARK: - Daily Health Summary

/// Aggregated daily health data for AI predictions.
struct DailyHealthSummary: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    let date: Date
    var stepsTotal: Int?
    var distanceMeters: Double?
    var activeCaloriesTotal: Double?
    var restingHeartRate: Double?
    var avgHeartRate: Double?
    var sleepHours: Double?
    var workoutMinutes: Int?
    var workoutCount: Int?
    
    /// Check if this summary has any data
    var hasData: Bool {
        stepsTotal != nil ||
        distanceMeters != nil ||
        activeCaloriesTotal != nil ||
        restingHeartRate != nil ||
        avgHeartRate != nil ||
        sleepHours != nil ||
        workoutMinutes != nil
    }
}

// MARK: - HealthKit Authorization Status

/// Represents the current authorization status for HealthKit.
enum HealthKitAuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case unavailable
    
    var isAuthorized: Bool {
        self == .authorized
    }
    
    var displayMessage: String {
        switch self {
        case .notDetermined:
            return "Not connected"
        case .authorized:
            return "Connected"
        case .denied:
            return "Access denied"
        case .unavailable:
            return "Not available on this device"
        }
    }
}

// MARK: - HealthKit Error

/// Errors that can occur during HealthKit operations.
enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case noData
    case fetchFailed(message: String)
    case syncFailed(message: String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .authorizationDenied:
            return "Health data access was denied. Please enable in Settings."
        case .noData:
            return "No health data found."
        case .fetchFailed(let message):
            return "Failed to fetch health data: \(message)"
        case .syncFailed(let message):
            return "Failed to sync health data: \(message)"
        }
    }
}

// MARK: - HKBiologicalSex Extension

extension HKBiologicalSex {
    /// Convert to app's SexAtBirth enum
    var asSexAtBirth: SexAtBirth? {
        switch self {
        case .male:
            return .male
        case .female:
            return .female
        case .other:
            return .other
        case .notSet:
            return nil
        @unknown default:
            return nil
        }
    }
}
