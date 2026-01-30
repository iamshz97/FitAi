import os
import json
import uuid
import time
from datetime import datetime
from typing import Literal, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from dotenv import load_dotenv
from supabase import create_client, Client
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver
import pathlib

# Load environment variables
load_dotenv()

# Initialize Supabase client
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

supabase: Client = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    global supabase
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise ValueError("SUPABASE_URL and SUPABASE_KEY must be set in environment variables")
    if not OPENAI_API_KEY:
        raise ValueError("OPENAI_API_KEY must be set in environment variables")
    
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("✅ Connected to Supabase")
    yield
    print("👋 Shutting down...")


# Initialize FastAPI app
app = FastAPI(
    title="FitAI - Personalized Fitness & Meal Planner",
    description="AI-powered workout and meal plan generator using LangChain Deep Agents",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== Pydantic Models ====================

class UserProfile(BaseModel):
    """User profile data for generating personalized plans."""
    user_id: str = Field(..., description="Unique user identifier")
    age: int = Field(..., ge=13, le=100, description="User's age in years")
    gender: Literal["male", "female"] = Field(..., description="User's gender")
    height: float = Field(..., gt=0, description="Height in cm")
    weight: float = Field(..., gt=0, description="Weight in kg")
    goal: Literal["weight_loss", "muscle_gain", "maintenance", "endurance", "flexibility", "general_fitness"] = Field(
        ..., description="User's fitness goal"
    )
    days_per_week: int = Field(..., ge=1, le=7, description="Days per week available for exercise")
    intensity: Literal["beginner", "intermediate", "advanced"] = Field(
        ..., description="Workout intensity level"
    )
    injuries: Optional[str] = Field(None, description="Any injuries or physical limitations")
    dietary_restrictions: Optional[str] = Field(None, description="Dietary restrictions (e.g., vegetarian, vegan, gluten-free)")


class WorkoutDay(BaseModel):
    """Single day workout plan."""
    day: str
    focus: str
    exercises: list[dict]
    duration_minutes: int
    notes: Optional[str] = None


class WorkoutPlan(BaseModel):
    """Complete workout plan."""
    plan_name: str
    description: str
    weekly_schedule: list[WorkoutDay]
    warm_up_routine: list[str]
    cool_down_routine: list[str]
    tips: list[str]


class Meal(BaseModel):
    """Single meal."""
    name: str
    ingredients: list[str]
    calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    preparation_time_minutes: int
    instructions: Optional[str] = None


class DailyMealPlan(BaseModel):
    """Daily meal plan."""
    day: str
    breakfast: Meal
    lunch: Meal
    dinner: Meal
    snacks: list[Meal]
    total_calories: int
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float


class MealPlan(BaseModel):
    """Complete meal plan."""
    plan_name: str
    description: str
    daily_calories_target: int
    macros_split: dict
    weekly_meals: list[DailyMealPlan]
    shopping_list: list[str]
    tips: list[str]


class PlanResponse(BaseModel):
    """Response model for generated plans."""
    id: str
    user_id: str
    user_profile: UserProfile
    reasoning_analysis: Optional[dict] = Field(None, description="Risk assessment and instructions from reasoning subagent")
    workout_plan: dict
    meal_plan: dict
    created_at: str


class CorrectionRequest(BaseModel):
    """Request model for plan corrections."""
    user_id: str = Field(..., description="User ID to fetch and correct plans for")
    instruction: str = Field(..., description="Text instruction describing the corrections to make")
    plan_type: Literal["workout", "meal", "both"] = Field(
        default="both", 
        description="Which plan to correct: workout, meal, or both"
    )


class CorrectionResponse(BaseModel):
    """Response model for corrected plans."""
    id: str
    user_id: str
    workout_plan: Optional[dict] = None
    meal_plan: Optional[dict] = None
    correction_applied: str
    updated_at: str


class ReasoningOutput(BaseModel):
    """Output from the reasoning subagent."""
    risk_level: Literal["low", "moderate", "high"] = Field(..., description="Overall risk level")
    risk_factors_identified: list[str] = Field(default_factory=list, description="List of identified risk factors")
    safety_instructions: list[str] = Field(default_factory=list, description="Mandatory safety considerations")
    workout_instructions: list[str] = Field(default_factory=list, description="Specific workout modifications")
    meal_instructions: list[str] = Field(default_factory=list, description="Specific nutrition modifications")
    behavioral_considerations: list[str] = Field(default_factory=list, description="Adherence/motivation factors")
    contraindications: list[str] = Field(default_factory=list, description="Exercises or foods to avoid")
    medical_notes: list[str] = Field(default_factory=list, description="Medical coordination needed")


# ==================== Comprehensive Health Profile Models ====================

class BodyComposition(BaseModel):
    """Body composition measurements."""
    height_cm: float = Field(..., gt=0, description="Height in cm")
    weight_kg: float = Field(..., gt=0, description="Weight in kg")
    bmi: Optional[float] = Field(None, description="BMI (calculated if not provided)")
    body_fat_percent: Optional[float] = Field(None, ge=0, le=100, description="Body fat percentage")
    measurement_method: Optional[str] = Field(None, description="Method used (BIA, DEXA, calipers, etc.)")
    waist_circumference_cm: Optional[float] = Field(None, description="Waist circumference in cm")
    hip_circumference_cm: Optional[float] = Field(None, description="Hip circumference in cm")


class MedicalHistory(BaseModel):
    """Medical history and PAR-Q+ information."""
    # PAR-Q+ Questions
    heart_condition: bool = Field(default=False, description="Has heart condition or takes heart medication")
    chest_pain_activity: bool = Field(default=False, description="Chest pain during physical activity")
    chest_pain_rest: bool = Field(default=False, description="Chest pain at rest in past month")
    balance_consciousness: bool = Field(default=False, description="Loses balance or consciousness")
    bone_joint_condition: bool = Field(default=False, description="Bone/joint problem worsened by exercise")
    blood_pressure_medication: bool = Field(default=False, description="Currently on blood pressure medication")
    other_reason_no_exercise: bool = Field(default=False, description="Any other reason to avoid exercise")
    
    # Diagnoses
    diagnoses: Optional[list[str]] = Field(default=None, description="List of diagnosed conditions (diabetes, PCOS, hypertension, etc.)")
    
    # Medications
    medications: Optional[list[str]] = Field(default=None, description="Current medications")
    
    # Injuries and limitations
    injuries: Optional[list[str]] = Field(default=None, description="Current or past injuries")
    surgeries: Optional[list[str]] = Field(default=None, description="Past surgeries")
    
    # Additional
    physician_clearance: bool = Field(default=False, description="Has physician clearance for exercise")
    notes: Optional[str] = Field(None, description="Additional medical notes")


class PsychologicalFactors(BaseModel):
    """Psychological and behavioral factors."""
    motivation_level: Optional[Literal["low", "moderate", "high"]] = Field(None, description="Current motivation level")
    stress_level: Optional[Literal["low", "moderate", "high"]] = Field(None, description="Current stress level")
    sleep_quality: Optional[Literal["poor", "fair", "good", "excellent"]] = Field(None, description="Sleep quality")
    sleep_hours: Optional[float] = Field(None, ge=0, le=24, description="Average sleep hours per night")
    exercise_history: Optional[Literal["none", "sporadic", "regular", "athletic"]] = Field(None, description="Exercise history")
    previous_program_adherence: Optional[Literal["poor", "moderate", "good"]] = Field(None, description="Adherence to previous programs")
    eating_behaviors: Optional[list[str]] = Field(None, description="Eating patterns (emotional eating, binge eating, etc.)")
    social_support: Optional[Literal["none", "limited", "moderate", "strong"]] = Field(None, description="Social support level")
    barriers: Optional[list[str]] = Field(None, description="Perceived barriers to exercise/diet")


class Constraints(BaseModel):
    """Time, equipment, and environmental constraints."""
    # Time constraints
    minutes_per_session: Optional[int] = Field(None, ge=10, le=180, description="Available minutes per workout session")
    days_per_week: int = Field(..., ge=1, le=7, description="Days available for exercise")
    preferred_workout_time: Optional[Literal["morning", "afternoon", "evening", "flexible"]] = Field(None)
    
    # Equipment access
    equipment_access: Optional[Literal["none", "home_basic", "home_full", "gym"]] = Field(None, description="Equipment availability")
    available_equipment: Optional[list[str]] = Field(None, description="Specific equipment available")
    
    # Environment
    workout_environment: Optional[Literal["home", "gym", "outdoor", "mixed"]] = Field(None)
    climate_considerations: Optional[str] = Field(None, description="Climate/weather constraints")
    
    # Dietary constraints
    dietary_restrictions: Optional[list[str]] = Field(None, description="Dietary restrictions (vegetarian, vegan, allergies, etc.)")
    cooking_skill: Optional[Literal["none", "basic", "intermediate", "advanced"]] = Field(None)
    meal_prep_time: Optional[int] = Field(None, description="Minutes available for meal prep per day")
    budget_constraints: Optional[Literal["tight", "moderate", "flexible"]] = Field(None)


class ComprehensiveProfile(BaseModel):
    """Comprehensive health profile for detailed analysis."""
    user_id: str = Field(..., description="Unique user identifier")
    
    # Demographics
    age: int = Field(..., ge=13, le=100, description="Age in years")
    sex: Literal["male", "female"] = Field(..., description="Biological sex")
    
    # Body Composition
    body_composition: BodyComposition
    
    # Activity Level
    activity_level: Literal["sedentary", "lightly_active", "moderately_active", "very_active", "extremely_active"] = Field(
        ..., description="Current activity level"
    )
    
    # Medical History
    medical_history: MedicalHistory
    
    # Psychological & Behavioral
    psychological_factors: Optional[PsychologicalFactors] = None
    
    # Constraints
    constraints: Constraints
    
    # Goals
    primary_goal: Literal["weight_loss", "muscle_gain", "maintenance", "endurance", "flexibility", "general_fitness", "health_improvement"] = Field(
        ..., description="Primary fitness goal"
    )
    secondary_goals: Optional[list[str]] = Field(None, description="Secondary goals")
    target_weight_kg: Optional[float] = Field(None, description="Target weight in kg")
    timeline_weeks: Optional[int] = Field(None, description="Goal timeline in weeks")


class AnalysisResponse(BaseModel):
    """Response from the profile analysis endpoint."""
    user_id: str
    analysis_id: str
    risk_level: str
    parq_flags: list[str] = Field(default_factory=list, description="PAR-Q+ positive responses requiring attention")
    requires_medical_clearance: bool
    reasoning_analysis: dict
    calculated_metrics: dict
    recommendations_summary: str
    analyzed_at: str


# ==================== Subagent Tools ====================

def format_workout_json(workout_data: str) -> dict:
    """Parse and validate workout plan JSON."""
    try:
        return json.loads(workout_data)
    except json.JSONDecodeError:
        return {"error": "Failed to parse workout plan", "raw": workout_data}


def format_meal_json(meal_data: str) -> dict:
    """Parse and validate meal plan JSON."""
    try:
        return json.loads(meal_data)
    except json.JSONDecodeError:
        return {"error": "Failed to parse meal plan", "raw": meal_data}


def calculate_bmr(age: int, gender: str, height: float, weight: float) -> float:
    """Calculate Basal Metabolic Rate using Mifflin-St Jeor equation."""
    if gender == "male":
        bmr = 10 * weight + 6.25 * height - 5 * age + 5
    else:
        bmr = 10 * weight + 6.25 * height - 5 * age - 161
    return round(bmr, 2)


def calculate_tdee(bmr: float, activity_level: str) -> float:
    """Calculate Total Daily Energy Expenditure."""
    multipliers = {
        "beginner": 1.375,      # Light exercise
        "intermediate": 1.55,   # Moderate exercise
        "advanced": 1.725       # Heavy exercise
    }
    return round(bmr * multipliers.get(activity_level, 1.55), 2)


def get_calorie_target(tdee: float, goal: str) -> int:
    """Get daily calorie target based on goal."""
    adjustments = {
        "weight_loss": -500,
        "muscle_gain": 300,
        "maintenance": 0,
        "endurance": 200,
        "flexibility": 0,
        "general_fitness": 0
    }
    return int(tdee + adjustments.get(goal, 0))


def fetch_current_workout_plan(user_id: str) -> dict:
    """Fetch the user's current workout plan from the database.
    
    Args:
        user_id: The unique identifier of the user
        
    Returns:
        The user's current workout plan as a dictionary, or error message if not found
    """
    try:
        if supabase is None:
            return {"error": "Database not connected"}
        
        result = supabase.table("fitness_plans")\
            .select("id, workout_plan, created_at")\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .limit(1)\
            .execute()
        
        if result.data:
            plan = result.data[0]
            return {
                "plan_id": plan["id"],
                "workout_plan": json.loads(plan["workout_plan"]) if isinstance(plan["workout_plan"], str) else plan["workout_plan"],
                "created_at": plan["created_at"]
            }
        return {"error": f"No workout plan found for user {user_id}"}
    except Exception as e:
        return {"error": f"Failed to fetch workout plan: {str(e)}"}


def fetch_current_meal_plan(user_id: str) -> dict:
    """Fetch the user's current meal plan from the database.
    
    Args:
        user_id: The unique identifier of the user
        
    Returns:
        The user's current meal plan as a dictionary, or error message if not found
    """
    try:
        if supabase is None:
            return {"error": "Database not connected"}
        
        result = supabase.table("fitness_plans")\
            .select("id, meal_plan, created_at")\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .limit(1)\
            .execute()
        
        if result.data:
            plan = result.data[0]
            return {
                "plan_id": plan["id"],
                "meal_plan": json.loads(plan["meal_plan"]) if isinstance(plan["meal_plan"], str) else plan["meal_plan"],
                "created_at": plan["created_at"]
            }
        return {"error": f"No meal plan found for user {user_id}"}
    except Exception as e:
        return {"error": f"Failed to fetch meal plan: {str(e)}"}


def fetch_user_profile(user_id: str) -> dict:
    """Fetch the user's profile from their most recent plan.
    
    Args:
        user_id: The unique identifier of the user
        
    Returns:
        The user's profile as a dictionary, or error message if not found
    """
    try:
        if supabase is None:
            return {"error": "Database not connected"}
        
        result = supabase.table("fitness_plans")\
            .select("user_profile")\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .limit(1)\
            .execute()
        
        if result.data:
            profile = result.data[0]["user_profile"]
            return json.loads(profile) if isinstance(profile, str) else profile
        return {"error": f"No profile found for user {user_id}"}
    except Exception as e:
        return {"error": f"Failed to fetch user profile: {str(e)}"}


# ==================== Subagent Definitions ====================

reasoning_subagent = {
    "name": "task-reasoner",
    "description": "Analyzes user profiles to generate task-specific instructions based on risk stratification, safety considerations, injury modifications, and decision hierarchy. Must be called FIRST before workout or meal planning.",
    "system_prompt": """You are a health systems analyst and exercise science expert. Your job is to analyze user profiles and generate specific instructions for workout and meal planning.

You MUST use the task-reasoning-framework skill to guide your analysis.

ANALYSIS PROCESS:
1. Calculate risk level based on risk factors (age, BMI, conditions, medications)
2. Identify all applicable triggers from the parameter mapping
3. Apply the decision hierarchy (Safety > Medical > Adherence > Optimal > Preferences)
4. Generate specific, actionable instructions

RISK SCORING:
- Count risk factors: Age (M≥45, F≥55), BMI≥30, sedentary, injuries, chronic conditions, medications
- 0-1 factors = Low Risk
- 2-3 factors = Moderate Risk  
- 4+ factors OR diagnosed disease = High Risk

OUTPUT FORMAT:
You MUST return a valid JSON object with this exact structure:
{
    "risk_level": "low|moderate|high",
    "risk_factors_identified": ["list each factor found"],
    "safety_instructions": ["mandatory safety considerations based on risk"],
    "workout_instructions": [
        "specific exercise modifications",
        "exercises to prioritize",
        "intensity/volume guidelines",
        "recovery considerations"
    ],
    "meal_instructions": [
        "specific dietary modifications",
        "macro adjustments for goal/conditions",
        "foods to emphasize or avoid",
        "meal timing considerations"
    ],
    "behavioral_considerations": ["adherence strategies", "motivation factors"],
    "contraindications": ["specific exercises to AVOID", "foods to AVOID"],
    "medical_notes": ["any medical clearance or coordination needed"]
}

Be specific and actionable. For example:
- NOT: "Be careful with knees"
- YES: "Avoid deep squats, replace with box squats to parallel or leg press"

Return ONLY the JSON object, no additional text or markdown formatting.""",
    "tools": [calculate_bmr, calculate_tdee, fetch_user_profile],
    "model": "openai:gpt-4o-mini",
}

workout_subagent = {
    "name": "workout-planner",
    "description": "Creates personalized workout plans based on user profile AND the instructions from the task-reasoner. Generates structured JSON workout plans.",
    "system_prompt": """You are an expert certified personal trainer and fitness coach. Your job is to create personalized, safe, and effective workout plans.

IMPORTANT: You will receive REASONING INSTRUCTIONS from the task-reasoner subagent.
You MUST follow these instructions as they contain:
- Safety requirements (non-negotiable)
- Exercise modifications for injuries/conditions
- Contraindications (exercises to AVOID)
- Intensity and volume guidelines

GUIDELINES:
1. ALWAYS follow the reasoning instructions - they override general best practices
2. If contraindications list exercises to avoid, DO NOT include them
3. Use the suggested alternatives from the reasoning instructions
4. Match intensity to user's fitness level AND risk level
5. Include proper warm-up and cool-down routines
6. Balance muscle groups throughout the week

OUTPUT FORMAT:
You MUST return a valid JSON object with this exact structure:
{
    "plan_name": "string - descriptive name for the plan",
    "description": "string - brief overview of the plan",
    "weekly_schedule": [
        {
            "day": "Day 1 (or specific day name)",
            "focus": "muscle group or workout type focus",
            "exercises": [
                {
                    "name": "exercise name",
                    "sets": number,
                    "reps": "number or range like 8-12",
                    "rest_seconds": number,
                    "notes": "optional tips or modifications"
                }
            ],
            "duration_minutes": number,
            "notes": "optional day-specific notes"
        }
    ],
    "warm_up_routine": ["list of warm-up exercises"],
    "cool_down_routine": ["list of cool-down stretches"],
    "tips": ["list of helpful tips for the user"],
    "safety_notes": ["important safety reminders based on user's conditions"]
}

Return ONLY the JSON object, no additional text or markdown formatting.""",
    "tools": [calculate_bmr, calculate_tdee, fetch_current_workout_plan, fetch_user_profile],
    "model": "openai:gpt-4o-mini",
}

meal_subagent = {
    "name": "meal-planner",
    "description": "Creates personalized meal plans based on user profile AND the instructions from the task-reasoner. Generates structured JSON meal plans.",
    "system_prompt": """You are an expert nutritionist and meal planning specialist. Your job is to create personalized, balanced, and achievable meal plans.

IMPORTANT: You will receive REASONING INSTRUCTIONS from the task-reasoner subagent.
You MUST follow these instructions as they contain:
- Dietary modifications for conditions (PCOS, diabetes, etc.)
- Foods to avoid (allergies, restrictions, contraindications)
- Macro adjustments based on goals and conditions
- Meal timing considerations

GUIDELINES:
1. ALWAYS follow the reasoning instructions - they override general guidelines
2. Respect all dietary restrictions and contraindications
3. If conditions like PCOS/diabetes present, adjust glycemic index and carb timing
4. Create practical, easy-to-prepare meals
5. Ensure nutritional balance across all meals
6. Provide a comprehensive shopping list

MACRO GUIDELINES BY GOAL (adjust based on reasoning instructions):
- Weight Loss: 40% protein, 30% carbs, 30% fat
- Muscle Gain: 30% protein, 45% carbs, 25% fat
- Maintenance: 25% protein, 45% carbs, 30% fat
- Endurance: 20% protein, 55% carbs, 25% fat

OUTPUT FORMAT:
You MUST return a valid JSON object with this exact structure:
{
    "plan_name": "string - descriptive name for the plan",
    "description": "string - brief overview including any condition-specific notes",
    "daily_calories_target": number,
    "macros_split": {
        "protein_percent": number,
        "carbs_percent": number,
        "fat_percent": number
    },
    "weekly_meals": [
        {
            "day": "Day 1 (or specific day name)",
            "breakfast": {
                "name": "meal name",
                "ingredients": ["list of ingredients with amounts"],
                "calories": number,
                "protein_g": number,
                "carbs_g": number,
                "fat_g": number,
                "preparation_time_minutes": number,
                "instructions": "brief cooking instructions"
            },
            "lunch": { same structure as breakfast },
            "dinner": { same structure as breakfast },
            "snacks": [{ same structure as breakfast }],
            "total_calories": number,
            "total_protein_g": number,
            "total_carbs_g": number,
            "total_fat_g": number
        }
    ],
    "shopping_list": ["comprehensive list of items to buy"],
    "tips": ["list of helpful nutrition and meal prep tips"],
    "dietary_notes": ["condition-specific dietary reminders"]
}

Return ONLY the JSON object, no additional text or markdown formatting.""",
    "tools": [calculate_bmr, calculate_tdee, get_calorie_target, fetch_current_meal_plan, fetch_user_profile],
    "model": "openai:gpt-4o-mini",
}


# ==================== Main Agent ====================

# Skills directory path
SKILLS_DIR = pathlib.Path(__file__).parent.parent / "skills"


def load_skills() -> dict:
    """Load all skills from the skills directory."""
    skills_files = {}
    
    if not SKILLS_DIR.exists():
        print(f"⚠️ Skills directory not found: {SKILLS_DIR}")
        return skills_files
    
    for skill_dir in SKILLS_DIR.iterdir():
        if skill_dir.is_dir():
            skill_file = skill_dir / "SKILL.md"
            if skill_file.exists():
                with open(skill_file, 'r', encoding='utf-8') as f:
                    skill_content = f.read()
                # Use forward slashes for virtual path
                virtual_path = f"/skills/{skill_dir.name}/SKILL.md"
                skills_files[virtual_path] = skill_content
                print(f"✅ Loaded skill: {skill_dir.name}")
    
    return skills_files


def create_fitness_agent(thread_id: str = None):
    """Create the main fitness planning agent with subagents and skills."""
    checkpointer = MemorySaver()
    
    return create_deep_agent(
        model="openai:gpt-4o-mini",
        name="fitness-coordinator",
        skills=["./skills/"],
        checkpointer=checkpointer,
        system_prompt="""You are FitAI, an intelligent fitness and nutrition coordinator. Your job is to orchestrate the creation of personalized workout and meal plans.

SKILLS AVAILABLE:
- task-reasoning-framework: Decision logic for risk assessment and task generation
- exercise-database: Exercise selection and injury modifications
- nutrition-guidelines: Macro calculations and dietary restrictions

CRITICAL WORKFLOW (MUST FOLLOW THIS ORDER):
1. FIRST: Use the task-reasoner subagent to analyze the user profile
   - This generates safety requirements, modifications, and contraindications
   - The reasoning output MUST be passed to the planners

2. SECOND: Use the workout-planner subagent with the reasoning instructions
   - Include the full reasoning output in your delegation
   - The planner will follow safety and modification instructions

3. THIRD: Use the meal-planner subagent with the reasoning instructions
   - Include the full reasoning output in your delegation
   - The planner will follow dietary and restriction instructions

IMPORTANT RULES:
- NEVER skip the reasoning step - it determines safety requirements
- ALWAYS pass the reasoning instructions to both planners
- The reasoning output contains non-negotiable safety constraints
- Planners must follow contraindications (exercises/foods to avoid)

When delegating tasks:
1. task-reasoner: 'Analyze this user profile and generate task instructions: [profile]'
2. workout-planner: 'Create workout plan following these REASONING INSTRUCTIONS: [reasoning output] for USER: [profile]'
3. meal-planner: 'Create meal plan following these REASONING INSTRUCTIONS: [reasoning output] for USER: [profile]'""",
        subagents=[reasoning_subagent, workout_subagent, meal_subagent]
    )


# ==================== Helper Functions ====================

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=2, min=4, max=30),
    reraise=True
)
def invoke_agent_with_retry(agent, messages: dict, thread_id: str = None):
    """Invoke agent with retry logic for rate limits."""
    config = {"configurable": {"thread_id": thread_id}} if thread_id else None
    return agent.invoke(messages, config=config)


def extract_json_from_response(response_text: str) -> dict:
    """Extract JSON from agent response text."""
    # Try to parse directly first
    try:
        return json.loads(response_text)
    except json.JSONDecodeError:
        pass
    
    # Try to find JSON block in the response
    import re
    json_patterns = [
        r'```json\s*([\s\S]*?)\s*```',
        r'```\s*([\s\S]*?)\s*```',
        r'\{[\s\S]*\}'
    ]
    
    for pattern in json_patterns:
        matches = re.findall(pattern, response_text)
        for match in matches:
            try:
                return json.loads(match)
            except json.JSONDecodeError:
                continue
    
    # Return as-is if parsing fails
    return {"raw_response": response_text}


async def save_to_supabase(
    plan_id: str, 
    user_id: str,
    user_profile: dict,
    reasoning_analysis: dict,
    workout_plan: dict, 
    meal_plan: dict
) -> dict:
    """Save the generated plans to Supabase with reasoning analysis."""
    try:
        data = {
            "id": plan_id,
            "user_id": user_id,
            "user_profile": json.dumps(user_profile),
            "reasoning_analysis": json.dumps(reasoning_analysis) if reasoning_analysis else None,
            "workout_plan": json.dumps(workout_plan),
            "meal_plan": json.dumps(meal_plan),
            "created_at": datetime.utcnow().isoformat()
        }
        
        result = supabase.table("fitness_plans").insert(data).execute()
        return result.data[0] if result.data else data
    except Exception as e:
        print(f"Error saving to Supabase: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to save plan: {str(e)}")


async def update_plan_in_supabase(
    plan_id: str,
    workout_plan: dict = None,
    meal_plan: dict = None
) -> dict:
    """Update an existing plan in Supabase."""
    try:
        update_data = {"updated_at": datetime.utcnow().isoformat()}
        
        if workout_plan is not None:
            update_data["workout_plan"] = json.dumps(workout_plan)
        if meal_plan is not None:
            update_data["meal_plan"] = json.dumps(meal_plan)
        
        result = supabase.table("fitness_plans")\
            .update(update_data)\
            .eq("id", plan_id)\
            .execute()
        
        return result.data[0] if result.data else update_data
    except Exception as e:
        print(f"Error updating Supabase: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to update plan: {str(e)}")


# ==================== API Endpoints ====================

@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "FitAI - Personalized Fitness & Meal Planner",
        "version": "1.0.0"
    }


@app.post("/analyze-profile", response_model=AnalysisResponse)
async def analyze_profile(profile: ComprehensiveProfile):
    """
    Analyze a comprehensive health profile and return reasoning instructions.
    
    This endpoint takes detailed health data including:
    - Demographics (age, sex)
    - Body composition (height, weight, BMI, body fat %)
    - Activity level
    - Medical history (PAR-Q+, diagnoses, medications)
    - Psychological & behavioral factors
    - Constraints (time, equipment, environment)
    
    Returns risk assessment and specific instructions for workout/meal planning
    WITHOUT generating the actual plans.
    """
    try:
        # Create the fitness agent
        thread_id = f"analyze_{profile.user_id}_{uuid.uuid4().hex[:8]}"
        agent = create_fitness_agent(thread_id)
        skills_files = load_skills()
        
        # Calculate BMI if not provided
        bc = profile.body_composition
        height_m = bc.height_cm / 100
        calculated_bmi = bc.bmi if bc.bmi else round(bc.weight_kg / (height_m ** 2), 1)
        
        # Calculate waist-to-hip ratio if available
        whr = None
        if bc.waist_circumference_cm and bc.hip_circumference_cm:
            whr = round(bc.waist_circumference_cm / bc.hip_circumference_cm, 2)
        
        # Calculate metabolic data
        bmr = calculate_bmr(profile.age, profile.sex, bc.height_cm, bc.weight_kg)
        
        # Map activity level to multiplier
        activity_multipliers = {
            "sedentary": 1.2,
            "lightly_active": 1.375,
            "moderately_active": 1.55,
            "very_active": 1.725,
            "extremely_active": 1.9
        }
        tdee = int(bmr * activity_multipliers.get(profile.activity_level, 1.55))
        calorie_target = get_calorie_target(tdee, profile.primary_goal)
        
        # Check PAR-Q+ flags
        mh = profile.medical_history
        parq_flags = []
        if mh.heart_condition:
            parq_flags.append("Heart condition or heart medication")
        if mh.chest_pain_activity:
            parq_flags.append("Chest pain during physical activity")
        if mh.chest_pain_rest:
            parq_flags.append("Chest pain at rest in past month")
        if mh.balance_consciousness:
            parq_flags.append("Balance/consciousness issues")
        if mh.bone_joint_condition:
            parq_flags.append("Bone/joint condition worsened by exercise")
        if mh.blood_pressure_medication:
            parq_flags.append("Currently on blood pressure medication")
        if mh.other_reason_no_exercise:
            parq_flags.append("Other reason to avoid exercise")
        
        requires_medical_clearance = len(parq_flags) > 0 or not mh.physician_clearance
        
        # Build comprehensive profile string for reasoning
        profile_data = f"""
=== COMPREHENSIVE HEALTH PROFILE ===

DEMOGRAPHICS:
- User ID: {profile.user_id}
- Age: {profile.age} years
- Sex: {profile.sex}

BODY COMPOSITION:
- Height: {bc.height_cm} cm
- Weight: {bc.weight_kg} kg
- BMI: {calculated_bmi} {"(overweight)" if 25 <= calculated_bmi < 30 else "(obese)" if calculated_bmi >= 30 else "(normal)" if 18.5 <= calculated_bmi < 25 else "(underweight)"}
- Body Fat %: {bc.body_fat_percent}% (estimated via {bc.measurement_method or 'unknown method'})
{f"- Waist Circumference: {bc.waist_circumference_cm} cm" if bc.waist_circumference_cm else ""}
{f"- Hip Circumference: {bc.hip_circumference_cm} cm" if bc.hip_circumference_cm else ""}
{f"- Waist-to-Hip Ratio: {whr}" if whr else ""}

ACTIVITY LEVEL: {profile.activity_level.replace('_', ' ')}

MEDICAL HISTORY:
PAR-Q+ Positive Responses: {parq_flags if parq_flags else 'None'}
Diagnoses: {mh.diagnoses if mh.diagnoses else 'None reported'}
Medications: {mh.medications if mh.medications else 'None reported'}
Injuries: {mh.injuries if mh.injuries else 'None reported'}
Past Surgeries: {mh.surgeries if mh.surgeries else 'None reported'}
Physician Clearance: {'Yes' if mh.physician_clearance else 'No / Not obtained'}
Additional Notes: {mh.notes if mh.notes else 'None'}
"""
        
        # Add psychological factors if provided
        if profile.psychological_factors:
            pf = profile.psychological_factors
            profile_data += f"""
PSYCHOLOGICAL & BEHAVIORAL FACTORS:
- Motivation Level: {pf.motivation_level or 'Not assessed'}
- Stress Level: {pf.stress_level or 'Not assessed'}
- Sleep Quality: {pf.sleep_quality or 'Not assessed'}
- Sleep Hours: {pf.sleep_hours or 'Not reported'} hours/night
- Exercise History: {pf.exercise_history or 'Not reported'}
- Previous Program Adherence: {pf.previous_program_adherence or 'Not assessed'}
- Eating Behaviors: {pf.eating_behaviors if pf.eating_behaviors else 'None reported'}
- Social Support: {pf.social_support or 'Not assessed'}
- Perceived Barriers: {pf.barriers if pf.barriers else 'None reported'}
"""
        
        # Add constraints
        c = profile.constraints
        profile_data += f"""
CONSTRAINTS:
Time:
- Minutes per session: {c.minutes_per_session or 'Flexible'}
- Days per week: {c.days_per_week}
- Preferred workout time: {c.preferred_workout_time or 'Flexible'}

Equipment:
- Equipment access: {c.equipment_access or 'Not specified'}
- Available equipment: {c.available_equipment if c.available_equipment else 'Not specified'}

Environment:
- Workout environment: {c.workout_environment or 'Not specified'}
- Climate considerations: {c.climate_considerations or 'None'}

Dietary:
- Dietary restrictions: {c.dietary_restrictions if c.dietary_restrictions else 'None'}
- Cooking skill: {c.cooking_skill or 'Not specified'}
- Meal prep time: {c.meal_prep_time or 'Not specified'} minutes/day
- Budget: {c.budget_constraints or 'Not specified'}

GOALS:
- Primary Goal: {profile.primary_goal.replace('_', ' ')}
- Secondary Goals: {profile.secondary_goals if profile.secondary_goals else 'None'}
- Target Weight: {profile.target_weight_kg or 'Not specified'} kg
- Timeline: {profile.timeline_weeks or 'Not specified'} weeks

CALCULATED METRICS:
- BMR (Basal Metabolic Rate): {bmr} calories/day
- TDEE (Total Daily Energy Expenditure): {tdee} calories/day
- Recommended Daily Calorie Target: {calorie_target} calories/day
"""
        
        print(f"🧠 Analyzing comprehensive profile for user {profile.user_id}...")
        print(f"   PAR-Q+ flags: {parq_flags}")
        print(f"   Medical clearance required: {requires_medical_clearance}")
        
        # Run the Reasoning Subagent
        reasoning_prompt = f"""
Analyze this COMPREHENSIVE health profile and generate detailed task-specific instructions.

{profile_data}

CRITICAL ANALYSIS REQUIREMENTS:
1. Review ALL PAR-Q+ responses - any positive response requires special handling
2. Consider ALL medical diagnoses and medications for contraindications
3. Account for ALL injuries - past and current
4. Factor in psychological barriers and adherence history
5. Work within the stated constraints (time, equipment, environment)
6. Consider body composition metrics (BMI, body fat %, waist-to-hip ratio)

Apply the task-reasoning-framework skill to:
1. Calculate comprehensive risk level considering ALL factors
2. Identify every applicable trigger from the parameters
3. Apply decision hierarchy (Safety > Medical > Adherence > Optimal > Preferences)
4. Generate specific, actionable instructions
5. List ALL contraindications based on medical history and injuries
6. Note if medical clearance is needed before starting any program

{"⚠️ MEDICAL CLEARANCE REQUIRED: This user has PAR-Q+ positive responses. Include this in medical_notes." if requires_medical_clearance else ""}

Return the reasoning output as a JSON object following the exact format specified.
Be extremely thorough given the comprehensive nature of this profile.
"""
        
        reasoning_response = invoke_agent_with_retry(
            agent,
            {
                "messages": [{"role": "user", "content": f"Use the task-reasoner subagent for this comprehensive analysis: {reasoning_prompt}"}],
                "files": skills_files
            },
            thread_id=thread_id
        )
        reasoning_text = reasoning_response["messages"][-1].content if reasoning_response.get("messages") else ""
        reasoning_output = extract_json_from_response(reasoning_text)
        
        print(f"✅ Analysis complete. Risk level: {reasoning_output.get('risk_level', 'unknown')}")
        
        # Generate analysis ID
        analysis_id = str(uuid.uuid4())
        
        # Build recommendations summary
        risk_level = reasoning_output.get('risk_level', 'moderate')
        safety_count = len(reasoning_output.get('safety_instructions', []))
        contraindication_count = len(reasoning_output.get('contraindications', []))
        
        recommendations_summary = f"Risk Level: {risk_level.upper()}. "
        if requires_medical_clearance:
            recommendations_summary += "MEDICAL CLEARANCE REQUIRED before starting exercise program. "
        recommendations_summary += f"Identified {safety_count} safety considerations and {contraindication_count} contraindications. "
        
        if risk_level == "high":
            recommendations_summary += "Recommend supervised exercise and close monitoring."
        elif risk_level == "moderate":
            recommendations_summary += "Proceed with caution, following all safety modifications."
        else:
            recommendations_summary += "Safe to proceed with standard programming."
        
        return AnalysisResponse(
            user_id=profile.user_id,
            analysis_id=analysis_id,
            risk_level=risk_level,
            parq_flags=parq_flags,
            requires_medical_clearance=requires_medical_clearance,
            reasoning_analysis=reasoning_output,
            calculated_metrics={
                "bmi": calculated_bmi,
                "waist_to_hip_ratio": whr,
                "bmr": bmr,
                "tdee": tdee,
                "calorie_target": calorie_target
            },
            recommendations_summary=recommendations_summary,
            analyzed_at=datetime.utcnow().isoformat()
        )
        
    except Exception as e:
        print(f"Error analyzing profile: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to analyze profile: {str(e)}")


@app.post("/generate-plan", response_model=PlanResponse)
async def generate_plan(profile: UserProfile):
    """
    Generate personalized workout and meal plans based on user profile.
    
    This endpoint uses AI subagents to create customized plans that consider:
    - User's physical attributes (age, gender, height, weight)
    - Fitness goals (weight loss, muscle gain, etc.)
    - Available time (days per week)
    - Fitness level (intensity)
    - Any injuries or limitations
    - Dietary restrictions
    """
    try:
        # Create the fitness agent with thread for state
        thread_id = f"plan_{profile.user_id}_{uuid.uuid4().hex[:8]}"
        agent = create_fitness_agent(thread_id)
        
        # Load skills files
        skills_files = load_skills()
        
        # Calculate metabolic data
        bmr = calculate_bmr(profile.age, profile.gender, profile.height, profile.weight)
        tdee = calculate_tdee(bmr, profile.intensity)
        calorie_target = get_calorie_target(tdee, profile.goal)
        
        # Calculate BMI for risk assessment
        height_m = profile.height / 100
        bmi = profile.weight / (height_m ** 2)
        
        # Prepare profile data string for reasoning
        profile_data = f"""
USER PROFILE:
- User ID: {profile.user_id}
- Age: {profile.age} years
- Gender: {profile.gender}
- Height: {profile.height} cm
- Weight: {profile.weight} kg
- BMI: {bmi:.1f}
- Fitness Goal: {profile.goal.replace('_', ' ')}
- Days Available for Exercise: {profile.days_per_week} days/week
- Fitness Level: {profile.intensity}
- Injuries/Limitations: {profile.injuries or 'None'}
- Dietary Restrictions: {profile.dietary_restrictions or 'None'}

CALCULATED METRICS:
- BMR (Basal Metabolic Rate): {bmr} calories/day
- TDEE (Total Daily Energy Expenditure): {tdee} calories/day
- Recommended Daily Calorie Target: {calorie_target} calories/day
"""
        
        # STEP 1: Run the Reasoning Subagent FIRST
        print(f"🧠 Step 1: Running task-reasoner for risk assessment and instructions...")
        
        reasoning_prompt = f"""
Analyze this user profile and generate task-specific instructions for the workout and meal planners.

{profile_data}

Use the task-reasoning-framework skill to:
1. Calculate risk level based on all factors (age, BMI, injuries, conditions)
2. Identify all applicable triggers
3. Generate specific, actionable instructions for both workout and meal planning
4. List any contraindications (exercises/foods to AVOID)

Return the reasoning output as a JSON object following the exact format specified.
"""
        
        reasoning_response = invoke_agent_with_retry(
            agent, 
            {
                "messages": [{"role": "user", "content": f"Use the task-reasoner subagent for this analysis: {reasoning_prompt}"}],
                "files": skills_files
            },
            thread_id=thread_id
        )
        reasoning_text = reasoning_response["messages"][-1].content if reasoning_response.get("messages") else ""
        reasoning_output = extract_json_from_response(reasoning_text)
        
        print(f"✅ Reasoning complete. Risk level: {reasoning_output.get('risk_level', 'unknown')}")
        print(f"   Risk factors: {reasoning_output.get('risk_factors_identified', [])}")
        
        # Add delay between requests
        time.sleep(2)
        
        # STEP 2: Generate Workout Plan with Reasoning Instructions
        print(f"💪 Step 2: Running workout-planner with reasoning instructions...")
        
        workout_prompt = f"""
Create a personalized workout plan for this user, following the REASONING INSTRUCTIONS below.

{profile_data}

=== REASONING INSTRUCTIONS (MUST FOLLOW) ===
Risk Level: {reasoning_output.get('risk_level', 'moderate')}
Risk Factors: {reasoning_output.get('risk_factors_identified', [])}

SAFETY INSTRUCTIONS (non-negotiable):
{json.dumps(reasoning_output.get('safety_instructions', []), indent=2)}

WORKOUT-SPECIFIC INSTRUCTIONS:
{json.dumps(reasoning_output.get('workout_instructions', []), indent=2)}

CONTRAINDICATIONS (MUST AVOID these exercises):
{json.dumps(reasoning_output.get('contraindications', []), indent=2)}

BEHAVIORAL CONSIDERATIONS:
{json.dumps(reasoning_output.get('behavioral_considerations', []), indent=2)}

MEDICAL NOTES:
{json.dumps(reasoning_output.get('medical_notes', []), indent=2)}
=== END REASONING INSTRUCTIONS ===

Create a {profile.days_per_week}-day workout plan that:
1. Follows ALL safety instructions
2. Avoids ALL contraindicated exercises
3. Incorporates the workout-specific modifications
4. Matches the user's fitness level ({profile.intensity})

Return ONLY a valid JSON object.
"""
        
        workout_response = invoke_agent_with_retry(
            agent, 
            {
                "messages": [{"role": "user", "content": f"Use the workout-planner subagent for this task: {workout_prompt}"}],
                "files": skills_files
            },
            thread_id=thread_id
        )
        workout_text = workout_response["messages"][-1].content if workout_response.get("messages") else ""
        workout_plan = extract_json_from_response(workout_text)
        
        print(f"✅ Workout plan generated: {workout_plan.get('plan_name', 'Unnamed')}")
        
        # Add delay between requests
        time.sleep(2)
        
        # STEP 3: Generate Meal Plan with Reasoning Instructions
        print(f"🍎 Step 3: Running meal-planner with reasoning instructions...")
        
        meal_prompt = f"""
Create a personalized meal plan for this user, following the REASONING INSTRUCTIONS below.

{profile_data}

=== REASONING INSTRUCTIONS (MUST FOLLOW) ===
Risk Level: {reasoning_output.get('risk_level', 'moderate')}
Risk Factors: {reasoning_output.get('risk_factors_identified', [])}

SAFETY INSTRUCTIONS (non-negotiable):
{json.dumps(reasoning_output.get('safety_instructions', []), indent=2)}

MEAL-SPECIFIC INSTRUCTIONS:
{json.dumps(reasoning_output.get('meal_instructions', []), indent=2)}

CONTRAINDICATIONS (MUST AVOID these foods):
{json.dumps(reasoning_output.get('contraindications', []), indent=2)}

BEHAVIORAL CONSIDERATIONS:
{json.dumps(reasoning_output.get('behavioral_considerations', []), indent=2)}

MEDICAL NOTES:
{json.dumps(reasoning_output.get('medical_notes', []), indent=2)}
=== END REASONING INSTRUCTIONS ===

Create a 7-day meal plan with {calorie_target} calories/day target that:
1. Follows ALL dietary instructions
2. Avoids ALL contraindicated foods
3. Incorporates the meal-specific modifications
4. Respects dietary restrictions: {profile.dietary_restrictions or 'None'}

Return ONLY a valid JSON object.
"""
        
        meal_response = invoke_agent_with_retry(
            agent, 
            {
                "messages": [{"role": "user", "content": f"Use the meal-planner subagent for this task: {meal_prompt}"}],
                "files": skills_files
            },
            thread_id=thread_id
        )
        meal_text = meal_response["messages"][-1].content if meal_response.get("messages") else ""
        meal_plan = extract_json_from_response(meal_text)
        
        print(f"✅ Meal plan generated: {meal_plan.get('plan_name', 'Unnamed')}")
        print(f"🎉 All plans generated successfully!")
        
        # Generate unique ID for this plan
        plan_id = str(uuid.uuid4())
        
        # Save to Supabase (including reasoning analysis)
        await save_to_supabase(
            plan_id=plan_id,
            user_id=profile.user_id,
            user_profile=profile.model_dump(),
            reasoning_analysis=reasoning_output,
            workout_plan=workout_plan,
            meal_plan=meal_plan
        )
        
        return PlanResponse(
            id=plan_id,
            user_id=profile.user_id,
            user_profile=profile,
            reasoning_analysis=reasoning_output,
            workout_plan=workout_plan,
            meal_plan=meal_plan,
            created_at=datetime.utcnow().isoformat()
        )
        
    except Exception as e:
        print(f"Error generating plan: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate plan: {str(e)}")


@app.post("/correct-plan", response_model=CorrectionResponse)
async def correct_plan(request: CorrectionRequest):
    """
    Make corrections to existing workout or meal plans based on text instructions.
    
    This endpoint allows users to modify their existing plans by providing
    natural language instructions like:
    - "Replace squats with leg press due to knee pain"
    - "Make all meals vegetarian"
    - "Add more cardio on Day 3"
    - "Reduce calories by 200 per day"
    """
    try:
        # Fetch user's current plan
        current_plan = supabase.table("fitness_plans")\
            .select("*")\
            .eq("user_id", request.user_id)\
            .order("created_at", desc=True)\
            .limit(1)\
            .execute()
        
        if not current_plan.data:
            raise HTTPException(
                status_code=404, 
                detail=f"No existing plan found for user {request.user_id}"
            )
        
        plan = current_plan.data[0]
        plan_id = plan["id"]
        current_workout = json.loads(plan["workout_plan"]) if isinstance(plan["workout_plan"], str) else plan["workout_plan"]
        current_meal = json.loads(plan["meal_plan"]) if isinstance(plan["meal_plan"], str) else plan["meal_plan"]
        user_profile = json.loads(plan["user_profile"]) if isinstance(plan["user_profile"], str) else plan["user_profile"]
        
        # Create agent for corrections
        thread_id = f"correct_{request.user_id}_{uuid.uuid4().hex[:8]}"
        agent = create_fitness_agent(thread_id)
        skills_files = load_skills()
        
        corrected_workout = current_workout
        corrected_meal = current_meal
        
        # Correct workout plan if requested
        if request.plan_type in ["workout", "both"]:
            workout_correction_prompt = f"""
The user wants to make corrections to their workout plan.

USER ID: {request.user_id}
USER PROFILE: {json.dumps(user_profile, indent=2)}

CURRENT WORKOUT PLAN:
{json.dumps(current_workout, indent=2)}

CORRECTION INSTRUCTION:
{request.instruction}

Please use the workout-planner subagent to apply the requested corrections.
The subagent should fetch the current plan using fetch_current_workout_plan tool,
then modify it according to the instruction while keeping the same JSON structure.
Return ONLY the corrected JSON workout plan.
"""
            
            workout_response = invoke_agent_with_retry(
                agent,
                {
                    "messages": [{"role": "user", "content": workout_correction_prompt}],
                    "files": skills_files
                },
                thread_id=thread_id
            )
            workout_text = workout_response["messages"][-1].content if workout_response.get("messages") else ""
            corrected_workout = extract_json_from_response(workout_text)
            
            time.sleep(2)
        
        # Correct meal plan if requested
        if request.plan_type in ["meal", "both"]:
            meal_correction_prompt = f"""
The user wants to make corrections to their meal plan.

USER ID: {request.user_id}
USER PROFILE: {json.dumps(user_profile, indent=2)}

CURRENT MEAL PLAN:
{json.dumps(current_meal, indent=2)}

CORRECTION INSTRUCTION:
{request.instruction}

Please use the meal-planner subagent to apply the requested corrections.
The subagent should fetch the current plan using fetch_current_meal_plan tool,
then modify it according to the instruction while keeping the same JSON structure.
Return ONLY the corrected JSON meal plan.
"""
            
            meal_response = invoke_agent_with_retry(
                agent,
                {
                    "messages": [{"role": "user", "content": meal_correction_prompt}],
                    "files": skills_files
                },
                thread_id=thread_id
            )
            meal_text = meal_response["messages"][-1].content if meal_response.get("messages") else ""
            corrected_meal = extract_json_from_response(meal_text)
        
        # Update the plan in Supabase
        await update_plan_in_supabase(
            plan_id=plan_id,
            workout_plan=corrected_workout if request.plan_type in ["workout", "both"] else None,
            meal_plan=corrected_meal if request.plan_type in ["meal", "both"] else None
        )
        
        return CorrectionResponse(
            id=plan_id,
            user_id=request.user_id,
            workout_plan=corrected_workout if request.plan_type in ["workout", "both"] else None,
            meal_plan=corrected_meal if request.plan_type in ["meal", "both"] else None,
            correction_applied=request.instruction,
            updated_at=datetime.utcnow().isoformat()
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error correcting plan: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to correct plan: {str(e)}")


@app.get("/plan/{plan_id}")
async def get_plan(plan_id: str):
    """Retrieve a previously generated plan by ID."""
    try:
        result = supabase.table("fitness_plans").select("*").eq("id", plan_id).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="Plan not found")
        
        plan = result.data[0]
        return {
            "id": plan["id"],
            "user_id": plan["user_id"],
            "user_profile": json.loads(plan["user_profile"]),
            "workout_plan": json.loads(plan["workout_plan"]),
            "meal_plan": json.loads(plan["meal_plan"]),
            "created_at": plan["created_at"]
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve plan: {str(e)}")


@app.get("/plans")
async def list_plans(limit: int = 10, offset: int = 0, user_id: Optional[str] = None):
    """List all generated plans with pagination. Optionally filter by user_id."""
    try:
        query = supabase.table("fitness_plans")\
            .select("id, user_id, goal, created_at")\
            .order("created_at", desc=True)
        
        if user_id:
            query = query.eq("user_id", user_id)
        
        result = query.range(offset, offset + limit - 1).execute()
        
        return {
            "plans": result.data,
            "limit": limit,
            "offset": offset
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list plans: {str(e)}")


@app.delete("/plan/{plan_id}")
async def delete_plan(plan_id: str):
    """Delete a plan by ID."""
    try:
        result = supabase.table("fitness_plans").delete().eq("id", plan_id).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="Plan not found")
        
        return {"message": "Plan deleted successfully", "id": plan_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete plan: {str(e)}")


# ==================== Run Server ====================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "mani:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
