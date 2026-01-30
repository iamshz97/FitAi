<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Act as a digital health systems architect, exercise science researcher, and AI decision-system analyst.

I am designing a fitness / health lifestyle planning application.
I already have a large library of persona instances and task prompts generated for different users
(e.g., sedentary adults, obese clients, older adults, PCOS, post-bariatric, time-constrained users, injury scenarios).

I want you to analyze these persona-task prompts NOT for their content quality,
but to reverse-engineer and explain the LOGIC used to generate tasks for each persona.

Your goal is to help me understand:

- WHY certain tasks are asked for a given persona
- HOW task categories change when parameters change
- HOW this logic could be formalized into rules or an AI decision engine

---

### INPUT CONTEXT (ASSUME THIS IS PROVIDED):

- Each persona includes:
    - Demographics (age, sex)
    - Body composition
    - Activity level
    - Medical history (PAR-Q+, diagnoses, medications)
    - Psychological \& behavioral factors
    - Constraints (time, equipment, environment)
- Each persona has multiple TASKS such as:
    - Risk stratification \& medical clearance
    - Exercise prescription changes
    - Nutrition strategy changes
    - Behavioral \& psychological interventions
    - Monitoring \& adaptation logic
    - App algorithm implications

---

### YOUR TASK:

### 1. TASK CATEGORIZATION FRAMEWORK

Create a clear taxonomy of task types used across personas.
For example (but not limited to):

- Safety \& Medical Tasks
- Physiological Optimization Tasks
- Constraint-Driven Adaptation Tasks
- Behavioral \& Adherence Tasks
- Progression \& Plateau Tasks
- App Algorithm / Automation Tasks

Explain:

- What each task category represents
- When it becomes mandatory vs optional

---

### 2. PARAMETER → TASK MAPPING

Explain how changes in specific parameters trigger new or modified tasks.

For each parameter below, explain:

- What new risks it introduces
- What task categories it activates
- Why those tasks are necessary

Parameters to analyze:

- Age increase (e.g., 38 → 62)
- Obesity class increase
- Presence of chronic disease (HTN, diabetes, PCOS)
- Medication use (Metformin, ACE inhibitors, SSRIs)
- Injury occurrence
- Low adherence / motivation drop
- Severe time constraints
- Post-surgical status (bariatric)

Provide a table:
Parameter Change → Activated Task Categories → Rationale

---

### 3. TASK INTENT ANALYSIS

For representative tasks (e.g., plateau management, injury handling, PCOS adaptation):

- Identify the underlying intent of the task
(e.g., risk mitigation, sustainability, physiology preservation)
- Explain why this intent is more important for this persona than others

---

### 4. DECISION-MAKING HIERARCHY

Explain the implicit hierarchy used when generating tasks:

- Safety vs Performance
- Medical constraints vs user goals
- Adherence vs optimal programming
- Short-term results vs long-term sustainability

Describe how conflicts are resolved
(e.g., obese client wants aggressive fat loss vs medical safety).

---

### 5. ABSTRACT THIS INTO A SYSTEM MODEL

Translate the observed task-generation logic into:

- Decision rules (if X → require Y)
- Guardrails (tasks that must always run first)
- Adaptive layers (tasks that appear only when conditions are met)

Example:

- If PAR-Q+ positive → medical clearance task mandatory
- If adherence <60% for 2 weeks → behavioral intervention task triggered

---

### 6. IMPLICATIONS FOR AN AI AGENT OR APP

Based on this analysis:

- Which tasks should be deterministic (rule-based)?
- Which tasks are suitable for AI reasoning?
- Which tasks should never be fully automated?

Explain how this task logic could power:

- Adaptive onboarding
- Ongoing plan adjustment
- Safety escalation workflows

---

### OUTPUT FORMAT:

- Sectioned, structured response
- Tables where appropriate
- Explicit reasoning (not just conclusions)
- Written for a system designer, not an end user

Based on my analysis of the persona-task prompt library, I'll reverse-engineer the underlying logic system that generates tasks for each persona. This is a systems-level analysis for application architecture.

***

# REVERSE-ENGINEERED TASK GENERATION LOGIC FOR FITNESS APPLICATION PERSONAS


***

## 1. TASK CATEGORIZATION FRAMEWORK

### 1.1 Core Task Taxonomy

The prompt library uses **six primary task categories**, activated conditionally based on persona risk profile:


| Task Category | Definition | Mandatory When | Optional When | Never Required When |
| :-- | :-- | :-- | :-- | :-- |
| **SAFETY \& MEDICAL TASKS** | Pre-participation screening, risk stratification, medical clearance, contraindication identification, symptom management | Any PAR-Q+ positive response, chronic disease present, medications present, age >50 with risk factors, BMI >35 | Healthy adults <40 with no risk factors planning moderate intensity | N/A - always some baseline safety assessment |
| **PHYSIOLOGICAL OPTIMIZATION TASKS** | Exercise prescription (FITT-VP), nutrition prescription (TDEE, macros), progressive overload strategy, periodization | All personas (universal) | N/A | N/A |
| **CONSTRAINT-DRIVEN ADAPTATION TASKS** | Time-efficient programming, equipment substitutions, home-based modifications, schedule flexibility | Time <3 days/week, no gym access, unpredictable schedule, equipment limitations | Standard availability (3-5 days/week, gym access) | N/A |
| **BEHAVIORAL \& ADHERENCE TASKS** | Habit formation, motivation assessment, cognitive restructuring, social support building, self-monitoring | Adherence <70%, past failure history, psychological barriers (anxiety, depression), weight cycling history | General fitness persona with intrinsic motivation | N/A |
| **PROGRESSION \& PLATEAU TASKS** | Plateau diagnosis, metabolic adaptation calculation, intervention hierarchy, goal revision, deload protocols | Weight plateau >3 weeks, performance stagnation >2 weeks, adherence decline >20% | Novice clients in first 12 weeks (no plateau expected) | First 4-6 weeks of program |
| **APP ALGORITHM / AUTOMATION TASKS** | Data triggers, decision trees, automated interventions, user interface implications, safety locks | All personas (for algorithm design purposes) | N/A | N/A |

### 1.2 Task Category Intent Mapping

Each task category addresses a specific failure mode:

- **Safety/Medical** → Prevents **adverse events** (injury, cardiovascular incidents, medication interactions)
- **Physiological** → Ensures **biological efficacy** (stimulus sufficient to drive adaptation)
- **Constraint-Driven** → Prevents **program abandonment** (unrealistic demands)
- **Behavioral** → Prevents **adherence failure** (psychological barriers, motivation decay)
- **Progression/Plateau** → Prevents **adaptation failure** (metabolic adaptation, overtraining)
- **App Algorithm** → Enables **system scalability** (translate expert reasoning into code)

***

## 2. PARAMETER → TASK MAPPING

### 2.1 Universal Parameter-Task Trigger Matrix

| Parameter Change | Activated Task Categories | Rationale | Example Tasks Generated |
| :-- | :-- | :-- | :-- |
| **Age: +20 years** (38 → 62) | Safety (+), Physiological (modify), Behavioral (modify) | ↑ CVD risk, ↓ recovery capacity, ↑ fall risk, ↑ joint disease prevalence | Balance testing (TUG, single-leg stance), modified PAR-Q+, lower intensity progression, longer recovery periods, joint-friendly exercise selection |
| **BMI: +10 points** (26 → 36) | Safety (++), Physiological (modify heavily), Behavioral (+), Medical Coordination (+) | ↑ metabolic disease risk, ↑ joint loading, ↑ exercise anxiety, requires physician clearance | ACSM risk stratification (High Risk), medical clearance mandatory, low-impact exercise selection, metabolic syndrome screening, gym anxiety intervention |
| **Chronic Disease: Added** (HTN, diabetes, PCOS) | Safety (++), Medical Coordination (++), Physiological (modify), Monitoring (+) | Contraindications, medication interactions, disease-specific exercise responses, requires supervision | Medication interaction analysis (Metformin + exercise = hypoglycemia risk), BP monitoring protocol, symptom education (shakiness, dizziness), physician communication workflow |
| **Medications: Added** (Metformin, Lisinopril, SSRIs) | Safety (+), Physiological (modify), Monitoring (+) | Drug-exercise interactions, HR/BP response altered, hypoglycemia/hypotension risk | RPE-based intensity (not HR zones if on beta-blockers/ACE inhibitors), glucose monitoring if on Metformin, hydration protocol, symptom recognition training |
| **Injury: Acute** | Safety (++), Physiological (modify), Psychological (+), Scope-of-Practice (+) | Pain management, rehab progression, detraining anxiety, PT referral criteria | ROM limitation protocol, pain scale monitoring (keep ≤3/10), exercise substitutions (knee-friendly alternatives), return-to-training criteria, PT referral decision tree |
| **Adherence: Drop >30%** | Behavioral (++), Constraint-Driven (+), Physiological (modify) | Motivation decay, barriers emerged, program mismatch | Motivational Interviewing script, barrier diagnosis (environmental/psychological/social), program simplification (reduce frequency/duration), habit-stacking strategies, cognitive distortion identification (all-or-nothing thinking) |
| **Time: <3 days/week** | Constraint-Driven (++), Physiological (modify) | Insufficient training volume, requires intensity/efficiency compensation | HIIT protocols, full-body training (not splits), compound movements prioritized, supersets/circuits, home-based options, minimal equipment solutions |
| **Plateau: >3 weeks** | Progression/Plateau (++), Physiological (modify), Behavioral (+) | Metabolic adaptation, program staleness, motivation decline | TDEE recalculation (account for weight loss), intervention hierarchy (diet break vs calorie reduction vs cardio increase), training stimulus variation (volume/intensity/frequency manipulation) |
| **Post-Surgical: Bariatric** | Physiological (modify heavily), Medical Coordination (++), Monitoring (++), Behavioral (+) | Protein malabsorption, rapid muscle loss risk, nutritional deficiencies, regain prevention | Protein prioritization (0.7-1.0 g/kg current weight despite low appetite), resistance training mandatory (muscle preservation), micronutrient monitoring (B12, iron, D, calcium), loose skin counseling, regain prevention strategies |

### 2.2 Risk Escalation Thresholds

The system uses **additive risk scoring** to determine task activation intensity:

**Low Risk (0-1 risk factors):**

- Basic safety screening (PAR-Q)
- Standard physiological programming
- Minimal medical coordination

**Moderate Risk (2-3 risk factors):**

- Enhanced safety screening
- Medical clearance recommended
- Modified intensity progression
- Regular monitoring checkpoints

**High Risk (4+ risk factors OR diagnosed disease):**

- Medical clearance mandatory
- Symptom-based exercise termination protocols
- Medication interaction analysis
- Physician coordination workflow
- Exercise under supervision recommended

**Risk Factor Examples:**

- Age (M ≥45, F ≥55)
- Family history CVD (1st degree relative, M <55, F <65)
- Hypertension or medication
- Dyslipidemia
- Pre-diabetes or diabetes
- Obesity (BMI ≥30)
- Sedentary lifestyle
- Current smoker

***

## 3. TASK INTENT ANALYSIS

### 3.1 Intent Hierarchy by Representative Tasks

#### **Plateau Management Task**

**Underlying Intent:**

- **Primary:** Sustain physiological adaptation (prevent metabolic compensation from halting fat loss)
- **Secondary:** Preserve adherence (prevent frustration-driven dropout)
- **Tertiary:** Educate client (understand normal adaptation, not "broken metabolism")

**Why More Important for Certain Personas:**

- **Obese:** Higher metabolic adaptation magnitude (hormonal resistance), psychological fragility (past failure experiences)
- **Sedentary:** Novice expectations unrealistic (expect linear progress), higher dropout risk
- **NOT for Athletic Performance:** Plateaus managed via periodization (built into program), athlete sophistication higher

**Task Components:**

1. Metabolic adaptation quantification (calculate expected TDEE reduction)
2. Intervention prioritization (evidence hierarchy: diet break > cardio addition > further calorie reduction)
3. Goal revision (shift to maintenance/recomp if pushing too hard)
4. Psychological reframing (plateau ≠ failure)

***

#### **Injury Handling Task**

**Underlying Intent:**

- **Primary:** Define scope of practice (fitness professional vs physical therapist boundary)
- **Secondary:** Prevent detraining (maintain training stimulus where safe)
- **Tertiary:** Prevent re-injury (conservative progression)

**Why More Important for Certain Personas:**

- **Older Adults:** Higher injury risk (balance, bone density), slower healing
- **Obese:** Joint loading issues, pre-existing OA common
- **NOT for Bodybuilding (as critical):** Advanced lifters understand injury management, have experience

**Task Components:**

1. Red flag symptom identification (when to refer to MD/PT)
2. Modified training prescription (exercise substitutions, ROM limits, load reductions)
3. Pain monitoring protocol (0-10 scale, acceptable threshold ≤3/10)
4. Return-to-training criteria (pain-free ROM, strength milestones)
5. Coordination with medical team (communication templates)

***

#### **PCOS Adaptation Task**

**Underlying Intent:**

- **Primary:** Hormonal optimization (improve insulin sensitivity, reduce androgens)
- **Secondary:** Fertility preservation (5-10% weight loss restores ovulation)
- **Tertiary:** Psychological support (body image with hirsutism/acne)

**Why More Important for This Persona:**

- **PCOS-Specific:** Insulin resistance requires different macronutrient distribution (lower carb, higher protein)
- **NOT for General Fitness:** Hormonal optimization not primary goal
- **NOT for Male Personas:** Reproductive health considerations irrelevant

**Task Components:**

1. PCOS-specific exercise prescription (resistance training prioritized for insulin sensitivity)
2. Insulin-resistant nutrition (lower glycemic index, carb timing, meal frequency)
3. Supplement evidence (inositol, vitamin D, omega-3)
4. Fertility timeline expectations (realistic counseling)
5. Psychological support for PCOS-specific body image issues

***

### 3.2 Intent Conflict Resolution Examples

**Conflict: Aggressive Fat Loss vs Muscle Preservation (Body Recomp Persona)**

**Resolution Logic:**

1. Prioritize muscle preservation (long-term metabolic benefit)
2. Accept slower fat loss (0.5% body weight/week max)
3. High protein (2.0-2.4 g/kg)
4. Adequate training volume (12-20 sets/muscle/week)
5. Slight deficit or maintenance calories

**Conflict: Medical Safety vs User Goals (Obese with Aggressive Timeline)**

**Resolution Logic:**

1. Medical safety overrides user preference (non-negotiable)
2. Educate on risks (gallstones, muscle loss, nutritional deficiencies if >1.5 kg/week sustained)
3. Redirect to sustainable rate (0.5-1% body weight/week)
4. Reframe timeline (12 months vs 6 months still achieves health improvements)

**Conflict: Time Constraints vs Optimal Programming (Single Parent, 2×30 min/week)**

**Resolution Logic:**

1. Adherence > Optimal (2×30 min done > 3×45 min planned but not done)
2. Accept reduced results (0.25 kg/week fat loss vs 0.5 kg/week)
3. Maximize efficiency (full-body, compound movements, supersets)
4. Add NEAT strategies (doesn't require scheduled time)

***

## 4. DECISION-MAKING HIERARCHY

### 4.1 Master Priority Framework

The system uses this **invariant hierarchy** when generating tasks:

```
TIER 0: SAFETY (Overrides all others)
    ↓
TIER 1: MEDICAL CONSTRAINTS (Non-negotiable guardrails)
    ↓
TIER 2: ADHERENCE SUSTAINABILITY (Realistic > Optimal)
    ↓
TIER 3: PHYSIOLOGICAL OPTIMIZATION (Evidence-based best practices)
    ↓
TIER 4: USER PREFERENCES (Within safe/effective bounds)
    ↓
TIER 5: PERFORMANCE GOALS (Lowest priority for general population)
```


### 4.2 Hierarchy Application in Task Generation

**Example 1: Obese Client Wants Aggressive Fat Loss (2 kg/week)**

**Tier 0 (Safety):**

- Rate >1.5 kg/week sustained = risk of gallstones, nutritional deficiencies, excessive muscle loss
- **Action:** Flag as unsafe, proceed to Tier 1

**Tier 1 (Medical Constraints):**

- Client has metabolic syndrome → rapid weight loss may destabilize BP/glucose medications
- **Action:** Require medical monitoring, cap rate at 1 kg/week

**Tier 2 (Adherence):**

- Aggressive deficit (>1000 kcal) = high hunger, poor adherence historically (weight cycling)
- **Action:** Moderate deficit (500-750 kcal) more sustainable

**Tier 3 (Physiological):**

- 0.5-1 kg/week preserves muscle, allows training intensity

**Tier 4 (User Preference):**

- Client wants faster → educate on why slower is better, redirect

**Output:** Prescribe 0.75 kg/week target (balances medical safety + adherence + physiology), reject 2 kg/week goal

***

**Example 2: Time-Constrained Client Can Only Do 2 Days/Week**

**Tier 0 (Safety):**

- 2 days/week is safe (no injury risk)

**Tier 1 (Medical):**

- No medical constraints violated

**Tier 2 (Adherence):**

- 2 days sustainable > 4 days planned but not done
- **Action:** Accept constraint, proceed to optimize

**Tier 3 (Physiological):**

- 2 days suboptimal for volume → compensate with intensity/efficiency
- **Action:** Full-body, compound movements, HIIT if tolerated

**Tier 4 (User Preference):**

- Client prefers home training → design home-based program

**Output:** 2×30 min full-body resistance + HIIT, home-based, compound movements

***

### 4.3 Conflict Resolution Decision Trees

**Conflict Type A: Medical Safety vs Performance Goals**

```
IF (PAR-Q+ positive OR diagnosed disease OR medications present)
    THEN medical_clearance_required = TRUE
    IF user_refuses_clearance
        THEN lock_program = TRUE  // Safety override
        RETURN "Medical clearance mandatory per ACSM guidelines"
    ELSE
        THEN proceed_with_clearance = TRUE
        APPLY medication_interaction_modifications()
        APPLY intensity_cap() // Conservative progression
END IF
```

**Conflict Type B: Adherence vs Optimal Programming**

```
IF (time_available < 3_days_per_week OR equipment = "none" OR schedule = "unpredictable")
    THEN prioritize_adherence = TRUE
    CALCULATE minimal_effective_dose() // What's minimum to see results?
    IF minimal_effective_dose > available_capacity
        THEN set_realistic_expectations() // "2×30min will produce slower results"
        ELSE proceed_with_modified_program()
END IF
```

**Conflict Type C: User Goals vs Evidence-Based Timelines**

```
IF (user_goal_timeline < evidence_based_minimum)
    THEN education_required = TRUE
    EXPLAIN risks(aggressive_approach)
    PRESENT alternatives(sustainable_timeline)
    IF user_still_insists
        THEN assess_risk_tolerance() // Can we compromise?
        IF compromise_safe
            THEN proceed_with_monitoring++
            ELSE refuse_program // "I cannot support this safely"
END IF
```


***

## 5. ABSTRACT SYSTEM MODEL

### 5.1 Task Generation Engine Architecture

```python
class PersonaTaskGenerator:
    def generate_tasks(self, persona):
        tasks = []
        
        # LAYER 1: Mandatory Guardrails (Always Run First)
        tasks.append(self.safety_screening(persona))
        
        if self.requires_medical_clearance(persona):
            tasks.append(self.medical_clearance_workflow(persona))
        
        # LAYER 2: Risk-Stratified Tasks (Conditional)
        risk_level = self.calculate_risk_score(persona)
        
        if risk_level >= MODERATE:
            tasks.append(self.medication_interaction_analysis(persona))
            tasks.append(self.monitoring_protocol(persona))
        
        if risk_level >= HIGH:
            tasks.append(self.physician_coordination_workflow(persona))
            tasks.append(self.exercise_supervision_recommendation(persona))
        
        # LAYER 3: Core Programming (Universal)
        tasks.append(self.exercise_prescription(persona))
        tasks.append(self.nutrition_prescription(persona))
        
        # LAYER 4: Constraint-Driven Adaptations (Conditional)
        if persona.time_availability < 3_days:
            tasks.append(self.time_efficient_programming(persona))
        
        if persona.equipment == "minimal":
            tasks.append(self.equipment_substitutions(persona))
        
        # LAYER 5: Behavioral Interventions (Triggered)
        if persona.adherence_history < 0.7:
            tasks.append(self.adherence_enhancement(persona))
        
        if persona.weight_cycling_history:
            tasks.append(self.psychological_support(persona))
        
        # LAYER 6: Monitoring & Adaptation (Ongoing)
        tasks.append(self.plateau_detection_logic(persona))
        tasks.append(self.injury_management_protocol(persona))
        
        # LAYER 7: App Algorithm Integration (Meta)
        tasks.append(self.automation_decision_tree(persona))
        
        return tasks
```


### 5.2 Decision Rules (If-Then Logic)

**SAFETY GUARDRAILS (Deterministic):**

```
IF (chest_pain OR palpitations OR syncope during exercise):
    STOP exercise immediately
    CALL emergency services if symptoms persist >5 min
    LOCK program until physician clearance

IF (PAR-Q+ positive):
    REQUIRE medical clearance before moderate-vigorous exercise

IF (BMI >35 AND sedentary AND planning vigorous exercise):
    REQUIRE physician clearance (ACSM High Risk)

IF (takes medication for CVD/metabolic/renal disease):
    ANALYZE drug-exercise interactions
    MODIFY intensity prescription (RPE vs HR zones)
```

**ADAPTIVE LAYERS (Triggered by Conditions):**

```
IF (weight unchanged for 3 consecutive weeks AND adherence >80%):
    TRIGGER plateau_intervention_workflow()
    OPTIONS:
        - Diet break (2 weeks maintenance)
        - Increase cardio (add 60-90 min/week)
        - Reduce calories (by 100-200 kcal/day)
    PRESENT prioritized options based on context

IF (adherence <60% for 2 consecutive weeks):
    TRIGGER adherence_recovery_protocol()
    DIAGNOSE barriers (environmental, psychological, program)
    SIMPLIFY program (reduce frequency, duration, or complexity)
    INCREASE check-in frequency

IF (exercise_related_injury):
    ASSESS severity (pain scale, ROM, function)
    IF (red_flags present): // severe pain, swelling, instability
        REFER to MD/PT immediately
        LOCK affected exercises
    ELSE:
        MODIFY program (exercise substitutions, load reduction)
        MONITOR pain (keep ≤3/10 during exercise)
        PROVIDE return-to-training criteria
```


***

## 6. IMPLICATIONS FOR AI AGENT OR APP

### 6.1 Task Automation Suitability Matrix

| Task Type | Deterministic (Rule-Based) | AI Reasoning Suitable | Never Fully Automate | Implementation Notes |
| :-- | :-- | :-- | :-- | :-- |
| **PAR-Q+ Screening** | ✓ | ✗ | ✗ | Simple conditional logic: IF answer = "Yes" THEN flag for clearance |
| **ACSM Risk Stratification** | ✓ | ✗ | ✗ | Count risk factors, apply algorithm (Low/Mod/High risk) |
| **Medical Clearance Letter Generation** | ✓ | Partial (template population) | MD signature required | Auto-populate demographics, proposed program, but MD must review |
| **Exercise Prescription (Initial)** | ✓ | ✗ | ✗ | FITT-VP parameters based on persona: IF sedentary THEN 2-3 days, light-moderate, 20-30 min |
| **Nutrition Prescription (Initial)** | ✓ | ✗ | ✗ | TDEE calculation (Mifflin-St Jeor), deficit/surplus based on goal |
| **Plateau Diagnosis** | ✓ | ✗ | ✗ | Weight trend analysis: IF weight Δ <0.5 kg over 3 weeks AND adherence >80% THEN plateau |
| **Plateau Intervention Selection** | ✗ | ✓ (Reasoning) | Partial (expert review for edge cases) | AI can prioritize interventions based on context (stress level, sleep, adherence), but complex cases need human |
| **Injury Assessment (Red Flags)** | ✓ | ✗ | ✓ (Liability) | Red flag checklist (severe pain, instability, neurological symptoms) → auto-refer to MD/PT, but human must confirm |
| **Exercise Modification Post-Injury** | ✗ | ✓ (Reasoning) | Partial (PT consultation for complex) | AI can suggest alternatives (swap squats for leg press), but PT needed for complex cases |
| **Adherence Barrier Diagnosis** | ✗ | ✓ (Reasoning) | ✗ | AI analyzes user feedback (text analysis: "too tired", "no time") → categorize barrier type |
| **Motivational Interviewing** | ✗ | ✓ (LLM) | Partial (human coach for crisis) | LLM can conduct conversational coaching, but escalate to human for severe motivation loss |
| **Medication Interaction Warnings** | ✓ | ✗ | ✓ (Liability) | Database lookup: IF Metformin THEN warn about hypoglycemia + educate, but pharmacist/MD must review |
| **Program Progression Decision** | ✗ | ✓ (Reasoning) | Partial (human oversight) | AI can analyze performance trends, suggest weight increases, but human reviews major changes |

### 6.2 Adaptive System Workflows

#### **A. Adaptive Onboarding**

```
USER REGISTRATION
    ↓
PAR-Q+ SCREENING (Automated)
    ↓
IF (PAR-Q+ positive):
    → MEDICAL CLEARANCE WORKFLOW
       - Generate clearance letter template
       - Lock program until clearance uploaded
       - Verify clearance document (manual or AI OCR)
    ↓
RISK STRATIFICATION (Automated)
    - Count CVD risk factors
    - Classify: Low / Moderate / High
    ↓
IF (Moderate/High Risk):
    → ENHANCED MONITORING
       - Require BP/glucose logs (if applicable)
       - Set symptom-based stop thresholds
       - Schedule early check-in (Week 2 vs Week 4)
    ↓
CONSTRAINT ASSESSMENT (Automated)
    - Time availability
    - Equipment access
    - Psychological barriers
    ↓
INITIAL PROGRAM GENERATION (Automated + AI)
    - Base template from persona match
    - Modify for constraints (time, equipment)
    - Adjust for risk level (intensity cap)
    - Personalize for preferences (exercise type)
    ↓
USER REVIEW & COMMITMENT
    - Present program
    - Set expectations (realistic outcomes)
    - Obtain informed consent
```


#### **B. Ongoing Plan Adjustment**

```
WEEKLY DATA COLLECTION
    - Body weight
    - Adherence (workouts completed)
    - Subjective feedback (energy, mood, pain)
    - Performance (weights lifted, reps achieved)
    ↓
AUTOMATED ANALYSIS
    ↓
IF (weight plateau detected): // <0.5 kg change over 3 weeks
    → PLATEAU INTERVENTION WORKFLOW
       - AI reasons through context (stress, sleep, adherence)
       - Prioritizes interventions (diet break vs cardio vs calorie reduction)
       - Presents options to user with rationale
       - User selects, program adjusts
    ↓
IF (adherence drop detected): // <70% completion for 2 weeks
    → ADHERENCE RECOVERY WORKFLOW
       - AI analyzes logged barriers (text, check-ins)
       - Categorizes barriers (time, motivation, program difficulty)
       - Suggests modifications (reduce frequency, simplify)
       - Increases check-in frequency, motivational messaging
    ↓
IF (performance stagnation): // No weight increases for 3 weeks
    → PROGRESSION ADJUSTMENT
       - AI suggests deload week OR volume increase
       - Explains rationale
       - Adjusts program
    ↓
IF (injury reported):
    → INJURY MANAGEMENT WORKFLOW
       - Red flag screening (automated checklist)
       - IF red flags: Lock program, refer to MD/PT
       - ELSE: AI suggests exercise modifications
       - Monitor pain scale, ROM
       - Provide return-to-training criteria
```


#### **C. Safety Escalation Workflows**

```
DURING-EXERCISE SYMPTOM MONITORING
    ↓
USER REPORTS SYMPTOM (chest pain, dizziness, severe SOB)
    ↓
AUTOMATED RED FLAG ASSESSMENT
    ↓
IF (red flag symptom):
    → IMMEDIATE STOP PROTOCOL
       - Display: "STOP EXERCISE IMMEDIATELY"
       - Prompt: "Are symptoms resolving within 5 minutes?"
       - IF NO: "Call emergency services (911)"
       - IF YES: "Rest, seek medical evaluation within 24 hours"
       - LOCK program until clearance uploaded
       - NOTIFY human coach (if app has support team)
    ↓
DOCUMENT INCIDENT
    - Timestamp, symptom type, duration, context
    - Store for physician review
    ↓
GENERATE PHYSICIAN REFERRAL LETTER
    - Auto-populate symptom details
    - Request specific clearance (return-to-exercise protocol)
    ↓
USER UPLOADS CLEARANCE
    - AI/human verifies document
    - IF cleared: Unlock program with modifications
    - IF restrictions noted: Apply restrictions to program
```


### 6.3 Human-in-the-Loop Requirements

**NEVER FULLY AUTOMATE (Liability + Complexity):**

1. **Medical diagnosis** (e.g., "Is this chest pain cardiac or musculoskeletal?") → Refer to MD
2. **Injury diagnosis** (e.g., "Is this meniscus tear or just soreness?") → Refer to PT/MD
3. **Medication adjustment recommendations** (e.g., "Reduce Metformin dose") → Physician only
4. **Crisis intervention** (e.g., severe depression, disordered eating) → Refer to mental health professional
5. **Legal/liability decisions** (e.g., "Train client despite risk?") → Human coach decision

**AI-ASSISTED WITH HUMAN OVERSIGHT:**

1. **Plateau intervention selection** → AI suggests, human reviews (especially for complex cases)
2. **Program progression** → AI suggests load increases, human verifies form is adequate
3. **Adherence barrier diagnosis** → AI analyzes text, human coaches conversation
4. **Exercise modifications post-injury** → AI suggests alternatives, PT reviews for complex cases

**FULLY AUTOMATED (Safe + Effective):**

1. **PAR-Q+ screening** → Simple conditional logic
2. **Risk stratification** → Count factors, apply ACSM algorithm
3. **Initial program generation** → Template-based with parameter substitutions
4. **TDEE/macro calculations** → Mathematical formulas
5. **Plateau detection** → Weight trend analysis (statistical)
6. **Workout logging \& tracking** → Data collection and visualization

***

## 7. KEY INSIGHTS FOR SYSTEM DESIGN

### 7.1 The "Safety-First" Architecture

Every task generation workflow MUST pass through safety filters before proceeding to optimization:

```
USER INPUT
    ↓
[SAFETY FILTER] ← ALWAYS FIRST
    ↓
[MEDICAL FILTER] ← IF safety flags triggered
    ↓
[ADHERENCE FILTER] ← Realistic > Optimal
    ↓
[OPTIMIZATION LAYER] ← Evidence-based best practices
    ↓
[PERSONALIZATION LAYER] ← User preferences
    ↓
OUTPUT (Program)
```


### 7.2 The "Additive Risk" Model

Tasks are activated based on **cumulative risk score**, not single parameters:

- 0-1 risk factors → Minimal tasks (basic programming)
- 2-3 risk factors → Moderate tasks (medical clearance recommended, monitoring)
- 4+ risk factors OR diagnosed disease → High tasks (clearance mandatory, supervision, medication analysis)


### 7.3 The "Intervention Hierarchy" Pattern

When problems arise (plateau, injury, adherence drop), the system uses **prioritized intervention cascades**:

**Example: Plateau Intervention Hierarchy**

1. **First:** Lifestyle factors (improve sleep, reduce stress)
2. **Second:** Diet break (restore metabolic rate)
3. **Third:** Increase activity (NEAT, cardio)
4. **Fourth:** Reduce calories (only if others ineffective)
5. **Last:** Revise goals (shift to maintenance/recomp)

This prevents aggressive interventions when conservative ones suffice.

### 7.4 The "Context-Aware Reasoning" Requirement

Simple rule-based systems fail for:

- Plateau interventions (requires context: stress, sleep, adherence, training history)
- Adherence barriers (requires NLP: analyze user feedback)
- Exercise modifications (requires biomechanics reasoning: "Why does this hurt? What alternative preserves stimulus?")

**Solution:** Hybrid architecture

- **Rules** for safety/medical (deterministic, no room for error)
- **AI reasoning** for optimization/behavioral (contextual, nuanced)

***

## FINAL SUMMARY: Task Generation Logic Formula

```
TASKS = f(PERSONA_PARAMETERS, RISK_SCORE, CONSTRAINTS, GOALS, CONTEXT)

WHERE:
    PERSONA_PARAMETERS = {age, sex, BMI, body_fat, activity_level, medical_history, medications}
    RISK_SCORE = count(CVD_risk_factors) + disease_severity_multiplier
    CONSTRAINTS = {time, equipment, environment, psychological_barriers}
    GOALS = {weight_change, performance, health_markers}
    CONTEXT = {adherence_history, progress_trend, current_stress, sleep_quality}

TASKS ACTIVATED:
    1. Safety & Medical (if RISK_SCORE >= threshold)
    2. Physiological Optimization (always)
    3. Constraint Adaptations (if CONSTRAINTS present)
    4. Behavioral Interventions (if adherence_risk OR psychological_barriers)
    5. Progression & Plateau (if triggered by CONTEXT)
    6. App Algorithm (always, for meta-design)
```

This logic can be translated into:

- Decision trees (for deterministic tasks)
- LLM prompts (for reasoning tasks)
- Database queries (for medical interaction lookups)
- Statistical models (for plateau detection, outcome prediction)

The key insight: **The system doesn't just generate tasks — it dynamically prioritizes them based on a safety-first, context-aware, evidence-constrained hierarchy.**
<span style="display:none">[^1]</span>

<div align="center">⁂</div>

[^1]: persona-prompts.md

