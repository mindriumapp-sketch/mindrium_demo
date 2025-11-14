from fastapi import APIRouter, Depends, HTTPException, Header
from db.mongo import get_db
from schemas.user import UserMe, UpdateUser
from core.security import decode_token
from datetime import datetime, timezone

router = APIRouter(prefix="/users", tags=["users"])

async def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid access token")
    return payload.get("sub")

@router.get("/me", response_model=UserMe)
async def me(db=Depends(get_db), user_id: str = Depends(get_current_user_id)):
    user = await db["users"].find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "_id": user["_id"],
        "email": user["email"],
        "name": user["name"],
        "gender": user.get("gender"),
        "survey_completed": user.get("survey_completed", False),
        "email_verified": user.get("email_verified", False),
        "created_at": user.get("created_at"),
    }

@router.put("/me", response_model=UserMe)
async def update_me(payload: UpdateUser, db=Depends(get_db), user_id: str = Depends(get_current_user_id)):
    update_fields = {k: v for k, v in payload.dict().items() if v is not None}
    if update_fields:
        update_fields["updated_at"] = datetime.now(timezone.utc)
        await db["users"].update_one({"_id": user_id}, {"$set": update_fields})
    user = await db["users"].find_one({"_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "_id": user["_id"],
        "email": user["email"],
        "name": user["name"],
        "gender": user.get("gender"),
        "survey_completed": user.get("survey_completed", False),
        "email_verified": user.get("email_verified", False),
        "created_at": user.get("created_at"),
    }
