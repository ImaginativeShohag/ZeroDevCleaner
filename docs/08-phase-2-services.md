# Phase 2: Core Services - Atomic Task Breakdown

**Estimated Total Time**: 15-20 hours
**Number of Atomic Tasks**: 45
**Dependencies**: Phase 1 complete

**Note**: Due to the size of Phase 2, this document focuses on the most critical atomic tasks. Each service follows the same pattern: Protocol → Implementation → Tests.

---

## Overview

Phase 2 implements four critical services:
1. **ProjectValidator**: Validates Android/iOS project structures
2. **FileSizeCalculator**: Calculates directory sizes asynchronously
3. **FileScanner**: Scans directory trees for build folders
4. **FileDeleter**: Safely moves folders to Trash

---

## Task 2.1: ProjectValidator Service (4 hours)

### Task 2.1.1: Create ProjectValidatorProtocol
**Time**: 15 min | **File**: `ZeroDevCleaner/Services/ProjectValidatorProtocol.swift` | **Deps**: Phase 1

```swift
//
//  ProjectValidatorProtocol.swift
//  ZeroDevCleaner
//

import Foundation

/// Protocol for validating development project structures
protocol ProjectValidatorProtocol: Sendable {
    /// Validates if a folder is part of an Android project
    func isValidAndroidProject(buildFolder: URL) -> Bool

    /// Validates if a folder is part of an iOS/Xcode project
    func isValidiOSProject(buildFolder: URL) -> Bool

    /// Validates if a folder is part of a Swift Package
    func isValidSwiftPackage(buildFolder: URL) -> Bool

    /// Determines project type if valid, nil otherwise
    func detectProjectType(buildFolder: URL) -> ProjectType?
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(services): add ProjectValidatorProtocol`

---

### Task 2.1.2: Create ProjectValidator Implementation
**Time**: 30 min | **File**: `ZeroDevCleaner/Services/ProjectValidator.swift` | **Deps**: 2.1.1

```swift
//
//  ProjectValidator.swift
//  ZeroDevCleaner
//

import Foundation

final class ProjectValidator: ProjectValidatorProtocol {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func isValidAndroidProject(buildFolder: URL) -> Bool {
        // Implementation in next task
        false
    }

    func isValidiOSProject(buildFolder: URL) -> Bool {
        // Implementation in next task
        false
    }

    func isValidSwiftPackage(buildFolder: URL) -> Bool {
        // Implementation in next task
        false
    }

    func detectProjectType(buildFolder: URL) -> ProjectType? {
        if isValidAndroidProject(buildFolder: buildFolder) {
            return .android
        } else if isValidSwiftPackage(buildFolder: buildFolder) {
            return .swiftPackage
        } else if isValidiOSProject(buildFolder: buildFolder) {
            return .iOS
        }
        return nil
    }

    // MARK: - Private Helpers

    private func fileExists(at path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    private func directoryContainsFile(directory: URL, named: String) -> Bool {
        fileExists(at: directory.appendingPathComponent(named).path)
    }

    private func findFileInParentDirectories(from url: URL, named: String, maxLevels: Int = 5) -> Bool {
        var currentURL = url.deletingLastPathComponent()
        var level = 0

        while level < maxLevels {
            if directoryContainsFile(directory: currentURL, named: named) {
                return true
            }
            let parentURL = currentURL.deletingLastPathComponent()
            if parentURL == currentURL { break }
            currentURL = parentURL
            level += 1
        }
        return false
    }
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(services): implement ProjectValidator skeleton`

---

### Task 2.1.3: Implement Android Validation
**Time**: 25 min | **File**: `ZeroDevCleaner/Services/ProjectValidator.swift` | **Deps**: 2.1.2

Replace `isValidAndroidProject` method:

```swift
func isValidAndroidProject(buildFolder: URL) -> Bool {
    // Check if folder is named "build"
    guard buildFolder.lastPathComponent == "build" else {
        return false
    }

    // Look for build.gradle or build.gradle.kts in parent directories
    if findFileInParentDirectories(from: buildFolder, named: "build.gradle") ||
       findFileInParentDirectories(from: buildFolder, named: "build.gradle.kts") {
        return true
    }

    // Look for settings.gradle or settings.gradle.kts
    if findFileInParentDirectories(from: buildFolder, named: "settings.gradle") ||
       findFileInParentDirectories(from: buildFolder, named: "settings.gradle.kts") {
        return true
    }

    // Check for app/build.gradle pattern (multi-module project)
    let parentURL = buildFolder.deletingLastPathComponent()
    if parentURL.lastPathComponent == "app" {
        let grandparentURL = parentURL.deletingLastPathComponent()
        if directoryContainsFile(directory: grandparentURL, named: "settings.gradle") ||
           directoryContainsFile(directory: grandparentURL, named: "settings.gradle.kts") {
            return true
        }
    }

    return false
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(services): implement Android project validation logic`

---

### Task 2.1.4: Implement iOS Validation
**Time**: 25 min | **File**: `ZeroDevCleaner/Services/ProjectValidator.swift` | **Deps**: 2.1.2

Replace `isValidiOSProject` and `isValidSwiftPackage` methods:

```swift
func isValidiOSProject(buildFolder: URL) -> Bool {
    // Check if folder is named ".build"
    guard buildFolder.lastPathComponent == ".build" else {
        return false
    }

    // Look for .xcodeproj in parent directories
    let parentURL = buildFolder.deletingLastPathComponent()
    do {
        let contents = try fileManager.contentsOfDirectory(
            at: parentURL,
            includingPropertiesForKeys: nil
        )
        if contents.contains(where: { $0.pathExtension == "xcodeproj" }) {
            return true
        }
        if contents.contains(where: { $0.pathExtension == "xcworkspace" }) {
            return true
        }
    } catch {
        return false
    }

    return false
}

func isValidSwiftPackage(buildFolder: URL) -> Bool {
    // Check if folder is named ".build"
    guard buildFolder.lastPathComponent == ".build" else {
        return false
    }

    // Look for Package.swift in parent directory
    return findFileInParentDirectories(from: buildFolder, named: "Package.swift", maxLevels: 2)
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(services): implement iOS and Swift Package validation logic`

---

### Task 2.1.5: Create ProjectValidator Tests
**Time**: 45 min | **File**: `ZeroDevCleanerTests/ServiceTests/ProjectValidatorTests.swift` | **Deps**: 2.1.4

```swift
//
//  ProjectValidatorTests.swift
//  ZeroDevCleanerTests
//

import XCTest
@testable import ZeroDevCleaner

final class ProjectValidatorTests: XCTestCase {
    var sut: ProjectValidator!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        sut = ProjectValidator()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Android Tests

    func test_isValidAndroidProject_withBuildGradle_returnsTrue() throws {
        // Given: Android project with build.gradle
        let projectDir = tempDirectory.appendingPathComponent("AndroidProject")
        let buildDir = projectDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let buildGradle = projectDir.appendingPathComponent("build.gradle")
        try "// build file".write(to: buildGradle, atomically: true, encoding: .utf8)

        // When
        let result = sut.isValidAndroidProject(buildFolder: buildDir)

        // Then
        XCTAssertTrue(result)
    }

    func test_isValidAndroidProject_withoutGradleFile_returnsFalse() throws {
        // Given: Random build folder
        let buildDir = tempDirectory.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // When
        let result = sut.isValidAndroidProject(buildFolder: buildDir)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - iOS Tests

    func test_isValidiOSProject_withXcodeProj_returnsTrue() throws {
        // Given: iOS project with .xcodeproj
        let projectDir = tempDirectory.appendingPathComponent("iOSProject")
        let buildDir = projectDir.appendingPathComponent(".build")
        let xcodeProjDir = projectDir.appendingPathComponent("App.xcodeproj")

        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: xcodeProjDir, withIntermediateDirectories: true)

        // When
        let result = sut.isValidiOSProject(buildFolder: buildDir)

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - Swift Package Tests

    func test_isValidSwiftPackage_withPackageSwift_returnsTrue() throws {
        // Given: Swift package
        let packageDir = tempDirectory.appendingPathComponent("MyPackage")
        let buildDir = packageDir.appendingPathComponent(".build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

        let packageSwift = packageDir.appendingPathComponent("Package.swift")
        try "// Package.swift".write(to: packageSwift, atomically: true, encoding: .utf8)

        // When
        let result = sut.isValidSwiftPackage(buildFolder: buildDir)

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - Detection Tests

    func test_detectProjectType_withAndroidProject_returnsAndroid() throws {
        // Given
        let projectDir = tempDirectory.appendingPathComponent("AndroidProject")
        let buildDir = projectDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        let buildGradle = projectDir.appendingPathComponent("build.gradle")
        try "".write(to: buildGradle, atomically: true, encoding: .utf8)

        // When
        let result = sut.detectProjectType(buildFolder: buildDir)

        // Then
        XCTAssertEqual(result, .android)
    }
}
```

**Verify**: `xcodebuild test -only-testing:ZeroDevCleanerTests/ProjectValidatorTests`
**Commit**: `test(services): add ProjectValidator tests`

---

## Task 2.2: FileSizeCalculator Service (2 hours)

### Task 2.2.1: Create FileSizeCalculatorProtocol
**Time**: 10 min | **File**: `ZeroDevCleaner/Services/FileSizeCalculatorProtocol.swift` | **Deps**: Phase 1

```swift
//
//  FileSizeCalculatorProtocol.swift
//  ZeroDevCleaner
//

import Foundation

/// Protocol for calculating directory sizes
protocol FileSizeCalculatorProtocol: Sendable {
    /// Calculates the total size of a directory
    func calculateSize(of url: URL) async throws -> Int64
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(services): add FileSizeCalculatorProtocol`

---

### Task 2.2.2: Implement FileSizeCalculator
**Time**: 45 min | **File**: `ZeroDevCleaner/Services/FileSizeCalculator.swift` | **Deps**: 2.2.1

```swift
//
//  FileSizeCalculator.swift
//  ZeroDevCleaner
//

import Foundation

final class FileSizeCalculator: FileSizeCalculatorProtocol {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func calculateSize(of url: URL) async throws -> Int64 {
        try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let size = try self.calculateSizeSync(of: url)
                    continuation.resume(returning: size)
                } catch {
                    continuation.resume(throwing: ZeroDevCleanerError.calculationFailed(url, error))
                }
            }
        }
    }

    private func calculateSizeSync(of url: URL) throws -> Int64 {
        var totalSize: Int64 = 0
        let keys: [URLResourceKey] = [.isDirectoryKey, .totalFileSizeKey, .fileSizeKey]

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            throw ZeroDevCleanerError.invalidPath(url)
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)) else {
                continue
            }

            if let fileSize = resourceValues.totalFileSize ?? resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
        }

        return totalSize
    }
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(services): implement FileSizeCalculator`

---

## Task 2.3: FileScanner Service (6 hours)

### Task 2.3.1: Create FileScannerProtocol
**Time**: 15 min | **File**: `ZeroDevCleaner/Services/FileScannerProtocol.swift` | **Deps**: 2.1.5, 2.2.2

```swift
//
//  FileScannerProtocol.swift
//  ZeroDevCleaner
//

import Foundation

/// Progress callback for scanning operations
typealias ScanProgressHandler = @Sendable (String, Int) -> Void

/// Protocol for scanning directories for build folders
protocol FileScannerProtocol: Sendable {
    /// Scans a directory for build folders
    /// - Parameters:
    ///   - url: Root directory to scan
    ///   - progressHandler: Called with current path and found count
    /// - Returns: Array of found build folders
    func scanDirectory(
        at url: URL,
        progressHandler: ScanProgressHandler?
    ) async throws -> [BuildFolder]
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(services): add FileScannerProtocol`

---

### Task 2.3.2: Implement FileScanner Core
**Time**: 1 hour | **File**: `ZeroDevCleaner/Services/FileScanner.swift` | **Deps**: 2.3.1

```swift
//
//  FileScanner.swift
//  ZeroDevCleaner
//

import Foundation

final class FileScanner: FileScannerProtocol {
    private let fileManager: FileManager
    private let validator: ProjectValidatorProtocol
    private let sizeCalculator: FileSizeCalculatorProtocol
    private let maxDepth: Int

    init(
        fileManager: FileManager = .default,
        validator: ProjectValidatorProtocol,
        sizeCalculator: FileSizeCalculatorProtocol,
        maxDepth: Int = 10
    ) {
        self.fileManager = fileManager
        self.validator = validator
        self.sizeCalculator = sizeCalculator
        self.maxDepth = maxDepth
    }

    func scanDirectory(
        at url: URL,
        progressHandler: ScanProgressHandler?
    ) async throws -> [BuildFolder] {
        var buildFolders: [BuildFolder] = []

        try await withThrowingTaskGroup(of: BuildFolder?.self) { group in
            try await scanRecursively(
                url: url,
                currentDepth: 0,
                foundFolders: &buildFolders,
                group: &group,
                progressHandler: progressHandler
            )

            for try await folder in group {
                if let folder {
                    buildFolders.append(folder)
                }
            }
        }

        return buildFolders
    }

    private func scanRecursively(
        url: URL,
        currentDepth: Int,
        foundFolders: inout [BuildFolder],
        group: inout ThrowingTaskGroup<BuildFolder?, Error>,
        progressHandler: ScanProgressHandler?
    ) async throws {
        guard currentDepth < maxDepth else { return }

        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        for itemURL in contents {
            let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
            guard resourceValues.isDirectory == true else { continue }

            let folderName = itemURL.lastPathComponent

            // Check if this is a build folder
            if folderName == "build" || folderName == ".build" {
                if let projectType = validator.detectProjectType(buildFolder: itemURL) {
                    group.addTask {
                        await self.createBuildFolder(url: itemURL, projectType: projectType)
                    }
                    await MainActor.run {
                        progressHandler?(itemURL.path, foundFolders.count + 1)
                    }
                }
            } else {
                // Recursively scan subdirectories
                try await scanRecursively(
                    url: itemURL,
                    currentDepth: currentDepth + 1,
                    foundFolders: &foundFolders,
                    group: &group,
                    progressHandler: progressHandler
                )
            }
        }
    }

    private func createBuildFolder(url: URL, projectType: ProjectType) async -> BuildFolder? {
        do {
            let size = try await sizeCalculator.calculateSize(of: url)
            let resourceValues = try url.resourceValues(forKeys: [.contentModificationDateKey])
            let lastModified = resourceValues.contentModificationDate ?? Date()

            let projectName = url.deletingLastPathComponent().lastPathComponent

            return BuildFolder(
                path: url,
                projectType: projectType,
                size: size,
                projectName: projectName,
                lastModified: lastModified,
                isSelected: false
            )
        } catch {
            return nil
        }
    }
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(services): implement FileScanner with async scanning`

---

## Task 2.4: FileDeleter Service (3 hours)

### Task 2.4.1: Create FileDeleterProtocol
**Time**: 10 min | **File**: `ZeroDevCleaner/Services/FileDeleterProtocol.swift` | **Deps**: Phase 1

```swift
//
//  FileDeleterProtocol.swift
//  ZeroDevCleaner
//

import Foundation

/// Progress callback for deletion operations
typealias DeletionProgressHandler = @Sendable (Int, Int) -> Void

/// Protocol for deleting build folders
protocol FileDeleterProtocol: Sendable {
    /// Deletes folders by moving them to Trash
    /// - Parameters:
    ///   - folders: Folders to delete
    ///   - progressHandler: Called with current index and total count
    func delete(
        folders: [BuildFolder],
        progressHandler: DeletionProgressHandler?
    ) async throws
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(services): add FileDeleterProtocol`

---

### Task 2.4.2: Implement FileDeleter
**Time**: 45 min | **File**: `ZeroDevCleaner/Services/FileDeleter.swift` | **Deps**: 2.4.1

```swift
//
//  FileDeleter.swift
//  ZeroDevCleaner
//

import Foundation

final class FileDeleter: FileDeleterProtocol {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func delete(
        folders: [BuildFolder],
        progressHandler: DeletionProgressHandler?
    ) async throws {
        for (index, folder) in folders.enumerated() {
            try await deleteSingleFolder(folder)
            await MainActor.run {
                progressHandler?(index + 1, folders.count)
            }
        }
    }

    private func deleteSingleFolder(_ folder: BuildFolder) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task.detached {
                do {
                    try self.fileManager.trashItem(at: folder.path, resultingItemURL: nil)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: ZeroDevCleanerError.deletionFailed(folder.path, error))
                }
            }
        }
    }
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(services): implement FileDeleter with Trash support`

---

## Phase 2 Summary Tasks

### Task 2.5: Integration Test
**Time**: 1 hour | **File**: `ZeroDevCleanerTests/ServiceTests/IntegrationTests.swift`

Create integration tests that test services working together.

### Task 2.6: Final Phase 2 Verification
**Time**: 30 min

**Checklist**:
- [ ] All 4 service protocols created
- [ ] All 4 service implementations complete
- [ ] Tests pass for all services
- [ ] No compiler warnings
- [ ] Update .ai-progress.json

**Verify**:
```bash
xcodebuild clean build test -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner
```

**Commit**: `chore(phase2): complete core services implementation`

**Next**: Proceed to Phase 3 - [09-phase-3-viewmodel.md](./09-phase-3-viewmodel.md)
