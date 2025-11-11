# Firebase → MongoDB 완전 전환 계획

## 📊 현황 분석
- Firebase를 사용하는 파일: **약 60개 이상**
- 주요 기능: 사용자 인증, 데이터 저장, 실시간 업데이트

## 🎯 전환 전략

### Phase 1: 백엔드 API 확장 (필수)
**목표**: MongoDB 백엔드에 필요한 모든 API 추가

#### 1.1 필요한 새로운 API 엔드포인트
```
[사용자 데이터]
- GET /users/me/data - 사용자 데이터 조회
- PUT /users/me/data - 사용자 데이터 업데이트
- POST /users/me/surveys - 설문조사 저장
- GET /users/me/progress - 진행상황 조회

[ABC 다이어리]
- GET /diaries - 다이어리 목록
- POST /diaries - 다이어리 생성
- PUT /diaries/:id - 다이어리 수정
- DELETE /diaries/:id - 다이어리 삭제
- GET /diaries/:id - 다이어리 상세

[걱정 그룹]
- GET /worry-groups - 그룹 목록 (이미 있음 - users.worry_groups)
- POST /worry-groups - 그룹 생성
- PUT /worry-groups/:id - 그룹 수정
- DELETE /worry-groups/:id - 그룹 삭제

[이완 훈련]
- POST /relaxation/sessions - 세션 저장
- GET /relaxation/sessions - 세션 목록
- POST /relaxation/scores - 점수 저장

[주차별 진행]
- POST /progress/week/:weekNum - 주차 완료
- GET /progress - 전체 진행상황
```

### Phase 2: Flutter 유틸리티 레이어 생성
**목표**: Firebase 의존성을 추상화

#### 2.1 생성할 파일
```dart
lib/data/api/
  ├── diaries_api.dart      // ABC 다이어리 API
  ├── groups_api.dart       // 걱정 그룹 API
  ├── relaxation_api.dart   // 이완 훈련 API
  ├── progress_api.dart     // 진행상황 API
  └── user_data_api.dart    // 사용자 데이터 API
```

### Phase 3: 파일별 수정
**목표**: Firebase 코드를 MongoDB API 호출로 대체

#### 3.1 핵심 인증 파일 (이미 완료)
- [x] `lib/features/auth/login_screen.dart`
- [x] `lib/features/auth/signup_screen.dart`
- [x] `lib/features/other/splash_screen.dart`

#### 3.2 사용자 프로필/데이터 (우선순위: 높음)
- [ ] `lib/navigation/screen/myinfo_screen.dart`
- [ ] `lib/navigation/screen/home_screen.dart`
- [ ] `lib/navigation/screen/treatment_screen.dart`
- [ ] `lib/data/user_data_storage.dart`
- [ ] `lib/data/user_pretest.dart`
- [ ] `lib/features/other/before_survey.dart`
- [ ] `lib/features/value_start.dart`

#### 3.3 ABC 다이어리 관련 (우선순위: 중간)
- [ ] `lib/features/2nd_treatment/abc_input_screen.dart`
- [ ] `lib/features/2nd_treatment/abc_group.dart`
- [ ] `lib/features/2nd_treatment/abc_group_add.dart`
- [ ] `lib/features/2nd_treatment/abc_group_add_screen.dart`
- [ ] `lib/features/2nd_treatment/abc_visualization_screen.dart`
- [ ] `lib/features/menu/diary/diary_directory_screen.dart`
- [ ] `lib/contents/diary_yes_or_no.dart`
- [ ] `lib/contents/filtered_diary_select.dart`
- [ ] `lib/contents/filtered_diary_show.dart`
- [ ] `lib/widgets/diary_card.dart`
- [ ] `lib/widgets/abc_group_design.dart`
- [ ] `lib/widgets/abc_group_add_design.dart`

#### 3.4 주차별 치료 (우선순위: 중간)
- [ ] `lib/features/1st_treatment/week1_value_goal_screen.dart`
- [ ] `lib/features/4th_treatment/week4_*.dart` (9개 파일)
- [ ] `lib/features/6th_treatment/week6_*.dart` (4개 파일)
- [ ] `lib/features/7th_treatment/week7_*.dart` (2개 파일)
- [ ] `lib/features/8th_treatment/week8_*.dart` (2개 파일)

#### 3.5 이완 훈련 (우선순위: 낮음)
- [ ] `lib/features/menu/relaxation/relaxation_logger.dart`
- [ ] `lib/features/menu/relaxation/relaxation_score_screen.dart`

#### 3.6 보관함 (우선순위: 낮음)
- [ ] `lib/features/menu/archive/archive_screen.dart`
- [ ] `lib/features/menu/archive/character_battle.dart`
- [ ] `lib/features/menu/archive/sea_archive_page.dart`

#### 3.7 기타 화면 (우선순위: 낮음)
- [ ] `lib/contents/before_sud_screen.dart`
- [ ] `lib/contents/after_sud_screen.dart`
- [ ] `lib/contents/apply_alternative_thought.dart`
- [ ] `lib/contents/similar_activation.dart`
- [ ] `lib/widgets/map_picker.dart`
- [ ] `lib/data/notification_provider.dart`

### Phase 4: 테스트 및 검증
- [ ] 로그인/회원가입 테스트
- [ ] 사용자 데이터 CRUD 테스트
- [ ] ABC 다이어리 기능 테스트
- [ ] 주차별 진행 테스트
- [ ] 이완 훈련 테스트

### Phase 5: 정리
- [ ] `pubspec.yaml`에서 Firebase 패키지 완전 제거
- [ ] `firebase_options.dart` 파일 삭제
- [ ] `web/index.html`에서 Firebase SDK 제거
- [ ] `main.dart`에서 Firebase 초기화 제거

## 📝 작업 순서 제안

### 옵션 A: 점진적 전환 (권장)
1. ✅ **백엔드 API 확장** (1-2일)
2. **유틸리티 레이어 생성** (반나절)
3. **핵심 기능부터 단계적 전환**
   - Phase 1: 사용자 프로필 (1일)
   - Phase 2: ABC 다이어리 (2일)
   - Phase 3: 주차별 치료 (2-3일)
   - Phase 4: 나머지 기능 (1-2일)

### 옵션 B: 빠른 전환 (위험)
1. 백엔드 API 한번에 생성
2. 모든 Firebase 코드를 주석처리
3. API 호출로 교체하면서 테스트

## 🚀 즉시 시작 가능한 작업

1. **백엔드 API 엔드포인트 추가** (가장 먼저!)
2. **API 유틸리티 클래스 생성**
3. **간단한 파일부터 시작** (myinfo_screen 등)

---

## ❓ 결정 필요
어떤 방식으로 진행하시겠습니까?
- [ ] 옵션 A: 점진적 전환 (안전, 시간 소요)
- [ ] 옵션 B: 빠른 전환 (빠름, 위험)
- [ ] 옵션 C: 하이브리드 (로그인만 MongoDB, 나머지 Firebase 유지)
