# Installation Guide

## macOS Security Notice

ZeroDevCleaner is currently **not notarized** by Apple, which means you'll see a security warning when you first open it. This is normal for apps distributed outside the Mac App Store by developers without a paid Apple Developer account.

**The app is safe to use** - you can verify the source code is open source on GitHub.

## Installation Steps

### Method 1: DMG Installation (Recommended)

1. **Download** the latest `ZeroDevCleaner-vX.X.X.dmg` from [GitHub Releases](https://github.com/ImaginativeShohag/ZeroDevCleaner/releases)

2. **Open the DMG** by double-clicking it

3. **Drag ZeroDevCleaner** to the Applications folder

4. **Open the app** (first time only):
   - Navigate to Applications folder
   - **Right-click** (or Control+click) on ZeroDevCleaner
   - Select **"Open"** from the menu
   - Click **"Open"** in the security dialog

5. **Subsequent launches**: You can now open the app normally from Launchpad or Applications folder

### Method 2: Command Line Installation

If the right-click method doesn't work, you can use Terminal:

```bash
# Navigate to Applications
cd /Applications

# Remove quarantine attribute
xattr -cr ZeroDevCleaner.app

# Open the app
open ZeroDevCleaner.app
```

### Method 3: System Settings (macOS Ventura+)

If you see "ZeroDevCleaner cannot be opened":

1. Open **System Settings** > **Privacy & Security**
2. Scroll down to the **Security** section
3. Click **"Open Anyway"** next to the ZeroDevCleaner message
4. Confirm by clicking **"Open"** in the dialog

## Troubleshooting

### "App is damaged and can't be opened"

This happens due to macOS Gatekeeper quarantine. Run:

```bash
xattr -cr /Applications/ZeroDevCleaner.app
```

### "App can't be opened because Apple cannot check it for malicious software"

Use **Method 1** above (right-click > Open) or **Method 3** (System Settings).

### App won't open after following steps

1. Check macOS version (requires macOS 15.0+)
2. Verify the app is in `/Applications` folder
3. Try removing and re-downloading the DMG

## Why No Notarization?

Notarization requires a **paid Apple Developer account** ($99/year). As an open-source project, we've chosen to distribute without notarization to keep the project free.

**You can verify the app's safety by:**
- Reviewing the source code on GitHub
- Building it yourself from source
- Checking that the app only requests permissions it needs

## Building from Source (Advanced)

If you prefer, you can build ZeroDevCleaner yourself:

```bash
# Clone the repository
git clone https://github.com/ImaginativeShohag/ZeroDevCleaner.git
cd ZeroDevCleaner

# Open in Xcode
open ZeroDevCleaner.xcodeproj

# Build and run (Cmd+R)
```

## Need Help?

- [Open an issue](https://github.com/ImaginativeShohag/ZeroDevCleaner/issues)
