# Distribution Guide for ZeroDevCleaner

This guide explains how to distribute ZeroDevCleaner without a paid Apple Developer account.

## Summary

- ✅ **GitHub Releases**: Primary distribution method (recommended)
- ✅ **Homebrew Cask**: Secondary option for power users
- ⚠️ **Code Signing**: Use free Apple ID (limited, but better than nothing)
- ❌ **Notarization**: Not possible without paid account ($99/year)

---

## 1. Code Signing (with Free Account)

Even without notarization, you should sign the app with your free Apple ID.

### Your Available Identities

You have 3 signing identities:
```
Apple Development: imaginativeshohag@gmail.com (BPS5K75MN2)  ← Recommended
```

### Update Xcode Project

1. Open `ZeroDevCleaner.xcodeproj`
2. Select target → Signing & Capabilities
3. Set **Team**: Your Apple ID
4. Set **Signing Certificate**: "Apple Development"
5. **Disable** "Automatically manage signing" for Release builds

### Sign During Build

Update `.github/workflows/release.yml`:

```yaml
- name: Build and Sign app
  run: |
    xcodebuild clean build \
      -project ZeroDevCleaner.xcodeproj \
      -scheme ZeroDevCleaner \
      -configuration Release \
      -derivedDataPath ./build \
      CODE_SIGN_IDENTITY="Apple Development: imaginativeshohag@gmail.com (BPS5K75MN2)" \
      CODE_SIGNING_REQUIRED=YES \
      CODE_SIGNING_ALLOWED=YES
```

**Benefits:**
- Basic code signing verification
- Shows developer identity in Finder
- Required for some macOS features

**Limitations:**
- Still shows security warning (no notarization)
- Users must bypass Gatekeeper manually

---

## 2. Professional DMG Creation

### Quick Start

Use the new script:

```bash
# Generate background image (optional, requires ImageMagick)
./resources/dmg/generate-background.sh

# Create professional DMG
./scripts/create-dmg.sh \
  ./build/Build/Products/Release/ZeroDevCleaner.app \
  1.0.0 \
  .
```

### Features

- ✅ Applications folder symlink (drag & drop installation)
- ✅ Custom background image
- ✅ Positioned icons (app + Applications)
- ✅ Custom window size (600x400)
- ✅ Icon view with large icons
- ✅ Compressed UDZO format

### Custom Background

Create `resources/dmg/dmg-background.png` (600x400 px) with:
- App branding
- Installation instructions
- Arrow graphic (app → Applications)
- Professional gradient background

---

## 3. GitHub Releases Distribution

### Recommended Workflow

1. **Create Release Workflow** (update `.github/workflows/release.yml`):

```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build App
        run: |
          xcodebuild clean build \
            -project ZeroDevCleaner.xcodeproj \
            -scheme ZeroDevCleaner \
            -configuration Release \
            -derivedDataPath ./build

      - name: Create DMG
        run: |
          VERSION=${GITHUB_REF#refs/tags/v}
          ./scripts/create-dmg.sh \
            ./build/Build/Products/Release/ZeroDevCleaner.app \
            $VERSION \
            .

      - name: Upload Release Asset
        uses: softprops/action-gh-release@v1
        with:
          files: |
            ZeroDevCleaner-v*.dmg
            INSTALLATION.md
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

2. **Create Release**:

```bash
# Tag a new version
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions will automatically build and create release
```

3. **Release Notes Template**:

```markdown
## ZeroDevCleaner v1.0.0

### Features
- Clean Xcode derived data and build folders
- Support for 12 project types
- Custom cache location support
- Statistics tracking

### Installation

⚠️ **Important**: This app is not notarized. Please see [INSTALLATION.md](INSTALLATION.md) for setup instructions.

**Quick Install:**
1. Download `ZeroDevCleaner-v1.0.0.dmg`
2. Open the DMG and drag the app to Applications
3. Right-click the app and select "Open" (first time only)

### Download
- [ZeroDevCleaner-v1.0.0.dmg](URL)

### Checksums
- SHA256: `shasum -a 256 ZeroDevCleaner-v1.0.0.dmg`
```

---

## 4. Homebrew Cask Distribution

### Create Homebrew Formula

1. **Fork homebrew-cask** (optional, or submit PR to official tap)

2. **Create cask file** `ZeroDevCleaner.rb`:

```ruby
cask "zerodev-cleaner" do
  version "1.0.0"
  sha256 "YOUR_DMG_SHA256_HERE"

  url "https://github.com/ImaginativeShohag/ZeroDevCleaner/releases/download/v#{version}/ZeroDevCleaner-v#{version}.dmg"
  name "ZeroDevCleaner"
  desc "Clean build artifacts and caches for developers"
  homepage "https://github.com/ImaginativeShohag/ZeroDevCleaner"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "ZeroDevCleaner.app"

  uninstall quit: "com.shohag.ZeroDevCleaner"

  zap trash: [
    "~/Library/Preferences/com.shohag.ZeroDevCleaner.plist",
    "~/Library/Application Support/ZeroDevCleaner",
  ]
end
```

3. **Submit to homebrew-cask** (or host in your own tap)

### Your Own Homebrew Tap (Easier)

```bash
# Create tap repository
gh repo create homebrew-tap --public

# Add cask
mkdir -p Casks
cp ZeroDevCleaner.rb Casks/
git add . && git commit -m "Add ZeroDevCleaner cask"
git push

# Users install with:
brew install YOUR_USERNAME/tap/zerodev-cleaner
```

---

## 5. User Installation Instructions

### Update README.md

Add prominent installation section:

```markdown
## Installation

### Option 1: Download DMG (Recommended)

1. Download the latest release from [Releases](https://github.com/ImaginativeShohag/ZeroDevCleaner/releases)
2. Open the DMG and drag ZeroDevCleaner to Applications
3. **Important**: Right-click the app and select "Open" (first time only)

[See detailed installation guide](INSTALLATION.md)

### Option 2: Homebrew

\`\`\`bash
brew install YOUR_USERNAME/tap/zerodev-cleaner
\`\`\`

### Option 3: Build from Source

\`\`\`bash
git clone https://github.com/ImaginativeShohag/ZeroDevCleaner.git
cd ZeroDevCleaner
open ZeroDevCleaner.xcodeproj
# Build and run with Cmd+R
\`\`\`

### ⚠️ Security Notice

This app is not notarized by Apple. You'll see a security warning on first launch.
**The app is safe** - it's open source and you can verify the code.
```

---

## 6. Additional Recommendations

### Create Download Page

Create `docs/download.html` with:
- Download buttons for latest release
- Installation GIF/video
- Security FAQ
- System requirements

### Add Shields/Badges to README

```markdown
![GitHub release](https://img.shields.io/github/v/release/ImaginativeShohag/ZeroDevCleaner)
![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-lightgrey)
![License](https://img.shields.io/github/license/ImaginativeShohag/ZeroDevCleaner)
```

### Create Checksums

Always provide SHA256 checksums:

```bash
shasum -a 256 ZeroDevCleaner-v1.0.0.dmg > checksums.txt
```

### Consider Analytics (Optional)

- Plausible Analytics (privacy-friendly)
- Track downloads from GitHub API
- No user tracking in the app itself

---

## 7. What to Tell Users

### In README and Release Notes

```markdown
## Security & Privacy

**Why do I see a security warning?**
- ZeroDevCleaner is not notarized by Apple (requires $99/year developer account)
- The app is completely safe - it's open source
- You can review all code on GitHub
- Simply right-click and select "Open" to bypass the warning

**What permissions does the app need?**
- Full Disk Access (to scan and delete files in protected locations)
- No network access required
- No data collection or telemetry

**Can I verify the app is safe?**
- Yes! Build it yourself from source
- Review the code on GitHub
- Check that it only requests necessary permissions
```

---

## 8. Future: Paid Account Benefits

If you later get a paid account ($99/year):

✅ **Notarization** - No security warnings
✅ **Mac App Store** distribution
✅ **StoreKit** for in-app purchases (if needed)
✅ **TestFlight** for beta testing
✅ **App Sandbox** entitlements
✅ **Gatekeeper** approval

---

## Quick Start Checklist

- [ ] Generate DMG background: `./resources/dmg/generate-background.sh`
- [ ] Test DMG creation: `./scripts/create-dmg.sh <app-path> 1.0.0`
- [ ] Update release.yml to use new DMG script
- [ ] Add INSTALLATION.md to repository
- [ ] Update README with installation instructions
- [ ] Create first GitHub release with tag v1.0.0
- [ ] (Optional) Create Homebrew tap
- [ ] (Optional) Add download page to GitHub Pages

---

## Support & Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Homebrew Cask Documentation](https://docs.brew.sh/Cask-Cookbook)
- [GitHub Releases Guide](https://docs.github.com/en/repositories/releasing-projects-on-github)
- [macOS Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
