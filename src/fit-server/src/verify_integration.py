import sys
import os
from dotenv import load_dotenv

# Ensure we can import from src
sys.path.append("c:/Projects/AiAgent/FitAi/FitAi/src/fit-server/src")

load_dotenv()

def verify_integration():
    try:
        from fitai import profiling_agent, user_repository
        from user_repository import UserProfileRepository
        
        print("Successfully imported fitai module.")
        
        if hasattr(profiling_agent, 'user_repository'):
            print("ProfilingAgent has 'user_repository' attribute.")
            if isinstance(profiling_agent.user_repository, UserProfileRepository):
                print("ProfilingAgent.user_repository is instance of UserProfileRepository.")
            else:
                print(f"Warning: ProfilingAgent.user_repository is {type(profiling_agent.user_repository)}")
        
        else:
            print("Error: ProfilingAgent missing 'user_repository' attribute.")
            
        print("Integration verification passed structure checks.")
        
    except ImportError as e:
        print(f"ImportError: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    verify_integration()
