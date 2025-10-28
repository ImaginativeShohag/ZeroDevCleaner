# Phase 3: ViewModel Layer - Atomic Task Breakdown

**Estimated Total Time**: 4-6 hours
**Number of Atomic Tasks**: 12
**Dependencies**: Phase 2 complete

---

## Overview

Phase 3 creates the MainViewModel that bridges the service layer and UI. This ViewModel uses Swift 6's @Observable macro and structured concurrency.

**Key Requirements**:
- Use `@Observable` (NOT `ObservableObject`)
- Use `@MainActor` for UI thread safety
- Use `Task` for async operations (NO `DispatchQueue`)
- No `@Published` wrappers needed
- ViewModels co-located with views

---

## Task 3.1: Create MainViewModel Foundation (2 hours)

### Task 3.1.1: Create MainViewModel File Structure
**Time**: 20 min | **File**: `ZeroDevCleaner/Views/Main/MainViewModel.swift` | **Deps**: Phase 2

#### Steps
1. Create `Views/Main` group in Xcode
2. Create `MainViewModel.swift` file
3. Implement basic structure with @Observable

#### Code Scaffold
```swift
//
//  MainViewModel.swift
//  ZeroDevCleaner
//
//  Created by AI Agent.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class MainViewModel {
    // MARK: - State Properties

    /// Currently selected folder to scan
    var selectedFolder: URL?

    /// Results from the last scan
    var scanResults: [BuildFolder] = []

    /// Whether a scan is currently in progress
    var isScanning: Bool = false

    /// Current scan progress (0.0 to 1.0)
    var scanProgress: Double = 0.0

    /// Current path being scanned
    var currentScanPath: String = ""

    /// Whether deletion is in progress
    var isDeleting: Bool = false

    /// Current deletion progress (0.0 to 1.0)
    var deletionProgress: Double = 0.0

    /// Current error to display
    var currentError: ZeroDevCleanerError?

    /// Whether to show error alert
    var showError: Bool = false

    // MARK: - Dependencies

    private let scanner: FileScannerProtocol
    private let deleter: FileDeleterProtocol

    // MARK: - Private Properties

    private var scanTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        scanner: FileScannerProtocol,
        deleter: FileDeleterProtocol
    ) {
        self.scanner = scanner
        self.deleter = deleter
    }

    /// Convenience initializer with default dependencies
    convenience init() {
        let validator = ProjectValidator()
        let sizeCalculator = FileSizeCalculator()
        let scanner = FileScanner(
            validator: validator,
            sizeCalculator: sizeCalculator
        )
        let deleter = FileDeleter()

        self.init(scanner: scanner, deleter: deleter)
    }
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(viewmodel): create MainViewModel with @Observable`

---

### Task 3.1.2: Implement Folder Selection
**Time**: 20 min | **File**: `ZeroDevCleaner/Views/Main/MainViewModel.swift` | **Deps**: 3.1.1

Add this method to MainViewModel:

```swift
// MARK: - Folder Selection

/// Opens folder selection dialog
func selectFolder() {
    let panel = NSOpenPanel()
    panel.title = "Select Folder to Scan"
    panel.message = "Choose a directory to scan for build folders"
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.canCreateDirectories = false
    panel.allowsMultipleSelection = false

    if panel.runModal() == .OK {
        selectedFolder = panel.url
    }
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(viewmodel): implement folder selection`

---

### Task 3.1.3: Implement Start Scan Method
**Time**: 45 min | **File**: `ZeroDevCleaner/Views/Main/MainViewModel.swift` | **Deps**: 3.1.2

Add these methods:

```swift
// MARK: - Scanning

/// Starts scanning the selected folder
func startScan() {
    guard let folder = selectedFolder else { return }

    // Cancel any existing scan
    cancelScan()

    // Reset state
    scanResults = []
    scanProgress = 0.0
    currentScanPath = ""
    isScanning = true

    // Start scan task
    scanTask = Task {
        do {
            let results = try await scanner.scanDirectory(at: folder) { [weak self] path, count in
                guard let self else { return }
                Task { @MainActor in
                    self.currentScanPath = path
                    self.scanProgress = Double(count) / 100.0 // Approximate progress
                }
            }

            // Update results on main actor
            self.scanResults = results
            self.isScanning = false
        } catch {
            self.handleError(error)
            self.isScanning = false
        }
    }
}

/// Cancels the current scan
func cancelScan() {
    scanTask?.cancel()
    scanTask = nil
    isScanning = false
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(viewmodel): implement scan functionality with Task`

---

### Task 3.1.4: Implement Selection Management
**Time**: 20 min | **File**: `ZeroDevCleaner/Views/Main/MainViewModel.swift` | **Deps**: 3.1.3

Add these methods:

```swift
// MARK: - Selection Management

/// Toggles selection for a specific folder
func toggleSelection(for folder: BuildFolder) {
    if let index = scanResults.firstIndex(where: { $0.id == folder.id }) {
        scanResults[index].isSelected.toggle()
    }
}

/// Selects all folders
func selectAll() {
    for index in scanResults.indices {
        scanResults[index].isSelected = true
    }
}

/// Deselects all folders
func deselectAll() {
    for index in scanResults.indices {
        scanResults[index].isSelected = false
    }
}

/// Returns currently selected folders
var selectedFolders: [BuildFolder] {
    scanResults.filter(\.isSelected)
}

/// Total size of selected folders
var selectedSize: Int64 {
    selectedFolders.reduce(0) { $0 + $1.size }
}

/// Formatted selected size
var formattedSelectedSize: String {
    ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(viewmodel): implement selection management`

---

### Task 3.1.5: Implement Deletion Method
**Time**: 45 min | **File**: `ZeroDevCleaner/Views/Main/MainViewModel.swift` | **Deps**: 3.1.4

Add these methods:

```swift
// MARK: - Deletion

/// Deletes selected folders
func deleteSelectedFolders() {
    let foldersToDelete = selectedFolders
    guard !foldersToDelete.isEmpty else { return }

    isDeleting = true
    deletionProgress = 0.0

    Task {
        do {
            try await deleter.delete(folders: foldersToDelete) { [weak self] current, total in
                guard let self else { return }
                Task { @MainActor in
                    self.deletionProgress = Double(current) / Double(total)
                }
            }

            // Remove deleted folders from results
            for folder in foldersToDelete {
                if let index = self.scanResults.firstIndex(where: { $0.id == folder.id }) {
                    self.scanResults.remove(at: index)
                }
            }

            self.isDeleting = false
        } catch {
            self.handleError(error)
            self.isDeleting = false
        }
    }
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(viewmodel): implement deletion with progress tracking`

---

### Task 3.1.6: Implement Error Handling
**Time**: 15 min | **File**: `ZeroDevCleaner/Views/Main/MainViewModel.swift` | **Deps**: 3.1.5

Add this method:

```swift
// MARK: - Error Handling

/// Handles errors and shows them to user
private func handleError(_ error: Error) {
    if let cleanerError = error as? ZeroDevCleanerError {
        currentError = cleanerError
    } else {
        currentError = .unknownError(error)
    }
    showError = true
}

/// Dismisses current error
func dismissError() {
    showError = false
    currentError = nil
}
```

**Verify**: `xcodebuild build`
**Commit**: `feat(viewmodel): implement error handling`

---

## Task 3.2: Create ViewModel Tests (2 hours)

### Task 3.2.1: Create Mock Services
**Time**: 45 min | **File**: `ZeroDevCleanerTests/ViewModelTests/MockServices.swift` | **Deps**: 3.1.6

```swift
//
//  MockServices.swift
//  ZeroDevCleanerTests
//

import Foundation
@testable import ZeroDevCleaner

final class MockFileScanner: FileScannerProtocol {
    var mockResults: [BuildFolder] = []
    var shouldThrowError: Error?
    var scanCalled: Bool = false

    func scanDirectory(
        at url: URL,
        progressHandler: ScanProgressHandler?
    ) async throws -> [BuildFolder] {
        scanCalled = true

        if let error = shouldThrowError {
            throw error
        }

        // Simulate progress
        for i in 0..<mockResults.count {
            progressHandler?(mockResults[i].path.path, i + 1)
        }

        return mockResults
    }
}

final class MockFileDeleter: FileDeleterProtocol {
    var deleteCalled: Bool = false
    var deletedFolders: [BuildFolder] = []
    var shouldThrowError: Error?

    func delete(
        folders: [BuildFolder],
        progressHandler: DeletionProgressHandler?
    ) async throws {
        deleteCalled = true
        deletedFolders = folders

        if let error = shouldThrowError {
            throw error
        }

        // Simulate progress
        for i in 0..<folders.count {
            progressHandler?(i + 1, folders.count)
        }
    }
}
```

**Verify**: `xcodebuild build`
**Commit**: `test(viewmodel): create mock services for testing`

---

### Task 3.2.2: Create MainViewModel Tests
**Time**: 1 hour | **File**: `ZeroDevCleanerTests/ViewModelTests/MainViewModelTests.swift` | **Deps**: 3.2.1

```swift
//
//  MainViewModelTests.swift
//  ZeroDevCleanerTests
//

import XCTest
@testable import ZeroDevCleaner

@MainActor
final class MainViewModelTests: XCTestCase {
    var sut: MainViewModel!
    var mockScanner: MockFileScanner!
    var mockDeleter: MockFileDeleter!

    override func setUp() {
        super.setUp()
        mockScanner = MockFileScanner()
        mockDeleter = MockFileDeleter()
        sut = MainViewModel(scanner: mockScanner, deleter: mockDeleter)
    }

    override func tearDown() {
        sut = nil
        mockScanner = nil
        mockDeleter = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_initialization_setsDefaultValues() {
        XCTAssertNil(sut.selectedFolder)
        XCTAssertTrue(sut.scanResults.isEmpty)
        XCTAssertFalse(sut.isScanning)
        XCTAssertEqual(sut.scanProgress, 0.0)
        XCTAssertFalse(sut.isDeleting)
    }

    // MARK: - Scan Tests

    func test_startScan_withValidFolder_updatesResults() async {
        // Given
        sut.selectedFolder = URL(fileURLWithPath: "/test")
        let mockFolder = BuildFolder(
            path: URL(fileURLWithPath: "/test/build"),
            projectType: .android,
            size: 1024,
            projectName: "Test",
            lastModified: Date()
        )
        mockScanner.mockResults = [mockFolder]

        // When
        sut.startScan()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec

        // Then
        XCTAssertTrue(mockScanner.scanCalled)
        XCTAssertEqual(sut.scanResults.count, 1)
        XCTAssertFalse(sut.isScanning)
    }

    func test_cancelScan_stopsScanning() {
        // Given
        sut.selectedFolder = URL(fileURLWithPath: "/test")
        sut.isScanning = true

        // When
        sut.cancelScan()

        // Then
        XCTAssertFalse(sut.isScanning)
    }

    // MARK: - Selection Tests

    func test_selectAll_selectsAllFolders() {
        // Given
        sut.scanResults = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date(), isSelected: false),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date(), isSelected: false)
        ]

        // When
        sut.selectAll()

        // Then
        XCTAssertTrue(sut.scanResults.allSatisfy(\.isSelected))
    }

    func test_deselectAll_deselectsAllFolders() {
        // Given
        sut.scanResults = [
            BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                       size: 1024, projectName: "Test1", lastModified: Date(), isSelected: true),
            BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                       size: 2048, projectName: "Test2", lastModified: Date(), isSelected: true)
        ]

        // When
        sut.deselectAll()

        // Then
        XCTAssertTrue(sut.scanResults.allSatisfy { !$0.isSelected })
    }

    // MARK: - Deletion Tests

    func test_deleteSelectedFolders_removesFromResults() async {
        // Given
        let folder1 = BuildFolder(path: URL(fileURLWithPath: "/test1"), projectType: .android,
                                 size: 1024, projectName: "Test1", lastModified: Date(), isSelected: true)
        let folder2 = BuildFolder(path: URL(fileURLWithPath: "/test2"), projectType: .iOS,
                                 size: 2048, projectName: "Test2", lastModified: Date(), isSelected: false)
        sut.scanResults = [folder1, folder2]

        // When
        sut.deleteSelectedFolders()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(mockDeleter.deleteCalled)
        XCTAssertEqual(sut.scanResults.count, 1)
        XCTAssertEqual(sut.scanResults.first?.id, folder2.id)
    }
}
```

**Verify**: `xcodebuild test -only-testing:ZeroDevCleanerTests/MainViewModelTests`
**Commit**: `test(viewmodel): add comprehensive MainViewModel tests`

---

## Task 3.3: Final Phase 3 Verification

### Task 3.3.1: Verify All Tests Pass
**Time**: 15 min | **Deps**: 3.2.2

**Checklist**:
- [ ] MainViewModel created with @Observable
- [ ] All methods implemented
- [ ] Mock services created
- [ ] All ViewModel tests pass
- [ ] No compiler warnings
- [ ] Update .ai-progress.json

**Verify**:
```bash
xcodebuild clean build test -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner
```

**Expected**: All tests pass, >80% ViewModel coverage

**Commit**: `chore(phase3): complete ViewModel layer implementation`

**Update .ai-progress.json**:
```json
{
  "current_phase": 4,
  "current_task": "4.1.1",
  "completed_tasks": ["1.1.1", "...", "3.3.1"],
  "phase_3_completed_at": "2025-10-29T10:00:00Z"
}
```

---

## Phase 3 Summary

**Completed**:
- ✅ MainViewModel with @Observable and @MainActor
- ✅ Folder selection and scanning logic
- ✅ Selection management
- ✅ Deletion with progress tracking
- ✅ Error handling
- ✅ Comprehensive tests with mocks
- ✅ Swift 6 concurrency compliant

**Next**: Proceed to Phase 4 - [10-phase-4-ui.md](./10-phase-4-ui.md)
