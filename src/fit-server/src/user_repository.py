from typing import Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel
from supabase import Client

class UserProfile(BaseModel):
    id: UUID
    onboarding_completed: Optional[bool] = False
    onboarding_step: Optional[int] = 0
    birth_year: Optional[int] = None
    sex_at_birth: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    bmi: Optional[float] = None
    goal: Optional[str] = None
    activity_level: Optional[str] = None
    days_per_week: Optional[int] = None
    minutes_per_session: Optional[int] = None
    equipment_context: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    email: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    body_fat_percentage: Optional[float] = None
    medical_history: Optional[str] = None
    family_medical_history: Optional[str] = None
    current_injuries: Optional[str] = None
    fitness_goals_text: Optional[str] = None
    training_constraints: Optional[str] = None
    sleep_pattern: Optional[str] = None

class UserProfileRepository:
    def __init__(self, supabase_client: Client):
        self.supabase = supabase_client

    def get_user_profile_by_id(self, user_id: str) -> Optional[UserProfile]:
        """
        Retrieves a user profile by ID from the user_profiles table.
        Returns a UserProfile object if found, otherwise None.
        """
        try:
            response = self.supabase.table("user_profiles") \
                .select("*") \
                .eq("id", user_id) \
                .single() \
                .execute()
            
            if response.data:
                return UserProfile(**response.data)
            return None
        except Exception as e:
            # Handle exceptions appropriately, maybe log them or re-raise
            # For now, print error and return None as a basic error handling strategy
            print(f"Error retrieving user profile: {e}")
            return None
    def get_all_user_profiles(self) -> list[UserProfile]:
        """
        Retrieves all user profiles from the user_profiles table.
        Returns a list of UserProfile objects.
        """
        print("[DEBUG] get_all_user_profiles called")
        try:
            print("[DEBUG] Executing Supabase query: table('user_profiles').select('*')")
            response = self.supabase.table("user_profiles") \
                .select("*") \
                .execute()
            
            print(f"[DEBUG] Supabase response raw: {response}")
            
            if response.data:
                print(f"[DEBUG] Found {len(response.data)} profiles")
                profiles = []
                for p in response.data:
                    try:
                        profiles.append(UserProfile(**p))
                    except Exception as val_err:
                        print(f"[DEBUG] Validation error for profile {p.get('id')}: {val_err}")
                return profiles
            else:
                print("[DEBUG] No data in response")
                return []
        except Exception as e:
            print(f"[DEBUG] Error retrieving all user profiles: {e}")
            import traceback
            traceback.print_exc()
            return []
