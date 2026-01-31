"""
Model configuration for FitAI.
"""

import os
from dotenv import load_dotenv
from openai import OpenAI

# Load environment variables
load_dotenv()

# API Keys
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

<<<<<<< HEAD
# Model configuration
MODEL_NAME = "gpt-4o"
=======
# Model configuration - set via environment variable or default to OpenAI
# Format: "provider:model_name"
# Examples: "openai:gpt-4o-mini", "openai:gpt-4o", "google_genai:gemini-2.0-flash", "google_genai:gemini-1.5-pro anthropic:claude-sonnet-4-5-20250929"
DEFAULT_MODEL_CONFIG = os.getenv("FIT_AI_MODEL", "google_genai:gemini-2.5-flash")
>>>>>>> 1c1764bb1bcbe2869abf439040544dac8249ec7f

def validate_api_keys() -> None:
    """Validate that the required API key is set."""
    if not OPENAI_API_KEY:
        raise ValueError("OPENAI_API_KEY must be set in environment variables")

# Initialize OpenAI client
client = OpenAI(api_key=OPENAI_API_KEY)
