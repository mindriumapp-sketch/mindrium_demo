"""
동기 HTTP 요청으로 API 테스트 (httpx 대신 requests 사용)
"""
import requests
from datetime import datetime, timezone

def test_apis():
    base_url = "http://localhost:8050"
    email = f"test_{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}@example.com"
    password = "Passw0rd!"
    
    print("=" * 60)
    print("🔍 백엔드 API 테스트 시작")
    print("=" * 60)
    
    # 1. Health Check
    print("\n1️⃣ Health Check...")
    try:
        r = requests.get(f"{base_url}/health", timeout=5)
        print(f"   상태 코드: {r.status_code}")
        print(f"   응답: {r.json()}")
    except Exception as e:
        print(f"   ❌ 오류: {e}")
        print("   ⚠️ 백엔드 서버가 실행 중인지 확인하세요 (http://localhost:8050)")
        return
    
    # 2. 회원가입
    print(f"\n2️⃣ 회원가입 (이메일: {email})...")
    signup_data = {
        "email": email,
        "password": password,
        "name": "테스트유저",
        "gender": "male"
    }
    try:
        r = requests.post(f"{base_url}/auth/signup", json=signup_data, timeout=5)
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
    except Exception as e:
        print(f"   ❌ 오류: {e}")
        return
    
    # 3. 로그인
    print(f"\n3️⃣ 로그인 (이메일: {email})...")
    login_data = {
        "email": email,
        "password": password
    }
    try:
        r = requests.post(f"{base_url}/auth/login", json=login_data, timeout=5)
        print(f"   상태 코드: {r.status_code}")
        if r.status_code == 200:
            tokens = r.json()
            print(f"   ✅ 로그인 성공!")
            print(f"   Access Token: {tokens['access_token'][:50]}...")
            access_token = tokens['access_token']
        else:
            print(f"   ❌ 로그인 실패: {r.text}")
            return
    except Exception as e:
        print(f"   ❌ 오류: {e}")
        return
    
    # 4. 사용자 정보 조회
    print(f"\n4️⃣ 사용자 정보 조회...")
    headers = {"Authorization": f"Bearer {access_token}"}
    try:
        r = requests.get(f"{base_url}/users/me", headers=headers, timeout=5)
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
    except Exception as e:
        print(f"   ❌ 오류: {e}")
        return
    
    print("\n" + "=" * 60)
    print("✅ 모든 테스트 완료! MongoDB에 사용자 데이터가 저장되었습니다.")
    print("=" * 60)

if __name__ == "__main__":
    test_apis()
