# Phase 1: Foundation - Atomic Task Breakdown

**Estimated Total Time**: 3-4 hours
**Number of Atomic Tasks**: 9
**Dependencies**: None (starting point)

---

## Task 1.1: Project Initialization (1 hour total)

### Task 1.1.1: Create Xcode Project
**Estimated Time**: 15 minutes
**File Location**: N/A (creates project)
**Dependencies**: None

#### Steps
1. Open Xcode
2. File → New → Project
3. Select macOS → App
4. Configure project:
   - Product Name: `ZeroDevCleaner`
   - Team: Your team
   - Organization Identifier: `org.imaginativeworld`
   - Bundle Identifier: `org.imaginativeworld.ZeroDevCleaner`
   - Interface: SwiftUI
   - Language: Swift
   - Storage: None
   - Hosting: None
   - Testing: Include Tests
5. Choose save location: `/Users/shohag/Developer/SourceCode/Own/apple/ZeroDevCleaner`
6. Create project

#### Verification
```bash
# Should see the project file
ls ZeroDevCleaner.xcodeproj

# Should be able to build
xcodebuild -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS' clean build
```

**Expected Output**: Build succeeds with "BUILD SUCCEEDED"

#### Commit Message
```
chore(project): create initial Xcode project structure

- Create macOS SwiftUI app project
- Set minimum deployment to macOS 15.0
- Include test target
- Configure bundle identifier

Task: 1.1.1
```

---

### Task 1.1.2: Configure Project Settings
**Estimated Time**: 10 minutes
**File Location**: Xcode Project Settings
**Dependencies**: Task 1.1.1

#### Steps
1. Select project in navigator
2. Select ZeroDevCleaner target
3. General tab:
   - Deployment Target: macOS 15.0
   - Supports: Mac (Designed for iPad: off)
4. Build Settings tab:
   - Search "Swift Language Version"
   - Set to "Swift 6"
   - Search "Strict Concurrency Checking"
   - Set to "Complete"
5. Signing & Capabilities:
   - Automatic signing enabled
   - Team selected

#### Verification
```bash
# Check project settings
xcodebuild -project ZeroDevCleaner.xcodeproj -target ZeroDevCleaner -showBuildSettings | grep -E "SWIFT_VERSION|MACOSX_DEPLOYMENT_TARGET"
```

**Expected Output**:
```
MACOSX_DEPLOYMENT_TARGET = 15.0
SWIFT_VERSION = 6.0
```

#### Commit Message
```
chore(project): configure build settings for Swift 6

- Set deployment target to macOS 15.0
- Enable Swift 6 language mode
- Enable strict concurrency checking
- Configure code signing

Task: 1.1.2
```

---

### Task 1.1.3: Create Folder Structure
**Estimated Time**: 10 minutes
**File Location**: `ZeroDevCleaner/` directory
**Dependencies**: Task 1.1.1

#### Steps
1. In Xcode, right-click `ZeroDevCleaner` group
2. New Group → Name it `App`
3. Move `ZeroDevCleanerApp.swift` into `App` group
4. Move `Assets.xcassets` into `App` group
5. Delete `ContentView.swift` (we'll create proper views later)
6. Create new groups (right-click ZeroDevCleaner):
   - `Models`
   - `Services`
   - `Views`
   - `ViewModels`
   - `Utilities`
7. In Xcode, right-click `ZeroDevCleanerTests` group
8. Create new groups:
   - `ModelTests`
   - `ServiceTests`
   - `ViewModelTests`
   - `Fixtures`

#### Verification
```bash
# Check group structure (visual inspection in Xcode)
# Navigator should show:
# - ZeroDevCleaner/
#   - App/
#   - Models/
#   - Services/
#   - Views/
#   - ViewModels/
#   - Utilities/
# - ZeroDevCleanerTests/
#   - ModelTests/
#   - ServiceTests/
#   - ViewModelTests/
#   - Fixtures/
```

**Expected Output**: Folder structure matches architecture plan

#### Commit Message
```
chore(project): organize folder structure

- Create App, Models, Services, Views, ViewModels, Utilities groups
- Create test organization groups
- Remove default ContentView
- Organize existing files

Task: 1.1.3
```

---

### Task 1.1.4: Initialize Git Repository
**Estimated Time**: 5 minutes
**File Location**: Project root
**Dependencies**: Task 1.1.1

#### Steps
1. Create `.gitignore` file at project root
2. Add standard Xcode ignore patterns (see code scaffold below)
3. Git is already initialized, add initial files
4. Create initial commit

#### Code Scaffold
Create file: `/Users/shohag/Developer/SourceCode/Own/apple/ZeroDevCleaner/.gitignore`

```gitignore
# Xcode
build/
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata/
*.xccheckout
*.moved-aside
DerivedData/
*.hmap
*.ipa
*.xcuserstate
*.xcscmblueprint

# Swift Package Manager
.build/
Packages/
Package.pins
Package.resolved

# CocoaPods
Pods/

# macOS
.DS_Store

# AI Progress
.ai-progress.json
```

#### Verification
```bash
# Check git status
git status

# Should show .gitignore and project files ready to commit
```

**Expected Output**: Git repository initialized, .gitignore in place

#### Commit Message
```
chore(git): add .gitignore for Xcode project

Task: 1.1.4
```

---

## Task 1.2: Create Data Models (2 hours total)

### Task 1.2.1: Create ProjectType Enum
**Estimated Time**: 20 minutes
**File Location**: `ZeroDevCleaner/Models/ProjectType.swift`
**Dependencies**: Task 1.1.3

#### Steps
1. In Xcode, right-click `Models` group
2. New File → Swift File
3. Name: `ProjectType`
4. Ensure target membership: ZeroDevCleaner
5. Implement enum according to scaffold below

#### Code Scaffold
```swift
//
//  ProjectType.swift
//  ZeroDevCleaner
//
//  Created by AI Agent.
//

import Foundation

/// Represents the type of development project
enum ProjectType: String, Codable, CaseIterable {
    case android
    case iOS
    case swiftPackage

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .android:
            return "Android"
        case .iOS:
            return "iOS/Xcode"
        case .swiftPackage:
            return "Swift Package"
        }
    }

    /// SF Symbol icon name for the project type
    var iconName: String {
        switch self {
        case .android:
            return "app.badge.fill"
        case .iOS:
            return "apple.logo"
        case .swiftPackage:
            return "shippingbox.fill"
        }
    }

    /// Folder name pattern to search for
    var buildFolderName: String {
        switch self {
        case .android:
            return "build"
        case .iOS, .swiftPackage:
            return ".build"
        }
    }
}
```

#### Verification
```bash
# Build should succeed
xcodebuild -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS' clean build
```

**Expected Output**: Build succeeds, no warnings

#### Commit Message
```
feat(models): add ProjectType enum

- Define android, iOS, swiftPackage cases
- Add displayName computed property
- Add iconName for SF Symbols
- Add buildFolderName pattern
- Implement Codable and CaseIterable

Task: 1.2.1
```

---

### Task 1.2.2: Create BuildFolder Model
**Estimated Time**: 30 minutes
**File Location**: `ZeroDevCleaner/Models/BuildFolder.swift`
**Dependencies**: Task 1.2.1

#### Steps
1. In Xcode, right-click `Models` group
2. New File → Swift File
3. Name: `BuildFolder`
4. Ensure target membership: ZeroDevCleaner
5. Implement struct according to scaffold below

#### Code Scaffold
```swift
//
//  BuildFolder.swift
//  ZeroDevCleaner
//
//  Created by AI Agent.
//

import Foundation

/// Represents a build folder found during scanning
struct BuildFolder: Identifiable, Hashable, Codable {
    /// Unique identifier
    let id: UUID

    /// Full path to the build folder
    let path: URL

    /// Type of project this build folder belongs to
    let projectType: ProjectType

    /// Size of the build folder in bytes
    let size: Int64

    /// Name of the parent project
    let projectName: String

    /// Last modified date of the build folder
    let lastModified: Date

    /// Whether this folder is selected for deletion
    var isSelected: Bool

    /// Initializer with all properties
    init(
        id: UUID = UUID(),
        path: URL,
        projectType: ProjectType,
        size: Int64,
        projectName: String,
        lastModified: Date,
        isSelected: Bool = false
    ) {
        self.id = id
        self.path = path
        self.projectType = projectType
        self.size = size
        self.projectName = projectName
        self.lastModified = lastModified
        self.isSelected = isSelected
    }

    /// Human-readable size (e.g., "125.5 MB")
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Relative path from a given root (computed when needed)
    func relativePath(from root: URL) -> String {
        path.path.replacingOccurrences(of: root.path, with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    /// Human-readable last modified time (e.g., "5 days ago")
    var formattedLastModified: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }
}
```

#### Verification
```bash
# Build should succeed
xcodebuild -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS' clean build
```

**Expected Output**: Build succeeds, no warnings

#### Commit Message
```
feat(models): add BuildFolder model

- Implement Identifiable with UUID
- Add path, size, projectType, lastModified properties
- Add formattedSize computed property
- Add relativePath(from:) method
- Add formattedLastModified computed property
- Implement Hashable and Codable

Task: 1.2.2
```

---

### Task 1.2.3: Create ScanResult Model
**Estimated Time**: 20 minutes
**File Location**: `ZeroDevCleaner/Models/ScanResult.swift`
**Dependencies**: Task 1.2.2

#### Steps
1. In Xcode, right-click `Models` group
2. New File → Swift File
3. Name: `ScanResult`
4. Implement struct according to scaffold below

#### Code Scaffold
```swift
//
//  ScanResult.swift
//  ZeroDevCleaner
//
//  Created by AI Agent.
//

import Foundation

/// Represents the result of a directory scan
struct ScanResult: Codable {
    /// Root path that was scanned
    let rootPath: URL

    /// When the scan was performed
    let scanDate: Date

    /// All build folders found during the scan
    let buildFolders: [BuildFolder]

    /// How long the scan took
    let scanDuration: TimeInterval

    /// Total size of all found build folders in bytes
    var totalSize: Int64 {
        buildFolders.reduce(0) { $0 + $1.size }
    }

    /// Total size of selected build folders in bytes
    var selectedSize: Int64 {
        buildFolders.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    /// Number of selected folders
    var selectedCount: Int {
        buildFolders.filter(\.isSelected).count
    }

    /// Human-readable total size
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    /// Human-readable selected size
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }

    /// Human-readable scan duration
    var formattedScanDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: scanDuration) ?? "\(scanDuration)s"
    }
}
```

#### Verification
```bash
# Build should succeed
xcodebuild -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS' clean build
```

**Expected Output**: Build succeeds, no warnings

#### Commit Message
```
feat(models): add ScanResult model

- Add rootPath, scanDate, buildFolders properties
- Add scanDuration property
- Add totalSize and selectedSize computed properties
- Add formatted string properties
- Implement Codable

Task: 1.2.3
```

---

### Task 1.2.4: Create Error Type
**Estimated Time**: 20 minutes
**File Location**: `ZeroDevCleaner/Models/ZeroDevCleanerError.swift`
**Dependencies**: Task 1.1.3

#### Steps
1. In Xcode, right-click `Models` group
2. New File → Swift File
3. Name: `ZeroDevCleanerError`
4. Implement enum according to scaffold below

#### Code Scaffold
```swift
//
//  ZeroDevCleanerError.swift
//  ZeroDevCleaner
//
//  Created by AI Agent.
//

import Foundation

/// Custom errors for ZeroDevCleaner operations
enum ZeroDevCleanerError: LocalizedError {
    case permissionDenied(URL)
    case fileNotFound(URL)
    case deletionFailed(URL, Error)
    case scanCancelled
    case invalidPath(URL)
    case calculationFailed(URL, Error)
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let url):
            return "Permission denied to access: \(url.path)"

        case .fileNotFound(let url):
            return "File or folder not found: \(url.path)"

        case .deletionFailed(let url, let error):
            return "Failed to delete \(url.lastPathComponent): \(error.localizedDescription)"

        case .scanCancelled:
            return "Scan was cancelled"

        case .invalidPath(let url):
            return "Invalid path: \(url.path)"

        case .calculationFailed(let url, let error):
            return "Failed to calculate size of \(url.lastPathComponent): \(error.localizedDescription)"

        case .unknownError(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Please grant Full Disk Access in System Settings → Privacy & Security → Full Disk Access"

        case .fileNotFound:
            return "The file may have been moved or deleted. Try scanning again."

        case .deletionFailed:
            return "Make sure you have write permissions and the file is not in use."

        case .scanCancelled:
            return "You can start a new scan whenever you're ready."

        case .invalidPath:
            return "Please select a valid directory path."

        case .calculationFailed:
            return "The folder may be inaccessible. Try scanning with elevated permissions."

        case .unknownError:
            return "Please try again or contact support if the problem persists."
        }
    }
}
```

#### Verification
```bash
# Build should succeed
xcodebuild -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS' clean build
```

**Expected Output**: Build succeeds, no warnings

#### Commit Message
```
feat(models): add ZeroDevCleanerError enum

- Define custom error cases
- Implement LocalizedError protocol
- Add user-friendly error descriptions
- Add recovery suggestions

Task: 1.2.4
```

---

### Task 1.2.5: Create Model Unit Tests
**Estimated Time**: 30 minutes
**File Location**: `ZeroDevCleanerTests/ModelTests/ModelTests.swift`
**Dependencies**: Task 1.2.1, 1.2.2, 1.2.3, 1.2.4

#### Steps
1. In Xcode, right-click `ModelTests` group
2. New File → Unit Test Case Class
3. Name: `ModelTests`
4. Implement tests according to scaffold below

#### Code Scaffold
```swift
//
//  ModelTests.swift
//  ZeroDevCleanerTests
//
//  Created by AI Agent.
//

import XCTest
@testable import ZeroDevCleaner

final class ModelTests: XCTestCase {

    // MARK: - ProjectType Tests

    func test_projectType_displayName_returnsCorrectNames() {
        XCTAssertEqual(ProjectType.android.displayName, "Android")
        XCTAssertEqual(ProjectType.iOS.displayName, "iOS/Xcode")
        XCTAssertEqual(ProjectType.swiftPackage.displayName, "Swift Package")
    }

    func test_projectType_iconName_returnsValidSFSymbols() {
        XCTAssertFalse(ProjectType.android.iconName.isEmpty)
        XCTAssertFalse(ProjectType.iOS.iconName.isEmpty)
        XCTAssertFalse(ProjectType.swiftPackage.iconName.isEmpty)
    }

    func test_projectType_buildFolderName_returnsCorrectPatterns() {
        XCTAssertEqual(ProjectType.android.buildFolderName, "build")
        XCTAssertEqual(ProjectType.iOS.buildFolderName, ".build")
        XCTAssertEqual(ProjectType.swiftPackage.buildFolderName, ".build")
    }

    func test_projectType_codable_encodesAndDecodes() throws {
        let type = ProjectType.android
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(type)
        let decoded = try decoder.decode(ProjectType.self, from: data)

        XCTAssertEqual(decoded, type)
    }

    // MARK: - BuildFolder Tests

    func test_buildFolder_initialization_setsAllProperties() {
        let url = URL(fileURLWithPath: "/test/path/build")
        let date = Date()
        let folder = BuildFolder(
            path: url,
            projectType: .android,
            size: 1024 * 1024 * 100, // 100 MB
            projectName: "TestProject",
            lastModified: date,
            isSelected: true
        )

        XCTAssertEqual(folder.path, url)
        XCTAssertEqual(folder.projectType, .android)
        XCTAssertEqual(folder.size, 1024 * 1024 * 100)
        XCTAssertEqual(folder.projectName, "TestProject")
        XCTAssertEqual(folder.lastModified, date)
        XCTAssertTrue(folder.isSelected)
    }

    func test_buildFolder_formattedSize_returnsHumanReadable() {
        let folder = BuildFolder(
            path: URL(fileURLWithPath: "/test"),
            projectType: .iOS,
            size: 1024 * 1024 * 100, // 100 MB
            projectName: "Test",
            lastModified: Date(),
            isSelected: false
        )

        XCTAssertFalse(folder.formattedSize.isEmpty)
        XCTAssertTrue(folder.formattedSize.contains("MB") || folder.formattedSize.contains("GB"))
    }

    func test_buildFolder_relativePath_removesRootPath() {
        let root = URL(fileURLWithPath: "/Users/test")
        let folder = BuildFolder(
            path: URL(fileURLWithPath: "/Users/test/project/build"),
            projectType: .android,
            size: 1024,
            projectName: "Test",
            lastModified: Date(),
            isSelected: false
        )

        let relative = folder.relativePath(from: root)
        XCTAssertEqual(relative, "project/build")
    }

    func test_buildFolder_hashable_worksInSet() {
        let folder1 = BuildFolder(
            id: UUID(),
            path: URL(fileURLWithPath: "/test1"),
            projectType: .android,
            size: 1024,
            projectName: "Test1",
            lastModified: Date(),
            isSelected: false
        )
        let folder2 = BuildFolder(
            id: UUID(),
            path: URL(fileURLWithPath: "/test2"),
            projectType: .iOS,
            size: 2048,
            projectName: "Test2",
            lastModified: Date(),
            isSelected: false
        )

        let set: Set<BuildFolder> = [folder1, folder2]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - ScanResult Tests

    func test_scanResult_totalSize_sumsAllFolders() {
        let folders = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date()),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date()),
            BuildFolder(path: URL(fileURLWithPath: "/test3"), projectType: .swiftPackage,
                       size: 512, projectName: "Test3", lastModified: Date())
        ]

        let result = ScanResult(
            rootPath: URL(fileURLWithPath: "/root"),
            scanDate: Date(),
            buildFolders: folders,
            scanDuration: 10.5
        )

        XCTAssertEqual(result.totalSize, 1024 + 2048 + 512)
    }

    func test_scanResult_selectedSize_sumsOnlySelected() {
        let folders = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date(), isSelected: true),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date(), isSelected: false),
            BuildFolder(path: URL(fileURLWithPath: "/test3"), projectType: .swiftPackage,
                       size: 512, projectName: "Test3", lastModified: Date(), isSelected: true)
        ]

        let result = ScanResult(
            rootPath: URL(fileURLWithPath: "/root"),
            scanDate: Date(),
            buildFolders: folders,
            scanDuration: 10.5
        )

        XCTAssertEqual(result.selectedSize, 1024 + 512)
        XCTAssertEqual(result.selectedCount, 2)
    }

    func test_scanResult_formattedScanDuration_isReadable() {
        let result = ScanResult(
            rootPath: URL(fileURLWithPath: "/root"),
            scanDate: Date(),
            buildFolders: [],
            scanDuration: 125.7
        )

        XCTAssertFalse(result.formattedScanDuration.isEmpty)
    }

    // MARK: - Error Tests

    func test_error_errorDescription_providesMessage() {
        let error = ZeroDevCleanerError.scanCancelled
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func test_error_recoverySuggestion_providesGuidance() {
        let error = ZeroDevCleanerError.permissionDenied(URL(fileURLWithPath: "/test"))
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("Full Disk Access"))
    }
}
```

#### Verification
```bash
# Run tests
xcodebuild test -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS'
```

**Expected Output**: All tests pass

#### Commit Message
```
test(models): add comprehensive model unit tests

- Test ProjectType properties and encoding
- Test BuildFolder initialization and computed properties
- Test ScanResult calculations
- Test error descriptions and recovery suggestions
- Achieve 100% model coverage

Task: 1.2.5
```

---

## Task 1.3: Update App Entry Point (30 minutes total)

### Task 1.3.1: Update ZeroDevCleanerApp.swift
**Estimated Time**: 15 minutes
**File Location**: `ZeroDevCleaner/App/ZeroDevCleanerApp.swift`
**Dependencies**: Task 1.1.3

#### Steps
1. Open `ZeroDevCleaner/App/ZeroDevCleanerApp.swift`
2. Replace content with scaffold below
3. Build and verify

#### Code Scaffold
```swift
//
//  ZeroDevCleanerApp.swift
//  ZeroDevCleaner
//
//  Created by AI Agent.
//

import SwiftUI

@main
struct ZeroDevCleanerApp: App {
    var body: some Scene {
        WindowGroup {
            // Placeholder - will be replaced with MainView in Phase 4
            PlaceholderView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

// Temporary placeholder view
struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("ZeroDevCleaner")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Foundation phase complete")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Ready for Phase 2: Core Services")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PlaceholderView()
}
```

#### Verification
```bash
# Build and run
xcodebuild -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS' clean build

# Optionally run the app to see placeholder
open build/Release/ZeroDevCleaner.app
```

**Expected Output**: App builds and shows placeholder view

#### Commit Message
```
feat(app): configure app entry point with placeholder

- Set up WindowGroup with proper styling
- Configure default window size
- Add placeholder view for Phase 1 completion
- Remove new item command

Task: 1.3.1
```

---

### Task 1.3.2: Final Phase 1 Verification
**Estimated Time**: 15 minutes
**File Location**: N/A (verification only)
**Dependencies**: All Phase 1 tasks

#### Steps
1. Clean build folder
2. Build entire project
3. Run all tests
4. Verify folder structure
5. Run app to see placeholder
6. Update progress file

#### Verification Commands
```bash
# Clean and build
xcodebuild clean -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner
xcodebuild build -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS'

# Run all tests
xcodebuild test -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS'

# Check for warnings
xcodebuild -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS' 2>&1 | grep -i warning
```

**Expected Output**:
- Build succeeds
- All tests pass (should see ~15+ tests)
- No warnings
- App runs showing placeholder

#### Create Progress File
Create: `/Users/shohag/Developer/SourceCode/Own/apple/ZeroDevCleaner/.ai-progress.json`

```json
{
  "current_phase": 2,
  "current_task": "2.1.1",
  "completed_tasks": [
    "1.1.1", "1.1.2", "1.1.3", "1.1.4",
    "1.2.1", "1.2.2", "1.2.3", "1.2.4", "1.2.5",
    "1.3.1", "1.3.2"
  ],
  "phase_1_completed_at": "2025-10-29T04:00:00Z",
  "started_at": "2025-10-29T00:00:00Z",
  "last_updated": "2025-10-29T04:00:00Z"
}
```

#### Commit Message
```
chore(phase1): complete foundation phase

Phase 1 Summary:
- ✅ Xcode project created and configured
- ✅ Swift 6 with strict concurrency enabled
- ✅ Folder structure organized
- ✅ All models implemented (ProjectType, BuildFolder, ScanResult, Error)
- ✅ Model tests passing (100% coverage)
- ✅ App entry point configured
- ✅ Ready for Phase 2

Stats:
- 9 tasks completed
- 4 model files created
- 15+ unit tests passing
- 0 warnings
- Time: ~3.5 hours

Task: 1.3.2
```

---

## Phase 1 Checklist

Before proceeding to Phase 2, verify:

- [ ] Xcode project builds without errors
- [ ] Swift 6 mode enabled and no concurrency warnings
- [ ] Folder structure matches architecture
- [ ] All 4 model files created (ProjectType, BuildFolder, ScanResult, Error)
- [ ] Model tests file exists with 15+ tests
- [ ] All tests pass
- [ ] App runs and shows placeholder view
- [ ] `.ai-progress.json` created and updated
- [ ] Git commits made for each task (9 commits total)
- [ ] No compiler warnings

**Success Criteria Met**: ✅ Foundation phase complete

**Next Step**: Proceed to [08-phase-2-services.md](./08-phase-2-services.md)
