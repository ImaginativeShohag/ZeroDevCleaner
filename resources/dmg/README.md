# DMG Creation Guide

ZeroDevCleaner uses [create-dmg](https://github.com/sindresorhus/create-dmg) by sindresorhus for creating professional DMG installers.

## Installation

```bash
# Install create-dmg
npm install --global create-dmg

# Install dependencies
brew install graphicsmagick imagemagick
```

## Usage

### Quick Start

```bash
./scripts/create-dmg.sh <path-to-app> <version>
```

Example:
```bash
./scripts/create-dmg.sh ./build/Build/Products/Release/ZeroDevCleaner.app 1.0.0
```

This will create: `ZeroDevCleaner-v1.0.0.dmg`

### Manual Usage

You can also use create-dmg directly:

```bash
create-dmg --overwrite --no-code-sign ZeroDevCleaner.app
```

## What You Get

The DMG automatically includes:
- ✅ Professional appearance with custom background
- ✅ Applications folder shortcut for drag & drop install
- ✅ Positioned icons
- ✅ Perfect window size
- ✅ Compressed format (~4-5 MB)

## GitHub Actions

See `.github/workflows/release.yml` for automated DMG creation on releases.

## Troubleshooting

**Error: create-dmg not found**
```bash
npm install --global create-dmg
```

**Error: graphicsmagick not found**
```bash
brew install graphicsmagick imagemagick
```

**DMG looks different than expected**
- create-dmg automatically handles all appearance settings
- No manual configuration needed
- Just run the command and it creates a beautiful DMG

## Why create-dmg?

- ✅ **Simple**: One command, no complex scripts
- ✅ **Professional**: Automatic beautiful appearance
- ✅ **Maintained**: Active open-source project
- ✅ **Standard**: Used by many popular macOS apps
- ✅ **No manual configuration**: Works out of the box
