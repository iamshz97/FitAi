//
//  HealthKitService.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/31/26.
//

import Foundation
import HealthKit
import os.log

// MARK: - Logger

private let logger = Logger(subsystem: "com.fitai.app", category: "HealthKitService")

// MARK: - HealthKit Service Protocol

/// Protocol for HealthKit operations, enabling dependency injection and testing.
protocol HealthKitServiceProtocol {
    /// Whether HealthKit is available on this device
    var isAvailable: Bool { get }
    
    /// Current authorization status
    var authorizationStatus: HealthKitAuthorizationStatus { get async }
    
    /// Request authorization to read/write health data
    func requestAuthorization() async throws -> Bool
    
    /// Fetch user characteristic data (sex, DOB, height, weight)
    func fetchUserCharacteristics() async throws -> HealthKitUserData
    
    /// Fetch recent health metrics for the specified number of days
    func fetchRecentMetrics(days: Int) async throws -> [HealthMetric]
    
    /// Fetch daily summary for a specific date
    func fetchDailySummary(for date: Date) async throws -> DailyHealthSummary
    
    /// Set up observer for real-time health data changes
    func observeChanges(handler: @escaping ([HealthMetric]) -> Void)
    
    /// Stop observing changes
    func stopObserving()
}

// MARK: - HealthKit Service Implementation

/// Concrete implementation of HealthKit operations.
/// This service is designed to be isolated and modular for easy modifications.
final class HealthKitService: HealthKitServiceProtocol {
    
    // MARK: - Properties
    
    private let healthStore: HKHealthStore
    private var observerQueries: [HKObserverQuery] = []
    
    // MARK: - Data Types
    
    /// Types we want to READ from HealthKit
    private var typesToRead: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        
        // Characteristics (profile data)
        if let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) {
            types.insert(biologicalSex)
        }
        if let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            types.insert(dateOfBirth)
        }
        
        // Body measurements
        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        
        // Activity
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distance)
        }
        if let activeCalories = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeCalories)
        }
        
        // Vitals
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHeartRate)
        }
        
        // Sleep
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        
        // Workouts
        types.insert(HKObjectType.workoutType())
        
        return types
    }
    
    /// Types we want to SHARE/WRITE to HealthKit (optional, for future use)
    private var typesToWrite: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        // Add workout type for saving workouts later if needed
        types.insert(HKObjectType.workoutType())
        return types
    }
    
    // MARK: - Computed Properties
    
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    var authorizationStatus: HealthKitAuthorizationStatus {
        get async {
            guard isAvailable else {
                return .unavailable
            }
            
            // Check authorization status for a key type (steps)
            guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
                return .unavailable
            }
            
            let status = healthStore.authorizationStatus(for: stepsType)
            switch status {
            case .notDetermined:
                return .notDetermined
            case .sharingAuthorized:
                return .authorized
            case .sharingDenied:
                return .denied
            @unknown default:
                return .notDetermined
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        self.healthStore = HKHealthStore()
        logger.info("🟢 HealthKitService initialized")
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws -> Bool {
        print("📍 [HealthKit] requestAuthorization() called")
        print("📍 [HealthKit] isAvailable: \(isAvailable)")
        print("📍 [HealthKit] Types to read: \(typesToRead.count)")
        print("📍 [HealthKit] Types to write: \(typesToWrite.count)")
        
        // Log each type we're requesting
        for type in typesToRead {
            print("   - Read: \(type.identifier)")
        }
        for type in typesToWrite {
            print("   - Write: \(type.identifier)")
        }
        
        guard isAvailable else {
            print("❌ [HealthKit] HealthKit not available on this device")
            throw HealthKitError.notAvailable
        }
        
        do {
            print("📍 [HealthKit] Calling healthStore.requestAuthorization...")
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            print("✅ [HealthKit] requestAuthorization completed successfully")
            
            // Check authorization status for each type we care about
            print("📍 [HealthKit] Checking authorization status for read types:")
            for type in typesToRead {
                if let sampleType = type as? HKSampleType {
                    let status = healthStore.authorizationStatus(for: sampleType)
                    print("   - \(type.identifier): \(status.rawValue) (\(statusDescription(status)))")
                }
            }
            
            return true
        } catch let error as NSError {
            print("❌ [HealthKit] Authorization error:")
            print("   - Domain: \(error.domain)")
            print("   - Code: \(error.code)")
            print("   - Description: \(error.localizedDescription)")
            print("   - UserInfo: \(error.userInfo)")
            throw HealthKitError.authorizationDenied
        }
    }
    
    private func statusDescription(_ status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .sharingDenied: return "sharingDenied"
        case .sharingAuthorized: return "sharingAuthorized"
        @unknown default: return "unknown"
        }
    }
    
    // MARK: - Fetch User Characteristics
    
    func fetchUserCharacteristics() async throws -> HealthKitUserData {
        print("📍 [HealthKit] fetchUserCharacteristics() called")
        
        guard isAvailable else {
            print("❌ [HealthKit] Not available")
            throw HealthKitError.notAvailable
        }
        
        var userData = HealthKitUserData()
        
        // Biological Sex
        do {
            let biologicalSex = try healthStore.biologicalSex()
            userData.biologicalSex = biologicalSex.biologicalSex
            print("✅ [HealthKit] biologicalSex: \(biologicalSex.biologicalSex.rawValue)")
        } catch let error {
            print("⚠️ [HealthKit] biologicalSex error: \(error.localizedDescription)")
        }
        
        // Date of Birth
        do {
            let dateOfBirth = try healthStore.dateOfBirthComponents()
            userData.dateOfBirth = dateOfBirth
            print("✅ [HealthKit] dateOfBirth: year=\(dateOfBirth.year ?? 0)")
        } catch let error {
            print("⚠️ [HealthKit] dateOfBirth error: \(error.localizedDescription)")
        }
        
        // Height (most recent)
        if let heightType = HKQuantityType.quantityType(forIdentifier: .height) {
            do {
                if let height = try await fetchMostRecentSample(for: heightType) {
                    userData.heightCm = height.quantity.doubleValue(for: .meterUnit(with: .centi))
                    print("✅ [HealthKit] height: \(userData.heightCm ?? 0) cm")
                } else {
                    print("⚠️ [HealthKit] height: no samples found")
                }
            } catch let error {
                print("⚠️ [HealthKit] height error: \(error.localizedDescription)")
            }
        }
        
        // Weight (most recent)
        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            do {
                if let weight = try await fetchMostRecentSample(for: weightType) {
                    userData.weightKg = weight.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    print("✅ [HealthKit] weight: \(userData.weightKg ?? 0) kg")
                } else {
                    print("⚠️ [HealthKit] weight: no samples found")
                }
            } catch let error {
                print("⚠️ [HealthKit] weight error: \(error.localizedDescription)")
            }
        }
        
        print("📍 [HealthKit] fetchUserCharacteristics complete - hasData: \(userData.hasData)")
        return userData
    }
    
    // MARK: - Fetch Recent Metrics
    
    func fetchRecentMetrics(days: Int) async throws -> [HealthMetric] {
        logger.info("📍 Fetching recent metrics for \(days) days...")
        
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        var allMetrics: [HealthMetric] = []
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            throw HealthKitError.fetchFailed(message: "Invalid date range")
        }
        
        // Fetch steps
        if let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let steps = try await fetchSamples(for: stepsType, from: startDate, to: endDate)
            let metrics = steps.map { sample in
                HealthMetric(
                    type: .steps,
                    value: sample.quantity.doubleValue(for: .count()),
                    unit: "count",
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    sourceName: sample.sourceRevision.source.name,
                    sourceBundleId: sample.sourceRevision.source.bundleIdentifier
                )
            }
            allMetrics.append(contentsOf: metrics)
        }
        
        // Fetch distance
        if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            let distances = try await fetchSamples(for: distanceType, from: startDate, to: endDate)
            let metrics = distances.map { sample in
                HealthMetric(
                    type: .distance,
                    value: sample.quantity.doubleValue(for: .meter()),
                    unit: "meters",
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    sourceName: sample.sourceRevision.source.name,
                    sourceBundleId: sample.sourceRevision.source.bundleIdentifier
                )
            }
            allMetrics.append(contentsOf: metrics)
        }
        
        // Fetch active calories
        if let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let calories = try await fetchSamples(for: caloriesType, from: startDate, to: endDate)
            let metrics = calories.map { sample in
                HealthMetric(
                    type: .activeCalories,
                    value: sample.quantity.doubleValue(for: .kilocalorie()),
                    unit: "kcal",
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    sourceName: sample.sourceRevision.source.name,
                    sourceBundleId: sample.sourceRevision.source.bundleIdentifier
                )
            }
            allMetrics.append(contentsOf: metrics)
        }
        
        // Fetch heart rate
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let heartRates = try await fetchSamples(for: heartRateType, from: startDate, to: endDate)
            let metrics = heartRates.map { sample in
                HealthMetric(
                    type: .heartRate,
                    value: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                    unit: "bpm",
                    startDate: sample.startDate,
                    endDate: sample.endDate,
                    sourceName: sample.sourceRevision.source.name,
                    sourceBundleId: sample.sourceRevision.source.bundleIdentifier
                )
            }
            allMetrics.append(contentsOf: metrics)
        }
        
        logger.info("✅ Fetched \(allMetrics.count) metrics")
        return allMetrics
    }
    
    // MARK: - Fetch Daily Summary
    
    func fetchDailySummary(for date: Date) async throws -> DailyHealthSummary {
        logger.info("📍 Fetching daily summary for \(date)...")
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.fetchFailed(message: "Invalid date")
        }
        
        var summary = DailyHealthSummary(date: startOfDay)
        
        // Steps total
        if let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let total = try await fetchStatistics(for: stepsType, from: startOfDay, to: endOfDay, option: .cumulativeSum)
            summary.stepsTotal = total.map { Int($0) }
        }
        
        // Distance total
        if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            summary.distanceMeters = try await fetchStatistics(for: distanceType, from: startOfDay, to: endOfDay, option: .cumulativeSum)
        }
        
        // Active calories total
        if let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            summary.activeCaloriesTotal = try await fetchStatistics(for: caloriesType, from: startOfDay, to: endOfDay, option: .cumulativeSum)
        }
        
        // Resting heart rate
        if let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            summary.restingHeartRate = try await fetchStatistics(for: restingHRType, from: startOfDay, to: endOfDay, option: .discreteAverage)
        }
        
        // Average heart rate
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            summary.avgHeartRate = try await fetchStatistics(for: heartRateType, from: startOfDay, to: endOfDay, option: .discreteAverage)
        }
        
        // Sleep (simplified - just total sleep time)
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            let sleepMinutes = try await fetchSleepMinutes(for: sleepType, from: startOfDay, to: endOfDay)
            summary.sleepHours = sleepMinutes.map { $0 / 60.0 }
        }
        
        // Workouts
        let workouts = try await fetchWorkouts(from: startOfDay, to: endOfDay)
        summary.workoutCount = workouts.count
        summary.workoutMinutes = Int(workouts.reduce(0) { $0 + $1.duration }) / 60
        
        logger.info("✅ Daily summary fetched - hasData: \(summary.hasData)")
        return summary
    }
    
    // MARK: - Observer Queries
    
    func observeChanges(handler: @escaping ([HealthMetric]) -> Void) {
        logger.info("📍 Setting up HealthKit observers...")
        
        // Observe steps
        if let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let query = HKObserverQuery(sampleType: stepsType, predicate: nil) { [weak self] _, completionHandler, error in
                if let error = error {
                    logger.error("❌ Observer error: \(error.localizedDescription)")
                    completionHandler()
                    return
                }
                
                Task {
                    do {
                        let metrics = try await self?.fetchRecentMetrics(days: 1) ?? []
                        handler(metrics)
                    } catch {
                        logger.error("❌ Failed to fetch on observer callback: \(error.localizedDescription)")
                    }
                    completionHandler()
                }
            }
            healthStore.execute(query)
            observerQueries.append(query)
        }
        
        logger.info("✅ Observers set up: \(self.observerQueries.count)")
    }
    
    func stopObserving() {
        logger.info("📍 Stopping HealthKit observers...")
        for query in observerQueries {
            healthStore.stop(query)
        }
        observerQueries.removeAll()
        logger.info("✅ Observers stopped")
    }
    
    // MARK: - Private Helpers
    
    private func fetchMostRecentSample(for type: HKQuantityType) async throws -> HKQuantitySample? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: Date(), options: .strictEndDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.fetchFailed(message: error.localizedDescription))
                    return
                }
                continuation.resume(returning: samples?.first as? HKQuantitySample)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchSamples(for type: HKQuantityType, from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.fetchFailed(message: error.localizedDescription))
                    return
                }
                let quantitySamples = samples?.compactMap { $0 as? HKQuantitySample } ?? []
                continuation.resume(returning: quantitySamples)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchStatistics(for type: HKQuantityType, from startDate: Date, to endDate: Date, option: HKStatisticsOptions) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: option
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.fetchFailed(message: error.localizedDescription))
                    return
                }
                
                guard let statistics = statistics else {
                    continuation.resume(returning: nil)
                    return
                }
                
                var value: Double?
                if option.contains(.cumulativeSum) {
                    value = statistics.sumQuantity()?.doubleValue(for: self.unit(for: type))
                } else if option.contains(.discreteAverage) {
                    value = statistics.averageQuantity()?.doubleValue(for: self.unit(for: type))
                }
                
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchSleepMinutes(for type: HKCategoryType, from startDate: Date, to endDate: Date) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.fetchFailed(message: error.localizedDescription))
                    return
                }
                
                let sleepSamples = samples?.compactMap { $0 as? HKCategorySample } ?? []
                // Filter for actual sleep (not in bed)
                let asleepSamples = sleepSamples.filter { sample in
                    sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                    sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                }
                
                let totalMinutes = asleepSamples.reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate) / 60.0
                }
                
                continuation.resume(returning: totalMinutes > 0 ? totalMinutes : nil)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.fetchFailed(message: error.localizedDescription))
                    return
                }
                let workouts = samples?.compactMap { $0 as? HKWorkout } ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }
    
    private func unit(for type: HKQuantityType) -> HKUnit {
        switch type.identifier {
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return .count()
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            return .meter()
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return .kilocalorie()
        case HKQuantityTypeIdentifier.heartRate.rawValue,
             HKQuantityTypeIdentifier.restingHeartRate.rawValue:
            return HKUnit.count().unitDivided(by: .minute())
        case HKQuantityTypeIdentifier.height.rawValue:
            return .meterUnit(with: .centi)
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            return .gramUnit(with: .kilo)
        default:
            return .count()
        }
    }
}
