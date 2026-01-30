//
//  UserProfile.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation

// MARK: - User Profile

/// Represents a user's profile including onboarding data and preferences.
struct UserProfile: Codable, Equatable {
    let id: UUID
    var email: String?
    var firstName: String?
    var lastName: String?
    var onboardingCompleted: Bool
    var onboardingStep: Int
    
    // Page 1: Personal Info
    var birthYear: Int?
    var sexAtBirth: SexAtBirth?
    var heightCm: Double?
    var weightKg: Double?
    var bmi: Double?
    var bodyFatPercentage: Double?
    
    // Page 2: Fitness Preferences
    var goal: FitnessGoal?
    var activityLevel: ActivityLevel?
    var daysPerWeek: Int?
    var minutesPerSession: Int?
    var equipmentContext: EquipmentContext?
    
    // Page 3: Health Background
    var medicalHistory: String?
    var familyMedicalHistory: String?
    var currentInjuries: String?
    
    // Page 4: Goals & Lifestyle
    var fitnessGoalsText: String?
    var trainingConstraints: String?
    var sleepPattern: SleepPattern?
    
    var createdAt: Date?
    var updatedAt: Date?
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case onboardingCompleted = "onboarding_completed"
        case onboardingStep = "onboarding_step"
        case birthYear = "birth_year"
        case sexAtBirth = "sex_at_birth"
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case bmi
        case bodyFatPercentage = "body_fat_percentage"
        case goal
        case activityLevel = "activity_level"
        case daysPerWeek = "days_per_week"
        case minutesPerSession = "minutes_per_session"
        case equipmentContext = "equipment_context"
        case medicalHistory = "medical_history"
        case familyMedicalHistory = "family_medical_history"
        case currentInjuries = "current_injuries"
        case fitnessGoalsText = "fitness_goals_text"
        case trainingConstraints = "training_constraints"
        case sleepPattern = "sleep_pattern"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Computed Properties
    
    /// Calculate BMI from height and weight
    var calculatedBMI: Double? {
        guard let height = heightCm, let weight = weightKg, height > 0 else {
            return nil
        }
        let heightInMeters = height / 100.0
        return weight / (heightInMeters * heightInMeters)
    }
    
    /// User's age based on birth year
    var age: Int? {
        guard let year = birthYear else { return nil }
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - year
    }
    
    // MARK: - Factory
    
    /// Create a new profile for a user
    static func newProfile(for userId: UUID) -> UserProfile {
        UserProfile(
            id: userId,
            onboardingCompleted: false,
            onboardingStep: 0
        )
    }
}

// MARK: - Sex at Birth

enum SexAtBirth: String, Codable, CaseIterable {
    case male
    case female
    case other
    case preferNotToSay = "prefer_not_to_say"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

// MARK: - Fitness Goal

enum FitnessGoal: String, Codable, CaseIterable {
    case loseFat = "lose_fat"
    case buildMuscle = "build_muscle"
    case getFitter = "get_fitter"
    case improveHealth = "improve_health"
    case performance
    
    var displayName: String {
        switch self {
        case .loseFat: return "Lose Fat"
        case .buildMuscle: return "Build Muscle"
        case .getFitter: return "Get Fitter"
        case .improveHealth: return "Improve Health"
        case .performance: return "Performance"
        }
    }
    
    var icon: String {
        switch self {
        case .loseFat: return "flame.fill"
        case .buildMuscle: return "figure.strengthtraining.traditional"
        case .getFitter: return "figure.run"
        case .improveHealth: return "heart.fill"
        case .performance: return "trophy.fill"
        }
    }
}

// MARK: - Activity Level

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary
    case somewhatActive = "somewhat_active"
    case active
    case veryActive = "very_active"
    
    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .somewhatActive: return "Somewhat Active"
        case .active: return "Active"
        case .veryActive: return "Very Active"
        }
    }
    
    var description: String {
        switch self {
        case .sedentary: return "Little to no exercise"
        case .somewhatActive: return "Light exercise 1-3 days/week"
        case .active: return "Moderate exercise 3-5 days/week"
        case .veryActive: return "Hard exercise 6-7 days/week"
        }
    }
}

// MARK: - Equipment Context

enum EquipmentContext: String, Codable, CaseIterable {
    case gym
    case homeWithGear = "home_with_gear"
    case bodyweightOnly = "bodyweight_only"
    
    var displayName: String {
        switch self {
        case .gym: return "Gym"
        case .homeWithGear: return "Home with Equipment"
        case .bodyweightOnly: return "Bodyweight Only"
        }
    }
    
    var description: String {
        switch self {
        case .gym: return "Full gym access"
        case .homeWithGear: return "Dumbbells, bands, etc."
        case .bodyweightOnly: return "No equipment needed"
        }
    }
    
    var icon: String {
        switch self {
        case .gym: return "dumbbell.fill"
        case .homeWithGear: return "house.fill"
        case .bodyweightOnly: return "figure.stand"
        }
    }
}

// MARK: - Sleep Pattern

enum SleepPattern: String, Codable, CaseIterable {
    case lessThan5 = "less_than_5"
    case fiveToSix = "5_to_6"
    case sixToSeven = "6_to_7"
    case sevenToEight = "7_to_8"
    case moreThan8 = "more_than_8"
    
    var displayName: String {
        switch self {
        case .lessThan5: return "< 5 hours"
        case .fiveToSix: return "5-6 hours"
        case .sixToSeven: return "6-7 hours"
        case .sevenToEight: return "7-8 hours"
        case .moreThan8: return "8+ hours"
        }
    }
    
    var icon: String {
        switch self {
        case .lessThan5: return "moon.zzz"
        case .fiveToSix: return "moon"
        case .sixToSeven: return "moon.fill"
        case .sevenToEight: return "bed.double.fill"
        case .moreThan8: return "sparkles"
        }
    }
}
