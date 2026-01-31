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
    case healthConnect = 0
    case personalInfo = 1
    case preferences = 2
    case healthBackground = 3
    case goalsLifestyle = 4
    
    var title: String {
        switch self {
        case .healthConnect: return "Health"
        case .personalInfo: return "About You"
        case .preferences: return "Preferences"
        case .healthBackground: return "Background"
        case .goalsLifestyle: return "Goals"
        }
    }
    
    var subtitle: String {
        switch self {
        case .healthConnect: return "Connect Apple Health"
        case .personalInfo: return "Tell us about yourself"
        case .preferences: return "Your fitness journey"
        case .healthBackground: return "Health background"
        case .goalsLifestyle: return "Your goals & lifestyle"
        }
    }
    
    /// Steps to display in the progress indicator (excludes healthConnect)
    static var displaySteps: [OnboardingStep] {
        [.personalInfo, .preferences, .healthBackground, .goalsLifestyle]
    }
    
    static var totalSteps: Int { allCases.count }
}

// MARK: - Onboarding View Model

@MainActor
final class OnboardingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentStep: OnboardingStep = .healthConnect
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isComplete: Bool = false
    
    // HealthKit State
    @Published var healthKitConnected: Bool = false
    @Published var healthKitData: HealthKitUserData?
    @Published var prefilledFromHealthKit: Set<String> = []
    
    // Page 1: Personal Info
    @Published var birthYear: Int = 1990
    @Published var sexAtBirth: SexAtBirth?
    @Published var heightCm: Double = 170
    @Published var weightKg: Double = 70
    @Published var bodyFatOverride: Double? = nil // User override for body fat
    
    // Page 2: Preferences
    @Published var goal: FitnessGoal?
    @Published var activityLevel: ActivityLevel?
    @Published var daysPerWeek: Int = 3
    @Published var minutesPerSession: Int = 45
    @Published var equipmentContext: EquipmentContext?
    
    // Page 3: Health Background
    @Published var medicalHistory: String = ""
    @Published var familyMedicalHistory: String = ""
    @Published var currentInjuries: String = ""
    
    // Page 4: Goals & Lifestyle
    @Published var fitnessGoalsText: String = ""
    @Published var trainingConstraints: String = ""
    @Published var sleepPattern: SleepPattern?
    
    // MARK: - Dependencies
    
    private let profileService: UserProfileService
    let healthKitService: HealthKitServiceProtocol
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
    
    // Page 3 is optional - always allow proceeding
    var canProceedPage3: Bool {
        true
    }
    
    // Page 4 requires fitness goals (500 char limit)
    var canProceedPage4: Bool {
        !fitnessGoalsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        fitnessGoalsText.count <= 500
    }
    
    var fitnessGoalsRemaining: Int {
        500 - fitnessGoalsText.count
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
    
    /// Estimated body fat percentage based on BMI (rough estimation)
    /// Uses the Deurenberg formula: BF% = (1.20 × BMI) + (0.23 × Age) − (10.8 × Sex) − 5.4
    /// where Sex = 1 for males, 0 for females
    var estimatedBodyFat: Double {
        let bmi = calculatedBMI
        let age = Double(Calendar.current.component(.year, from: Date()) - birthYear)
        let sexFactor: Double = (sexAtBirth == .male) ? 1.0 : 0.0
        
        let bodyFat = (1.20 * bmi) + (0.23 * age) - (10.8 * sexFactor) - 5.4
        return max(5, min(50, bodyFat)) // Clamp between 5-50%
    }
    
    /// Returns override value if set, otherwise estimated value
    var bodyFatPercentage: Double {
        bodyFatOverride ?? estimatedBodyFat
    }
    
    /// Whether the body fat value is user-overridden
    var isBodyFatOverridden: Bool {
        bodyFatOverride != nil
    }
    
    // MARK: - Initialization
    
    init(profileService: UserProfileService, healthKitService: HealthKitServiceProtocol) {
        self.profileService = profileService
        self.healthKitService = healthKitService
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
        updatedProfile.bodyFatPercentage = bodyFatPercentage
        updatedProfile.goal = goal
        updatedProfile.activityLevel = activityLevel
        updatedProfile.daysPerWeek = daysPerWeek
        updatedProfile.minutesPerSession = minutesPerSession
        updatedProfile.equipmentContext = equipmentContext
        
        // Page 3: Health Background
        updatedProfile.medicalHistory = medicalHistory.isEmpty ? nil : medicalHistory
        updatedProfile.familyMedicalHistory = familyMedicalHistory.isEmpty ? nil : familyMedicalHistory
        updatedProfile.currentInjuries = currentInjuries.isEmpty ? nil : currentInjuries
        
        // Page 4: Goals & Lifestyle
        updatedProfile.fitnessGoalsText = fitnessGoalsText.isEmpty ? nil : fitnessGoalsText
        updatedProfile.trainingConstraints = trainingConstraints.isEmpty ? nil : trainingConstraints
        updatedProfile.sleepPattern = sleepPattern
        
        updatedProfile.onboardingStep = currentStep.rawValue
        
        logger.info("🔄 Calling profileService.updateProfile()...")
        logger.info("  Data: birthYear=\(self.birthYear), sex=\(self.sexAtBirth?.rawValue ?? "nil"), height=\(self.heightCm), weight=\(self.weightKg)")
        logger.info("  Data: goal=\(self.goal?.rawValue ?? "nil"), activity=\(self.activityLevel?.rawValue ?? "nil"), equipment=\(self.equipmentContext?.rawValue ?? "nil")")
        logger.info("  Data: fitnessGoals=\(self.fitnessGoalsText.prefix(50))..., sleep=\(self.sleepPattern?.rawValue ?? "nil")")
        
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
    
    func completeOnboarding() async {
        print("🔐 [ONBOARDING] completeOnboarding() called")
        logger.info("📍 completeOnboarding() called")
        isLoading = true
        
        // Save final data
        print("🔐 [ONBOARDING] Saving final data...")
        logger.info("🔄 Saving final data...")
        await saveProgress()
        print("🔐 [ONBOARDING] saveProgress() completed")
        
        // Mark onboarding complete in database
        do {
            print("🔐 [ONBOARDING] Calling profileService.completeOnboarding()...")
            logger.info("🔄 Marking onboarding as complete...")
            try await profileService.completeOnboarding()
            print("✅ [ONBOARDING] completeOnboarding() succeeded!")
            logger.info("✅ Onboarding completed!")
            isComplete = true
        } catch {
            print("❌ [ONBOARDING] completeOnboarding() FAILED: \(error)")
            print("❌ [ONBOARDING] Error type: \(type(of: error))")
            print("❌ [ONBOARDING] Error description: \(error.localizedDescription)")
            logger.error("❌ completeOnboarding failed: \(error.localizedDescription)")
            errorMessage = "Failed to complete onboarding: \(error.localizedDescription)"
        }
        
        isLoading = false
        print("🔐 [ONBOARDING] isLoading = false, isComplete = \(isComplete)")
    }
    
    // MARK: - HealthKit Integration
    
    /// Connect to HealthKit and fetch user characteristics
    /// - Returns: true if authorization was granted and data was fetched
    @discardableResult
    func connectHealthKit() async -> Bool {
        print("📍 [Onboarding] connectHealthKit() called")
        isLoading = true
        errorMessage = nil
        
        print("📍 [Onboarding] Checking HealthKit availability...")
        guard healthKitService.isAvailable else {
            print("⚠️ [Onboarding] HealthKit not available on this device")
            isLoading = false
            return false
        }
        print("✅ [Onboarding] HealthKit is available")
        
        do {
            // Request authorization
            print("📍 [Onboarding] Requesting HealthKit authorization...")
            let authorized = try await healthKitService.requestAuthorization()
            print("📍 [Onboarding] Authorization result: \(authorized)")
            
            guard authorized else {
                print("⚠️ [Onboarding] HealthKit authorization returned false")
                isLoading = false
                return false
            }
            
            healthKitConnected = true
            print("✅ [Onboarding] HealthKit connected!")
            
            // Fetch user characteristics
            print("📍 [Onboarding] Fetching user characteristics...")
            let data = try await healthKitService.fetchUserCharacteristics()
            healthKitData = data
            print("📍 [Onboarding] Data received - hasData: \(data.hasData)")
            
            // Prefill fields from HealthKit data
            print("📍 [Onboarding] Prefilling fields...")
            prefillFromHealthKit(data)
            
            print("✅ [Onboarding] HealthKit data fetched and prefilled successfully!")
            print("   - prefilledFromHealthKit: \(prefilledFromHealthKit)")
            isLoading = false
            return true
            
        } catch let error as NSError {
            print("❌ [Onboarding] HealthKit connection failed:")
            print("   - Domain: \(error.domain)")
            print("   - Code: \(error.code)")
            print("   - Description: \(error.localizedDescription)")
            print("   - UserInfo: \(error.userInfo)")
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    /// Prefill onboarding fields from HealthKit data
    private func prefillFromHealthKit(_ data: HealthKitUserData) {
        logger.info("📍 Prefilling from HealthKit data...")
        prefilledFromHealthKit.removeAll()
        
        // Biological Sex
        if let hkSex = data.biologicalSex, let sex = hkSex.asSexAtBirth {
            sexAtBirth = sex
            prefilledFromHealthKit.insert("sexAtBirth")
            logger.debug("  Prefilled sexAtBirth: \(sex.rawValue)")
        }
        
        // Birth Year
        if let year = data.birthYear {
            birthYear = year
            prefilledFromHealthKit.insert("birthYear")
            logger.debug("  Prefilled birthYear: \(year)")
        }
        
        // Height
        if let height = data.heightCm {
            heightCm = height
            prefilledFromHealthKit.insert("heightCm")
            logger.debug("  Prefilled heightCm: \(height)")
        }
        
        // Weight
        if let weight = data.weightKg {
            weightKg = weight
            prefilledFromHealthKit.insert("weightKg")
            logger.debug("  Prefilled weightKg: \(weight)")
        }
        
        logger.info("✅ Prefilled \(self.prefilledFromHealthKit.count) fields from HealthKit")
    }
    
    /// Check if a field was prefilled from HealthKit
    func isPrefilledFromHealthKit(_ field: String) -> Bool {
        prefilledFromHealthKit.contains(field)
    }
    
    /// Progress for display (excludes healthConnect step)
    var displayProgress: Double {
        guard currentStep != .healthConnect else { return 0 }
        let adjustedStep = currentStep.rawValue - 1 // Subtract 1 because healthConnect is step 0
        return Double(adjustedStep + 1) / Double(OnboardingStep.displaySteps.count)
    }
}
