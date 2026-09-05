#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/CodexUsage.app"
BINARY="$ROOT/.build/release/CodexUsage"

if ! command -v swift >/dev/null 2>&1; then
  echo "ERROR: Swift toolchain not found."
  echo "Install Xcode Command Line Tools with:"
  echo "  xcode-select --install"
  exit 1
fi

cd "$ROOT"

echo "Building CodexUsage..."
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BINARY" "$APP/Contents/MacOS/CodexUsage"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"

if [ -f "$ROOT/Resources/AppIcon.icns" ]; then
  cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

chmod +x "$APP/Contents/MacOS/CodexUsage"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true
fi

echo
echo "Built:"
echo "  $APP"
echo
echo "Run:"
echo "  open \"$APP\""
