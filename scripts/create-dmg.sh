#!/bin/bash
# Simple DMG creator using sindresorhus/create-dmg
#
# Requirements:
#   npm install --global create-dmg
#   brew install graphicsmagick imagemagick

set -e

APP_PATH="$1"
VERSION="$2"
OUTPUT_DIR="${3:-.}"

if [ -z "$APP_PATH" ] || [ -z "$VERSION" ]; then
    echo "Usage: $0 <path-to-app> <version> [output-dir]"
    echo "Example: $0 ./build/Build/Products/Release/ZeroDevCleaner.app 1.0.0"
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

# Check dependencies
if ! command -v create-dmg &> /dev/null; then
    echo "Error: create-dmg not found"
    echo "Install with: npm install --global create-dmg"
    exit 1
fi

if ! command -v gm &> /dev/null; then
    echo "Error: graphicsmagick not found"
    echo "Install with: brew install graphicsmagick imagemagick"
    exit 1
fi

echo "Creating DMG..."

# Get absolute paths
ABS_APP_PATH="$(cd "$(dirname "$APP_PATH")" && pwd)/$(basename "$APP_PATH")"
ABS_OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

# Create DMG using create-dmg tool
cd "$ABS_OUTPUT_DIR"
create-dmg --overwrite --no-code-sign "$ABS_APP_PATH" 2>&1 | grep -v "deprecated"

# Rename to standard format (ZeroDevCleaner-vX.X.X.dmg)
GENERATED_DMG="ZeroDevCleaner $VERSION.dmg"
FINAL_DMG="ZeroDevCleaner-v${VERSION}.dmg"

if [ -f "$GENERATED_DMG" ]; then
    mv "$GENERATED_DMG" "$FINAL_DMG"
    echo ""
    echo "✓ Created: $FINAL_DMG ($(ls -lh "$FINAL_DMG" | awk '{print $5}'))"
fi
