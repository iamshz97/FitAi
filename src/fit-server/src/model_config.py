"""
Model configuration for FitAI.
"""

import os
from dotenv import load_dotenv
from langchain.chat_models import init_chat_model

# Load environment variables
load_dotenv()

# API Keys
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

# Model configuration - set via environment variable or default to OpenAI
# Format: "provider:model_name"
# Examples: "openai:gpt-4o-mini", "openai:gpt-4o", "google_genai:gemini-2.0-flash", "google_genai:gemini-1.5-pro anthropic:claude-sonnet-4-5-20250929"
DEFAULT_MODEL_CONFIG = os.getenv("FIT_AI_MODEL", "google_genai:gemini-2.5-flash")


def parse_model_config(config: str) -> tuple[str, str]:
    """Parse model config string into (provider, model_name)."""
    if ":" in config:
        provider, model_name = config.split(":", 1)
        return provider, model_name
    # Default to openai if no provider specified
    return "openai", config


def get_model_info() -> tuple[str, str]:
    """Get the current model provider and name."""
    return parse_model_config(DEFAULT_MODEL_CONFIG)


def create_model():
    """Create and return the configured chat model."""
    provider, model_name = parse_model_config(DEFAULT_MODEL_CONFIG)
    return init_chat_model(model=model_name, model_provider=provider)


def validate_api_keys(provider: str) -> None:
    """Validate that the required API key is set for the given provider."""
    if provider == "openai" and not OPENAI_API_KEY:
        raise ValueError("OPENAI_API_KEY must be set when using OpenAI models")
    if provider in ["google_genai", "google_vertexai"] and not GOOGLE_API_KEY:
        raise ValueError("GOOGLE_API_KEY must be set when using Google Gemini models")


# Initialize model provider and name
MODEL_PROVIDER, MODEL_NAME = get_model_info()

# Initialize the chat model with provider
DEFAULT_MODEL = create_model()
