//
//  UserProfileService.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation
import Supabase

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
    }
    
    // MARK: - Get Current User ID
    
    private func getCurrentUserId() async throws -> UUID {
        guard let session = try? await client.auth.session else {
            throw UserProfileError.notAuthenticated
        }
        return session.user.id
    }
    
    // MARK: - Fetch Profile
    
    func fetchProfile() async throws -> UserProfile? {
        let userId = try await getCurrentUserId()
        
        do {
            let response: UserProfile = try await client
                .from(tableName)
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            return response
        } catch {
            // If profile doesn't exist yet, return nil
            if error.localizedDescription.contains("no rows") ||
               error.localizedDescription.contains("0 rows") {
                return nil
            }
            throw UserProfileError.fetchFailed(message: error.localizedDescription)
        }
    }
    
    // MARK: - Create Profile
    
    func createProfile() async throws -> UserProfile {
        let userId = try await getCurrentUserId()
        let newProfile = UserProfile.newProfile(for: userId)
        
        do {
            let response: UserProfile = try await client
                .from(tableName)
                .insert(newProfile)
                .select()
                .single()
                .execute()
                .value
            
            return response
        } catch {
            throw UserProfileError.saveFailed(message: error.localizedDescription)
        }
    }
    
    // MARK: - Update Profile
    
    func updateProfile(_ profile: UserProfile) async throws {
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
        }
        if let sex = profile.sexAtBirth {
            updateData["sex_at_birth"] = AnyEncodable(sex.rawValue)
        }
        if let height = profile.heightCm {
            updateData["height_cm"] = AnyEncodable(height)
        }
        if let weight = profile.weightKg {
            updateData["weight_kg"] = AnyEncodable(weight)
        }
        if let bmi = profile.calculatedBMI {
            updateData["bmi"] = AnyEncodable(bmi)
        }
        
        // Page 2 fields
        if let goal = profile.goal {
            updateData["goal"] = AnyEncodable(goal.rawValue)
        }
        if let activity = profile.activityLevel {
            updateData["activity_level"] = AnyEncodable(activity.rawValue)
        }
        if let days = profile.daysPerWeek {
            updateData["days_per_week"] = AnyEncodable(days)
        }
        if let minutes = profile.minutesPerSession {
            updateData["minutes_per_session"] = AnyEncodable(minutes)
        }
        if let equipment = profile.equipmentContext {
            updateData["equipment_context"] = AnyEncodable(equipment.rawValue)
        }
        
        do {
            try await client
                .from(tableName)
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            throw UserProfileError.saveFailed(message: error.localizedDescription)
        }
    }
    
    // MARK: - Update Onboarding Step
    
    func updateOnboardingStep(_ step: Int) async throws {
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
        } catch {
            throw UserProfileError.saveFailed(message: error.localizedDescription)
        }
    }
    
    // MARK: - Complete Onboarding
    
    func completeOnboarding() async throws {
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
        } catch {
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
