# Raw Mongo document helper functions
from typing import Any, Dict
from datetime import datetime, timezone

USER_COLLECTION = "users"

DEFAULT_USER_FIELDS = {
    "survey_completed": False,
    "worry_groups": [],
    "relaxation_tasks": [],
    "surveys": [],
    "custom_tags": [],
    "practice_sessions": [],
<<<<<<< HEAD
    "screen_time": [],
=======
>>>>>>> 7cf0a32 (1118 통합)
    "email_verified": False,
    "created_at": datetime.now(timezone.utc),
}

def build_user_doc(user_id: str, email: str, name: str, gender: str, password_hash: str) -> Dict[str, Any]:
    doc = DEFAULT_USER_FIELDS.copy()
    doc.update({
        "_id": user_id,
        "email": email,
        "name": name,
        "gender": gender,
        "password_hash": password_hash,
    })
    return doc
