@echo off
setlocal
cd /d "C:\Users\Administrator\Desktop\관광\flutter_app"
C:\flutter\bin\flutter.bat run -d web-server --web-port=3000 --dart-define=USE_MOCK_API=false --dart-define=USE_MOCK_LOGIN=false --dart-define=MAP_PROVIDER=kakao --dart-define=KAKAO_MAP_APP_KEY=0a04bcf1d503e4d308af70020fa0819f --dart-define=API_BASE_URL=http://localhost:8080/api --dart-define=FASTAPI_BASE_URL=http://localhost:8000
