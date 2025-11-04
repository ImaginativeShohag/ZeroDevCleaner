#!/bin/bash
# Quick script to prepare for Homebrew tap creation
# Run this after creating a GitHub release

set -e

VERSION="$1"

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

DMG_URL="https://github.com/ImaginativeShohag/ZeroDevCleaner/releases/download/v${VERSION}/ZeroDevCleaner-v${VERSION}.dmg"
DMG_FILE="ZeroDevCleaner-v${VERSION}.dmg"

echo "📦 Preparing Homebrew Cask for ZeroDevCleaner v${VERSION}"
echo ""

# Download DMG
echo "⬇️  Downloading DMG..."
curl -L -o "$DMG_FILE" "$DMG_URL"

# Calculate SHA256
echo "🔐 Calculating SHA256..."
SHA256=$(shasum -a 256 "$DMG_FILE" | awk '{print $1}')

# Clean up
rm "$DMG_FILE"

echo ""
echo "✅ Done! Use these values in your Homebrew cask:"
echo ""
echo "version \"${VERSION}\""
echo "sha256 \"${SHA256}\""
echo ""
echo "Full cask formula:"
echo "---"
cat << EOF
cask "zerodev-cleaner" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "https://github.com/ImaginativeShohag/ZeroDevCleaner/releases/download/v#{version}/ZeroDevCleaner-v#{version}.dmg"
  name "ZeroDevCleaner"
  desc "Native macOS app to reclaim disk space by cleaning build artifacts"
  homepage "https://github.com/ImaginativeShohag/ZeroDevCleaner"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "ZeroDevCleaner.app"

  zap trash: [
    "~/Library/Application Support/ZeroDevCleaner",
    "~/Library/Preferences/org.imaginativeworld.ZeroDevCleaner.plist",
    "~/Library/Caches/org.imaginativeworld.ZeroDevCleaner",
  ]
end
EOF
echo "---"
