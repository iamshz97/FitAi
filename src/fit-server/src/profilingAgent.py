from user_repository import UserProfileRepository

class ProfilingAgent:
    def __init__(self, user_repository: UserProfileRepository):
        self.user_repository = user_repository

    def get_profile(self, user_id: str):
        """
        Retrieves user profile using UserProfileRepository.
        """
        user_profile = self.user_repository.get_user_profile_by_id(user_id)
        if user_profile:
             return user_profile.model_dump()
        return {"error": "User profile not found"}

    def get_all_profiles(self):
        """
        Retrieves all user profiles.
        """
        print("[DEBUG] ProfilingAgent.get_all_profiles called")
        profiles = self.user_repository.get_all_user_profiles()
        print(f"[DEBUG] ProfilingAgent received {len(profiles)} profiles from repo")
        return [profile.model_dump() for profile in profiles]

    def post_profile(self, payload: dict):
        """
        Mock method to receive a profile payload.
        """
        return {
            "status": "received",
            "received_payload": payload,
            "processed_at": "2024-01-01T12:05:00Z"
        }
