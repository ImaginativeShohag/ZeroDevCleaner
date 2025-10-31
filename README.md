# ZeroDevCleaner

> A native macOS app to reclaim disk space by cleaning build artifacts and developer caches.

![macOS](https://img.shields.io/badge/macOS-15.0+-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)
[![Build Check](https://github.com/ImaginativeShohag/ZeroDevCleaner/actions/workflows/build.yml/badge.svg)](https://github.com/ImaginativeShohag/ZeroDevCleaner/actions/workflows/build.yml)

ZeroDevCleaner helps developers quickly identify and remove build artifacts, caches, and temporary files that accumulate during software development. With support for multiple project types and system caches, you can reclaim gigabytes of disk space in seconds.

## ✨ Features

### Project Type Support
- **Android Projects** - `build/` folders from Gradle builds
- **iOS/Xcode Projects** - Build folders and intermediate files
- **Swift Packages** - `.build/` directories
- **Flutter Projects** - `build/` folders from Flutter builds
- **Node.js Projects** - `node_modules/` dependency folders
- **Rust Projects** - `target/` build directories
- **Python Projects** - `__pycache__/`, `venv/`, `.venv/`, `env/` folders

### System Cache Cleaning
- **Xcode DerivedData** - `~/Library/Developer/Xcode/DerivedData`
- **Xcode Archives** - `~/Library/Developer/Xcode/Archives`
- **iOS Device Support** - `~/Library/Developer/Xcode/iOS DeviceSupport`
- **Xcode Documentation Cache** - `~/Library/Developer/Xcode/DocumentationCache`
- **Gradle Cache** - `~/.gradle/caches`
- **CocoaPods Cache** - `~/Library/Caches/CocoaPods`
- **npm Cache** - `~/.npm`
- **Yarn Cache** - `~/Library/Caches/Yarn`
- **Carthage Cache** - `~/Library/Caches/org.carthage.CarthageKit`

### Smart Features
- 🔍 **Fast Scanning** - Quickly scans your projects and system caches
- 📊 **Visual Results** - See exactly what's taking up space with size information
- 🎯 **Selective Deletion** - Choose exactly what to delete
- 💾 **Safe Deletion** - Moves items to Trash (recoverable)
- ⚙️ **Multi-Location Support** - Configure multiple project folders to scan
- 🚀 **Auto-Scan** - Automatically scans configured locations and system caches
- ⌨️ **Keyboard Shortcuts** - Efficient workflow with keyboard support
- 🔄 **Persistent Settings** - Remembers your scan locations
- 📈 **Statistics on Home Screen** - Track cleaning history at a glance with sidebar display

## 📸 Screenshots

<!-- TODO: Add screenshots here -->
_Coming soon_

## 🚀 Installation

### Download Pre-built Release
1. Download the latest release from [Releases](https://github.com/ImaginativeShohag/ZeroDevCleaner/releases)
2. Open the `.dmg` file
3. Drag **ZeroDevCleaner** to your Applications folder
4. Launch from Applications

> **Note**: Releases are automatically built and published via GitHub Actions when a new version is tagged.

### Build from Source
```bash
git clone https://github.com/ImaginativeShohag/ZeroDevCleaner.git
cd ZeroDevCleaner
open ZeroDevCleaner.xcodeproj
```
Then build and run with Xcode (⌘R)

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/ImaginativeShohag/ZeroDevCleaner.git
   cd ZeroDevCleaner
   ```

2. **Open in Xcode**
   ```bash
   open ZeroDevCleaner.xcodeproj
   ```

3. **Build and run**
   - Select the `ZeroDevCleaner` scheme
   - Press `Cmd+R` to build and run

### Code Style
- Swift 6.0 with strict concurrency
- SwiftUI for all UI components
- Comprehensive error handling
- Detailed logging with OSLog
- Component-based architecture (no ViewModels in reusable components)

### CI/CD

The project uses GitHub Actions for continuous integration:

**Build Check** (`.github/workflows/build.yml`)
- Runs on push to main and pull requests
- Builds the project in Debug configuration
- Runs unit tests (with error tolerance)
- Ensures code compiles on latest macOS/Xcode

**Release Build** (`.github/workflows/release.yml`)
- Triggers when a new release is created
- Builds the project in Release configuration
- Creates a DMG file
- Automatically uploads DMG to the release assets
- Can be manually triggered for testing

**Creating a Release:**
1. Update version in Xcode project settings
2. Commit and push changes
3. Create a new tag: `git tag -a v1.0.0 -m "Release version 1.0.0"`
4. Push tag: `git push origin v1.0.0`
5. Create release on GitHub - CI will automatically build and attach DMG

## 📋 Requirements

- macOS 15.0 (Sequoia) or later
- Xcode 16.0+ (for building from source)

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with Swift and SwiftUI
- Icons from SF Symbols
- Inspired by the need to reclaim disk space from countless build artifacts

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/ImaginativeShohag/ZeroDevCleaner/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ImaginativeShohag/ZeroDevCleaner/discussions)

## 🗺️ Roadmap

- [ ] Scheduled automatic scans
- [ ] Advanced filtering and search capabilities

---

**Made with ❤️ for developers who love clean disks**
