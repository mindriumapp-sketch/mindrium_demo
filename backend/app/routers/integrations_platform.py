from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Dict, Any
from datetime import datetime, timezone, timedelta

from db.mongo import get_db

router = APIRouter(
    prefix="/api/integrations/platform",
    tags=["Integrations-Platform"],
)

# ------------------------------
# 1. 환자 요약 정보
# ------------------------------
@router.get("/patients/{patient_id}/summary")
async def patient_summary(patient_id: str, db=Depends(get_db)):

    user = await db["users"].find_one(
        {"patient_id": patient_id},
        {"_id": 0, "user_id": 1, "email": 1, "name": 1, "patient_id": 1}
    )

    if not user:
        raise HTTPException(status_code=404, detail="patient_id not linked")

    diary_count = await db["diaries"].count_documents({"patient_id": patient_id})
    relax_count = await db["relaxation_tasks"].count_documents({"patient_id": patient_id})
    edu_count = await db["edu_sessions"].count_documents({"patient_id": patient_id})
    worry_count = await db["worry_groups"].count_documents({"patient_id": patient_id})

    latest = (
        db["diaries"]
        .find({"patient_id": patient_id}, {"_id": 0, "created_at": 1})
        .sort("created_at", -1)
        .limit(1)
    )

    latest_dt = None
    async for item in latest:
        latest_dt = item.get("created_at")

    return {
        "patient_id": patient_id,
        "mindrium_user": user,
        "counts": {
            "diaries": diary_count,
            "relaxation_tasks": relax_count,
            "edu_sessions": edu_count,
            "worry_groups": worry_count,
        },
        "latest_diary_at": latest_dt,
    }


# ------------------------------
# 2. 최근 다이어리 5개
# ------------------------------
@router.get("/patients/{patient_id}/diaries")
async def recent_diaries(
    patient_id: str,
    limit: int = Query(5, ge=1, le=20),
    db=Depends(get_db),
):

    cursor = (
        db["diaries"]
        .find(
            {"patient_id": patient_id},
            {"_id": 0, "diary_id": 1, "created_at": 1, "title": 1, "content": 1}
        )
        .sort("created_at", -1)
        .limit(limit)
    )

    items = []
    async for doc in cursor:
        items.append(doc)

    return {"patient_id": patient_id, "items": items}


# ------------------------------
# 3. 일별 다이어리 작성수 시계열
# ------------------------------
@router.get("/patients/{patient_id}/timeseries/diary-count-daily")
async def diary_count_daily(
    patient_id: str,
    days: int = Query(14, ge=7, le=90),
    db=Depends(get_db),
):

    start_date = datetime.now(timezone.utc) - timedelta(days=days)

    pipeline = [
        {
            "$match": {
                "patient_id": patient_id,
                "created_at": {"$gte": start_date},
            }
        },
        {
            "$project": {
                "day": {
                    "$dateToString": {
                        "format": "%Y-%m-%d",
                        "date": "$created_at",
                    }
                }
            }
        },
        {
            "$group": {
                "_id": "$day",
                "count": {"$sum": 1},
            }
        },
        {"$sort": {"_id": 1}},
    ]

    cursor = db["diaries"].aggregate(pipeline)

    results = []
    async for row in cursor:
        results.append({"date": row["_id"], "count": row["count"]})

    return {"patient_id": patient_id, "series": results}


# ------------------------------
# 4. SUD 점수 시계열
# ------------------------------
@router.get("/patients/{patient_id}/timeseries/sud")
async def sud_timeseries(
    patient_id: str,
    days: int = Query(30, ge=7, le=180),
    db=Depends(get_db),
):

    start_date = datetime.now(timezone.utc) - timedelta(days=days)

    cursor = (
        db["sud_scores"]
        .find(
            {
                "patient_id": patient_id,
                "created_at": {"$gte": start_date},
            },
            {"_id": 0, "score": 1, "created_at": 1},
        )
        .sort("created_at", 1)
    )

    items = []
    async for doc in cursor:
        items.append(doc)

    return {"patient_id": patient_id, "series": items}
