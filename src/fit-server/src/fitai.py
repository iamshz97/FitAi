from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
from dotenv import load_dotenv
from supabase import create_client
from profilingAgent import ProfilingAgent
from user_repository import UserProfileRepository

from contextlib import asynccontextmanager
from typing import Optional
from supabase import Client

# Global variables
supabase: Optional[Client] = None
user_repository: Optional[UserProfileRepository] = None
profiling_agent: Optional[ProfilingAgent] = None

import pathlib

@asynccontextmanager
async def lifespan(app: FastAPI):
    global supabase, user_repository, profiling_agent
    
    # Load .env from parent directory (fit-server/.env, not fit-server/src/.env)
    env_path = pathlib.Path(__file__).parent.parent / ".env"
    print(f"[DEBUG] Loading .env from: {env_path}")
    load_dotenv(dotenv_path=env_path)
    
    # Initialize Supabase client
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_KEY = os.getenv("SUPABASE_KEY")
    print(f"[DEBUG] SUPABASE_KEY: {SUPABASE_KEY}")
    print(f"[DEBUG] SUPABASE_URL: {SUPABASE_URL}")

    if not SUPABASE_URL or not SUPABASE_KEY:
        print("Warning: SUPABASE_URL and SUPABASE_KEY must be set in environment variables")
        supabase = None
    else:
        # Standard client for general use (respects RLS)
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

    # Initialize Repository and Agent
    if supabase:
        user_repository = UserProfileRepository(supabase)
        profiling_agent = ProfilingAgent(user_repository)
        print("✅ Supabase and Agents initialized successfully")
    else:
        print("❌ Failed to initialize Supabase credentials")
        # Ensure we don't crash on startup but endpoints might fail
    
    yield
    print("👋 Shutting down...")

app = FastAPI(lifespan=lifespan)

class ProfilingRequest(BaseModel):
    user_id: str
    profile_data: str

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get("/profiling/{user_id}")
async def get_user_profile(user_id: str):
    """Get a user profile by ID"""
    profile = profiling_agent.get_profile(user_id)
    if "error" in profile:
        raise HTTPException(status_code=404, detail=profile["error"])
    return profile

@app.get("/profiles")
async def get_all_profiles():
    """Get all user profiles"""
    print("[DEBUG] GET /profiles endpoint hit")
    result = profiling_agent.get_all_profiles()
    print(f"[DEBUG] GET /profiles result count: {len(result)}")
    return result

@app.post("/profiling")
async def create_profiling(request: ProfilingRequest):
    return profiling_agent.post_profile(request.model_dump())
