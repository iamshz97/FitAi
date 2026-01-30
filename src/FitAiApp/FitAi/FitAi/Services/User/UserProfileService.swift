//
//  UserProfileService.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation
import Supabase
import os.log

// MARK: - Logger

private let logger = Logger(subsystem: "com.fitai.app", category: "UserProfileService")

// MARK: - User Profile Error

enum UserProfileError: Error, LocalizedError {
    case notAuthenticated
    case profileNotFound
    case saveFailed(message: String)
    case fetchFailed(message: String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated."
        case .profileNotFound:
            return "User profile not found."
        case .saveFailed(let message):
            return "Failed to save profile: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch profile: \(message)"
        }
    }
}

// MARK: - User Profile Service Protocol

protocol UserProfileService {
    /// Fetch the current user's profile
    func fetchProfile() async throws -> UserProfile?
    
    /// Create a new profile for the current user
    func createProfile() async throws -> UserProfile
    
    /// Update the user's profile
    func updateProfile(_ profile: UserProfile) async throws
    
    /// Update just the onboarding step
    func updateOnboardingStep(_ step: Int) async throws
    
    /// Mark onboarding as completed
    func completeOnboarding() async throws
}

// MARK: - Supabase User Profile Service

final class SupabaseUserProfileService: UserProfileService {
    
    private let client: SupabaseClient
    private let tableName = "user_profiles"
    
    init(clientProvider: SupabaseClientProviding) {
        self.client = clientProvider.client
        logger.info("🟢 UserProfileService initialized")
    }
    
    // MARK: - Get Current User ID
    
    private func getCurrentUserId() async throws -> UUID {
        logger.info("📍 Getting current user ID...")
        
        guard let session = try? await client.auth.session else {
            logger.error("❌ No auth session found - user not authenticated")
            throw UserProfileError.notAuthenticated
        }
        
        logger.info("✅ Got user ID: \(session.user.id.uuidString)")
        return session.user.id
    }
    
    // MARK: - Fetch Profile
    
    func fetchProfile() async throws -> UserProfile? {
        logger.info("📍 Fetching profile...")
        
        let userId = try await getCurrentUserId()
        
        do {
            logger.info("🔄 Querying user_profiles table for user: \(userId.uuidString)")
            
            let response: UserProfile = try await client
                .from(tableName)
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            logger.info("✅ Profile fetched successfully - onboarding_completed: \(response.onboardingCompleted), step: \(response.onboardingStep)")
            return response
        } catch {
            let errorDesc = error.localizedDescription.lowercased()
            logger.warning("⚠️ Fetch error: \(error.localizedDescription)")
            
            // If profile doesn't exist yet, return nil
            // Handle various error formats from Supabase
            if errorDesc.contains("no rows") ||
               errorDesc.contains("0 rows") ||
               errorDesc.contains("pgrst116") ||
               errorDesc.contains("coerce") ||
               errorDesc.contains("single") {
                logger.info("ℹ️ No profile exists yet - returning nil")
                return nil
            }
            
            logger.error("❌ Fetch failed: \(error.localizedDescription)")
            throw UserProfileError.fetchFailed(message: error.localizedDescription)
        }
    }
    
    // MARK: - Create Profile
    
    func createProfile() async throws -> UserProfile {
        logger.info("📍 Creating new profile...")
        
        guard let session = try? await client.auth.session else {
            logger.error("❌ No auth session found")
            throw UserProfileError.notAuthenticated
        }
        
        let userId = session.user.id
        let email = session.user.email
        
        logger.info("🔄 Creating profile for user: \(userId.uuidString), email: \(email ?? "none")")
        
        // Build insert payload with email
        let insertData: [String: AnyEncodable] = [
            "id": AnyEncodable(userId.uuidString),
            "email": AnyEncodable(email),
            "onboarding_completed": AnyEncodable(false),
            "onboarding_step": AnyEncodable(0)
        ]
        
        do {
            try await client
                .from(tableName)
                .insert(insertData)
                .execute()
            
            logger.info("✅ Profile inserted!")
            
            // Fetch the created profile
            let response: UserProfile = try await client
                .from(tableName)
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            logger.info("✅ Profile created and fetched successfully!")
            return response
        } catch {
            logger.error("❌ Create profile failed: \(error.localizedDescription)")
            throw UserProfileError.saveFailed(message: error.localizedDescription)
        }
    }
    
    // MARK: - Update Profile
    
    func updateProfile(_ profile: UserProfile) async throws {
        logger.info("📍 Updating profile...")
        
        let userId = try await getCurrentUserId()
        
        // Create update payload
        var updateData: [String: AnyEncodable] = [
            "onboarding_completed": AnyEncodable(profile.onboardingCompleted),
            "onboarding_step": AnyEncodable(profile.onboardingStep),
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]
        
        // Page 1 fields
        if let birthYear = profile.birthYear {
            updateData["birth_year"] = AnyEncodable(birthYear)
            logger.debug("  birth_year: \(birthYear)")
        }
        if let sex = profile.sexAtBirth {
            updateData["sex_at_birth"] = AnyEncodable(sex.rawValue)
            logger.debug("  sex_at_birth: \(sex.rawValue)")
        }
        if let height = profile.heightCm {
            updateData["height_cm"] = AnyEncodable(height)
            logger.debug("  height_cm: \(height)")
        }
        if let weight = profile.weightKg {
            updateData["weight_kg"] = AnyEncodable(weight)
            logger.debug("  weight_kg: \(weight)")
        }
        if let bmi = profile.calculatedBMI {
            updateData["bmi"] = AnyEncodable(bmi)
            logger.debug("  bmi: \(bmi)")
        }
        
        // Page 2 fields
        if let goal = profile.goal {
            updateData["goal"] = AnyEncodable(goal.rawValue)
            logger.debug("  goal: \(goal.rawValue)")
        }
        if let activity = profile.activityLevel {
            updateData["activity_level"] = AnyEncodable(activity.rawValue)
            logger.debug("  activity_level: \(activity.rawValue)")
        }
        if let days = profile.daysPerWeek {
            updateData["days_per_week"] = AnyEncodable(days)
            logger.debug("  days_per_week: \(days)")
        }
        if let minutes = profile.minutesPerSession {
            updateData["minutes_per_session"] = AnyEncodable(minutes)
            logger.debug("  minutes_per_session: \(minutes)")
        }
        if let equipment = profile.equipmentContext {
            updateData["equipment_context"] = AnyEncodable(equipment.rawValue)
            logger.debug("  equipment_context: \(equipment.rawValue)")
        }
        
        logger.info("🔄 Updating profile with \(updateData.count) fields for user: \(userId.uuidString)")
        
        do {
            try await client
                .from(tableName)
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .execute()
            
            logger.info("✅ Profile updated successfully!")
        } catch {
            logger.error("❌ Update profile failed: \(error.localizedDescription)")
            throw UserProfileError.saveFailed(message: error.localizedDescription)
        }
    }
    
    // MARK: - Update Onboarding Step
    
    func updateOnboardingStep(_ step: Int) async throws {
        logger.info("📍 Updating onboarding step to: \(step)")
        
        let userId = try await getCurrentUserId()
        
        let updateData: [String: AnyEncodable] = [
            "onboarding_step": AnyEncodable(step),
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]
        
        do {
            try await client
                .from(tableName)
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .execute()
            
            logger.info("✅ Onboarding step updated to \(step)")
        } catch {
            logger.error("❌ Update step failed: \(error.localizedDescription)")
            throw UserProfileError.saveFailed(message: error.localizedDescription)
        }
    }
    
    // MARK: - Complete Onboarding
    
    func completeOnboarding() async throws {
        logger.info("📍 Completing onboarding...")
        
        let userId = try await getCurrentUserId()
        
        let updateData: [String: AnyEncodable] = [
            "onboarding_completed": AnyEncodable(true),
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]
        
        do {
            try await client
                .from(tableName)
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .execute()
            
            logger.info("✅ Onboarding completed successfully!")
        } catch {
            logger.error("❌ Complete onboarding failed: \(error.localizedDescription)")
            throw UserProfileError.saveFailed(message: error.localizedDescription)
        }
    }
}

// MARK: - AnyEncodable Helper

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    
    init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
