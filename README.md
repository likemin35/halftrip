# HalfTrip Flutter Prototype

프로토타입용 Flutter Web/앱 레포입니다.  
실서비스 완성본이 아니라, 기능 흐름을 빠르게 검증하고 팀원이 구조를 파악하기 쉽게 유지하는 것을 목표로 합니다.

## 관련 레포

- Spring API: [halftrip-springboot](https://github.com/likemin35/halftrip-springboot)
- FastAPI OCR/PDF: [halftrip-fastapi](https://github.com/likemin35/halftrip-fastapi)

## 이 레포에서 다루는 범위

- 로그인/회원가입/내 정보 플로우
- 여행 신청, 여행 목록, 여행 상세
- 지정관광지/지역화폐 가맹점 지도 UI
- 플래너, 일정 추가/삭제/정렬 UI
- 영수증 업로드, 인증사진 업로드, 숙박확인서 화면
- 정산 신청, 제출물 통합, 온라인몰, 커뮤니티 등 프로토타입 화면
- API 모드/Mock 모드 전환

## 현재 프로토타입에서 중요한 특징

- 실제 서비스 운영보다 “화면 흐름과 기능 연결 검증”에 초점이 맞춰져 있습니다.
- 일부 기능은 Mock 데이터와 실제 API가 함께 존재합니다.
- 카카오맵, OCR, PDF 같은 기능은 백엔드 상태에 따라 동작 품질이 달라질 수 있습니다.
- README는 “같이 개발하는 사람이 빠르게 구조를 읽는 용도”로 작성했습니다.

## 주요 폴더

```text
flutter_app/
  lib/
    core/           앱 설정, API base URL, 앱 스코프, 전역 컨트롤러
    models/         공통 데이터 모델, enum, DTO 매핑
    repositories/   API/Mock 저장소 구현
    screens/        실제 화면 단위 UI
    widgets/        공통 위젯, 앱 셸, 카카오맵 래퍼
    data/           지역 가이드, 정적 문구, 샘플성 데이터
    utils/          다운로드, 보조 유틸
  assets/
    logo/           로고 이미지
    card/           홈 배너 이미지
    localmoney/     지역화폐/숙박 관련 이미지
    spot/           관광지 대표 이미지
  web/              Flutter Web 엔트리, 웹 리소스
```

## 파일/영역별 역할

### `flutter_app/lib/core`

- `app_config.dart`
  - `dart-define` 기반 환경설정 읽기
  - API 주소, FastAPI 주소, 카카오맵 사용 여부 관리
- `app_scope.dart`
  - 저장소와 현재 사용자 상태를 화면에 공급하는 앱 컨테이너

### `flutter_app/lib/models`

- `app_models.dart`
  - 앱 전체에서 공통으로 쓰는 모델 정의
  - 여행, 영수증, 업로드 파일, 지역, 플래너, 숙박확인서 등의 JSON 매핑 담당

### `flutter_app/lib/repositories`

- `travel_repository.dart`
  - 프론트가 기대하는 저장소 인터페이스
- `api_travel_repository.dart`
  - Spring API와 통신하는 실제 구현
- `mock_travel_repository.dart`
  - 서버 없이도 화면을 검증할 수 있게 하는 Mock 구현

### `flutter_app/lib/screens`

- `login_screen.dart`
  - 로그인/회원가입 진입
- `trip_list_screen.dart`, `trip_detail_screen.dart`
  - 여행 목록, 여행 상세, 제출물/정산 플로우 중심 화면
- `place_info_screen.dart`
  - 직접 코스 만들기
  - 지정관광지 탭, 지역화폐 가맹점 탭, 마커 오버레이 UI
- `planner_screen.dart`
  - 플래너 보기, 순서 정렬, 제거
- `auth_photo_upload_screen.dart`
  - 인증사진 업로드 및 AI 판정 결과 메시지 처리
- `receipt_evidence_screen.dart`
  - 영수증 업로드, OCR 결과 미리보기, 저장 목록 표시
- `lodging_form_screen.dart`
  - 숙박확인서 작성/편집 UI
- `online_mall_screen.dart`
  - 지역화폐/온라인몰 프로토타입 화면

### `flutter_app/lib/widgets`

- `app_shell.dart`
  - 상단바, 하단 네비게이션, 공통 레이아웃
- `place_map_view.dart`
  - 플랫폼별 지도 엔트리
- `place_map_view_web.dart`
  - 웹 카카오맵 구현
  - 마커, 오버레이, 경로선 표시
- `place_map_models.dart`
  - 지도에 필요한 마커/경로 데이터 구조

## 실행 방법

### Flutter 실행

```powershell
cd C:\Users\Administrator\Desktop\관광\flutter_app
flutter pub get
flutter run -d chrome
```

### 자주 쓰는 `dart-define`

```powershell
flutter run -d chrome `
  --dart-define=API_BASE_URL=https://halftrip-springboot.onrender.com/api `
  --dart-define=FASTAPI_BASE_URL=https://halftrip-fastapi.onrender.com `
  --dart-define=MAP_PROVIDER=kakao `
  --dart-define=KAKAO_MAP_APP_KEY=YOUR_KEY
```

## 협업 시 참고

- 새 화면을 만들 때는 먼저 `models`와 `repository` 계약을 확인해 주세요.
- 실제 서버 연동 기능을 바꿀 때는 Mock 저장소도 같이 맞춰야 화면 테스트가 편합니다.
- 지도/업로드/OCR처럼 백엔드 의존성이 큰 기능은 UI만 수정하지 말고 관련 레포와 같이 확인하는 게 좋습니다.

## 함께 보면 좋은 레포

- Spring API: [https://github.com/likemin35/halftrip-springboot](https://github.com/likemin35/halftrip-springboot)
- FastAPI OCR/PDF: [https://github.com/likemin35/halftrip-fastapi](https://github.com/likemin35/halftrip-fastapi)
