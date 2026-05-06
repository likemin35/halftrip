#!/bin/bash
# Flutter가 없으면 다운로드
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

# 환경 변수 추가
export PATH="$PATH:`pwd`/flutter/bin"

# Flutter 설정 및 빌드
flutter config --enable-web
flutter build web --release
