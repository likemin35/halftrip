# Travel Support MVP

Flutter + Spring Boot + FastAPI + MySQL 기반의 여행 지원 앱 MVP입니다. 한국관광공사 반값여행 관련 신청/관리/정산 준비 흐름을 빠르게 검증할 수 있도록 실제 동작 기능과 mock/TODO 영역을 분리했습니다.

## 1. 프로젝트 구조

```text
.
|-- backend-fastapi/         # AI/OCR/PDF 전용 서버
|-- backend-spring/          # 메인 비즈니스 API 서버
|-- docs/
|   |-- api-spec.md
|   `-- screen-flow.md
|-- flutter_app/             # 모바일 앱
`-- infra/
    `-- docker-compose.yml   # MySQL 실행용
```

상세 구조

```text
backend-spring/
|-- src/main/java/com/tourism/travelmvp/
|   |-- client/              # FastAPI 호출
|   |-- config/              # CORS, JPA auditing, properties
|   |-- controller/          # REST API
|   |-- dto/                 # request/response
|   |-- entity/              # JPA entity
|   |-- repository/          # JPA repository
|   `-- service/             # business logic
`-- src/main/resources/db/migration/
    `-- V1__init_schema.sql  # schema + sample seed

backend-fastapi/
`-- app/
    |-- core/                # settings
    |-- routers/             # OCR/PDF routes
    |-- schemas/             # response schema
    `-- services/            # mock OCR, PDF merge

flutter_app/
`-- lib/
    |-- core/                # config, controller, scope
    |-- models/              # app model
    |-- repositories/        # mock/api repository
    |-- screens/             # login, 신청, 관리, 정산 화면
    `-- widgets/             # 공통 scaffold, map, signature
```

## 2. 현재 MVP에서 실제 동작하는 범위

- Flutter
  - 카카오/구글 로그인 UI
  - mock login 모드
  - 메인 화면
  - 여행 신청 폼
  - 지역 선택 및 거주지 기반 필터링
  - 여행 리스트/상세/장소 체크/플래너/증빙서류/정산/설정/환급 사용처 화면
  - 지도 SDK 미설정 시 placeholder map 동작
- Spring Boot
  - 사용자/알림설정/여행/지역/장소/가맹점/온라인몰/업로드파일/영수증/숙박정보 조회 및 기본 저장
  - 누적 소비금액 계산
  - 정산 알림 대상 계산 API
  - FastAPI 호출용 클라이언트 구조
- FastAPI
  - OCR/금액추출/숙박정보추출 mock API
  - PDF 병합 API
  - 숙박확인서 자동 채움 JSON API
- MySQL
  - Flyway migration
  - sample seed data

## 3. mock/TODO로 남겨둔 범위

- 반값여행 대상 지역 실제 데이터 연동
- 지역별 예산 잔여 공개 데이터 연동
- 디지털관광주민증 실제 연동 데이터
- 한국관광공사 API 보정
- 실제 카카오/구글 OAuth
- 실제 푸시 서버 연동
- 고도화된 OCR 엔진
- 카카오맵 실 SDK 연결

위 항목들은 코드에 `TODO:` 주석 또는 mock service로 분리되어 있습니다.

## 4. 빠른 실행

### 4.1 MySQL

```bash
cd infra
docker compose up -d
```

기본 DB 정보

- DB: `travel_mvp`
- User: `travel_user`
- Password: `travel_password`

### 4.2 Spring Boot

```bash
cd backend-spring
copy .env.example .env
mvn spring-boot:run
```

기본 포트: `8080`

### 4.3 FastAPI

```bash
cd backend-fastapi
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --reload --port 8000
```

기본 포트: `8000`

### 4.4 Flutter

```bash
cd flutter_app
flutter pub get
flutter run --dart-define=USE_MOCK_API=true --dart-define=USE_MOCK_LOGIN=true
```

추가 옵션

- `--dart-define=USE_MOCK_API=false`
- `--dart-define=FASTAPI_BASE_URL=http://10.0.2.2:8000`
- `--dart-define=API_BASE_URL=http://10.0.2.2:8080/api`
- `--dart-define=MAP_PROVIDER=kakao`
- `--dart-define=KAKAO_MAP_APP_KEY=` 비워두면 placeholder map 사용

## 5. 환경변수

### 5.1 Spring Boot

| 이름 | 설명 | 기본값 |
|---|---|---|
| `SPRING_DATASOURCE_URL` | MySQL JDBC URL | `jdbc:mysql://localhost:3306/travel_mvp?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul` |
| `SPRING_DATASOURCE_USERNAME` | DB 사용자 | `travel_user` |
| `SPRING_DATASOURCE_PASSWORD` | DB 비밀번호 | `travel_password` |
| `FASTAPI_BASE_URL` | FastAPI 서버 주소 | `http://localhost:8000` |
| `APP_ALLOWED_ORIGINS` | CORS 허용 origin | `*` |
| `MOCK_EXTERNAL_DATA` | 외부 데이터 mock 사용 여부 | `true` |

### 5.2 FastAPI

| 이름 | 설명 | 기본값 |
|---|---|---|
| `APP_ENV` | 실행 환경 | `local` |
| `TEMP_UPLOAD_DIR` | 임시 업로드 디렉터리 | `./tmp` |
| `COMMON_LODGING_TEMPLATE_PATH` | 공통 숙박확인서 템플릿 경로 | `./templates/common_lodging_form.pdf` |

### 5.3 Flutter `dart-define`

| 이름 | 설명 | 기본값 |
|---|---|---|
| `API_BASE_URL` | Spring API base URL | `http://10.0.2.2:8080/api` |
| `FASTAPI_BASE_URL` | FastAPI base URL | `http://10.0.2.2:8000` |
| `USE_MOCK_LOGIN` | mock 로그인 사용 | `true` |
| `USE_MOCK_API` | Flutter mock repository 사용 | `true` |
| `MAP_PROVIDER` | 지도 provider 식별자 | `mock` |
| `KAKAO_MAP_APP_KEY` | 카카오맵 앱 키 | 빈 값 |

예시 파일: [flutter_app/dart_defines.example.txt](C:\Users\Administrator\Desktop\관광\flutter_app\dart_defines.example.txt)

## 6. 실제 연동이 필요한 부분

- OAuth Client ID/Secret
- 카카오맵 SDK 설정
- 관광공사/반값여행/디지털관광주민증 실제 데이터 소스
- 푸시 알림 발송 인프라
- OCR 엔진/API 키

환경변수만 연결하면 되도록 구조를 분리했고, 현재는 sample data 또는 mock response로 동작합니다.

## 6.1 현재 환경에서 미검증인 항목

현재 작업 환경에는 `flutter`, `mvn`, `python` 실행 파일이 설치되어 있지 않아 실제 빌드/런타임 검증은 수행하지 못했습니다. 대신 아래 원칙으로 코드와 문서를 맞췄습니다.

- Flutter는 `USE_MOCK_API=true`일 때 서버 없이도 전체 화면 플로우가 동작하도록 작성
- Spring Boot는 MySQL + Flyway + FastAPI 연동 구조를 실제 코드로 작성
- FastAPI는 OCR/PDF mock 로직과 실제 엔드포인트 형태를 구현
- README에 필요한 실행 명령과 환경변수를 명시

## 7. 문서

- API 초안: [docs/api-spec.md](C:\Users\Administrator\Desktop\관광\docs\api-spec.md)
- 화면 흐름: [docs/screen-flow.md](C:\Users\Administrator\Desktop\관광\docs\screen-flow.md)

## 8. 현재 서비스에서 사용하는 데이터

### 8.1 공공/외부 데이터

- 한국관광공사 국문관광정보 서비스 API 기반 지정관광지 데이터
  - 지역별 지정관광지명
  - 관광지 주소
  - 관광지 좌표
  - 현재 서비스에서는 사용자 제공 정제본을 MySQL `places` 테이블에 저장해 사용
  - 주요 활용 화면
    - `내 여행 > 지정 관광지`
    - 카카오맵 마커 표출
    - 지도형 플래너 순서 저장

- 카카오맵 JavaScript SDK / 지도 API
  - 지정관광지 좌표 시각화
  - 마커 표시
  - 지도형 플래너 마커 순서 표현
  - 사용자 클릭 기반 장소 탐색 UI

### 8.2 내부 운영 데이터(MySQL)

- `users`
  - 이름, 로그인 ID, 전화번호, 거주지(광역시/도, 시/군/구)
  - 활용: 신청 가능 지역 필터링, 신청자/정산 신청자 정보 자동 입력

- `regions`
  - 반값여행 지역명, 상태, 신청 URL, 정산 URL, 환급조건금액, 디지털관광주민증 여부, mock 잔여예산
  - 활용: 지역 카드 노출, 신청/정산 링크 연결, 소비현황 목표금액 계산

- `trips`
  - 신청자명, 일정, 여행 인원, 상태, 누적 소비금액, 목표 환급 조건 금액
  - 활용: `내 여행`, 증빙서류, 지정관광지, 정산 신청 플로우

- `trip_places`
  - 사용자가 저장한 지정관광지 방문 순서
  - 활용: 지도형 플래너, 순서 변경, 저장 후 재호출

- `places`
  - 지역별 지정관광지명, 주소, 좌표
  - 활용: 지정관광지 카카오맵 마커 및 리스트

- `digital_tour_card_places`
  - 디지털 관광주민증 할인 가능 장소
  - 현재는 sample seed / mock 중심

- `receipts`
  - 결제수단 분류, 사용처 범주, OCR 추출 금액, 인정금액, 심사상태, 심사사유
  - 활용: 소비현황 누적 금액 반영, 지역별 정산 규칙 자동 심사

- `lodging_infos`
  - 숙박업소명, 대표자명, 전화번호, 주소, 동의 여부, 서명 정보
  - 활용: 숙박확인서 자동 채움, PDF 렌더링

- `lodging_form_templates`
  - 지역별 숙박확인서 템플릿 메타데이터와 입력칸 좌표
  - 활용: PDF 미리보기 오버레이, 최종 PDF 렌더링
  - 최근에는 지역별 입력칸 좌표를 DB에 저장해 재기동 후에도 유지 가능하도록 확장

- `lodging_form_instances`
  - 여행별 숙박확인서 입력값 payload
  - 활용: 저장 후 재편집, PDF 생성

- `uploaded_files`
  - 인증사진, 영수증, 숙박 관련 파일 메타데이터
  - 활용: 증빙서류 관리, PDF 병합

- `merchants`, `online_malls`
  - 지역별 환급 사용처 / 지역 온라인몰 링크
  - 활용: 지역 온라인몰 탭, 환급 사용 안내

### 8.3 사용자 생성 데이터

- 회원가입 정보
  - 이름, 아이디, 비밀번호, 전화번호, 거주지

- 여행 신청 데이터
  - 지역, 일정, 인원수

- 여행 플래너 데이터
  - 사용자가 선택한 관광지 순서

- 증빙 데이터
  - 영수증 이미지
  - 인증사진
  - 숙박확인서 입력값
  - 전자서명

### 8.4 AI / 문서 처리 데이터

- FastAPI OCR/문서 처리 입력 데이터
  - 영수증 이미지
  - 숙박확인서 PDF

- FastAPI OCR/문서 처리 출력 데이터
  - 결제수단 분류
  - 결제금액 추출
  - 숙박업소 정보 후보
  - PDF 렌더링 결과물

- OpenAI 기반 보조 분석(설정 시)
  - 영수증 분류/추출 정확도 보강
  - 현재는 OpenAI 키가 있을 때 보조적으로 활용하고, 실패 시 heuristic fallback 사용

### 8.5 현재 mock / sample seed로 사용하는 데이터

- 반값여행 지역 상태(접수중 / 준비중 / 1차 마감)
- 잔여 예산 수치
- 디지털 관광주민증 가능 여부 일부
- 일부 지역 할인/가맹점/온라인몰 연결 데이터
- 지역별 신청/정산 링크 중 일부 수동 입력 데이터

## 9. 보고서용 데이터 활용 방안

### 9.1 관광지 데이터 활용

- 한국관광공사 관광정보 데이터를 활용해 지역별 지정관광지를 표준화
- 관광지명, 주소, 좌표를 저장해 지도 기반 탐색/플래너/방문 인증 흐름에 활용
- 향후 관광공사 API와 직접 연동하면 운영자가 수동 입력하지 않아도 최신 관광지 목록을 반영 가능

### 9.2 지도 데이터 활용

- 카카오맵 API를 활용해 관광지 위치를 직관적으로 시각화
- 사용자가 선택한 관광지의 방문 순서를 마커 번호와 연결선으로 표현 가능
- 지도 기반 UX를 통해 “정산용 방문 계획 수립” 기능으로 확장 가능

### 9.3 영수증/정산 데이터 활용

- 영수증 OCR 결과에서 결제수단과 결제금액을 추출
- 지역별 정산 규칙과 자동 대조해 1차 심사 자동화
- 인정된 금액만 누적 소비현황에 반영해 사용자가 정산 가능 상태를 즉시 확인 가능

### 9.4 사용자 거주지 데이터 활용

- 회원 거주지 데이터를 기준으로 신청 가능 지역을 자동 필터링
- 반값여행의 “거주지 인접 지역 제한” 규칙을 적용하는 데 활용

### 9.5 숙박확인서 데이터 활용

- 지역별 숙박확인서 PDF 템플릿을 DB 좌표와 매핑해 모바일에서 직접 입력
- 사용자가 입력한 숙박업소 정보, 동의 여부, 서명을 최종 PDF로 자동 생성
- 향후 지역별 양식이 추가되어도 템플릿 좌표만 저장하면 재사용 가능

### 9.6 지역경제 연계 데이터 활용

- 지역 온라인몰, 가맹점, 지역화폐/앱 결제수단 데이터를 연결해 환급금 사용처 안내
- 반값여행 정책 목적(지역 내 소비 유도, 재방문 유도)을 서비스 UX와 직접 연결

## 10. 보고서에 쓰기 좋은 한 줄 정리

- 본 서비스는 한국관광공사 관광정보, 카카오맵 위치 시각화 데이터, 사용자 여행/증빙 데이터, OCR 기반 결제 데이터, 지역별 정산 규칙 데이터를 결합해 반값여행 신청부터 여행 관리, 정산 준비까지 하나의 흐름으로 지원하는 모바일 MVP이다.
