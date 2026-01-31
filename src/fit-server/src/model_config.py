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

# Model configuration
MODEL_NAME = "gpt-4o"

def validate_api_keys() -> None:
    """Validate that the required API key is set."""
    if not OPENAI_API_KEY:
        raise ValueError("OPENAI_API_KEY must be set in environment variables")

# Initialize OpenAI client
client = OpenAI(api_key=OPENAI_API_KEY)
