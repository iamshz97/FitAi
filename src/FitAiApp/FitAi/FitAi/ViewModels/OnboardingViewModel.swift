//
//  OnboardingViewModel.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation
import Combine
import os.log

// MARK: - Logger

private let logger = Logger(subsystem: "com.fitai.app", category: "OnboardingViewModel")

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case personalInfo = 0
    case preferences = 1
    
    var title: String {
        switch self {
        case .personalInfo: return "About You"
        case .preferences: return "Your Goals"
        }
    }
    
    static var totalSteps: Int { allCases.count }
}

// MARK: - Onboarding View Model

@MainActor
final class OnboardingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentStep: OnboardingStep = .personalInfo
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isComplete: Bool = false
    
    // Page 1: Personal Info
    @Published var birthYear: Int = 1990
    @Published var sexAtBirth: SexAtBirth?
    @Published var heightCm: Double = 170
    @Published var weightKg: Double = 70
    
    // Page 2: Preferences
    @Published var goal: FitnessGoal?
    @Published var activityLevel: ActivityLevel?
    @Published var daysPerWeek: Int = 3
    @Published var minutesPerSession: Int = 45
    @Published var equipmentContext: EquipmentContext?
    
    // MARK: - Dependencies
    
    private let profileService: UserProfileService
    private var profile: UserProfile?
    
    // MARK: - Computed Properties
    
    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.totalSteps)
    }
    
    var canProceedPage1: Bool {
        sexAtBirth != nil
    }
    
    var canProceedPage2: Bool {
        goal != nil && activityLevel != nil && equipmentContext != nil
    }
    
    var calculatedBMI: Double {
        let heightInMeters = heightCm / 100.0
        return weightKg / (heightInMeters * heightInMeters)
    }
    
    var bmiCategory: String {
        let bmi = calculatedBMI
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
    
    // MARK: - Initialization
    
    init(profileService: UserProfileService) {
        self.profileService = profileService
        logger.info("🟢 OnboardingViewModel initialized")
    }
    
    // MARK: - Load Profile
    
    func loadProfile() async {
        logger.info("📍 loadProfile() called")
        isLoading = true
        errorMessage = nil
        
        do {
            logger.info("🔄 Fetching existing profile...")
            if let existingProfile = try await profileService.fetchProfile() {
                logger.info("✅ Found existing profile - step: \(existingProfile.onboardingStep)")
                profile = existingProfile
                restoreFromProfile(existingProfile)
            } else {
                logger.info("ℹ️ No profile found - creating new one...")
                profile = try await profileService.createProfile()
                logger.info("✅ New profile created")
            }
        } catch {
            logger.error("❌ loadProfile failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Restore from Profile
    
    private func restoreFromProfile(_ profile: UserProfile) {
        logger.info("📍 Restoring UI state from profile...")
        
        // Set current step
        if let step = OnboardingStep(rawValue: profile.onboardingStep) {
            currentStep = step
            logger.info("  Restored step: \(step.rawValue)")
        }
        
        // Page 1
        if let year = profile.birthYear {
            birthYear = year
        }
        sexAtBirth = profile.sexAtBirth
        if let height = profile.heightCm {
            heightCm = height
        }
        if let weight = profile.weightKg {
            weightKg = weight
        }
        
        // Page 2
        goal = profile.goal
        activityLevel = profile.activityLevel
        if let days = profile.daysPerWeek {
            daysPerWeek = days
        }
        if let minutes = profile.minutesPerSession {
            minutesPerSession = minutes
        }
        equipmentContext = profile.equipmentContext
        
        logger.info("✅ UI state restored")
    }
    
    // MARK: - Navigation
    
    func nextStep() async {
        logger.info("📍 nextStep() called - current step: \(self.currentStep.rawValue)")
        
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            logger.info("ℹ️ No next step - completing onboarding")
            await completeOnboarding()
            return
        }
        
        // Save current step data
        logger.info("🔄 Saving progress before moving to step \(nextStep.rawValue)...")
        await saveProgress()
        
        // Move to next step
        currentStep = nextStep
        logger.info("➡️ Moved to step: \(nextStep.rawValue)")
        
        // Update step in database
        do {
            try await profileService.updateOnboardingStep(nextStep.rawValue)
        } catch {
            logger.error("❌ Failed to update step in DB: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func previousStep() {
        guard let prevStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        currentStep = prevStep
        logger.info("⬅️ Moved back to step: \(prevStep.rawValue)")
    }
    
    // MARK: - Save Progress
    
    private func saveProgress() async {
        logger.info("📍 saveProgress() called")
        
        // Defensive: if profile is nil, try to load/create it
        if profile == nil {
            logger.warning("⚠️ Profile is nil - attempting to load/create...")
            do {
                if let existingProfile = try await profileService.fetchProfile() {
                    profile = existingProfile
                    logger.info("✅ Loaded existing profile")
                } else {
                    profile = try await profileService.createProfile()
                    logger.info("✅ Created new profile")
                }
            } catch {
                logger.error("❌ Failed to load/create profile: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                return
            }
        }
        
        guard var updatedProfile = profile else {
            logger.error("❌ Still no profile to update!")
            return
        }
        
        // Update with current values
        updatedProfile.birthYear = birthYear
        updatedProfile.sexAtBirth = sexAtBirth
        updatedProfile.heightCm = heightCm
        updatedProfile.weightKg = weightKg
        updatedProfile.bmi = calculatedBMI
        updatedProfile.goal = goal
        updatedProfile.activityLevel = activityLevel
        updatedProfile.daysPerWeek = daysPerWeek
        updatedProfile.minutesPerSession = minutesPerSession
        updatedProfile.equipmentContext = equipmentContext
        updatedProfile.onboardingStep = currentStep.rawValue
        
        logger.info("🔄 Calling profileService.updateProfile()...")
        logger.info("  Data: birthYear=\(self.birthYear), sex=\(self.sexAtBirth?.rawValue ?? "nil"), height=\(self.heightCm), weight=\(self.weightKg)")
        logger.info("  Data: goal=\(self.goal?.rawValue ?? "nil"), activity=\(self.activityLevel?.rawValue ?? "nil"), equipment=\(self.equipmentContext?.rawValue ?? "nil")")
        
        do {
            try await profileService.updateProfile(updatedProfile)
            profile = updatedProfile
            logger.info("✅ Profile saved successfully!")
        } catch {
            logger.error("❌ saveProgress failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Complete Onboarding
    
    private func completeOnboarding() async {
        logger.info("📍 completeOnboarding() called")
        isLoading = true
        
        // Save final data
        logger.info("🔄 Saving final data...")
        await saveProgress()
        
        do {
            logger.info("🔄 Marking onboarding as complete...")
            try await profileService.completeOnboarding()
            logger.info("✅ Onboarding completed!")
            isComplete = true
        } catch {
            logger.error("❌ completeOnboarding failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
