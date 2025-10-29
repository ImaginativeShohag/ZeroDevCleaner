# ZeroDevCleaner - Remaining Features & Improvements Plan

## Document Purpose

This document provides a comprehensive roadmap for completing ZeroDevCleaner. It's designed for AI agents (like Claude) to pick up and continue development autonomously.

**Last Updated**: 2025-10-29
**Current Status**: Phase 4B (MVP Enhancements) Complete
**Next Critical Task**: Task 6.2 - Permission Handling & Full Disk Access (MUST DO FIRST)

---

## Current State Analysis

### ✅ Completed (Phases 1-4)

#### Phase 1: Foundation
- Project structure configured
- Data models implemented (ProjectType, BuildFolder, ScanResult, ZeroDevCleanerError)
- All models are Sendable and Swift 6 compliant
- Model unit tests passing

#### Phase 2: Core Services
- ProjectValidator service (validates Android/iOS/Swift Package projects)
- FileSizeCalculator service (async size calculation)
- FileScanner service (recursive scanning with progress)
- FileDeleter service (safe deletion to Trash)
- All services use Swift 6 concurrency patterns
- Service unit tests passing

#### Phase 3: ViewModel Layer
- MainViewModel with @Observable macro
- @MainActor for UI thread safety
- State management for scanning, selection, deletion
- Error handling with proper error types
- ViewModel unit tests passing

#### Phase 4: Basic UI
- MainView with toolbar and state-based rendering
- EmptyStateView for initial state
- ScanProgressView with progress bar and current path
- ScanResultsView with table, selection controls, and action buttons
- Basic summary showing selected count and size

#### Phase 4B: MVP Enhancements
- Show in Finder (context menu + double-click)
- Drag & Drop folder selection with visual feedback
- Keyboard shortcuts (Cmd+O, Cmd+R, Cmd+A, Cmd+Shift+A, Delete)
- Enhanced summary card with totals and selection stats
- Quick filter by project type (All/Android/iOS/Swift Package)
- Recent folders list with UserDefaults persistence
- Copy path to clipboard

**Test Status**: 40+ tests passing, Swift 6 strict concurrency enabled

---

## Priority-Based Implementation Plan

### ✅ Phase 4B: MVP Enhancements (COMPLETE)

**Status**: ✅ All 7 features implemented and tested
**Time Spent**: ~6 hours
**Completion Date**: 2025-10-29

All high-priority MVP enhancements have been successfully implemented:
1. ✅ Show in Finder (context menu + double-click)
2. ✅ Drag & Drop folder selection
3. ✅ Keyboard shortcuts
4. ✅ Enhanced summary card
5. ✅ Quick filter by project type
6. ✅ Recent folders list
7. ✅ Copy path to clipboard

See commits: cb1effe, a4ad3a5, ee3a971, 697d0f3

---

### 🔴 Phase 6: Error Handling & Robustness (CRITICAL PRIORITY - START HERE)

**Goal**: Handle all error cases gracefully and make the app production-ready
**Estimated Time**: 6-8 hours
**Priority**: CRITICAL (essential for app to function on macOS)

**⚠️ IMPORTANT**: Task 6.2 (Permission Handling) should be implemented FIRST as the app cannot function without Full Disk Access on macOS. This is a blocking issue for any real-world usage.

**📋 Phase 6 Tasks** (listed below, after Phase 5):
- Task 6.2: Permission Handling & Full Disk Access ⚠️ **DO THIS FIRST** (2h) - See line ~465
- Task 6.1: Comprehensive Error Handling (2h)
- Task 6.3: Handle Edge Cases (2-3h)
- Task 6.4: Logging & Debugging Support (1h)

---

### 🟡 Phase 5: Enhanced UI & Polish (MEDIUM PRIORITY)

**Goal**: Polish the UI to look professional and feel smooth
**Estimated Time**: 8-10 hours
**Priority**: MEDIUM (enhances user experience)

---

#### Task 5.1: Sortable Table Columns

**Time Estimate**: 2 hours
**Priority**: MEDIUM
**Value**: MEDIUM

**Description**: Make table columns sortable by clicking headers.

**Implementation Steps**:

1. **Add Sort State to MainViewModel** (30 min)
   - Add `enum SortColumn { case projectName, type, size, lastModified }`
   - Add `enum SortOrder { case ascending, descending }`
   - Add `var sortColumn: SortColumn = .size`
   - Add `var sortOrder: SortOrder = .descending`
   - Add computed property `var sortedResults: [BuildFolder]`

2. **Update Table Definition** (60 min)
   - Make columns sortable using `.sortable()`
   - Wire sort state to ViewModel
   - Show sort indicator in headers

3. **Implement Sorting Logic** (30 min)
   - Sort by each column type
   - Handle ascending/descending
   - Maintain sort during filter changes

**Code Example**:
```swift
// In MainViewModel.swift
enum SortColumn: String {
    case projectName = "Project Name"
    case type = "Type"
    case size = "Size"
    case lastModified = "Last Modified"
}

enum SortOrder {
    case ascending, descending
}

var sortColumn: SortColumn = .size
var sortOrder: SortOrder = .descending

var sortedAndFilteredResults: [BuildFolder] {
    let filtered = filteredResults

    return filtered.sorted { lhs, rhs in
        let ascending = sortOrder == .ascending

        switch sortColumn {
        case .projectName:
            return ascending ? lhs.projectName < rhs.projectName : lhs.projectName > rhs.projectName
        case .type:
            return ascending ? lhs.projectType.rawValue < rhs.projectType.rawValue : lhs.projectType.rawValue > rhs.projectType.rawValue
        case .size:
            return ascending ? lhs.size < rhs.size : lhs.size > rhs.size
        case .lastModified:
            return ascending ? lhs.lastModified < rhs.lastModified : lhs.lastModified > rhs.lastModified
        }
    }
}

// In ScanResultsView.swift
Table(viewModel.sortedAndFilteredResults, sortOrder: $sortOrder) {
    TableColumn("", value: \.id) { folder in
        // Checkbox
    }
    .width(40)

    TableColumn("Project", value: \.projectName, comparator: .localizedStandard)

    TableColumn("Type", value: \.projectType.displayName)

    TableColumn("Size", value: \.formattedSize) { folder in
        Text(folder.formattedSize)
    }

    TableColumn("Last Modified", value: \.lastModified) { folder in
        Text(folder.formattedLastModified)
    }
}
.onChange(of: sortOrder) { oldValue, newValue in
    // Update ViewModel sort
}
```

**Acceptance Criteria**:
- All columns except checkbox are sortable
- Clicking header toggles sort direction
- Sort indicator shows in header
- Default sort is by size (descending)
- Sort persists during filtering

**Testing**:
- Click each column header
- Verify sort order is correct
- Toggle ascending/descending
- Combine with filters

---

#### Task 5.2: Better Confirmation Dialog

**Time Estimate**: 1.5 hours
**Priority**: MEDIUM
**Value**: MEDIUM

**Description**: Create a more polished confirmation dialog with detailed information.

**Current**: Basic alert
**Enhanced**: Custom sheet with styled content

**Implementation Steps**:

1. **Create DeletionConfirmationView** (60 min)
   - Custom sheet view
   - Show warning icon
   - List items to be deleted (first 5, then "and X more...")
   - Total size prominently displayed
   - Reassuring message about Trash
   - Styled buttons

2. **Integrate with MainView** (30 min)
   - Show sheet instead of alert
   - Wire up actions
   - Handle cancellation

**Code Example**:
```swift
struct DeletionConfirmationView: View {
    let foldersToDelete: [BuildFolder]
    let totalSize: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Confirm Deletion")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("You are about to delete:")
                    .fontWeight(.medium)

                ForEach(Array(foldersToDelete.prefix(5))) { folder in
                    Text("• \(folder.projectName)")
                        .font(.callout)
                }

                if foldersToDelete.count > 5 {
                    Text("• and \(foldersToDelete.count - 5) more...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    Text("Total size:")
                    Spacer()
                    Text(totalSize)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            Text("These items will be moved to Trash and can be restored if needed.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Button("Move to Trash") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}
```

**Acceptance Criteria**:
- Shows custom sheet instead of alert
- Lists items to be deleted
- Shows total size prominently
- Has cancel and confirm buttons
- Reassuring message about Trash
- Keyboard shortcuts work (Enter to confirm, Esc to cancel)

**Testing**:
- Delete various numbers of items
- Verify list shows correctly
- Test keyboard shortcuts

---

#### Task 5.3: Better Deletion Progress Sheet

**Time Estimate**: 1.5 hours
**Priority**: MEDIUM
**Value**: MEDIUM

**Description**: Create a detailed progress sheet during deletion.

**Implementation Steps**:

1. **Create DeletionProgressView** (60 min)
   - Show progress bar
   - Show current item being deleted
   - Show count (X of Y)
   - Show size progress (X MB of Y MB)
   - Cancel button

2. **Update ViewModel** (30 min)
   - Add `deletionProgress` property
   - Add `currentDeletionItem` property
   - Track deleted size

**Code Example**:
```swift
struct DeletionProgressView: View {
    let currentItem: String
    let progress: Double
    let currentIndex: Int
    let totalItems: Int
    let deletedSize: String
    let totalSize: String
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Deleting Build Folders...")
                .font(.headline)

            VStack(spacing: 8) {
                Text("Deleting: \(currentItem)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)

                HStack {
                    Text("\(currentIndex) of \(totalItems)")
                        .font(.caption)
                    Spacer()
                    Text("\(deletedSize) of \(totalSize)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .padding(30)
        .frame(width: 400)
    }
}
```

**Acceptance Criteria**:
- Shows during deletion
- Progress bar animates smoothly
- Current item updates
- Size progress updates
- Can be cancelled
- Closes automatically on completion

**Testing**:
- Delete multiple items
- Verify progress is accurate
- Test cancellation

---

#### Task 5.4: Visual Polish & Animations

**Time Estimate**: 3 hours
**Priority**: LOW-MEDIUM
**Value**: MEDIUM

**Description**: Add polish with smooth animations, hover effects, and improved styling.

**Implementation Steps**:

1. **Add Hover Effects** (45 min)
   - Table rows highlight on hover
   - Buttons brighten on hover
   - Smooth transitions

2. **Add Transitions** (60 min)
   - Fade transitions between views
   - Slide-in for sheets
   - Smooth progress animations

3. **Improve Colors & Styling** (45 min)
   - Consistent spacing
   - Better use of SF Symbols
   - Proper dark mode support
   - Accent color consistency

4. **Loading States** (30 min)
   - Better empty states
   - Skeleton loading (optional)
   - Smooth state transitions

**Code Example**:
```swift
// Hover effects
.onHover { isHovering in
    withAnimation(.easeInOut(duration: 0.2)) {
        self.isHovered = isHovering
    }
}
.background(isHovered ? Color.accentColor.opacity(0.05) : Color.clear)

// Transitions
.transition(.opacity.combined(with: .scale))

// View changes
.animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewState)
```

**Acceptance Criteria**:
- All transitions are smooth
- Hover effects work consistently
- Dark mode looks good
- No visual glitches
- Feels polished and professional

**Testing**:
- Switch between light and dark mode
- Hover over all interactive elements
- Test all transitions

---

### 🔴 Phase 6: Error Handling & Robustness (CRITICAL PRIORITY)

**Goal**: Handle all error cases gracefully and make the app production-ready
**Estimated Time**: 6-8 hours
**Priority**: CRITICAL (essential for app to function on macOS)

**⚠️ IMPORTANT**: Task 6.2 (Permission Handling) should be implemented FIRST as the app cannot function without Full Disk Access on macOS. This is a blocking issue for any real-world usage.

---

#### Task 6.2: Permission Handling & Full Disk Access ⚠️ IMPLEMENT FIRST

**Time Estimate**: 2 hours
**Priority**: CRITICAL
**Value**: CRITICAL

**⚠️ WHY THIS IS CRITICAL**: On macOS, the app needs Full Disk Access permission to scan most user directories. Without this permission:
- The app cannot scan ~/Library, ~/Documents, or most development folders
- Users will get confusing "permission denied" errors
- The app appears broken and unusable
- This must be implemented before any production use

**Description**: Properly detect and handle Full Disk Access permission with user-friendly guidance.

**Implementation Steps**:

1. **Create Permission Checker** (45 min)
   - Create `PermissionManager.swift` in Utilities folder
   - Check if app has Full Disk Access
   - Method to open System Settings to correct pane
   - Singleton pattern with @MainActor

2. **Add Permission Check on First Scan** (45 min)
   - Check before starting scan in MainViewModel
   - Show helpful dialog if denied with clear instructions
   - Link to System Settings with one-click action
   - Don't show scary technical errors

3. **Handle Permission Errors During Scan** (30 min)
   - Skip inaccessible folders gracefully
   - Track skipped folders
   - Show summary: "Scanned X folders, skipped Y due to permissions"
   - Offer to open System Settings from results

**Code Example**:
```swift
@MainActor
final class PermissionManager: Sendable {
    static let shared = PermissionManager()

    private init() {}

    func hasFullDiskAccess() -> Bool {
        // Try to access a known protected location
        let testPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Safari/History.db")

        return FileManager.default.isReadableFile(atPath: testPath.path)
    }

    func requestFullDiskAccess() {
        // Opens System Settings to Full Disk Access pane
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
}

// In MainViewModel
func startScan() {
    guard let folder = selectedFolder else { return }

    // Check permissions first
    if !PermissionManager.shared.hasFullDiskAccess() {
        currentError = .permissionDenied(folder)
        showError = true
        return
    }

    // Continue with scan...
}
```

**User-Friendly Permission Dialog**:
```swift
.alert("Full Disk Access Required", isPresented: $viewModel.showPermissionError) {
    Button("Open System Settings") {
        PermissionManager.shared.requestFullDiskAccess()
    }
    Button("Cancel", role: .cancel) { }
} message: {
    Text("ZeroDevCleaner needs Full Disk Access to scan your development folders.\n\n1. Click 'Open System Settings'\n2. Enable 'ZeroDevCleaner' in the Full Disk Access list\n3. Return to the app and try again")
}
```

**Acceptance Criteria**:
- ✅ Detects missing Full Disk Access before scan
- ✅ Shows clear, non-technical error message
- ✅ Opens System Settings to correct pane with one click
- ✅ Scans work properly after permission granted
- ✅ Handles partial access gracefully (some folders accessible, some not)
- ✅ Provides helpful guidance, not scary error messages

**Testing**:
1. Test app without Full Disk Access
2. Verify helpful dialog shows
3. Click "Open System Settings" and verify it goes to right place
4. Grant access and verify scanning works
5. Test on restricted folders (~/Library)
6. Test with partial access

---

#### Task 6.1: Comprehensive Error Handling

**Time Estimate**: 2 hours
**Priority**: HIGH
**Value**: HIGH

**Description**: Handle all error scenarios with user-friendly messages and recovery options.

**Error Cases to Handle**:
1. Permission denied
2. Folder no longer exists
3. Deletion failures (partial or complete)
4. Out of disk space
5. Folder in use
6. Network drives/volumes

**Implementation Steps**:

1. **Enhance ZeroDevCleanerError** (30 min)
   - Add all specific error cases
   - Add recovery suggestions
   - Add helpful error descriptions

2. **Add Error Views** (60 min)
   - Create `ErrorAlertView.swift`
   - Create `PermissionErrorView.swift`
   - Show actionable solutions

3. **Update ViewModel Error Handling** (30 min)
   - Catch all error types
   - Convert to user-friendly messages
   - Provide recovery actions

**Code Example**:
```swift
// Enhanced error enum
enum ZeroDevCleanerError: LocalizedError {
    case permissionDenied(URL)
    case folderNotFound(URL)
    case deletionFailed(URL, underlyingError: Error)
    case scanCancelled
    case outOfDiskSpace
    case folderInUse(URL)
    case networkDriveNotSupported(URL)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let url):
            return "Permission Denied"
        case .folderNotFound(let url):
            return "Folder Not Found"
        case .deletionFailed(let url, _):
            return "Deletion Failed"
        case .scanCancelled:
            return "Scan Cancelled"
        case .outOfDiskSpace:
            return "Out of Disk Space"
        case .folderInUse(let url):
            return "Folder In Use"
        case .networkDriveNotSupported(let url):
            return "Network Drive Not Supported"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Grant Full Disk Access in System Settings > Privacy & Security."
        case .folderNotFound:
            return "The folder may have been moved or deleted. Try rescanning."
        case .deletionFailed:
            return "The folder may be in use. Close any apps using it and try again."
        case .scanCancelled:
            return "The scan was cancelled. Start a new scan to continue."
        case .outOfDiskSpace:
            return "Free up space on your disk and try again."
        case .folderInUse:
            return "Close any apps using this folder and try again."
        case .networkDriveNotSupported:
            return "Scanning network drives is not currently supported."
        }
    }
}
```

**Acceptance Criteria**:
- All error cases have specific handling
- User-friendly error messages
- Recovery suggestions provided
- No unhandled errors crash the app

**Testing**:
- Trigger each error scenario
- Verify error messages are clear
- Test recovery actions

---

#### Task 6.3: Handle Edge Cases

**Time Estimate**: 2-3 hours
**Priority**: MEDIUM
**Value**: HIGH

**Description**: Handle all edge cases to prevent crashes and confusion.

**Edge Cases**:
1. Empty scan results (no build folders found)
2. Scan cancellation cleanup
3. Partial deletion failures
4. Very large folders (>100GB)
5. Special characters in paths
6. Symlinks (don't follow outside root)
7. Concurrent operations

**Implementation Steps**:

1. **Handle Empty Results** (30 min)
   - Show friendly message
   - Suggest scanning different folder
   - Don't show empty table

2. **Handle Scan Cancellation** (30 min)
   - Clean up resources
   - Show partial results
   - Clear progress state

3. **Handle Partial Deletion Failures** (45 min)
   - Continue deleting other items
   - Collect failed items
   - Show summary with failures
   - Don't remove failed items from list

4. **Handle Large Folders** (30 min)
   - Show size calculation progress
   - Don't block UI
   - Allow cancellation

5. **Handle Symlinks Safely** (30 min)
   - Don't follow symlinks outside root
   - Validate paths before operations
   - Prevent infinite loops

**Code Example**:
```swift
// In MainViewModel
func handleEmptyScanResults() {
    if scanResults.isEmpty {
        // Show empty state with message
        currentError = .noResultsFound
        showError = true
    }
}

// In FileDeleter
func delete(folders: [BuildFolder], progressHandler: @escaping (Double, String) -> Void) async throws {
    var failedDeletions: [(BuildFolder, Error)] = []

    for (index, folder) in folders.enumerated() {
        do {
            try await deleteSingle(folder)
            let progress = Double(index + 1) / Double(folders.count)
            progressHandler(progress, folder.projectName)
        } catch {
            // Don't throw, collect failures
            failedDeletions.append((folder, error))
        }
    }

    if !failedDeletions.isEmpty {
        // Report partial failure
        throw ZeroDevCleanerError.partialDeletionFailure(failedDeletions)
    }
}
```

**Acceptance Criteria**:
- Empty results show helpful message
- Cancellation cleans up properly
- Partial failures show detail
- Large folders don't freeze UI
- Symlinks handled safely
- No crashes in any scenario

**Testing**:
- Scan folder with no build folders
- Cancel scan mid-operation
- Delete folder that's in use
- Test with very large folders
- Test with symlinks

---

#### Task 6.4: Add Logging & Debugging Support

**Time Estimate**: 1 hour
**Priority**: LOW
**Value**: MEDIUM

**Description**: Add logging to help debug issues in production.

**Implementation Steps**:

1. **Add Logger** (30 min)
   - Use `os.Logger`
   - Log key operations
   - Log errors with context

2. **Add Debug Menu** (Optional, 30 min)
   - Show logs in UI (debug builds only)
   - Export logs
   - Clear logs

**Code Example**:
```swift
import os.log

extension Logger {
    static let app = Logger(subsystem: "org.imaginativeworld.ZeroDevCleaner", category: "app")
    static let scanning = Logger(subsystem: "org.imaginativeworld.ZeroDevCleaner", category: "scanning")
    static let deletion = Logger(subsystem: "org.imaginativeworld.ZeroDevCleaner", category: "deletion")
}

// Usage
Logger.scanning.info("Starting scan at \(url.path)")
Logger.scanning.error("Scan failed: \(error.localizedDescription)")
```

**Acceptance Criteria**:
- Key operations are logged
- Errors include context
- Logs help debug issues
- Performance not impacted

---

### 🔵 Phase 7: Testing & Quality Assurance (HIGH PRIORITY)

**Goal**: Ensure app is stable and reliable
**Estimated Time**: 8-12 hours
**Priority**: HIGH (critical for release)

---

#### Task 7.1: Expand Unit Tests

**Time Estimate**: 3 hours
**Priority**: HIGH
**Value**: HIGH

**Description**: Add comprehensive unit tests for all new features.

**Implementation Steps**:

1. **Test MVP Enhancements** (90 min)
   - Test drag & drop logic
   - Test keyboard shortcuts
   - Test filtering
   - Test recent folders manager
   - Test sorting

2. **Test Error Handling** (60 min)
   - Test all error types
   - Test error recovery
   - Test permission checks

3. **Improve Coverage** (30 min)
   - Aim for >85% code coverage
   - Focus on critical paths
   - Test edge cases

**Acceptance Criteria**:
- All new features have tests
- Code coverage >85%
- All tests pass
- No flaky tests

---

#### Task 7.2: Integration Tests

**Time Estimate**: 3 hours
**Priority**: MEDIUM
**Value**: HIGH

**Description**: Test complete flows end-to-end.

**Test Scenarios**:
1. Complete scan flow (select → scan → results)
2. Complete deletion flow (select → delete → confirm → complete)
3. Filter and sort flow
4. Error scenarios (permission, missing folder, etc.)
5. Recent folders flow
6. Drag & drop flow

**Implementation Steps**:

1. **Create Test Fixtures** (60 min)
   - Create sample project structures
   - Android projects with build folders
   - iOS projects with .build folders
   - Invalid folders

2. **Write Integration Tests** (90 min)
   - Test each scenario
   - Use test fixtures
   - Verify end state

3. **Automate Tests** (30 min)
   - Run on CI (if using)
   - Run before commits

**Acceptance Criteria**:
- All key flows tested
- Tests use realistic data
- Tests are reliable

---

#### Task 7.3: UI Tests

**Time Estimate**: 2 hours
**Priority**: LOW-MEDIUM
**Value**: MEDIUM

**Description**: Test UI interactions and flows.

**Implementation Steps**:

1. **Set up UI Testing** (30 min)
   - Configure UI test target
   - Add accessibility identifiers

2. **Write UI Tests** (90 min)
   - Test main flows
   - Test keyboard navigation
   - Test accessibility

**Acceptance Criteria**:
- Key UI flows tested
- Keyboard navigation works
- VoiceOver support verified

---

#### Task 7.4: Manual Testing Checklist

**Time Estimate**: 2-4 hours
**Priority**: HIGH
**Value**: HIGH

**Description**: Thorough manual testing before release.

**Checklist**:
- [ ] Test on Intel Mac
- [ ] Test on Apple Silicon Mac
- [ ] Test on macOS 15.0
- [ ] Test on macOS 15.1+
- [ ] Test with Android projects
- [ ] Test with iOS projects
- [ ] Test with Swift Package projects
- [ ] Test with large directory trees (1000+ folders)
- [ ] Test with deep nesting (10+ levels)
- [ ] Test with special characters in paths
- [ ] Test light mode
- [ ] Test dark mode
- [ ] Test all keyboard shortcuts
- [ ] Test drag & drop
- [ ] Test all filters
- [ ] Test sorting
- [ ] Test error scenarios
- [ ] Test permission flows
- [ ] Test recent folders
- [ ] Test context menus
- [ ] Test window resizing
- [ ] Test with external drives
- [ ] Test performance

**Acceptance Criteria**:
- All checklist items pass
- No critical bugs found
- Performance is acceptable

---

### 🟣 Phase 8: Performance & Optimization (MEDIUM PRIORITY)

**Goal**: Ensure app performs well with large data sets
**Estimated Time**: 4-6 hours
**Priority**: MEDIUM (important for UX)

---

#### Task 8.1: Performance Profiling

**Time Estimate**: 2 hours
**Priority**: MEDIUM
**Value**: HIGH

**Description**: Profile app with Instruments to find bottlenecks.

**Implementation Steps**:

1. **Profile with Time Profiler** (45 min)
   - Find slow operations
   - Optimize hot paths
   - Test with large data sets

2. **Profile with Allocations** (45 min)
   - Find memory leaks
   - Reduce memory usage
   - Test with large scans

3. **Profile with UI Rendering** (30 min)
   - Find UI bottlenecks
   - Ensure 60fps
   - Test with many items

**Performance Targets**:
- Scan >1000 folders/second
- Memory usage <100MB for typical scans
- UI maintains 60fps during all operations
- Table scrolling is smooth with 100+ items

**Acceptance Criteria**:
- No obvious bottlenecks
- Meets performance targets
- Smooth on older Macs

---

#### Task 8.2: Optimize Large Result Sets

**Time Estimate**: 2 hours
**Priority**: MEDIUM
**Value**: MEDIUM

**Description**: Optimize UI for large numbers of results.

**Implementation Steps**:

1. **Virtual Scrolling** (60 min)
   - Table should handle 1000+ items
   - Use LazyVStack if needed
   - Test performance

2. **Batch Operations** (30 min)
   - Batch select/deselect operations
   - Update UI efficiently

3. **Progressive Loading** (Optional, 30 min)
   - Show results as they're found
   - Don't wait for complete scan

**Acceptance Criteria**:
- Table performs well with 1000+ items
- Scrolling is smooth
- Selection operations are fast

---

#### Task 8.3: Memory Optimization

**Time Estimate**: 1 hour
**Priority**: LOW-MEDIUM
**Value**: MEDIUM

**Description**: Reduce memory usage during operations.

**Implementation Steps**:

1. **Profile Memory Usage** (30 min)
   - Find memory leaks
   - Reduce allocations

2. **Optimize Caching** (30 min)
   - Don't cache unnecessary data
   - Release memory after operations

**Acceptance Criteria**:
- No memory leaks
- Memory usage stays reasonable
- App doesn't crash with large scans

---

### 🟠 Phase 9: App Icon & Branding (LOW-MEDIUM PRIORITY)

**Goal**: Create professional app icon and branding
**Estimated Time**: 2-3 hours
**Priority**: LOW-MEDIUM (important for first impression)

---

#### Task 9.1: Design App Icon

**Time Estimate**: 2 hours
**Priority**: MEDIUM
**Value**: MEDIUM

**Description**: Design and implement app icon following macOS guidelines.

**Design Concept Ideas**:
1. Folder with cleaning/broom symbol
2. Folder with recycling symbol
3. Build tools being cleaned
4. Developer tools with sparkle

**Implementation Steps**:

1. **Design Icon** (90 min)
   - Sketch concepts
   - Design in vector format
   - Follow macOS Big Sur style
   - Create all required sizes

2. **Add to Project** (30 min)
   - Export all sizes
   - Add to Assets.xcassets
   - Set in project settings
   - Test on dock and Finder

**Sizes Needed**:
- 1024x1024 (App Store)
- 512x512, 256x256, 128x128, 64x64, 32x32, 16x16
- @1x and @2x for each

**Acceptance Criteria**:
- Icon follows macOS design guidelines
- Looks good at all sizes
- Represents app purpose clearly
- No trademark issues

---

### ⚫ Phase 10: Documentation & Release Prep (MEDIUM-HIGH PRIORITY)

**Goal**: Prepare for public release
**Estimated Time**: 6-8 hours
**Priority**: MEDIUM-HIGH (required for release)

---

#### Task 10.1: Code Documentation

**Time Estimate**: 2 hours
**Priority**: MEDIUM
**Value**: MEDIUM

**Description**: Add documentation comments to all public APIs.

**Implementation Steps**:

1. **Document Public APIs** (90 min)
   - Add doc comments to all public types
   - Add doc comments to all public methods
   - Include parameter descriptions
   - Include example usage

2. **Create Architecture Documentation** (30 min)
   - Update technical architecture doc
   - Document key decisions
   - Add diagrams if helpful

**Acceptance Criteria**:
- All public APIs documented
- Documentation is clear and helpful
- Examples provided where useful

---

#### Task 10.2: User Guide & Screenshots

**Time Estimate**: 2 hours
**Priority**: HIGH
**Value**: HIGH

**Description**: Create user guide with screenshots.

**Implementation Steps**:

1. **Take Screenshots** (30 min)
   - Screenshot each major view
   - Show key features
   - Use representative data

2. **Write User Guide** (60 min)
   - Getting started
   - How to scan
   - How to delete
   - Features overview
   - FAQ

3. **Create README** (30 min)
   - Project description
   - Screenshots
   - Download link
   - System requirements
   - Quick start guide

**Acceptance Criteria**:
- Screenshots show all major features
- User guide is comprehensive
- README is attractive and informative

---

#### Task 10.3: Signing & Notarization

**Time Estimate**: 2 hours
**Priority**: HIGH
**Value**: CRITICAL

**Description**: Set up code signing and notarize the app.

**Implementation Steps**:

1. **Set Up Code Signing** (45 min)
   - Get Developer ID certificate
   - Configure in Xcode
   - Add entitlements
   - Test signed build

2. **Notarize App** (45 min)
   - Archive app
   - Submit to notary service
   - Staple notarization ticket
   - Verify notarization

3. **Create DMG** (30 min)
   - Create disk image
   - Add background and layout
   - Sign DMG
   - Test installation

**Acceptance Criteria**:
- App is properly signed
- App passes notarization
- DMG installs without warnings
- Gatekeeper allows app to run

---

#### Task 10.4: Release Process

**Time Estimate**: 1 hour
**Priority**: HIGH
**Value**: HIGH

**Description**: Prepare and execute release.

**Implementation Steps**:

1. **Create GitHub Release** (20 min)
   - Tag version
   - Upload DMG
   - Write release notes

2. **Announce Release** (20 min)
   - Update README with download link
   - Post announcement (if applicable)

3. **Set Up Issue Tracking** (20 min)
   - Configure GitHub issues
   - Add issue templates
   - Add labels

**Acceptance Criteria**:
- Release is published
- Download works
- Release notes are clear

---

## Additional Future Enhancements (Post-Release)

These features are mentioned in documentation but not critical for initial release:

### Additional Project Type Support

**Time Estimate**: 4-6 hours per type
**Priority**: LOW
**Value**: MEDIUM

1. **DerivedData Folders** (Xcode)
   - Location: `~/Library/Developer/Xcode/DerivedData`
   - Often very large
   - Safe to delete when not building

2. **Gradle Cache** (Android)
   - Location: `~/.gradle/caches`
   - Can grow very large
   - Safe to delete

3. **CocoaPods** (iOS)
   - `Pods/` folders in projects
   - Can be regenerated with `pod install`

4. **Node Modules** (Optional, if expanding scope)
   - `node_modules/` folders
   - Can be very large
   - Different project type though

5. **Flutter Build** (Future)
   - `build/` folders in Flutter projects
   - Similar to Android/iOS

### Advanced Features (Phase 11+)

These are "nice to have" features mentioned in docs:

1. **Settings/Preferences** (2-3 hours)
   - Scan options
   - Deletion options
   - Exclusion patterns

2. **Statistics Dashboard** (3-4 hours)
   - Total space cleaned over time
   - Number of projects scanned
   - Charts and graphs

3. **Scheduled Scans** (4-5 hours)
   - Automatic scanning on schedule
   - Notifications when space found

4. **Export Results** (2 hours)
   - Export scan results to CSV
   - Generate reports

5. **Save/Load Scan Results** (2-3 hours)
   - Save scan results for later
   - Compare scans over time

---

## Implementation Priorities Summary

### ⚠️ CRITICAL - Must Do First
**Task 6.2: Permission Handling & Full Disk Access** (2 hours)
- This is the HIGHEST PRIORITY task
- The app cannot function on macOS without Full Disk Access
- Users will see "permission denied" errors everywhere
- Must be implemented before any real-world testing or use
- See Phase 6, Task 6.2 for full details

### 🔴 Must Have (For Release)
1. **Phase 6: Error Handling (6-8 hours)** ← START HERE
   - Task 6.2: Permission Handling (2h) ⚠️ DO FIRST
   - Task 6.1: Comprehensive Error Handling (2h)
   - Task 6.3: Handle Edge Cases (2-3h)
   - Task 6.4: Logging & Debugging (1h)

2. Phase 7: Testing (8-12 hours)
3. Phase 10: Documentation & Release (6-8 hours)

**Total**: 20-28 hours

**Note**: Phase 4B (MVP Enhancements) is complete ✅

### 🟡 Should Have (Soon After Release)
1. Phase 5: Enhanced UI (8-10 hours)
2. Phase 8: Performance (4-6 hours)
3. Phase 9: App Icon (2-3 hours)

**Total**: 14-19 hours

### 🟢 Nice to Have (Future)
1. Additional project types (4-6 hours each)
2. Advanced features (10-20 hours)

---

## How to Use This Document

### For AI Agents (Like Claude)

When picking up this project:

1. **Read CLAUDE.md first** - Understand current status
2. **Check this document** - Find next tasks to work on
3. **Follow priorities** - Start with 🔴 Must Have items
4. **Update CLAUDE.md** - After completing each phase/task
5. **Run tests frequently** - Ensure nothing breaks
6. **Commit often** - Small, focused commits

### Task Selection Guidelines

- If user asks for specific feature → Find it in this doc and implement
- If user says "continue" → Pick next highest priority task
- If user says "what's next" → Show priorities and ask for preference
- If unclear → Ask user which phase they want to focus on

### Verification Checklist Per Task

Before marking any task complete:

- [ ] Implementation matches specification
- [ ] Code compiles without warnings
- [ ] Tests written and passing
- [ ] Manual testing performed
- [ ] No regressions introduced
- [ ] CLAUDE.md updated
- [ ] Git commit created

---

## Dependencies & Constraints

### Technical Constraints
- Swift 6.0 required
- macOS 15.0+ target
- SwiftUI for UI
- No third-party dependencies (MVP)
- Strict concurrency checking enabled

### Design Constraints
- Follow macOS Human Interface Guidelines
- Native macOS look and feel
- Keyboard-accessible
- VoiceOver support

### Performance Constraints
- Must handle 1000+ build folders
- Scan speed >1000 folders/second
- Memory usage <100MB typical
- UI must maintain 60fps

---

## Success Metrics

### For Enhanced MVP (Phase 4B Complete)
- All high-priority MVP enhancements working
- App is user-friendly and intuitive
- No crashes during normal operation
- All unit tests passing

### For Release (Phase 10 Complete)
- App is signed and notarized
- All tests passing
- Code coverage >85%
- User guide complete
- No critical bugs
- Performance meets targets

### For Post-Release
- User feedback positive
- No crash reports
- Feature requests guide future development

---

## Risk Mitigation

### High Risk Areas
1. **File System Permissions** - Mitigated by clear error messages and permission handling
2. **Performance with Large Trees** - Mitigated by async operations and progress reporting
3. **False Positives** - Mitigated by strong validation logic

### Testing Strategy
- Unit tests for all logic
- Integration tests for flows
- Manual testing checklist
- Beta testing before release (optional)

---

## Notes for Future Development

### Code Quality
- Maintain Swift 6 compliance
- Keep test coverage >85%
- Document all public APIs
- Follow existing patterns

### User Experience
- Prioritize safety over speed
- Always provide feedback
- Clear error messages
- Intuitive workflows

### Architecture
- Keep services protocol-based
- ViewModels co-located with views
- Use @Observable (not ObservableObject)
- Structured concurrency throughout

---

## Conclusion

This document provides a complete roadmap for finishing ZeroDevCleaner. The app is currently at Phase 4 (Basic UI complete) with a solid foundation. The next steps focus on enhancing UX with high-value features, ensuring robustness with comprehensive error handling, and preparing for release with proper documentation and signing.

**Estimated time to Enhanced MVP**: 26-36 hours
**Estimated time to Release**: 40-55 hours

By following this plan systematically, any AI agent or developer can pick up the project and continue development effectively.
