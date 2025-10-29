# ZeroDevCleaner - New High Priority Features Implementation Plan

## Overview

These three features have been prioritized and moved to the front of the development queue:
1. **Known Static Directories Support** (4-5 hours)
2. **Settings Panel for Multiple Scan Locations** (4-6 hours)
3. **Open Source Preparation** (3-5 hours)

Total estimated time: **11-16 hours**

---

## Feature 1: Known Static Directories Support (4-5 hours)

### Goal
Add support for scanning common static build cache directories that don't require folder selection.

### Directories to Support

1. **DerivedData** (Xcode): `~/Library/Developer/Xcode/DerivedData`
   - Contains build artifacts for all Xcode projects
   - Can be very large (10-50+ GB)
   - Safe to delete (Xcode recreates as needed)

2. **Gradle Cache** (Android): `~/.gradle/caches`
   - Contains downloaded dependencies and build cache
   - Can be 5-20+ GB
   - Safe to delete (Gradle re-downloads as needed)

3. **CocoaPods** (iOS): `~/Library/Caches/CocoaPods`
   - Contains pod specs and downloaded pods
   - Usually 1-5 GB
   - Safe to delete (pod install recreates)

4. **npm cache**: `~/.npm` or `~/.npm/_cacache`
   - Contains cached npm packages
   - Can be 2-10+ GB
   - Safe to delete (npm re-downloads)

5. **yarn cache**: `~/Library/Caches/Yarn`
   - Contains cached yarn packages
   - Similar to npm cache
   - Safe to delete

6. **Carthage**: `~/Library/Caches/org.carthage.CarthageKit`
   - Contains Carthage build cache
   - Usually 500MB-2GB
   - Safe to delete

### Implementation Steps

#### Step 1: Create StaticLocation Model (45 min)

1. Create `ZeroDevCleaner/Models/StaticLocation.swift`:

```swift
//
//  StaticLocation.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import Foundation

enum StaticLocationType: String, Codable, CaseIterable {
    case derivedData = "DerivedData"
    case gradleCache = "Gradle Cache"
    case cocoapodsCache = "CocoaPods Cache"
    case npmCache = "npm Cache"
    case yarnCache = "Yarn Cache"
    case carthageCache = "Carthage Cache"

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .derivedData:
            return "Xcode build artifacts and indexes"
        case .gradleCache:
            return "Gradle dependencies and build cache"
        case .cocoapodsCache:
            return "CocoaPods specs and pods cache"
        case .npmCache:
            return "npm package cache"
        case .yarnCache:
            return "Yarn package cache"
        case .carthageCache:
            return "Carthage build cache"
        }
    }

    var iconName: String {
        switch self {
        case .derivedData:
            return "hammer.fill"
        case .gradleCache:
            return "cube.fill"
        case .cocoapodsCache:
            return "shippingbox.fill"
        case .npmCache:
            return "n.square.fill"
        case .yarnCache:
            return "y.square.fill"
        case .carthageCache:
            return "archivebox.fill"
        }
    }

    var defaultPath: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch self {
        case .derivedData:
            return home.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        case .gradleCache:
            return home.appendingPathComponent(".gradle/caches")
        case .cocoapodsCache:
            return home.appendingPathComponent("Library/Caches/CocoaPods")
        case .npmCache:
            return home.appendingPathComponent(".npm")
        case .yarnCache:
            return home.appendingPathComponent("Library/Caches/Yarn")
        case .carthageCache:
            return home.appendingPathComponent("Library/Caches/org.carthage.CarthageKit")
        }
    }
}

struct StaticLocation: Identifiable, Hashable {
    let id = UUID()
    let type: StaticLocationType
    let path: URL
    var size: Int64
    var lastModified: Date
    var exists: Bool
    var isSelected: Bool = false

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedLastModified: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }
}
```

#### Step 2: Create StaticLocationScanner Service (1.5 hours)

1. Create `ZeroDevCleaner/Services/StaticLocationScanner.swift`:

```swift
//
//  StaticLocationScanner.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import Foundation
import OSLog

protocol StaticLocationScannerProtocol: Sendable {
    func scanStaticLocations(
        types: [StaticLocationType],
        progressHandler: (@Sendable (String, Int) -> Void)?
    ) async throws -> [StaticLocation]
}

final class StaticLocationScanner: StaticLocationScannerProtocol, Sendable {
    private let sizeCalculator: FileSizeCalculatorProtocol
    private let fileManager: FileManager

    init(
        sizeCalculator: FileSizeCalculatorProtocol = FileSizeCalculator(),
        fileManager: FileManager = .default
    ) {
        self.sizeCalculator = sizeCalculator
        self.fileManager = fileManager
    }

    func scanStaticLocations(
        types: [StaticLocationType],
        progressHandler: (@Sendable (String, Int) -> Void)?
    ) async throws -> [StaticLocation] {
        Logger.scanning.info("Starting static location scan for \(types.count) types")

        var results: [StaticLocation] = []

        for (index, type) in types.enumerated() {
            let path = type.defaultPath

            progressHandler?(path.path, index + 1)

            // Check if directory exists
            var isDirectory: ObjCBool = false
            let exists = fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory)

            guard exists && isDirectory.boolValue else {
                Logger.scanning.debug("Static location does not exist: \(path.path)")
                // Still add it but mark as not existing
                let location = StaticLocation(
                    type: type,
                    path: path,
                    size: 0,
                    lastModified: Date(),
                    exists: false
                )
                results.append(location)
                continue
            }

            // Calculate size
            let size = try await sizeCalculator.calculateSize(of: path)

            // Get last modified date
            let attributes = try fileManager.attributesOfItem(atPath: path.path)
            let lastModified = attributes[.modificationDate] as? Date ?? Date()

            let location = StaticLocation(
                type: type,
                path: path,
                size: size,
                lastModified: lastModified,
                exists: true
            )

            results.append(location)
            Logger.scanning.debug("Found static location: \(type.displayName) - \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
        }

        Logger.scanning.info("Static location scan complete. Found \(results.filter(\.exists).count) of \(types.count) locations")
        return results
    }
}
```

#### Step 3: Update MainViewModel (1 hour)

Add static location support to MainViewModel:

```swift
// Add properties
var staticLocations: [StaticLocation] = []
var includeStaticLocations: Bool = true
var isScanningStatic: Bool = false

// Add scanner
private let staticScanner: StaticLocationScannerProtocol

// Update init
init(
    scanner: FileScannerProtocol,
    deleter: FileDeleterProtocol,
    staticScanner: StaticLocationScannerProtocol = StaticLocationScanner()
) {
    self.scanner = scanner
    self.deleter = deleter
    self.staticScanner = staticScanner
}

// Add method to scan static locations
func scanStaticLocations() {
    guard !isScanningStatic else { return }

    isScanningStatic = true

    Task {
        do {
            let types = StaticLocationType.allCases
            let results = try await staticScanner.scanStaticLocations(types: types) { path, count in
                Task { @MainActor in
                    self.currentScanPath = path
                }
            }

            self.staticLocations = results
            self.isScanningStatic = false
        } catch {
            Logger.scanning.error("Static scan failed: \(error.localizedDescription)")
            self.handleError(error)
            self.isScanningStatic = false
        }
    }
}

// Update combined results
var allResults: [Any] {
    var combined: [Any] = sortedAndFilteredResults
    if includeStaticLocations {
        combined.append(contentsOf: staticLocations.filter(\.exists))
    }
    return combined
}
```

#### Step 4: Update UI (1 hour)

Add toggle and section for static locations in ScanResultsView.

**Acceptance Criteria:**
- ✅ All 6 static locations are supported
- ✅ Shows existence and size for each location
- ✅ Can toggle static locations on/off
- ✅ Can select and delete static locations
- ✅ Persists across app launches

---

## Feature 2: Settings Panel for Multiple Scan Locations (4-6 hours)

### Goal
Allow users to configure multiple folders that will be scanned automatically, instead of selecting one folder each time.

### Features
1. Settings window with scan location management
2. Add/remove custom scan locations
3. Enable/disable individual locations
4. Quick "Scan All" button to scan all enabled locations
5. Show last scan time for each location
6. Persistent storage

### Implementation Steps

#### Step 1: Create ScanLocation Model (30 min)

Create `ZeroDevCleaner/Models/ScanLocation.swift`:

```swift
//
//  ScanLocation.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import Foundation

struct ScanLocation: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: URL
    var isEnabled: Bool
    var lastScanned: Date?

    init(id: UUID = UUID(), name: String, path: URL, isEnabled: Bool = true, lastScanned: Date? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.isEnabled = isEnabled
        self.lastScanned = lastScanned
    }

    var formattedLastScanned: String {
        guard let lastScanned else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastScanned, relativeTo: Date())
    }
}
```

#### Step 2: Create ScanLocationManager (1 hour)

Create `ZeroDevCleaner/Utilities/ScanLocationManager.swift`:

```swift
//
//  ScanLocationManager.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class ScanLocationManager {
    private let userDefaultsKey = "scanLocations"

    var locations: [ScanLocation] = [] {
        didSet {
            saveLocations()
        }
    }

    init() {
        loadLocations()
    }

    func addLocation(_ location: ScanLocation) {
        locations.append(location)
    }

    func removeLocation(_ location: ScanLocation) {
        locations.removeAll { $0.id == location.id }
    }

    func updateLocation(_ location: ScanLocation) {
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index] = location
        }
    }

    func toggleEnabled(for location: ScanLocation) {
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index].isEnabled.toggle()
        }
    }

    func updateLastScanned(for location: ScanLocation) {
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index].lastScanned = Date()
        }
    }

    var enabledLocations: [ScanLocation] {
        locations.filter(\.isEnabled)
    }

    private func saveLocations() {
        if let encoded = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadLocations() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([ScanLocation].self, from: data) {
            locations = decoded
        }
    }
}
```

#### Step 3: Create SettingsView (2 hours)

Create `ZeroDevCleaner/Views/Settings/SettingsView.swift`:

```swift
//
//  SettingsView.swift
//  ZeroDevCleaner
//
//  Created by Md. Mahmudul Hasan Shohag on 30/10/25.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var locationManager: ScanLocationManager
    @State private var showingFolderPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Scan Locations")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Add Location") {
                    showingFolderPicker = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Locations List
            if locationManager.locations.isEmpty {
                ContentUnavailableView(
                    "No Scan Locations",
                    systemImage: "folder.badge.plus",
                    description: Text("Add folders to scan automatically")
                )
            } else {
                List {
                    ForEach(locationManager.locations) { location in
                        LocationRow(
                            location: location,
                            onToggle: { locationManager.toggleEnabled(for: location) },
                            onRemove: { locationManager.removeLocation(location) }
                        )
                    }
                }
            }
        }
        .frame(width: 600, height: 400)
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                let location = ScanLocation(
                    name: url.lastPathComponent,
                    path: url
                )
                locationManager.addLocation(location)
            }
        }
    }
}

struct LocationRow: View {
    let location: ScanLocation
    let onToggle: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Toggle("", isOn: .constant(location.isEnabled))
                .toggleStyle(.checkbox)
                .labelsHidden()
                .onChange(of: location.isEnabled) {
                    onToggle()
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                Text(location.path.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Last scanned: \(location.formattedLastScanned)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button(role: .destructive) {
                onRemove()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
```

#### Step 4: Integrate with MainView (1 hour)

Add settings button to toolbar and "Scan All" functionality:

```swift
// In MainView
@State private var showingSettings = false
@State private var locationManager = ScanLocationManager()

// In toolbar
ToolbarItem(placement: .automatic) {
    Button("Settings") {
        showingSettings = true
    }
}

ToolbarItem(placement: .automatic) {
    Button("Scan All") {
        viewModel.scanAllLocations(locationManager.enabledLocations)
    }
    .disabled(locationManager.enabledLocations.isEmpty)
}

// Add sheet
.sheet(isPresented: $showingSettings) {
    SettingsView(locationManager: locationManager)
}
```

**Acceptance Criteria:**
- ✅ Can add/remove scan locations
- ✅ Can enable/disable locations
- ✅ Settings persist across app launches
- ✅ "Scan All" scans all enabled locations
- ✅ Shows last scan time for each location

---

## Feature 3: Open Source Preparation (3-5 hours)

### Goal
Prepare the project for public open source release with proper documentation and licensing.

### Recommended License: **MIT License**

**Why MIT?**
- ✅ Most permissive and business-friendly
- ✅ Allows commercial use
- ✅ Simple and widely understood
- ✅ Used by most macOS open source apps
- ✅ Compatible with App Store distribution

**Alternative: Apache 2.0** (if you want patent protection)

### Implementation Steps

#### Step 1: Create LICENSE File (15 min)

Create `/Users/shohag/Developer/SourceCode/Own/apple/ZeroDevCleaner/LICENSE`:

```
MIT License

Copyright (c) 2025 Md. Mahmudul Hasan Shohag

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

#### Step 2: Create Comprehensive README.md (2 hours)

Create a detailed README with:
- Project description and features
- Screenshots
- Installation instructions
- Usage guide
- Building from source
- Contributing guidelines
- License information

(See detailed README template below)

#### Step 3: Create CONTRIBUTING.md (30 min)

Create guidelines for contributors.

#### Step 4: Create CODE_OF_CONDUCT.md (15 min)

Add a code of conduct (Contributor Covenant recommended).

#### Step 5: Update Code Documentation (1 hour)

- Add file headers to all source files
- Add doc comments to public APIs
- Update existing documentation

#### Step 6: Create GitHub Repository (30 min)

- Create repository
- Add description and topics
- Configure GitHub settings
- Add GitHub Actions (optional)

**Acceptance Criteria:**
- ✅ LICENSE file added
- ✅ Comprehensive README with screenshots
- ✅ CONTRIBUTING.md added
- ✅ CODE_OF_CONDUCT.md added
- ✅ All code has proper documentation
- ✅ GitHub repository created and configured

---

## README.md Template

```markdown
# ZeroDevCleaner

🧹 A powerful macOS app to reclaim disk space by cleaning build artifacts and cache from development projects.

![ZeroDevCleaner Screenshot](docs/images/screenshot.png)

## Features

✨ **Smart Scanning**
- Automatically detects Android, iOS, and Swift Package build folders
- Scans multiple directories simultaneously
- Finds hidden `.build` folders

🎯 **Static Directory Cleanup**
- DerivedData (Xcode)
- Gradle Cache (Android)
- CocoaPods Cache
- npm/yarn cache
- Carthage cache

⚙️ **Flexible Configuration**
- Configure multiple scan locations
- Quick "Scan All" functionality
- Enable/disable locations individually

💾 **Safe Deletion**
- Moves files to Trash (recoverable)
- Shows detailed confirmation dialog
- Real-time deletion progress

🎨 **Modern Interface**
- Native macOS design
- Dark mode support
- Sortable table columns
- Keyboard shortcuts

## Installation

### Download

Download the latest release from [Releases](https://github.com/yourusername/ZeroDevCleaner/releases)

### Build from Source

Requirements:
- macOS 15.0+
- Xcode 16.0+
- Swift 6.0+

```bash
git clone https://github.com/yourusername/ZeroDevCleaner.git
cd ZeroDevCleaner
open ZeroDevCleaner.xcodeproj
```

Build and run in Xcode (⌘R)

## Usage

1. **Grant Full Disk Access** (required)
   - System Settings → Privacy & Security → Full Disk Access
   - Add ZeroDevCleaner to the list

2. **Select Folders to Scan**
   - Click "Select Folder" or drag & drop
   - Or configure multiple locations in Settings

3. **Scan for Build Artifacts**
   - Click "Scan" or press ⌘R
   - Review found items with filters

4. **Clean Up**
   - Select items to delete
   - Click "Remove Selected" or press ⌘⌫
   - Confirm deletion

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘O | Select Folder |
| ⌘R | Start Scan |
| ⌘A | Select All |
| ⌘D | Deselect All |
| ⌘⌫ | Delete Selected |

## What Gets Cleaned?

### Project Build Folders
- **Android**: `build/` folders
- **iOS/Xcode**: `build/`, `.build/` folders
- **Swift Package**: `.build/` folders

### System Caches
- **DerivedData**: `~/Library/Developer/Xcode/DerivedData`
- **Gradle**: `~/.gradle/caches`
- **CocoaPods**: `~/Library/Caches/CocoaPods`
- **npm**: `~/.npm`
- **Yarn**: `~/Library/Caches/Yarn`
- **Carthage**: `~/Library/Caches/org.carthage.CarthageKit`

## Technical Details

- **Language**: Swift 6.0
- **Framework**: SwiftUI
- **Architecture**: MVVM with Observation framework
- **Concurrency**: Structured concurrency (async/await)
- **Tests**: 60+ unit and integration tests
- **Minimum macOS**: 15.0

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built with ❤️ using SwiftUI
- Icons from SF Symbols

## Support

- 🐛 [Report a Bug](https://github.com/yourusername/ZeroDevCleaner/issues)
- 💡 [Request a Feature](https://github.com/yourusername/ZeroDevCleaner/issues)
- 📧 [Contact](mailto:your.email@example.com)

---

Made with Swift 6.0 and SwiftUI
```

---

## Testing Plan

After implementing these features:

1. **Static Locations**
   - Test each static directory detection
   - Test size calculation for large directories
   - Test deletion of static locations

2. **Settings**
   - Test adding/removing locations
   - Test persistence across app restarts
   - Test "Scan All" with multiple locations

3. **Open Source**
   - Review all documentation
   - Test build from clean checkout
   - Verify all links work

---

## Summary

These three features will significantly enhance ZeroDevCleaner:

1. **Static Directories** - Adds support for 6 common cache locations
2. **Settings Panel** - Makes the app more convenient with saved locations
3. **Open Source** - Prepares for public release and community contributions

**Total Time**: 11-16 hours
**Recommended Order**: 1 → 2 → 3
