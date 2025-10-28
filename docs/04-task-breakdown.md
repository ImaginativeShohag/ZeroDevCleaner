# ZeroDevCleaner - Detailed Task Breakdown

## Phase 1: Project Setup & Foundation

### Task 1.1: Project Initialization
**Estimated Time**: 1 hour

#### Subtasks:
1. Create new Xcode project
   - Template: macOS App
   - Interface: SwiftUI
   - Language: Swift
   - Bundle ID: org.imaginativeworld.ZeroDevCleaner
   - Minimum deployment: macOS 15.0

2. Configure project settings
   - Set up proper signing
   - Configure capabilities
   - Set app icon placeholder

3. Create project folder structure
   ```
   ZeroDevCleaner/
   ├── App/
   │   ├── ZeroDevCleanerApp.swift
   │   └── Assets.xcassets
   ├── Views/
   ├── ViewModels/
   ├── Models/
   ├── Services/
   ├── Utilities/
   └── Resources/
   ```

4. Set up Git repository
   - Initialize Git
   - Create .gitignore
   - Initial commit

### Task 1.2: Create Data Models
**Estimated Time**: 2 hours

#### Subtasks:
1. Create `ProjectType.swift`
   - Define enum with cases: android, iOS, swiftPackage
   - Add displayName computed property
   - Add icon (SF Symbol) computed property
   - Add Codable conformance

2. Create `BuildFolder.swift`
   - Define struct with all properties
   - Add Identifiable conformance
   - Add Hashable conformance
   - Add formattedSize computed property
   - Add relativePath computed property
   - Add unit tests for model

3. Create `ScanResult.swift`
   - Define struct for scan results
   - Add totalSize computed property
   - Add formattedScanDuration property

4. Create `ZeroDevCleanerError.swift`
   - Define custom error enum
   - Implement LocalizedError protocol
   - Add user-friendly error descriptions

**Acceptance Criteria**:
- All models compile without errors
- Models have proper documentation
- Unit tests pass

---

## Phase 2: Service Layer Implementation

### Task 2.1: Implement ProjectValidator
**Estimated Time**: 4 hours

#### Subtasks:
1. Create `ProjectValidatorProtocol.swift`
   - Define protocol interface
   - Document expected behavior

2. Create `ProjectValidator.swift`
   - Implement protocol
   - Add private helper methods

3. Implement Android project validation
   - Check for build.gradle files
   - Check for settings.gradle files
   - Check for typical Android structure
   - Handle edge cases (multi-module projects)

4. Implement iOS project validation
   - Check for .xcodeproj files
   - Check for .xcworkspace files
   - Check for Package.swift
   - Handle Swift Package Manager projects

5. Implement build folder validation
   - Verify folder structure
   - Check for expected contents
   - Prevent false positives

6. Write comprehensive unit tests
   - Test with valid projects
   - Test with invalid projects
   - Test edge cases
   - Mock file system operations

**Acceptance Criteria**:
- Correctly identifies valid Android projects
- Correctly identifies valid iOS/Xcode projects
- Rejects false positives
- All unit tests pass (>80% coverage)

### Task 2.2: Implement FileSizeCalculator
**Estimated Time**: 2 hours

#### Subtasks:
1. Create `FileSizeCalculatorProtocol.swift`
   - Define protocol interface

2. Create `FileSizeCalculator.swift`
   - Implement async size calculation
   - Use FileManager for traversal
   - Handle permission errors gracefully
   - Optimize for performance

3. Add size formatting utilities
   - Create extension on Int64
   - Format bytes to KB/MB/GB
   - Handle edge cases (0 bytes, very large sizes)

4. Write unit tests
   - Test with known directory sizes
   - Test with empty directories
   - Test error handling
   - Test formatting

**Acceptance Criteria**:
- Accurately calculates directory sizes
- Handles errors without crashing
- Formats sizes correctly
- Tests pass

### Task 2.3: Implement FileScanner
**Estimated Time**: 6 hours

#### Subtasks:
1. Create `FileScannerProtocol.swift`
   - Define protocol with async methods
   - Define progress callback signature

2. Create `FileScanner.swift`
   - Implement directory traversal
   - Use FileManager.enumerator
   - Implement cancellation support
   - Add progress reporting

3. Integrate with ProjectValidator
   - Call validator for each potential build folder
   - Skip invalid folders

4. Integrate with FileSizeCalculator
   - Calculate size for valid build folders
   - Cache results to avoid recalculation

5. Implement optimizations
   - Skip common non-project folders (.git, node_modules)
   - Implement depth limit
   - Handle symlinks safely
   - Batch progress updates

6. Handle edge cases
   - Very deep directory structures
   - Permission errors
   - Symlink loops
   - Special characters in paths

7. Write comprehensive tests
   - Test with mock file system
   - Test cancellation
   - Test progress reporting
   - Test error handling

**Acceptance Criteria**:
- Successfully scans directory trees
- Reports accurate progress
- Can be cancelled mid-scan
- Handles errors gracefully
- Tests pass with >80% coverage

### Task 2.4: Implement FileDeleter
**Estimated Time**: 3 hours

#### Subtasks:
1. Create `FileDeleterProtocol.swift`
   - Define protocol interface
   - Define progress callback

2. Create `FileDeleter.swift`
   - Implement move to Trash functionality
   - Use FileManager.trashItem
   - Add progress reporting
   - Handle errors per-item

3. Implement batch deletion
   - Delete multiple folders
   - Continue on error
   - Collect error details

4. Add safety checks
   - Verify paths before deletion
   - Prevent deleting outside scanned root
   - Validate folder still exists

5. Write unit tests
   - Test with temporary directories
   - Test error handling
   - Test progress reporting
   - Verify items moved to Trash

**Acceptance Criteria**:
- Successfully moves folders to Trash
- Reports accurate progress
- Handles partial failures gracefully
- Tests pass

---

## Phase 3: ViewModel Layer

### Task 3.1: Implement MainViewModel
**Estimated Time**: 4 hours
**Note**: This ViewModel will consolidate all business logic, including responsibilities that might have been in a separate `ScanViewModel`. ViewModels are co-located with their corresponding screen view files.

#### Subtasks:
1. Create `MainViewModel.swift` next to the main view file
   - Use @Observable macro instead of ObservableObject
   - Mark with @MainActor for UI thread safety
   - Inject service dependencies
   - Remove @Published wrappers (not needed with @Observable)

2. Implement folder selection
   - Use NSOpenPanel
   - Validate selected folder
   - Update UI state

3. Implement scan functionality with structured concurrency
   - Use Task for async operations
   - Call FileScanner service
   - Update progress on main actor
   - Handle results
   - Handle errors
   - Support task cancellation

4. Implement deletion functionality
   - Use Task for async operations
   - Call FileDeleter service
   - Update UI state on main actor
   - Handle errors
   - Update results list

5. Add state management
   - Track scanning state
   - Track selection state
   - Track error state

6. Write unit tests
   - Mock service dependencies
   - Test state transitions
   - Test error handling
   - Test async operations with Task

**Acceptance Criteria**:
- ViewModel correctly manages app state
- All operations use Swift 6 structured concurrency
- Errors are handled and exposed to UI
- Tests pass with >80% coverage

---

## Phase 4: User Interface Implementation

### Task 4.1: Create Main Window Structure
**Estimated Time**: 3 hours

#### Subtasks:
1. Create `MainView.swift`
   - Set up basic window structure
   - Add toolbar
   - Add content area
   - Add status bar

2. Configure window properties
   - Set default size
   - Set minimum size
   - Enable resizing

3. Create toolbar
   - Add Select Folder button
   - Add Start/Stop Scan button
   - Show selected path

4. Create status bar
   - Show scan status
   - Show last scan time
   - Show item counts

5. Test window behavior
   - Verify resizing works
   - Verify toolbar functionality

**Acceptance Criteria**:
- Window opens with correct size
- Toolbar displays correctly
- Status bar updates properly

### Task 4.2: Implement Empty State View
**Estimated Time**: 2 hours

#### Subtasks:
1. Create `EmptyStateView.swift`
   - Add icon
   - Add welcome text
   - Add description
   - Add call-to-action button

2. Apply styling
   - Center content
   - Use system colors
   - Match design spec

3. Wire up button action
   - Connect to ViewModel
   - Trigger folder selection

**Acceptance Criteria**:
- Empty state displays on launch
- Button triggers folder selection
- Matches design specification

### Task 4.3: Implement Scanning Progress View
**Estimated Time**: 3 hours

#### Subtasks:
1. Create `ScanProgressView.swift`
   - Add progress bar
   - Add current path label
   - Add statistics
   - Add stop button

2. Bind to ViewModel
   - Update progress bar
   - Update current path
   - Update statistics
   - Handle stop action

3. Add animations
   - Smooth progress updates
   - Fade transitions

4. Test progress updates
   - Verify smooth animation
   - Verify stop functionality

**Acceptance Criteria**:
- Progress displays during scan
- Updates are smooth
- Stop button works correctly

### Task 4.4: Implement Results Table View
**Estimated Time**: 5 hours

#### Subtasks:
1. Create `BuildFolderRow.swift`
   - Design row layout
   - Add checkbox
   - Add path label
   - Add type icon
   - Add size label

2. Create `ScanResultsView.swift`
   - Implement Table view
   - Add column headers
   - Implement sorting
   - Add row selection

3. Implement selection functionality
   - Checkbox toggle
   - Select all button
   - Deselect all button
   - Track selection state

4. Add selection summary
   - Show selected count
   - Show total size of selected
   - Update dynamically

5. Apply styling
   - Alternating row colors
   - Hover effects
   - Proper spacing

6. Test interactions
   - Verify sorting works
   - Verify selection works
   - Verify performance with many items

**Acceptance Criteria**:
- Table displays all results
- Sorting works on all columns
- Selection works correctly
- Performs well with 100+ items

### Task 4.5: Implement Action Buttons Area
**Estimated Time**: 2 hours

#### Subtasks:
1. Create action button area
   - Layout buttons
   - Add spacing
   - Apply styling

2. Implement Select All button
   - Wire to ViewModel
   - Update button state

3. Implement Deselect All button
   - Wire to ViewModel
   - Update button state

4. Implement Remove Selected button
   - Apply destructive styling
   - Enable only when items selected
   - Wire to ViewModel

**Acceptance Criteria**:
- Buttons are properly styled
- Buttons work correctly
- Remove button is disabled when nothing selected

### Task 4.6: Implement Confirmation Dialog
**Estimated Time**: 2 hours

#### Subtasks:
1. Create `DeletionConfirmationView.swift`
   - Design dialog layout
   - Add warning icon
   - Add summary text
   - Add buttons

2. Wire up to ViewModel
   - Show when Remove clicked
   - Pass selection data
   - Handle confirmation
   - Handle cancellation

3. Apply styling
   - Use sheet presentation
   - Match design spec

**Acceptance Criteria**:
- Dialog shows before deletion
- Displays correct information
- Buttons work correctly

### Task 4.7: Implement Deletion Progress Sheet
**Estimated Time**: 2 hours

#### Subtasks:
1. Create `DeletionProgressView.swift`
   - Add progress bar
   - Add current item label
   - Add progress statistics
   - Add cancel button

2. Bind to ViewModel
   - Update progress
   - Update current item
   - Handle cancellation

3. Apply styling and animations

**Acceptance Criteria**:
- Shows during deletion
- Updates smoothly
- Can be cancelled

### Task 4.8: Implement Completion Dialog
**Estimated Time**: 1 hour

#### Subtasks:
1. Create `CompletionView.swift`
   - Add success icon
   - Add summary text
   - Add statistics
   - Add done button

2. Wire up to ViewModel
   - Show after deletion completes
   - Display results
   - Reset state on done

**Acceptance Criteria**:
- Shows after successful deletion
- Displays correct statistics
- Closes properly

### Task 4.9: Implement MVP Enhancements
**Estimated Time**: 8 hours

#### Subtasks:
1.  **Implement "Show in Finder"**: Add context menu, double-click functionality, and an "Open in Finder" button to reveal items in Finder.
2.  **Implement Drag & Drop**: Allow users to drop folders onto the app to start a scan.
3.  **Implement Keyboard Shortcuts**: Add shortcuts for common actions (e.g., Cmd+O, Cmd+R, Cmd+A).
4.  **Implement Total Space Summary**: Display a summary of total and selected space to be cleaned.
5.  **Implement Quick Filter**: Add controls to filter results by project type (Android, iOS).
6.  **Implement Recent Folders**: Remember and provide quick access to recently scanned folders.

**Acceptance Criteria**:
- All enhancement features are implemented and functional.
- UI remains clean and intuitive.
- Performance is not negatively impacted.

---

## Phase 5: Error Handling & Edge Cases

### Task 5.1: Implement Error Views
**Estimated Time**: 3 hours

#### Subtasks:
1. Create `ErrorView.swift`
   - Generic error display component
   - Reusable across app

2. Create `PermissionErrorView.swift`
   - Specific to permission errors
   - Link to System Settings

3. Implement error handling in ViewModel
   - Catch and categorize errors
   - Expose error state to UI

4. Add error alerts
   - Show appropriate error view
   - Provide actionable solutions

**Acceptance Criteria**:
- Errors display user-friendly messages
- Permission errors link to Settings
- No unhandled errors

### Task 5.2: Handle Permission Errors
**Estimated Time**: 2 hours

#### Subtasks:
1. Check for Full Disk Access
   - Detect missing permissions
   - Show helpful error message

2. Add Settings button
   - Open System Preferences
   - Direct to correct pane

3. Test permission flows
   - Test with permissions granted
   - Test with permissions denied

**Acceptance Criteria**:
- Detects missing permissions
- Provides clear instructions
- Opens System Settings correctly

### Task 5.3: Handle Edge Cases
**Estimated Time**: 3 hours

#### Subtasks:
1. Handle empty scan results
   - Show appropriate message
   - Suggest different folder

2. Handle scan cancellation
   - Clean up properly
   - Show partial results

3. Handle partial deletion failures
   - Show which items failed
   - Show which succeeded
   - Provide details

4. Handle very large folders
   - Don't freeze UI
   - Show progress appropriately

**Acceptance Criteria**:
- All edge cases handled gracefully
- No crashes or freezes
- User always knows what happened

---

## Phase 6: Testing & Quality Assurance

### Task 6.1: Unit Testing
**Estimated Time**: 4 hours

#### Subtasks:
1. Write tests for all models
2. Write tests for all services
3. Write tests for ViewModels
4. Achieve >80% code coverage

**Acceptance Criteria**:
- All tests pass
- Coverage >80%

### Task 6.2: Integration Testing
**Estimated Time**: 3 hours

#### Subtasks:
1. Test complete scan flow
2. Test complete deletion flow
3. Test error scenarios
4. Test with real project structures

**Acceptance Criteria**:
- End-to-end flows work correctly
- Handles real-world scenarios

### Task 6.3: UI Testing
**Estimated Time**: 3 hours

#### Subtasks:
1. Write UI tests for main flows
2. Test accessibility
3. Test keyboard navigation
4. Test VoiceOver compatibility

**Acceptance Criteria**:
- UI tests pass
- Accessibility requirements met

### Task 6.4: Manual Testing
**Estimated Time**: 4 hours

#### Subtasks:
1. Test with various project types
2. Test with large directory trees
3. Test error conditions
4. Test on different macOS versions
5. Test on Intel and Apple Silicon

**Acceptance Criteria**:
- No critical bugs found
- Performance is acceptable
- Works on all target platforms

---

## Phase 7: Polish & Optimization

### Task 7.1: Performance Optimization
**Estimated Time**: 3 hours

#### Subtasks:
1. Profile app with Instruments
2. Optimize slow operations
3. Reduce memory usage
4. Improve UI responsiveness

**Acceptance Criteria**:
- Scans at least 1000 folders/second
- Memory usage <100MB
- UI maintains 60fps

### Task 7.2: UI Polish
**Estimated Time**: 3 hours

#### Subtasks:
1. Refine animations
2. Improve loading states
3. Polish transitions
4. Fix visual glitches

**Acceptance Criteria**:
- Animations are smooth
- No visual bugs
- Matches design spec

### Task 7.3: Add App Icon
**Estimated Time**: 2 hours

#### Subtasks:
1. Design app icon
   - Create in Sketch/Figma
   - Follow macOS guidelines
   - Create all required sizes

2. Add to project
   - Import to Assets.xcassets
   - Set in project settings

**Acceptance Criteria**:
- Icon displays correctly
- Follows macOS guidelines
- Looks professional

---

## Phase 8: Documentation & Deployment

### Task 8.1: Code Documentation
**Estimated Time**: 2 hours

#### Subtasks:
1. Add documentation comments to public APIs
2. Create README.md
3. Add usage examples
4. Document architecture

**Acceptance Criteria**:
- All public APIs documented
- README is comprehensive
- Easy for others to understand

### Task 8.2: User Documentation
**Estimated Time**: 2 hours

#### Subtasks:
1. Create user guide
2. Add screenshots
3. Create FAQ
4. Add troubleshooting section

**Acceptance Criteria**:
- User guide is clear
- Covers all features
- Addresses common issues

### Task 8.3: Prepare for Release
**Estimated Time**: 3 hours

#### Subtasks:
1. Set up code signing
2. Archive for distribution
3. Notarize with Apple
4. Create disk image (DMG)
5. Test installation

**Acceptance Criteria**:
- App is properly signed
- App is notarized
- DMG installs correctly
- No Gatekeeper warnings

### Task 8.4: Release
**Estimated Time**: 1 hour

#### Subtasks:
1. Create GitHub release
2. Upload DMG
3. Write release notes
4. Announce release

**Acceptance Criteria**:
- Release is live
- Download works
- Release notes are clear

---

## Summary of Estimates

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Phase 1: Project Setup | 2 | 3 hours |
| Phase 2: Service Layer | 4 | 15 hours |
| Phase 3: ViewModel Layer | 1 | 4 hours |
| Phase 4: UI Implementation | 9 | 28 hours |
| Phase 5: Error Handling | 3 | 8 hours |
| Phase 6: Testing & QA | 4 | 14 hours |
| Phase 7: Polish | 3 | 8 hours |
| Phase 8: Documentation | 4 | 8 hours |
| **TOTAL** | **30 tasks** | **88 hours** |

**Note**: These are estimates for an experienced iOS/macOS developer. Actual time may vary based on experience level and unforeseen complications.

## Task Dependencies

```
Phase 1 (Project Setup)
    ↓
Phase 2 (Service Layer)
    ↓
Phase 3 (ViewModel)
    ↓
Phase 4 (UI Implementation)
    ↓
Phase 5 (Error Handling) ← Can be parallel with Phase 4
    ↓
Phase 6 (Testing) ← Ongoing throughout
    ↓
Phase 7 (Polish)
    ↓
Phase 8 (Documentation & Release)
```

## Priority Breakdown

### Must Have (MVP)
- All of Phase 1-4
- Basic error handling (Phase 5)
- Unit tests (Phase 6.1)

### Should Have
- Complete Phase 5 (Error Handling)
- Complete Phase 6 (Testing)
- Basic polish (Phase 7)

### Nice to Have
- Advanced polish
- Comprehensive documentation
- Professional release process

## Risk Areas

**High Risk**:
- File system permissions (Task 5.2)
- Performance with large trees (Task 7.1)
- Project validation accuracy (Task 2.1)

**Medium Risk**:
- UI responsiveness during scan (Task 4.3)
- Deletion safety (Task 2.4)

**Low Risk**:
- UI implementation (Phase 4)
- Documentation (Phase 8)
