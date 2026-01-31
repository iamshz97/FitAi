import os
import json
import uuid
import time
import pathlib
from datetime import datetime
from typing import Optional, Any
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from tenacity import retry, stop_after_attempt, wait_exponential
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from supabase import create_client, Client

# Import model configuration
from model_config import (
    MODEL_NAME,
    validate_api_keys,
    client as openai_client
)

# Import prompts
from prompts import (
    REASONING_SUBAGENT_SYSTEM_PROMPT,
    WORKOUT_SUBAGENT_SYSTEM_PROMPT,
    MEAL_SUBAGENT_SYSTEM_PROMPT,
    COORDINATOR_SYSTEM_PROMPT
)

# Import Pydantic models
from models import (
    UserProfile,
    WorkoutDay,
    WorkoutPlan,
    Meal,
    DailyMealPlan,
    MealPlan,
    PlanResponse,
    TextProfileRequest,
    SimplePlanResponse,
    CorrectionRequest,
    CorrectionResponse,
    ReasoningOutput,
    BodyComposition,
    MedicalHistory,
    PsychologicalFactors,
    Constraints,
    ComprehensiveProfile,
    AnalysisResponse
)

# Load environment variables
load_dotenv()

# Initialize Supabase client
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

supabase: Client = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    global supabase
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise ValueError("SUPABASE_URL and SUPABASE_KEY must be set in environment variables")
    
    # Validate API keys for the configured model
    validate_api_keys()
    
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    print(f"✅ Connected to Supabase")
    print(f"🤖 Using model: {MODEL_NAME}")
    yield
    print("👋 Shutting down...")


# Initialize FastAPI app
app = FastAPI(
    title="FitAI - Personalized Fitness & Meal Planner",
    description="AI-powered workout and meal plan generator using OpenAI SDK",
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


# ==================== OpenAI Tool Schemas ====================

FIT_TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "calculate_bmr",
            "description": "Calculate Basal Metabolic Rate using Mifflin-St Jeor equation.",
            "parameters": {
                "type": "object",
                "properties": {
                    "age": {"type": "integer"},
                    "gender": {"type": "string", "enum": ["male", "female"]},
                    "height": {"type": "number", "description": "Height in cm"},
                    "weight": {"type": "number", "description": "Weight in kg"},
                },
                "required": ["age", "gender", "height", "weight"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "calculate_tdee",
            "description": "Calculate Total Daily Energy Expenditure.",
            "parameters": {
                "type": "object",
                "properties": {
                    "bmr": {"type": "number"},
                    "activity_level": {"type": "string", "enum": ["beginner", "intermediate", "advanced"]},
                },
                "required": ["bmr", "activity_level"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_calorie_target",
            "description": "Get daily calorie target based on goal.",
            "parameters": {
                "type": "object",
                "properties": {
                    "tdee": {"type": "number"},
                    "goal": {"type": "string", "enum": ["weight_loss", "muscle_gain", "maintenance", "endurance", "flexibility", "general_fitness"]},
                },
                "required": ["tdee", "goal"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "fetch_current_workout_plan",
            "description": "Fetch the user's current workout plan from the database.",
            "parameters": {
                "type": "object",
                "properties": {
                    "user_id": {"type": "string"},
                },
                "required": ["user_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "fetch_current_meal_plan",
            "description": "Fetch the user's current meal plan from the database.",
            "parameters": {
                "type": "object",
                "properties": {
                    "user_id": {"type": "string"},
                },
                "required": ["user_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "fetch_user_profile",
            "description": "Fetch the user's profile from their most recent plan.",
            "parameters": {
                "type": "object",
                "properties": {
                    "user_id": {"type": "string"},
                },
                "required": ["user_id"],
            },
        },
    }
]

# Tool mapper
TOOL_MAP = {
    "calculate_bmr": calculate_bmr,
    "calculate_tdee": calculate_tdee,
    "get_calorie_target": get_calorie_target,
    "fetch_current_workout_plan": fetch_current_workout_plan,
    "fetch_current_meal_plan": fetch_current_meal_plan,
    "fetch_user_profile": fetch_user_profile,
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


@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=2, min=4, max=30),
    reraise=True
)
def call_openai_with_tools(messages: list, system_prompt: str = None, tools: list = None) -> str:
    """Helper function to call OpenAI with tool support."""
    all_messages = []
    if system_prompt:
        all_messages.append({"role": "system", "content": system_prompt})
    all_messages.extend(messages)
    
    response = openai_client.chat.completions.create(
        model=MODEL_NAME,
        messages=all_messages,
        tools=tools,
        tool_choice="auto" if tools else None
    )
    
    response_message = response.choices[0].message
    tool_calls = response_message.tool_calls
    
    if tool_calls:
        all_messages.append(response_message)
        for tool_call in tool_calls:
            function_name = tool_call.function.name
            function_to_call = TOOL_MAP.get(function_name)
            function_args = json.loads(tool_call.function.arguments)
            
            print(f"🛠️ Calling tool: {function_name} with {function_args}")
            function_response = function_to_call(**function_args)
            
            all_messages.append({
                "tool_call_id": tool_call.id,
                "role": "tool",
                "name": function_name,
                "content": json.dumps(function_response),
            })
        
        # Call again with tool results
        second_response = openai_client.chat.completions.create(
            model=MODEL_NAME,
            messages=all_messages,
        )
        return second_response.choices[0].message.content
    
    return response_message.content


def extract_message_content(content) -> str:
    """Extract text content from message content which may be string or list of parts."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        # Handle list of content parts (common with Gemini and other models)
        text_parts = []
        for part in content:
            if isinstance(part, str):
                text_parts.append(part)
            elif isinstance(part, dict):
                # Handle {"type": "text", "text": "..."} format
                if part.get("type") == "text" and "text" in part:
                    text_parts.append(part["text"])
                elif "text" in part:
                    text_parts.append(part["text"])
            elif hasattr(part, "text"):
                # Handle object with text attribute
                text_parts.append(part.text)
        return "\n".join(text_parts)
    # Fallback: convert to string
    return str(content) if content else ""


def extract_json_from_response(response_text, debug_label: str = "") -> dict:
    """Extract JSON from agent response text."""
    # First ensure we have a string
    if not isinstance(response_text, str):
        response_text = extract_message_content(response_text)
    
    # Try to parse directly first
    try:
        result = json.loads(response_text)
        print(f"📋 {debug_label} JSON parsed directly")
        return result
    except json.JSONDecodeError:
        pass
    
    # Try to find JSON block in the response
    import re
    
    # First try to find ```json blocks
    json_block_pattern = r'```json\s*([\s\S]*?)\s*```'
    matches = re.findall(json_block_pattern, response_text)
    
    if matches:
        print(f"📋 {debug_label} Found {len(matches)} JSON blocks")
        for i, match in enumerate(matches):
            try:
                result = json.loads(match)
                print(f"📋 {debug_label} Successfully parsed JSON block {i+1}, keys: {list(result.keys())}")
                return result
            except json.JSONDecodeError as e:
                print(f"📋 {debug_label} JSON block {i+1} parse error: {e}")
                continue
    
    # Try generic code blocks
    code_block_pattern = r'```\s*([\s\S]*?)\s*```'
    matches = re.findall(code_block_pattern, response_text)
    
    if matches:
        print(f"📋 {debug_label} Found {len(matches)} code blocks")
        for i, match in enumerate(matches):
            try:
                result = json.loads(match)
                print(f"📋 {debug_label} Successfully parsed code block {i+1}")
                return result
            except json.JSONDecodeError:
                continue
    
    # Try to find raw JSON object
    json_object_pattern = r'\{[\s\S]*\}'
    match = re.search(json_object_pattern, response_text)
    if match:
        try:
            result = json.loads(match.group())
            print(f"📋 {debug_label} Successfully parsed raw JSON object")
            return result
        except json.JSONDecodeError:
            pass
    
    # Return as-is if parsing fails
    print(f"📋 {debug_label} No valid JSON found, returning raw_response")
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
        
        # Run the Reasoning Agent
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
        
        reasoning_text = call_openai_with_tools(
            messages=[{"role": "user", "content": reasoning_prompt}],
            system_prompt=REASONING_SUBAGENT_SYSTEM_PROMPT,
            tools=FIT_TOOLS
        )
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


@app.post("/generate-plan", response_model=SimplePlanResponse)
async def generate_plan(request: TextProfileRequest):
    """
    Generate personalized workout and meal plans based on text profile description.
    """
    try:
        # STEP 1: Run the Reasoning Agent to generate task instructions
        print(f"🧠 Step 1: Running task-reasoner to generate task instructions...")
        
        reasoning_prompt = f"""
Analyze the following user profile and generate detailed TASK INSTRUCTIONS for the workout and meal planning agents.

**PROFILE:**
{request.profile}

Generate comprehensive task instructions that cover:
1. Pre-participation assessment requirements
2. Exercise prescription tasks (using FITT-VP principles)
3. Nutrition prescription tasks
4. Behavioral & lifestyle tasks
5. Monitoring & adaptation tasks

Remember: You are ONLY generating instructions/tasks - NOT making conclusions or creating plans.
Return the task instructions as structured markdown text.
"""
        
        task_instructions = call_openai_with_tools(
            messages=[{"role": "user", "content": reasoning_prompt}],
            system_prompt=REASONING_SUBAGENT_SYSTEM_PROMPT,
            tools=FIT_TOOLS
        )
        
        print(f"✅ Task instructions generated ({len(task_instructions)} chars)")
        
        # STEP 2: Generate Workout Plan
        print(f"💪 Step 2: Running workout-planner...")
        
        workout_prompt = f"""
{request.profile}

**TASK:**
{task_instructions}
"""
        
        workout_text = call_openai_with_tools(
            messages=[{"role": "user", "content": workout_prompt}],
            system_prompt=WORKOUT_SUBAGENT_SYSTEM_PROMPT,
            tools=FIT_TOOLS
        )
        
        print(f"📋 Extracted workout text (first 500 chars): {workout_text[:500] if workout_text else 'EMPTY'}")
        workout_plan = extract_json_from_response(workout_text, "Workout")
        
        # Ensure we have a summary field with actual content
        if "summary" not in workout_plan or not workout_plan.get("summary"):
            if workout_text:
                workout_plan = {"summary": workout_text}
            elif "raw_response" in workout_plan:
                workout_plan = {"summary": workout_plan["raw_response"]}
        
        print(f"✅ Workout plan generated")
        
        # Add delay between requests
        time.sleep(2)
        
        # STEP 3: Generate Meal Plan
        print(f"🍎 Step 3: Running meal-planner...")
        
        meal_prompt = f"""
{request.profile}

**TASK:**
{task_instructions}
"""
        
        meal_text = call_openai_with_tools(
            messages=[{"role": "user", "content": meal_prompt}],
            system_prompt=MEAL_SUBAGENT_SYSTEM_PROMPT,
            tools=FIT_TOOLS
        )
        
        print(f"📋 Extracted meal text (first 500 chars): {meal_text[:500] if meal_text else 'EMPTY'}")
        meal_plan = extract_json_from_response(meal_text, "Meal")
        
        # Ensure we have a summary field with actual content
        if "summary" not in meal_plan or not meal_plan.get("summary"):
            if meal_text:
                meal_plan = {"summary": meal_text}
            elif "raw_response" in meal_plan:
                meal_plan = {"summary": meal_plan["raw_response"]}
        
        print(f"✅ Meal plan generated")
        print(f"🎉 All plans generated successfully!")
        
        # Generate unique ID for this plan
        plan_id = str(uuid.uuid4())
        
        # Save to Supabase
        await save_to_supabase(
            plan_id=plan_id,
            user_id=request.user_id,
            user_profile={"profile_text": request.profile},
            reasoning_analysis={"task_instructions": task_instructions},
            workout_plan=workout_plan,
            meal_plan=meal_plan
        )
        
        return SimplePlanResponse(
            id=plan_id,
            user_id=request.user_id,
            profile=request.profile,
            task_instructions=task_instructions,
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

Please apply the requested corrections. Modify the plan according to the instruction while keeping the same JSON structure.
Return ONLY the corrected JSON workout plan.
"""
            
            workout_text = call_openai_with_tools(
                messages=[{"role": "user", "content": workout_correction_prompt}],
                system_prompt=WORKOUT_SUBAGENT_SYSTEM_PROMPT,
                tools=FIT_TOOLS
            )
            corrected_workout = extract_json_from_response(workout_text)
        
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

Please apply the requested corrections. Modify the plan according to the instruction while keeping the same JSON structure.
Return ONLY the corrected JSON meal plan.
"""
            
            meal_text = call_openai_with_tools(
                messages=[{"role": "user", "content": meal_correction_prompt}],
                system_prompt=MEAL_SUBAGENT_SYSTEM_PROMPT,
                tools=FIT_TOOLS
            )
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
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
