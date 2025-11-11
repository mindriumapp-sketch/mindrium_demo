from motor.motor_asyncio import AsyncIOMotorClient
from core.config import get_settings
from functools import lru_cache

@lru_cache
def get_client() -> AsyncIOMotorClient:
    settings = get_settings()
    return AsyncIOMotorClient(settings.mongo_uri)

def get_db():
    settings = get_settings()
    client = get_client()
    return client[settings.mongo_db]
