#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"
ARCHIVE_DIR="$BUILD_DIR/archive"
EXPORT_DIR="$BUILD_DIR/export"
STAGE_DIR="$BUILD_DIR/dmg-root"
DMG_PATH="$BUILD_DIR/Aangilam.dmg"
APP_NAME="Aangilam"

cd "$ROOT"

/usr/bin/killall Aangilam 2>/dev/null || true
sleep 0.2

xcodebuild \
  -project "$ROOT/Aangilam.xcodeproj" \
  -scheme Aangilam \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=NO \
  MACOSX_DEPLOYMENT_TARGET=14.0 \
  build

APP_PATH="$(find "$BUILD_DIR/DerivedData/Build/Products/Release" -name "${APP_NAME}.app" -maxdepth 2 | head -n 1)"
if [[ -z "$APP_PATH" ]]; then
  echo "Aangilam.app was not produced" >&2
  exit 1
fi

DEV_IDENTITY="$(/usr/bin/security find-identity -v -p codesigning | /usr/bin/sed -n 's/.*"\(Apple Development:[^"]*\)".*/\1/p' | /usr/bin/head -n 1)"
if [[ -n "$DEV_IDENTITY" ]]; then
  echo "Signing with Apple Development identity"
  /usr/bin/codesign --force --deep --sign "$DEV_IDENTITY" --identifier com.aangilam.app --timestamp=none "$APP_PATH"
else
  echo "No Apple Development identity found; leaving ad-hoc signature"
fi

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
cp -R "$APP_PATH" "$STAGE_DIR/Aangilam.app"
ln -s /Applications "$STAGE_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "Aangilam" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$BUILD_DIR/Aangilam.app"
cp -R "$APP_PATH" "$BUILD_DIR/Aangilam.app"

echo "APP $BUILD_DIR/Aangilam.app"
echo "DMG $DMG_PATH"
ls -lh "$DMG_PATH"
