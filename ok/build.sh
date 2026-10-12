#!/usr/bin/env bash
# PhotoCraft ok — 원본 릴리스 + 내 패치 판을 빌드해 ~/Applications/PhotoCraft ok.app 에 설치한다.
#
#   ok/build.sh            빌드 + 설치
#   ok/build.sh --no-install
#
# 정식 판(/Applications/PhotoCraft.app, ai.storyteller.photocraft)과 나란히 쓰도록
# 이름 "PhotoCraft ok", 번들 id ai.storyteller.photocraft.ok, 버전 "<릴리스>+ok.<패치 수>".
# 원본 packaging/ 스크립트는 고치지 않는다 — 새 릴리스로 rebase 할 때 충돌이 안 나게.
# 서명은 ad-hoc(공증 없음): 처음 열 때 우클릭 → 열기 한 번.
set -euo pipefail
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TAG="$(git describe --tags --abbrev=0 --match 'v*')"          # 기준 릴리스, 예: v0.7.0
BASE="${TAG#v}"
N="$(git rev-list --count "$TAG"..HEAD -- . ':!ok')"          # ok/ 밖을 바꾼 커밋 = 패치 수
VERSION="$BASE+ok.$N"
SHA="$(git rev-parse --short HEAD)"
TARGET=aarch64-apple-darwin                                    # ponytail: 이 맥(arm64)만. 인텔도 필요하면 universal + lipo
export MACOSX_DEPLOYMENT_TARGET=11.0

echo "==> PhotoCraft ok $VERSION ($SHA)"
cargo build --release --locked -p photocraft --features heif --target "$TARGET"

WORK="$ROOT/target/ok-package"
APP="$WORK/PhotoCraft ok.app"
rm -rf "$WORK" && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "target/$TARGET/release/photocraft" "$APP/Contents/MacOS/PhotoCraft"
"$ROOT/ok/icon.sh" assets/app-icon/photocraft.icns "$APP/Contents/Resources/PhotoCraft.icns"   # 주황 + ok 표 아이콘
sed -e "s/@VERSION@/$VERSION/g" -e "s/@SHORT_VERSION@/$BASE/g" -e "s/@BUILD_SHA@/$SHA/g" \
    -e "s#<string>ai.storyteller.photocraft</string>#<string>ai.storyteller.photocraft.ok</string>#" \
    packaging/macos/Info.plist.in >"$APP/Contents/Info.plist"
# 화면에 보이는 이름만 바꾼다 (실행 파일 이름 PhotoCraft 는 그대로)
plutil -replace CFBundleDisplayName -string "PhotoCraft ok" "$APP/Contents/Info.plist"
plutil -replace CFBundleName -string "PhotoCraft ok" "$APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$VERSION" "$APP/Contents/Info.plist"
plutil -lint "$APP/Contents/Info.plist" >/dev/null
printf 'APPL????' >"$APP/Contents/PkgInfo"
codesign --force --sign - --options runtime --entitlements packaging/macos/entitlements.plist "$APP"

if [ "${1:-}" != "--no-install" ]; then
  mkdir -p "$HOME/Applications"
  pkill -x -f "$HOME/Applications/PhotoCraft ok.app/Contents/MacOS/PhotoCraft" 2>/dev/null || true
  rm -rf "$HOME/Applications/PhotoCraft ok.app"
  ditto "$APP" "$HOME/Applications/PhotoCraft ok.app"
  echo "==> 설치: ~/Applications/PhotoCraft ok.app ($VERSION)"
fi
