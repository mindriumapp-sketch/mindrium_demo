import asyncio
import json
from datetime import datetime, timezone

import httpx
from main import app  # run from backend/app directory

async def main():
    # Use timezone-aware UTC to avoid deprecation warnings
    email = f"test_{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}@example.com"
    payload = {"email": email, "password": "Passw0rd!", "name": "테스트", "gender": "male"}
    async with httpx.AsyncClient(app=app, base_url="http://testserver") as client:
        # health
        r = await client.get("/health")
        print("/health:", r.status_code, r.json())
        # signup
        r = await client.post("/auth/signup", json=payload)
        print("/auth/signup:", r.status_code, r.json())
        # login
        r = await client.post("/auth/login", json={"email": email, "password": "Passw0rd!"})
        print("/auth/login:", r.status_code, r.json())
        if r.status_code == 200:
            tokens = r.json()
            access = tokens.get("access_token")
            # me
            r = await client.get("/users/me", headers={"Authorization": f"Bearer {access}"})
            print("/users/me:", r.status_code, r.json())

if __name__ == "__main__":
    # On Windows + Python 3.13, SelectorEventLoop can fail (WinError 10014).
    # Prefer Proactor policy for this in-process check.
    try:
        if hasattr(asyncio, "WindowsProactorEventLoopPolicy"):
            asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
    except Exception:
        pass
    asyncio.run(main())
