#!/usr/bin/env bash
# Builds a Release simulator build of the app and zips it for testers.
set -euo pipefail

cd "$(dirname "$0")/.."
BUILD_DIR="build"
DERIVED="$BUILD_DIR/DerivedData"
OUT_ZIP="$BUILD_DIR/BudakMiles-simulator.zip"

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate --quiet
fi

xcodebuild build \
  -project BudakMiles.xcodeproj \
  -scheme BudakMiles \
  -configuration Release \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  -quiet

APP="$DERIVED/Build/Products/Release-iphonesimulator/BudakMiles.app"
rm -f "$OUT_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT_ZIP"

echo "Built $OUT_ZIP"
echo "Install on a booted simulator:"
echo "  unzip $(basename "$OUT_ZIP") && xcrun simctl install booted BudakMiles.app && xcrun simctl launch booted id.budakmiles.app"
