#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="HistoryClipboard"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Applications}"
TARGET_APP="$INSTALL_DIR/$APP_NAME.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "App bundle not found: $APP_BUNDLE"
    echo "Run scripts/package-app.sh first."
    exit 1
fi

mkdir -p "$INSTALL_DIR"

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
    echo "Stopping running $APP_NAME..."
    pkill -x "$APP_NAME" || true
    sleep 1
fi

rm -rf "$TARGET_APP"
ditto "$APP_BUNDLE" "$TARGET_APP"

echo "Installed: $TARGET_APP"
echo "Open it with:"
echo "open \"$TARGET_APP\""
