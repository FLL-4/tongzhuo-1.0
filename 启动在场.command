#!/bin/zsh

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DERIVED_DATA_DIR="$HOME/Library/Developer/Xcode/DerivedData"

APP_PATH="$(find "$DERIVED_DATA_DIR" \
  -path '*/Build/Products/Debug/在场.app/Contents/MacOS/在场' \
  -type f -print 2>/dev/null \
  | while IFS= read -r executable; do
      app_dir="${executable%/Contents/MacOS/在场}"
      printf '%s\n' "$app_dir"
    done \
  | head -n 1)"

if [[ -z "$APP_PATH" ]]; then
  echo "未找到构建产物，正在编译在场…"
  xcodebuild \
    -project "$PROJECT_DIR/在场.xcodeproj" \
    -scheme 在场 \
    -destination 'platform=macOS' \
    CODE_SIGNING_ALLOWED=NO \
    build
  APP_PATH="$(find "$DERIVED_DATA_DIR" \
    -path '*/Build/Products/Debug/在场.app/Contents/MacOS/在场' \
    -type f -print 2>/dev/null \
    | while IFS= read -r executable; do
        printf '%s\n' "${executable%/Contents/MacOS/在场}"
      done \
    | head -n 1)"
fi

if [[ -z "$APP_PATH" || ! -x "$APP_PATH/Contents/MacOS/在场" ]]; then
  echo "找不到可启动的在场应用。"
  exit 1
fi

open "$APP_PATH"
echo "已启动：$APP_PATH"
