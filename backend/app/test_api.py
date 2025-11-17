"""
실제 HTTP 요청으로 API 테스트
백엔드 서버가 실행 중이어야 함 (http://localhost:8050)
"""
import asyncio
from datetime import datetime, timezone, timedelta
import httpx

async def main():
    base_url = "http://localhost:8050"
    email = f"test_{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}@example.com"
    password = "Passw0rd!"
    
    async with httpx.AsyncClient(base_url=base_url, timeout=10.0) as client:
        print("=" * 60)
        print("🔍 백엔드 API 테스트 시작")
        print("=" * 60)
        
        # 1. Health Check
        print("\n1️⃣ Health Check...")
        r = await client.get("/health")
        print(f"   상태 코드: {r.status_code}")
        print(f"   응답: {r.json()}")
        
        # 2. 회원가입
        print(f"\n2️⃣ 회원가입 (이메일: {email})...")
        signup_data = {
            "email": email,
            "password": password,
            "name": "테스트유저",
            "gender": "male"
        }
        r = await client.post("/auth/signup", json=signup_data)
        print(f"   상태 코드: {r.status_code}")
        if r.status_code == 200:
            tokens = r.json()
            print(f"   ✅ 회원가입 성공!")
            print(f"   Access Token: {tokens['access_token'][:50]}...")
            print(f"   Refresh Token: {tokens['refresh_token'][:50]}...")
            access_token = tokens['access_token']
        else:
            print(f"   ❌ 회원가입 실패: {r.text}")
            return
        
        # 3. 로그인
        print(f"\n3️⃣ 로그인 (이메일: {email})...")
        login_data = {
            "email": email,
            "password": password
        }
        r = await client.post("/auth/login", json=login_data)
        print(f"   상태 코드: {r.status_code}")
        if r.status_code == 200:
            tokens = r.json()
            print(f"   ✅ 로그인 성공!")
            print(f"   Access Token: {tokens['access_token'][:50]}...")
            access_token = tokens['access_token']
        else:
            print(f"   ❌ 로그인 실패: {r.text}")
            return
        
        # 4. 사용자 정보 조회
        print(f"\n4️⃣ 사용자 정보 조회...")
        headers = {"Authorization": f"Bearer {access_token}"}
        r = await client.get("/users/me", headers=headers)
        print(f"   상태 코드: {r.status_code}")
        if r.status_code == 200:
            user = r.json()
            print(f"   ✅ 사용자 정보 조회 성공!")
            print(f"   ID: {user.get('_id')}")
            print(f"   이메일: {user.get('email')}")
            print(f"   이름: {user.get('name')}")
            print(f"   성별: {user.get('gender')}")
            print(f"   설문 완료: {user.get('survey_completed')}")
        else:
            print(f"   ❌ 사용자 정보 조회 실패: {r.text}")

        # 5. 스크린타임 기록 추가
        print(f"\n5️⃣ 스크린타임 기록 추가...")
        start_time = datetime.now(timezone.utc) - timedelta(minutes=45)
        end_time = start_time + timedelta(minutes=15)
        payload = {
            "start_time": start_time.isoformat(),
            "end_time": end_time.isoformat(),
            "label": "테스트 집중 시간",
            "source": "manual",
        }
        r = await client.post("/users/me/screen-time", headers=headers, json=payload)
        print(f"   상태 코드: {r.status_code}")
        if r.status_code == 201:
            entry = r.json()
            entry_id = entry.get("entryId") or entry.get("entry_id")
            print(f"   ✅ 기록 추가 성공! entry_id={entry_id}")

            # 6. 스크린타임 목록 확인
            print("\n6️⃣ 스크린타임 목록 조회...")
            r = await client.get("/users/me/screen-time", headers=headers)
            print(f"   상태 코드: {r.status_code}")
            if r.status_code == 200:
                data = r.json()
                print(f"   ✅ {len(data)}건 조회")
            else:
                print(f"   ❌ 목록 조회 실패: {r.text}")

            # 7. 스크린타임 요약
            print("\n7️⃣ 스크린타임 요약 조회...")
            r = await client.get("/users/me/screen-time/summary", headers=headers)
            print(f"   상태 코드: {r.status_code}")
            if r.status_code == 200:
                summary = r.json()
                print(f"   총 사용 시간: {summary.get('totalMinutes')}분, 오늘: {summary.get('todayMinutes')}분")
            else:
                print(f"   ❌ 요약 조회 실패: {r.text}")
        else:
            print(f"   ❌ 스크린타임 기록 추가 실패: {r.text}")

        print("\n" + "=" * 60)
        print("✅ 모든 테스트 완료!")
        print("=" * 60)

if __name__ == "__main__":
    asyncio.run(main())
