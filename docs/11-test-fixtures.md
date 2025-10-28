# Test Fixtures Documentation

**Last Modified**: 2025-10-29

## Overview

This document describes the test fixture structure for ZeroDevCleaner. Fixtures provide realistic project structures for testing validation, scanning, and deletion functionality.

---

## Fixture Location

All test fixtures should be created in:
```
ZeroDevCleanerTests/Fixtures/
```

---

## Required Test Fixtures

### 1. Valid Android Project

**Path**: `ZeroDevCleanerTests/Fixtures/ValidAndroidProject/`

**Structure**:
```
ValidAndroidProject/
├── build.gradle.kts          # Root build file
├── settings.gradle.kts       # Settings file
├── app/
│   ├── build.gradle.kts      # App module build file
│   ├── src/
│   │   └── main/
│   │       └── AndroidManifest.xml
│   └── build/                # BUILD FOLDER TO DETECT
│       ├── intermediates/
│       │   └── dummy.txt
│       ├── outputs/
│       │   └── apk/
│       │       └── dummy.apk
│       └── tmp/
│           └── temp.txt
├── lib/
│   ├── build.gradle.kts
│   └── build/                # BUILD FOLDER TO DETECT
│       └── classes/
│           └── dummy.class
└── gradle/
    └── wrapper/
        └── gradle-wrapper.properties
```

**Files to Create**:

`build.gradle.kts`:
```kotlin
// Root build file
plugins {
    id("com.android.application") version "8.0.0" apply false
}
```

`settings.gradle.kts`:
```kotlin
rootProject.name = "ValidAndroidProject"
include(":app")
include(":lib")
```

`app/build.gradle.kts`:
```kotlin
plugins {
    id("com.android.application")
}
```

---

### 2. Valid iOS Project

**Path**: `ZeroDevCleanerTests/Fixtures/ValidiOSProject/`

**Structure**:
```
ValidiOSProject/
├── iOSApp.xcodeproj/
│   ├── project.pbxproj       # Xcode project file
│   └── project.xcworkspace/
│       └── contents.xcworkspacedata
├── .build/                   # BUILD FOLDER TO DETECT (hidden)
│   ├── debug/
│   │   └── Products/
│   │       └── iOSApp.app/
│   └── release/
│       └── Products/
│           └── iOSApp.app/
└── Sources/
    └── main.swift
```

**Files to Create**:

`iOSApp.xcodeproj/project.pbxproj`:
```xml
// !$*UTF8*$!
{
    archiveVersion = 1;
    classes = {
    };
    objectVersion = 56;
}
```

---

### 3. Valid Swift Package

**Path**: `ZeroDevCleanerTests/Fixtures/ValidSwiftPackage/`

**Structure**:
```
ValidSwiftPackage/
├── Package.swift             # Package manifest
├── .build/                   # BUILD FOLDER TO DETECT
│   ├── debug/
│   │   └── MyPackage.swiftmodule
│   └── release/
│       └── MyPackage.swiftmodule
├── Sources/
│   └── MyPackage/
│       └── MyPackage.swift
└── Tests/
    └── MyPackageTests/
        └── MyPackageTests.swift
```

**Files to Create**:

`Package.swift`:
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ValidSwiftPackage",
    products: [
        .library(name: "MyPackage", targets: ["MyPackage"]),
    ],
    targets: [
        .target(name: "MyPackage"),
        .testTarget(name: "MyPackageTests", dependencies: ["MyPackage"]),
    ]
)
```

---

### 4. Invalid Project (False Positive Test)

**Path**: `ZeroDevCleanerTests/Fixtures/InvalidProject/`

**Structure**:
```
InvalidProject/
├── build/                    # Random build folder (NOT project-related)
│   └── random_stuff.txt
├── .build/                   # Random .build folder (NOT project-related)
│   └── random_data.bin
└── README.md
```

**Purpose**: Should NOT be detected as valid projects

---

### 5. Multi-Module Android Project

**Path**: `ZeroDevCleanerTests/Fixtures/MultiModuleAndroidProject/`

**Structure**:
```
MultiModuleAndroidProject/
├── build.gradle.kts
├── settings.gradle.kts
├── app/
│   ├── build.gradle.kts
│   └── build/                # BUILD FOLDER 1
├── feature1/
│   ├── build.gradle.kts
│   └── build/                # BUILD FOLDER 2
├── feature2/
│   ├── build.gradle.kts
│   └── build/                # BUILD FOLDER 3
└── core/
    ├── build.gradle.kts
    └── build/                # BUILD FOLDER 4
```

**Purpose**: Test detection of multiple build folders in single project

---

### 6. Nested Projects

**Path**: `ZeroDevCleanerTests/Fixtures/NestedProjects/`

**Structure**:
```
NestedProjects/
├── OuterAndroidProject/
│   ├── build.gradle.kts
│   └── build/                # BUILD FOLDER 1
└── InnerProjects/
    ├── AndroidApp/
    │   ├── build.gradle.kts
    │   └── build/            # BUILD FOLDER 2
    └── iOSApp/
        ├── iOSApp.xcodeproj/
        └── .build/           # BUILD FOLDER 3
```

**Purpose**: Test scanning nested project structures

---

## Creating Fixtures Programmatically

For tests that need temporary fixtures:

```swift
// Example: Create temporary Android project
func createTemporaryAndroidProject() throws -> URL {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)

    let projectDir = tempDir.appendingPathComponent("TestAndroidProject")
    let buildDir = projectDir.appendingPathComponent("build")

    // Create directories
    try FileManager.default.createDirectory(
        at: buildDir,
        withIntermediateDirectories: true
    )

    // Create build.gradle
    let buildGradle = projectDir.appendingPathComponent("build.gradle")
    try "plugins { id 'com.android.application' }".write(
        to: buildGradle,
        atomically: true,
        encoding: .utf8
    )

    return projectDir
}

// Cleanup after test
func cleanupTemporaryProject(at url: URL) throws {
    try FileManager.default.removeItem(at: url.deletingLastPathComponent())
}
```

---

## Fixture Sizes for Testing

### Small Fixture (for unit tests)
- Size: ~1-5 MB
- Files: 10-50 files
- Purpose: Fast tests

### Medium Fixture (for integration tests)
- Size: ~50-100 MB
- Files: 500-1000 files
- Purpose: Realistic scanning

### Large Fixture (for performance tests)
- Size: ~500 MB - 1 GB
- Files: 5000-10000 files
- Purpose: Performance validation

---

## Using Fixtures in Tests

### Example Test Using Fixtures

```swift
import XCTest
@testable import ZeroDevCleaner

final class FileScannerIntegrationTests: XCTestCase {
    var sut: FileScanner!
    var fixturesURL: URL!

    override func setUp() {
        super.setUp()

        // Get fixtures directory
        let bundle = Bundle(for: type(of: self))
        fixturesURL = bundle.resourceURL?
            .appendingPathComponent("Fixtures")

        // Create scanner
        let validator = ProjectValidator()
        let calculator = FileSizeCalculator()
        sut = FileScanner(
            validator: validator,
            sizeCalculator: calculator
        )
    }

    func test_scanDirectory_findsAllAndroidBuildFolders() async throws {
        // Given
        let androidProjectURL = fixturesURL
            .appendingPathComponent("ValidAndroidProject")

        // When
        let results = try await sut.scanDirectory(
            at: androidProjectURL,
            progressHandler: nil
        )

        // Then
        XCTAssertEqual(results.count, 2) // app/build and lib/build
        XCTAssertTrue(results.allSatisfy { $0.projectType == .android })
    }

    func test_scanDirectory_ignoresInvalidProjects() async throws {
        // Given
        let invalidProjectURL = fixturesURL
            .appendingPathComponent("InvalidProject")

        // When
        let results = try await sut.scanDirectory(
            at: invalidProjectURL,
            progressHandler: nil
        )

        // Then
        XCTAssertEqual(results.count, 0)
    }
}
```

---

## Adding Fixtures to Xcode

### Steps:

1. **Create Fixtures folder**:
   - In Xcode, right-click `ZeroDevCleanerTests`
   - New Group → `Fixtures`

2. **Add fixture files**:
   - Create folders on disk first
   - Drag folders into `Fixtures` group in Xcode
   - Ensure "Create folder references" is selected
   - Ensure target membership includes `ZeroDevCleanerTests`

3. **Verify bundle inclusion**:
   - Select project in navigator
   - Select `ZeroDevCleanerTests` target
   - Go to "Build Phases" → "Copy Bundle Resources"
   - Verify `Fixtures` folder is listed

---

## Maintenance

### When to Update Fixtures:

1. **New project type added**: Create new fixture
2. **Validation logic changes**: Update existing fixtures
3. **Edge case discovered**: Add specific fixture
4. **Test failure**: Verify fixture accuracy

### Fixture Checklist:

- [ ] All required fixtures exist
- [ ] Fixtures included in test bundle
- [ ] Fixture sizes appropriate
- [ ] All tests using fixtures pass
- [ ] Fixtures documented

---

## Future Fixture Ideas

1. **React Native Project**: For future expansion
2. **Flutter Project**: For future expansion
3. **Gradle Cache**: For .gradle folder support
4. **DerivedData**: For Xcode DerivedData support
5. **CocoaPods**: For Pods/ folder support
6. **Node Modules**: For comparison/learning
7. **Corrupted Projects**: For error handling tests
8. **Permission-Denied Folders**: For permission testing

---

## References

- **Android Project Structure**: https://developer.android.com/studio/projects
- **Xcode Project Structure**: https://developer.apple.com/documentation/xcode
- **Swift Package Structure**: https://swift.org/package-manager/

---

**Status**: Documentation complete
**Next**: Create actual fixture files when running tests
