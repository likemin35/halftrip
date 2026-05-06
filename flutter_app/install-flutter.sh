#!/bin/bash

if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

export PATH="$PATH:$(pwd)/flutter/bin"

API_BASE_URL_VALUE="${API_BASE_URL:-https://halftrip-springboot.onrender.com/api}"
FASTAPI_BASE_URL_VALUE="${FASTAPI_BASE_URL:-https://halftrip-fastapi.onrender.com}"
USE_MOCK_LOGIN_VALUE="${USE_MOCK_LOGIN:-true}"
USE_MOCK_API_VALUE="${USE_MOCK_API:-false}"
MAP_PROVIDER_VALUE="${MAP_PROVIDER:-mock}"
KAKAO_MAP_APP_KEY_VALUE="${KAKAO_MAP_APP_KEY:-}"

flutter config --enable-web
flutter build web --release \
  --dart-define=API_BASE_URL="$API_BASE_URL_VALUE" \
  --dart-define=FASTAPI_BASE_URL="$FASTAPI_BASE_URL_VALUE" \
  --dart-define=USE_MOCK_LOGIN="$USE_MOCK_LOGIN_VALUE" \
  --dart-define=USE_MOCK_API="$USE_MOCK_API_VALUE" \
  --dart-define=MAP_PROVIDER="$MAP_PROVIDER_VALUE" \
  --dart-define=KAKAO_MAP_APP_KEY="$KAKAO_MAP_APP_KEY_VALUE"
