import os
import asyncio
from dotenv import load_dotenv
from supabase import create_client
from user_repository import UserProfileRepository

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

async def main():
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("Skipping test: SUPABASE_URL or SUPABASE_KEY not set")
        return

    print("Connecting to Supabase...")
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    repo = UserProfileRepository(supabase)
    
    # Use a dummy UUID to check if the query runs without syntax errors
    # It should return None
    dummy_id = "00000000-0000-0000-0000-000000000000"
    print(f"Fetching profile for {dummy_id}...")
    
    try:
        profile = repo.get_user_profile_by_id(dummy_id)
        print(f"Result: {profile}")
    except Exception as e:
        print(f"Error calling get_user_profile_by_id: {e}")

if __name__ == "__main__":
    asyncio.run(main())
