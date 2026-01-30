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
    age: int = Field(..., ge=13, le=100, description="User's age in years")
    gender: Literal["male", "female", "other"] = Field(..., description="User's gender")
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
    user_profile: UserProfile
    workout_plan: dict
    meal_plan: dict
    created_at: str


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


# ==================== Subagent Definitions ====================

workout_subagent = {
    "name": "workout-planner",
    "description": "Creates personalized workout plans based on user profile, fitness goals, available days, and any injuries or limitations. Generates structured JSON workout plans.",
    "system_prompt": """You are an expert certified personal trainer and fitness coach. Your job is to create personalized, safe, and effective workout plans.

IMPORTANT GUIDELINES:
1. Always consider any injuries or physical limitations mentioned
2. Match exercise intensity to the user's fitness level
3. Include proper warm-up and cool-down routines
4. Balance muscle groups throughout the week
5. Provide clear exercise instructions with sets, reps, and rest periods

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
    "tips": ["list of helpful tips for the user"]
}

Return ONLY the JSON object, no additional text or markdown formatting.""",
    "tools": [calculate_bmr, calculate_tdee],
    "model": "openai:gpt-4o-mini",
}

meal_subagent = {
    "name": "meal-planner",
    "description": "Creates personalized meal plans based on user profile, fitness goals, calorie needs, and dietary restrictions. Generates structured JSON meal plans.",
    "system_prompt": """You are an expert nutritionist and meal planning specialist. Your job is to create personalized, balanced, and achievable meal plans.

IMPORTANT GUIDELINES:
1. Always respect dietary restrictions mentioned
2. Calculate appropriate macros based on the fitness goal
3. Create practical, easy-to-prepare meals
4. Ensure nutritional balance across all meals
5. Include variety to maintain interest
6. Provide a comprehensive shopping list

MACRO GUIDELINES BY GOAL:
- Weight Loss: 40% protein, 30% carbs, 30% fat
- Muscle Gain: 30% protein, 45% carbs, 25% fat
- Maintenance: 25% protein, 45% carbs, 30% fat
- Endurance: 20% protein, 55% carbs, 25% fat

OUTPUT FORMAT:
You MUST return a valid JSON object with this exact structure:
{
    "plan_name": "string - descriptive name for the plan",
    "description": "string - brief overview of the plan",
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
    "tips": ["list of helpful nutrition and meal prep tips"]
}

Return ONLY the JSON object, no additional text or markdown formatting.""",
    "tools": [calculate_bmr, calculate_tdee, get_calorie_target],
    "model": "openai:gpt-4o-mini",
}


# ==================== Main Agent ====================

def create_fitness_agent():
    """Create the main fitness planning agent with subagents."""
    return create_deep_agent(
        model="openai:gpt-4o-mini",
        name="fitness-coordinator",
        system_prompt="""You are FitAI, an intelligent fitness and nutrition coordinator. Your job is to orchestrate the creation of personalized workout and meal plans.

WORKFLOW:
1. Analyze the user's profile data (age, gender, height, weight, goal, etc.)
2. Delegate workout plan creation to the workout-planner subagent
3. Delegate meal plan creation to the meal-planner subagent
4. Ensure both plans are aligned with the user's goals

IMPORTANT:
- Always delegate to specialized subagents using the task() tool
- The workout-planner handles all exercise-related planning
- The meal-planner handles all nutrition-related planning
- Ensure plans account for any injuries or dietary restrictions mentioned

When delegating tasks, provide all relevant user profile information to each subagent.""",
        subagents=[workout_subagent, meal_subagent]
    )


# ==================== Helper Functions ====================

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=2, min=4, max=30),
    reraise=True
)
def invoke_agent_with_retry(agent, messages: dict):
    """Invoke agent with retry logic for rate limits."""
    return agent.invoke(messages)


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


async def save_to_supabase(plan_id: str, user_profile: dict, workout_plan: dict, meal_plan: dict) -> dict:
    """Save the generated plans to Supabase."""
    try:
        data = {
            "id": plan_id,
            "user_profile": json.dumps(user_profile),
            "workout_plan": json.dumps(workout_plan),
            "meal_plan": json.dumps(meal_plan),
            "created_at": datetime.utcnow().isoformat()
        }
        
        result = supabase.table("fitness_plans").insert(data).execute()
        return result.data[0] if result.data else data
    except Exception as e:
        print(f"Error saving to Supabase: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to save plan: {str(e)}")


# ==================== API Endpoints ====================

@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "FitAI - Personalized Fitness & Meal Planner",
        "version": "1.0.0"
    }


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
        # Create the fitness agent
        agent = create_fitness_agent()
        
        # Calculate metabolic data
        bmr = calculate_bmr(profile.age, profile.gender, profile.height, profile.weight)
        tdee = calculate_tdee(bmr, profile.intensity)
        calorie_target = get_calorie_target(tdee, profile.goal)
        
        # Prepare the prompt for the agent
        user_data = f"""
Please create a comprehensive fitness plan for the following user:

USER PROFILE:
- Age: {profile.age} years
- Gender: {profile.gender}
- Height: {profile.height} cm
- Weight: {profile.weight} kg
- Fitness Goal: {profile.goal.replace('_', ' ')}
- Days Available for Exercise: {profile.days_per_week} days/week
- Fitness Level: {profile.intensity}
- Injuries/Limitations: {profile.injuries or 'None'}
- Dietary Restrictions: {profile.dietary_restrictions or 'None'}

CALCULATED METRICS:
- BMR (Basal Metabolic Rate): {bmr} calories/day
- TDEE (Total Daily Energy Expenditure): {tdee} calories/day
- Recommended Daily Calorie Target: {calorie_target} calories/day

Please:
1. Use the workout-planner subagent to create a {profile.days_per_week}-day workout plan
2. Use the meal-planner subagent to create a 7-day meal plan with {calorie_target} calories/day target

Ensure both plans are returned as valid JSON objects.
"""
        
        # Run the agent
        workout_plan = {}
        meal_plan = {}
        
        # Generate workout plan
        workout_prompt = f"""
Create a personalized workout plan for:
- Age: {profile.age}, Gender: {profile.gender}
- Height: {profile.height}cm, Weight: {profile.weight}kg
- Goal: {profile.goal.replace('_', ' ')}
- Days/week: {profile.days_per_week}
- Level: {profile.intensity}
- Injuries: {profile.injuries or 'None'}

Return ONLY a valid JSON object.
"""
        
        workout_response = invoke_agent_with_retry(agent, {"messages": [{"role": "user", "content": f"Use the workout-planner subagent for this task: {workout_prompt}"}]})
        workout_text = workout_response["messages"][-1].content if workout_response.get("messages") else ""
        workout_plan = extract_json_from_response(workout_text)
        
        # Add small delay between requests to avoid rate limits
        time.sleep(2)
        
        # Generate meal plan
        meal_prompt = f"""
Create a personalized meal plan for:
- Age: {profile.age}, Gender: {profile.gender}
- Height: {profile.height}cm, Weight: {profile.weight}kg
- Goal: {profile.goal.replace('_', ' ')}
- Daily Calories: {calorie_target}
- Dietary Restrictions: {profile.dietary_restrictions or 'None'}

Return ONLY a valid JSON object.
"""
        
        meal_response = invoke_agent_with_retry(agent, {"messages": [{"role": "user", "content": f"Use the meal-planner subagent for this task: {meal_prompt}"}]})
        meal_text = meal_response["messages"][-1].content if meal_response.get("messages") else ""
        meal_plan = extract_json_from_response(meal_text)
        
        # Generate unique ID for this plan
        plan_id = str(uuid.uuid4())
        
        # Save to Supabase
        await save_to_supabase(
            plan_id=plan_id,
            user_profile=profile.model_dump(),
            workout_plan=workout_plan,
            meal_plan=meal_plan
        )
        
        return PlanResponse(
            id=plan_id,
            user_profile=profile,
            workout_plan=workout_plan,
            meal_plan=meal_plan,
            created_at=datetime.utcnow().isoformat()
        )
        
    except Exception as e:
        print(f"Error generating plan: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate plan: {str(e)}")


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
async def list_plans(limit: int = 10, offset: int = 0):
    """List all generated plans with pagination."""
    try:
        result = supabase.table("fitness_plans")\
            .select("id, created_at")\
            .order("created_at", desc=True)\
            .range(offset, offset + limit - 1)\
            .execute()
        
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
