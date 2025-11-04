# Homebrew Publication Plan for ZeroDevCleaner

## Overview

Homebrew Cask allows users to install macOS applications with a simple command:
```bash
brew install --cask zerodev-cleaner
```

There are two approaches: **Official Homebrew Cask** (harder, more visibility) or **Your Own Tap** (easier, faster).

---

## Option 1: Official Homebrew Cask (Recommended for Popular Apps)

### Prerequisites

✅ **Requirements to Submit:**
1. App must be distributed as a DMG
2. DMG must be publicly downloadable (GitHub Releases)
3. App should be stable (not beta)
4. No security warnings preferred (but not required)
5. App should be useful to the community
6. Open source preferred (but not required)

### Step-by-Step Process

#### Phase 1: Preparation (Before First Release)

**1. Create Your First Release**
```bash
# Tag and push v1.0.0
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions will automatically:
# - Build the app
# - Create DMG
# - Upload to GitHub Release
```

**2. Verify DMG is Downloadable**
- Go to: https://github.com/ImaginativeShohag/ZeroDevCleaner/releases/tag/v1.0.0
- Confirm `ZeroDevCleaner-v1.0.0.dmg` is available
- Test download URL works

**3. Calculate SHA256 Checksum**
```bash
# Download your DMG
curl -L -o ZeroDevCleaner-v1.0.0.dmg \
  https://github.com/ImaginativeShohag/ZeroDevCleaner/releases/download/v1.0.0/ZeroDevCleaner-v1.0.0.dmg

# Calculate SHA256
shasum -a 256 ZeroDevCleaner-v1.0.0.dmg
# Output: abc123... ZeroDevCleaner-v1.0.0.dmg
```

#### Phase 2: Create Cask Formula

**4. Fork homebrew-cask**
```bash
# Go to: https://github.com/Homebrew/homebrew-cask
# Click "Fork" button
```

**5. Clone Your Fork**
```bash
cd ~/Developer
git clone https://github.com/YOUR_USERNAME/homebrew-cask.git
cd homebrew-cask
```

**6. Create the Cask File**
```bash
# Create new cask
touch Casks/z/zerodev-cleaner.rb
```

**7. Write the Cask Formula**

Create `Casks/z/zerodev-cleaner.rb` with:

```ruby
cask "zerodev-cleaner" do
  version "1.0.0"
  sha256 "YOUR_SHA256_HERE"

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
```

**8. Test Your Cask Locally**
```bash
# Test audit (checks for issues)
brew audit --cask --new zerodev-cleaner

# Test style
brew style --fix Casks/z/zerodev-cleaner.rb

# Test installation
brew install --cask Casks/z/zerodev-cleaner.rb

# Test the app works
open /Applications/ZeroDevCleaner.app

# Uninstall
brew uninstall --cask zerodev-cleaner
```

#### Phase 3: Submit to Homebrew

**9. Create Pull Request**
```bash
# Create branch
git checkout -b zerodev-cleaner

# Add and commit
git add Casks/z/zerodev-cleaner.rb
git commit -m "zerodev-cleaner 1.0.0 (new formula)"

# Push to your fork
git push origin zerodev-cleaner
```

**10. Open Pull Request**
- Go to: https://github.com/Homebrew/homebrew-cask/pulls
- Click "New Pull Request"
- Select your fork and branch
- Fill in PR template:

```markdown
## zerodev-cleaner 1.0.0 (new formula)

### Description
Native macOS app to reclaim disk space by cleaning build artifacts and developer caches. Supports 12 project types (Android, iOS, Node.js, Rust, Python, etc.) and system caches (DerivedData, Xcode Archives, CocoaPods, npm, etc.).

### Why This App Should Be in Homebrew
- **Useful for developers**: Helps reclaim gigabytes of disk space
- **Native macOS app**: Built with Swift and SwiftUI
- **Open source**: MIT License
- **Active development**: Regular updates and maintenance
- **Community need**: Developers frequently run out of disk space

### Testing
- [x] `brew audit --cask --new zerodev-cleaner` - passes
- [x] `brew style Casks/z/zerodev-cleaner.rb` - passes
- [x] App installs and launches successfully
- [x] App functions as expected

### Additional Notes
- First stable release (v1.0.0)
- DMG is properly signed (with free Apple Developer account)
- App requires Full Disk Access permission to scan protected directories
```

**11. Wait for Review**
- Homebrew maintainers will review (usually 1-7 days)
- They may request changes:
  - Fix cask syntax
  - Update description
  - Add/remove trash paths
- Make requested changes and push to your branch

**12. Merge and Celebrate! 🎉**
Once approved, your cask will be merged and users can install with:
```bash
brew install --cask zerodev-cleaner
```

---

## Option 2: Your Own Homebrew Tap (Easier, Immediate)

### Advantages
✅ **Full control** - No review process
✅ **Faster** - Available immediately
✅ **Easier updates** - Update anytime
✅ **Good for early releases** - Test before official submission

### Step-by-Step Process

#### 1. Create Tap Repository
```bash
# Create new GitHub repo named: homebrew-tap
gh repo create homebrew-tap --public --description "Homebrew tap for ZeroDevCleaner"
```

#### 2. Clone and Setup
```bash
cd ~/Developer
git clone https://github.com/ImaginativeShohag/homebrew-tap.git
cd homebrew-tap

# Create Casks directory
mkdir -p Casks

# Create cask file
touch Casks/zerodev-cleaner.rb
```

#### 3. Create Cask Formula
Create `Casks/zerodev-cleaner.rb`:

```ruby
cask "zerodev-cleaner" do
  version "1.0.0"
  sha256 "YOUR_SHA256_HERE"

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
```

#### 4. Commit and Push
```bash
git add Casks/zerodev-cleaner.rb
git commit -m "Add ZeroDevCleaner cask"
git push origin main
```

#### 5. Users Install From Your Tap
```bash
# Add your tap
brew tap imaginativeshohag/tap

# Install app
brew install --cask zerodev-cleaner

# Update (after you release new version)
brew upgrade --cask zerodev-cleaner
```

#### 6. Update README.md
Add to your ZeroDevCleaner README:

```markdown
## Installation

### Homebrew (Recommended)

```bash
brew tap imaginativeshohag/tap
brew install --cask zerodev-cleaner
```

### Manual Download
Download the latest DMG from [Releases](https://github.com/ImaginativeShohag/ZeroDevCleaner/releases)
```

---

## Recommended Approach: Both!

**Phase 1: Start with Your Own Tap (v1.0.0)**
- Get immediate Homebrew availability
- Test the formula with users
- Collect feedback
- Fix any issues

**Phase 2: Submit to Official Homebrew (v1.1.0+)**
- After app is stable and tested
- When you have some users/stars on GitHub
- Shows app is maintained and useful
- Provides wider discoverability

---

## Maintaining Your Cask

### When You Release a New Version

**For Your Own Tap:**
```bash
# 1. Get new SHA256
curl -L -o ZeroDevCleaner-v1.1.0.dmg \
  https://github.com/ImaginativeShohag/ZeroDevCleaner/releases/download/v1.1.0/ZeroDevCleaner-v1.1.0.dmg
shasum -a 256 ZeroDevCleaner-v1.1.0.dmg

# 2. Update Casks/zerodev-cleaner.rb
version "1.1.0"
sha256 "NEW_SHA256_HERE"

# 3. Commit and push
git commit -am "Update ZeroDevCleaner to v1.1.0"
git push
```

**For Official Homebrew:**
```bash
# Fork homebrew-cask again (if needed)
# Update Casks/z/zerodev-cleaner.rb
# Create PR with title: "zerodev-cleaner 1.1.0"
```

---

## Automation: Auto-Update Cask

You can create a GitHub Action to automatically update your tap:

`.github/workflows/update-homebrew-cask.yml` (in homebrew-tap repo):

```yaml
name: Update Cask on New Release

on:
  repository_dispatch:
    types: [new-release]
  workflow_dispatch:

jobs:
  update:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Update cask
        env:
          VERSION: ${{ github.event.client_payload.version }}
          DMG_URL: ${{ github.event.client_payload.dmg_url }}
        run: |
          # Download DMG
          curl -L -o temp.dmg "$DMG_URL"

          # Calculate SHA256
          SHA256=$(shasum -a 256 temp.dmg | awk '{print $1}')

          # Update cask file
          sed -i '' "s/version \".*\"/version \"$VERSION\"/" Casks/zerodev-cleaner.rb
          sed -i '' "s/sha256 \".*\"/sha256 \"$SHA256\"/" Casks/zerodev-cleaner.rb

          # Commit and push
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git commit -am "Update ZeroDevCleaner to v$VERSION"
          git push
```

Then trigger from your main repo's release workflow.

---

## Testing Checklist

Before submitting to Homebrew, verify:

- [ ] DMG is publicly downloadable
- [ ] DMG URL is stable (doesn't change)
- [ ] App name in DMG matches cask
- [ ] App installs to /Applications
- [ ] App launches without errors
- [ ] `brew audit --cask` passes
- [ ] `brew style` passes
- [ ] All trash paths are correct
- [ ] Uninstall works cleanly
- [ ] Version numbers are consistent

---

## Common Issues and Solutions

### Issue: SHA256 Mismatch
**Solution:** Recalculate SHA256 after uploading DMG
```bash
shasum -a 256 ZeroDevCleaner-v1.0.0.dmg
```

### Issue: App Not Found in DMG
**Solution:** Verify app name in DMG matches exactly
```bash
hdiutil attach ZeroDevCleaner-v1.0.0.dmg
ls "/Volumes/ZeroDevCleaner/"
# Should show: ZeroDevCleaner.app
```

### Issue: Security Warning
**Solution:** Document in cask that app requires right-click to open
```ruby
caveats do
  <<~EOS
    ZeroDevCleaner is not notarized. To open:
    1. Right-click the app
    2. Select "Open"
    3. Click "Open" in the dialog
  EOS
end
```

### Issue: Wrong Bundle Identifier
**Solution:** Check actual bundle ID
```bash
defaults read /Applications/ZeroDevCleaner.app/Contents/Info.plist CFBundleIdentifier
# Update zap trash paths accordingly
```

---

## Timeline Estimate

### Your Own Tap
- **Setup**: 30 minutes
- **Testing**: 1 hour
- **Documentation**: 30 minutes
- **Total**: 2 hours
- **Availability**: Immediate

### Official Homebrew
- **Preparation**: Same as above
- **PR Creation**: 1 hour
- **Review Wait**: 1-7 days
- **Revisions**: 1-3 hours (if requested)
- **Total**: 3-10 days

---

## Next Steps

**Immediate Actions:**

1. **Create v1.0.0 Release**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Download and Get SHA256**
   - Wait for GitHub Actions to build
   - Download DMG from releases
   - Calculate SHA256

3. **Create Your Tap** (Option 2)
   - Create homebrew-tap repository
   - Add cask formula
   - Test installation

4. **Update README**
   - Add Homebrew installation instructions
   - Update documentation

**Future Actions (After v1.1.0+):**

5. **Submit to Official Homebrew** (Option 1)
   - Fork homebrew-cask
   - Create PR
   - Wait for review

---

## Resources

- [Homebrew Cask Documentation](https://docs.brew.sh/Cask-Cookbook)
- [Homebrew Cask Formula Reference](https://docs.brew.sh/Cask-Cookbook#stanza-reference)
- [Contributing to Homebrew Cask](https://github.com/Homebrew/homebrew-cask/blob/master/CONTRIBUTING.md)
- [Homebrew Audit](https://docs.brew.sh/Homebrew-Cask-Audit)

---

## Summary

**Start with:** Your Own Tap (Quick, Easy, Immediate)
**Progress to:** Official Homebrew (More Visibility, Wider Reach)
**Maintain:** Both taps for maximum availability

This approach gives you immediate availability while working towards official Homebrew inclusion!
