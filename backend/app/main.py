# backend/app/main.py
import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.config import get_settings
from db.mongo import get_db

from routers.auth import router as auth_router
from routers.users import router as users_router
from routers.user_data import router as user_data_router
from routers.custom_tags import router as custom_tags_router
from routers.diaries import router as diaries_router
from routers.sud_scores import router as sud_scores_router
from routers.relaxation_tasks import router as relaxation_router
from routers.screen_time import router as screen_time_router
from routers.schedule_events import router as schedule_events_router
from routers.edu_sessions import router as edu_sessions_router
from routers.worry_groups import router as worry_groups_router
from routers.ai import router as ai_router
from routers.integrations_platform import router as integrations_platform_router

settings = get_settings()

# Windows Python 3.13 이벤트 루프 호환성 문제 대응: Proactor 대신 Selector 사용
try:
    if hasattr(asyncio, "WindowsSelectorEventLoopPolicy"):
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
except Exception:
    # 로컬/리눅스 환경 등에서는 그냥 무시
    pass


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    앱 시작 시 컬렉션별 인덱스 초기화.
    get_db()가 sync 함수로 AsyncIOMotorDatabase를 반환한다고 가정.
    """
    db = get_db()

    # ---------- users 컬렉션 ----------
    try:
        users = db["users"]

        await users.create_index(
            "email",
            unique=True,
            name="unique_email_index",
        )

        await users.create_index(
            "last_active_at",
            name="idx_last_active_at",
        )

        await users.create_index(
            "created_at",
            name="idx_created_at",
        )


    # ✅ patient_id는 "있을 때만" 유니크 (null 여러개 허용)
        await users.create_index(
            "patient_id",
            unique=True,
            sparse=True,
            name="unique_patient_id_sparse",
        )

        await users.create_index(
            [("identities.provider", 1), ("identities.sub", 1)],
            name="idx_identities_provider_sub",
        )

        print("✅ users 인덱스 생성/확인 완료")
    except Exception as e:
        print(f"⚠️ users 인덱스 생성 중 오류: {e}")

    # ---------- custom_tags 컬렉션 ----------
    try:
        custom_tags = db["custom_tags"]

        # 1) user + chip_id 유니크 (단일 태그 조회, 로그 업데이트 전부 여기 의존)
        await custom_tags.create_index(
            [("user_id", 1), ("chip_id", 1)],
            unique=True,
            name="custom_tags_user_chip_unique",
        )

        # 2) 목록 조회용: 타입/삭제여부 + 생성일 정렬
        await custom_tags.create_index(
            [("user_id", 1), ("type", 1), ("deleted", 1), ("created_at", 1)],
            name="custom_tags_list_query",
        )

        # 3) Real Oddness 로그 조회용 (기간 필터 대비)
        await custom_tags.create_index(
            [("user_id", 1), ("real_oddness_logs.completed_at", 1)],
            name="custom_tags_real_oddness_completed_at",
        )

        # 4) Category 로그 조회용 (기간 필터 대비)
        await custom_tags.create_index(
            [("user_id", 1), ("category_logs.completed_at", 1)],
            name="custom_tags_category_completed_at",
        )

        print("✅ custom_tags 인덱스 생성/확인 완료")
    except Exception as e:
        print(f"⚠️ custom_tags 인덱스 생성 중 오류: {e}")

    # ---------- diaries 컬렉션 ----------
    try:
        diaries = db["diaries"]

        # 유저 + sud_scores.created_at (SUD 시간별 집계용)
        await diaries.create_index(
            [("user_id", 1), ("sud_scores.created_at", 1)],
            name="idx_user_sud_created_at",
        )

        # 유저 + 그룹별 조회 (worry_group / any group_id)
        await diaries.create_index(
            [("user_id", 1), ("group_id", 1)],
            name="idx_user_group",
        )

        # 유저별 일기 목록 최신순 조회
        await diaries.create_index(
            [("user_id", 1), ("created_at", -1)],
            name="idx_user_created_at_desc",
        )

        # 단건 조회/수정용 (SUD 라우터 포함)
        await diaries.create_index(
            [("user_id", 1), ("diary_id", 1)],
            unique=True,
            name="unique_user_diary",
        )

        print("✅ diaries 인덱스 생성 완료")
    except Exception as e:
        print(f"⚠️ diaries 인덱스 생성 중 오류: {e}")

    # ---------- sud_scores 컬렉션 ----------
    # SUD 점수를 diaries에 embed 안 하고 별도 컬렉션으로도 쓸 경우 대비
    try:
        sud_scores = db["sud_scores"]

        await sud_scores.create_index(
            [("user_id", 1), ("created_at", 1)],
            name="idx_sud_user_created_at",
        )
        print("✅ sud_scores 인덱스 생성 완료")
    except Exception as e:
        print(f"⚠️ sud_scores 인덱스 생성 중 오류: {e}")

    # ---------- relaxation_tasks 컬렉션 ----------
    # 이완/명상 세션 로그 (user + start_time / end_time / session_id 기반 조회)
    try:
        relax = db["relaxation_tasks"]

        await relax.create_index(
            [("user_id", 1), ("start_time", 1)],
            name="idx_relax_user_start_time",
        )

        await relax.create_index(
            [("user_id", 1), ("end_time", 1)],
            name="idx_relaxation_user_end_time",
        )

        # 세션 단건 조회 / 업데이트용 (예전 session_id 기준 인덱스, 있어도 무해)
        await relax.create_index(
            "session_id",
            unique=True,
            name="unique_relax_session_id",
        )

        print("✅ relaxation_tasks 인덱스 생성 완료")
    except Exception as e:
        print(f"⚠️ relaxation_tasks 인덱스 생성 중 오류: {e}")

    # ---------- screen_time 컬렉션 ----------
    # 유저별 일/주 단위 스크린타임 합계 조회
    try:
        screen_time = db["screen_time"]

        await screen_time.create_index(
            [("user_id", 1), ("start_time", 1), ("end_time", 1)],
            name="idx_screen_time_user_start_end",
        )
        await screen_time.create_index(
            [("user_id", 1), ("end_time", -1)],
            name="idx_screen_time_user_last_end",
        )
        print("✅ screen_time 인덱스 생성 완료")
    except Exception as e:
        print(f"⚠️ screen_time 인덱스 생성 중 오류: {e}")

    # ---------- schedule_events 컬렉션 ----------
    try:
        schedule_events = db["schedule_events"]

        await schedule_events.create_index("user_id")

        await schedule_events.create_index(
            [("user_id", 1), ("start_date", 1)],
            name="idx_schedule_user_start_date",
        )
        print("✅ schedule_events 인덱스 생성 완료")
    except Exception as e:
        print(f"⚠️ schedule_events 인덱스 생성 중 오류 (이미 존재할 수 있음): {e}")

    # ---------- edu_sessions 컬렉션 ----------
    # 주차별 세션 히스토리/통계 조회용 (여러 세션 허용)
    try:
        edu_sessions = db["edu_sessions"]

        # 주차별 + 시작시간 기준 정렬 조회
        await edu_sessions.create_index(
            [("user_id", 1), ("week_number", 1), ("start_time", -1)],
            name="idx_edu_user_week_start_desc",
        )

        # 주차별/기간별 통계 조회 대비
        await edu_sessions.create_index(
            [("user_id", 1), ("created_at", 1)],
            name="idx_edu_user_created_at",
        )

        print("✅ edu_sessions 인덱스 생성 완료")
    except Exception as e:
        print(f"⚠️ edu_sessions 인덱스 생성 중 오류: {e}")

    # ---------- user_data ----------
    # 현재 운영/통합 플로우에서는 user_data 컬렉션을 사용하지 않으므로 제거합니다.
    # users 컬렉션에 동일 인덱스를 또 만드는 중복/혼동을 방지하기 위함.

    # ---------- worry_groups 컬렉션 ----------
    # 걱정 그룹 관리 (유저별 생성 순으로 조회 + 단건 조회/업데이트)
    try:
        worry_groups = db["worry_groups"]

        # 리스트 조회(정렬)용
        await worry_groups.create_index(
            [("user_id", 1), ("created_at", 1)],
            name="idx_worry_user_created_at",
        )

        # 단건 조회/아카이브/삭제/metric 업데이트용
        await worry_groups.create_index(
            [("user_id", 1), ("group_id", 1)],
            unique=True,
            name="unique_user_group",
        )

        print("✅ worry_groups 인덱스 생성 완료")
    except Exception as e:
        print(f"⚠️ worry_groups 인덱스 생성 중 오류: {e}")

    # startup 끝
    yield
    # shutdown 시 별도 정리할 자원 있으면 여기서 처리


app = FastAPI(
    title="Mindrium API",
    version="0.1.0",
    lifespan=lifespan,
)

# 개발 환경: 모든 origin 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: 모든 origin 허용 (개발용) -> 앱 도메인으로 제한할 것
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {
        "message": "Mindrium API",
        "version": "0.1.0",
        "docs": "/docs",
        "health": "/health",
    }


@app.get("/health")
async def health():
    return {"status": "ok"}


# ----- 라우터 등록 -----
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(diaries_router)
app.include_router(sud_scores_router)       # SUD 점수 기록 라우터
app.include_router(user_data_router)        # 사용자 데이터(설문 등)  <-- (주의) 이 라우터 자체도 안 쓰면 제거 권장
app.include_router(relaxation_router)
app.include_router(screen_time_router)
app.include_router(schedule_events_router)
app.include_router(edu_sessions_router)
app.include_router(custom_tags_router)
app.include_router(worry_groups_router)
app.include_router(ai_router)
app.include_router(integrations_platform_router)
