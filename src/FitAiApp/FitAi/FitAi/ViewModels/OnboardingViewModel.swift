//
//  OnboardingViewModel.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation
import Combine

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
    }
    
    // MARK: - Load Profile
    
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let existingProfile = try await profileService.fetchProfile() {
                profile = existingProfile
                restoreFromProfile(existingProfile)
            } else {
                // Create new profile
                profile = try await profileService.createProfile()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Restore from Profile
    
    private func restoreFromProfile(_ profile: UserProfile) {
        // Set current step
        if let step = OnboardingStep(rawValue: profile.onboardingStep) {
            currentStep = step
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
    }
    
    // MARK: - Navigation
    
    func nextStep() async {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            // Final step - complete onboarding
            await completeOnboarding()
            return
        }
        
        // Save current step data
        await saveProgress()
        
        // Move to next step
        currentStep = nextStep
        
        // Update step in database
        do {
            try await profileService.updateOnboardingStep(nextStep.rawValue)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func previousStep() {
        guard let prevStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        currentStep = prevStep
    }
    
    // MARK: - Save Progress
    
    private func saveProgress() async {
        guard var updatedProfile = profile else { return }
        
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
        
        do {
            try await profileService.updateProfile(updatedProfile)
            profile = updatedProfile
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Complete Onboarding
    
    private func completeOnboarding() async {
        isLoading = true
        
        // Save final data
        await saveProgress()
        
        do {
            try await profileService.completeOnboarding()
            isComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
