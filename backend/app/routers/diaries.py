from fastapi import APIRouter, Depends, HTTPException, Header
from db.mongo import get_db
from schemas.user import DiaryItem
from core.security import decode_token
from datetime import datetime, timezone
import uuid

router = APIRouter(prefix="/worry-groups", tags=["diaries"])

async def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid access token")
    return payload.get("sub")

@router.get("/{group_id}/diaries")
async def list_diaries(group_id: str, db=Depends(get_db), user_id: str = Depends(get_current_user_id)):
    user = await db["users"].find_one({"_id": user_id, "worry_groups.group_id": group_id})
    if not user:
        raise HTTPException(status_code=404, detail="Group or user not found")
    for g in user.get("worry_groups", []):
        if g["group_id"] == group_id:
            return {"diaries": g.get("diaries", [])}
    return {"diaries": []}

@router.post("/{group_id}/diaries")
async def create_diary(group_id: str, db=Depends(get_db), user_id: str = Depends(get_current_user_id)):
    diary_id = f"diary_{uuid.uuid4().hex[:8]}"
    diary = {
        "diary_id": diary_id,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
        "latitude": None,
        "longitude": None,
        "tags": [],
        "alternative_thoughts": [],
        "confront_avoid_logs": [],
    }
    result = await db["users"].update_one(
        {"_id": user_id, "worry_groups.group_id": group_id},
        {"$push": {"worry_groups.$.diaries": diary}}
    )
    if result.modified_count == 0:
        raise HTTPException(status_code=404, detail="Group or user not found")
    return {"created": True, "diary_id": diary_id}
