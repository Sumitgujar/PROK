from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    mongodb_url: str = "mongodb://localhost:27017"
    database_name: str = "prok_db"
    secret_key: str = "prok-secret-key-please-change"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    upload_dir: str = "uploads"
    max_file_size: int = 10485760
    class Config:
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()

settings = get_settings()
