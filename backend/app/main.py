import asyncio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.config import get_settings
from routers.auth import router as auth_router
from routers.users import router as users_router
from routers.diaries import router as diaries_router

settings = get_settings()

# Windows Python 3.13 이벤트 루프 호환성 문제 대응: Proactor 대신 Selector 사용
try:
    if hasattr(asyncio, "WindowsSelectorEventLoopPolicy"):
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
except Exception:
    pass

app = FastAPI(title="Mindrium API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health():
    return {"status": "ok"}

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(diaries_router)
