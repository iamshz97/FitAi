---
name: task-reasoning-framework
description: Use this skill to analyze user profiles and generate task-specific instructions based on risk stratification, parameter mapping, and decision hierarchy for fitness planning.
---

# Task Reasoning Framework

## Overview
This framework provides the logic system for generating personalized fitness tasks based on user parameters. Use this to analyze a user profile and determine what safety considerations, modifications, and specialized instructions should be applied.

## 1. TASK CATEGORIZATION FRAMEWORK

### Core Task Categories

| Category | Definition | Mandatory When | Optional When |
|----------|------------|----------------|---------------|
| **SAFETY & MEDICAL** | Pre-participation screening, risk stratification, contraindication identification | PAR-Q+ positive, chronic disease, medications, age >50 with risk factors, BMI >35 | Healthy adults <40 with no risk factors |
| **PHYSIOLOGICAL OPTIMIZATION** | Exercise prescription (FITT-VP), nutrition prescription (TDEE, macros), progressive overload | All personas (universal) | N/A |
| **CONSTRAINT-DRIVEN ADAPTATION** | Time-efficient programming, equipment substitutions, schedule flexibility | Time <3 days/week, no gym access, equipment limitations | Standard availability |
| **BEHAVIORAL & ADHERENCE** | Habit formation, motivation assessment, self-monitoring | Adherence <70%, past failure history, psychological barriers | Intrinsically motivated users |
| **PROGRESSION & PLATEAU** | Plateau diagnosis, metabolic adaptation, intervention hierarchy | Weight plateau >3 weeks, performance stagnation | Novice clients in first 12 weeks |

## 2. PARAMETER → TASK MAPPING

### Age-Based Triggers
| Age Range | Risk Considerations | Required Modifications |
|-----------|---------------------|----------------------|
| 13-39 | Low baseline risk | Standard programming |
| 40-49 | Moderate CVD risk (if other factors) | Consider cardiac screening if sedentary |
| 50-59 | Increased joint concerns, recovery needs | Lower intensity progression, longer rest periods |
| 60+ | High fall risk, bone density concerns | Balance training mandatory, joint-friendly exercises, supervision recommended |

### BMI-Based Triggers
| BMI Range | Classification | Required Modifications |
|-----------|---------------|----------------------|
| 18.5-24.9 | Normal | Standard programming |
| 25-29.9 | Overweight | Low-impact options available, joint protection |
| 30-34.9 | Obese Class I | Low-impact mandatory, medical clearance recommended, gym anxiety consideration |
| 35-39.9 | Obese Class II | Medical clearance required, supervised exercise recommended |
| 40+ | Obese Class III | Medical clearance mandatory, specialist referral |

### Injury/Condition Triggers
| Condition | Avoid | Replace With | Special Instructions |
|-----------|-------|--------------|---------------------|
| Lower back pain | Deadlifts, sit-ups, good mornings | Leg press, hip thrusts, dead bugs, planks | Keep spine neutral, no loaded flexion |
| Knee issues | Deep squats, leg extensions (heavy), jumping | Box squats, reverse lunges, leg press | Limit ROM to pain-free range |
| Shoulder injuries | Overhead press, wide-grip bench, behind-neck | Landmine press, neutral grip, front raises | Avoid impingement positions |
| PCOS | N/A | N/A | Prioritize resistance training for insulin sensitivity, lower glycemic meals |
| Hypertension | Breath holding, heavy isometrics | Moderate intensity, continuous breathing | Monitor BP, avoid Valsalva |
| Diabetes (Type 2) | N/A | N/A | Monitor glucose, carb timing around exercise, hypoglycemia awareness |

### Time Constraint Triggers
| Available Time | Programming Approach |
|----------------|---------------------|
| 5+ days/week | Split routines possible, optimal periodization |
| 3-4 days/week | Full-body or upper/lower splits, compound focus |
| 2 days/week | Full-body mandatory, HIIT for efficiency, compound movements only |
| <2 days/week | Minimal effective dose, NEAT strategies, realistic expectations |

### Goal-Based Modifications
| Goal | Calorie Strategy | Exercise Priority | Special Considerations |
|------|-----------------|-------------------|----------------------|
| Weight Loss | Deficit 500 kcal | Resistance + cardio | Preserve muscle, protein high (1.0-1.2g/lb) |
| Muscle Gain | Surplus 300-500 kcal | Resistance primary | Progressive overload, adequate recovery |
| Maintenance | TDEE | Balanced | Sustainability focus |
| Endurance | Slight surplus | Cardio primary | Carb timing, glycogen replenishment |

## 3. DECISION HIERARCHY

Priority order (higher overrides lower):

```
TIER 0: SAFETY (Non-negotiable)
    ↓
TIER 1: MEDICAL CONSTRAINTS (Guardrails)
    ↓
TIER 2: ADHERENCE SUSTAINABILITY (Realistic > Optimal)
    ↓
TIER 3: PHYSIOLOGICAL OPTIMIZATION (Evidence-based)
    ↓
TIER 4: USER PREFERENCES (Within safe bounds)
    ↓
TIER 5: PERFORMANCE GOALS (Lowest priority for general pop)
```

### Conflict Resolution Rules

**Safety vs User Goals:**
- If user wants aggressive approach that risks safety → Override with safe alternative
- Educate on risks, redirect to sustainable approach

**Adherence vs Optimal:**
- 2 days done > 4 days planned but not done
- Accept reduced results for improved compliance
- Simplify before adding

**Time Constraints vs Results:**
- Calculate minimal effective dose
- Set realistic expectations
- Focus on compound movements and efficiency

## 4. RISK SCORING

### Calculate User Risk Level
- Low Risk (0-1 factors): Basic screening, standard programming
- Moderate Risk (2-3 factors): Enhanced screening, modified progression
- High Risk (4+ factors OR disease): Medical clearance mandatory, supervision recommended

### Risk Factors to Count:
- Age (M ≥45, F ≥55)
- Family history CVD
- Hypertension or medication
- Dyslipidemia
- Pre-diabetes or diabetes
- Obesity (BMI ≥30)
- Sedentary lifestyle
- Current smoker
- Known injuries or chronic conditions

## 5. OUTPUT FORMAT FOR REASONING

When analyzing a user, generate instructions in this format:

```json
{
    "risk_level": "low|moderate|high",
    "risk_factors_identified": ["list of factors"],
    "safety_instructions": ["mandatory safety considerations"],
    "workout_instructions": ["specific workout modifications"],
    "meal_instructions": ["specific nutrition modifications"],
    "behavioral_considerations": ["adherence/motivation factors"],
    "contraindications": ["exercises or foods to avoid"],
    "medical_notes": ["any medical coordination needed"]
}
```
