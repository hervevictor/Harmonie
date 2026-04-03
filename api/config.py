from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # Supabase
    SUPABASE_URL: str
    SUPABASE_SERVICE_KEY: str
    SUPABASE_JWT_SECRET: str

    # IA APIs
    ANTHROPIC_API_KEY: str
    OPENAI_API_KEY: str
    ACRCLOUD_HOST: str
    ACRCLOUD_ACCESS_KEY: str
    ACRCLOUD_SECRET_KEY: str

    # Storage
    STORAGE_BUCKET_FILES: str = "music-files"
    STORAGE_BUCKET_MIDI: str = "midi-outputs"
    STORAGE_BUCKET_AUDIO: str = "generated-audio"
    STORAGE_BUCKET_SCORES: str = "sheet-music"

    # App
    APP_ENV: str = "development"
    APP_PORT: int = 8000
    MAX_FILE_SIZE_MB: int = 100
    TEMP_DIR: str = "/tmp/music_api"

    class Config:
        env_file = ".env"

@lru_cache()
def get_settings() -> Settings:
    return Settings()

settings = get_settings()
