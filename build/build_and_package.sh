#!/bin/bash
# Blender iPad (Unofficial) — local macOS build + repackage into an .ipa.
# Usage:  bash build_and_package.sh
# Then sideload ~/Blender-iPad-Unofficial.ipa (see ../INSTALL.md).
# (For a no-Mac cloud build, use ../.github/workflows/build-ipa.yml instead.)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$HOME/build_ios_xcode"
APP_DIR="$BUILD_DIR/bin/Release"
IPA="$HOME/Blender-iPad-Unofficial.ipa"
LOG="$HOME/build.log"

echo "==> [1/3] Building (xcodebuild)…  log: $LOG"
cd "$BUILD_DIR"
set +e
xcodebuild -scheme install -configuration Release \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$LOG"
BUILD_RC=${PIPESTATUS[0]}
set -e

if [ "$BUILD_RC" -ne 0 ] || grep -q "error:" "$LOG"; then
  echo ""
  echo "!! Build error — skipping the rest. See errors below:"
  grep -n "error:" "$LOG" | head -30
  exit 1
fi

echo "==> [2/3] Applying branding + iOS app icon (iOS ignores the .icns, so PNGs are injected)…"
bash "$SCRIPT_DIR/apply_branding.sh" "$APP_DIR/Blender.app" "$SCRIPT_DIR/../ios/icon/icon_1024.png"

echo "==> [3/3] Repackaging .ipa (don't skip — otherwise the old app installs)…"
cd "$APP_DIR"
rm -rf Payload "$IPA"
mkdir -p Payload
cp -R Blender.app Payload/
zip -qr "$IPA" Payload
rm -rf Payload

echo "==> Done!  $(du -h "$IPA" | cut -f1)  →  $IPA"
echo "    Sideload $IPA (free Apple ID = re-sign every 7 days). See ../INSTALL.md."
