# ZeroDevCleaner - Technical Architecture

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────┐
│           Presentation Layer                │
│         (SwiftUI Views)                     │
│  - MainView                                 │
│  - ScanResultsView                          │
│  - SettingsView                             │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│           ViewModel Layer                   │
│         (Business Logic)                    │
│  - MainViewModel                            │
│  - ScanViewModel                            │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│            Service Layer                    │
│  - FileScanner                              │
│  - ProjectValidator                         │
│  - FileSizeCalculator                       │
│  - FileDeleter                              │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│            Data Layer                       │
│         (Models & Storage)                  │
│  - BuildFolder                              │
│  - ScanResult                               │
│  - ProjectType                              │
└─────────────────────────────────────────────┘
```

## Component Breakdown

### 1. Presentation Layer (SwiftUI)

#### MainView
- Root view of the application
- Contains folder selection UI
- Shows scan button and progress indicators
- Displays scan results

#### ScanResultsView
- Table/List view showing found build folders
- Columns: Checkbox, Project Path, Type, Size, Last Modified
- Sort and filter capabilities
- Delete button and selection controls

#### ProgressView
- Shows scanning progress
- Displays current directory being scanned
- Cancellation support

#### ConfirmationDialog
- Shows before deletion
- Lists items to be deleted with total size
- Confirm/Cancel actions

### 2. ViewModel Layer

**Note**: ViewModels are co-located with their corresponding screen view files for better organization and maintainability.

#### MainViewModel
```swift
@Observable
@MainActor
class MainViewModel {
    var selectedFolder: URL?
    var scanResults: [BuildFolder] = []
    var isScanning: Bool = false
    var scanProgress: Double = 0.0
    var errorMessage: String?

    // Services
    private let scanner: FileScannerProtocol
    private let validator: ProjectValidatorProtocol
    private let deleter: FileDeleterProtocol

    // Methods
    func selectFolder()
    func startScan() async
    func cancelScan()
    func deleteSelectedFolders([BuildFolder]) async
}
```

### 3. Service Layer

#### FileScannerProtocol
```swift
protocol FileScannerProtocol {
    func scanDirectory(
        at url: URL,
        progressHandler: (Double, String) -> Void
    ) async throws -> [BuildFolder]
}
```

**Implementation**: FileScanner
- Recursively traverses directory tree
- Identifies potential build folders
- Uses ProjectValidator to confirm validity
- Calculates folder sizes
- Reports progress during scan
- Supports cancellation

#### ProjectValidatorProtocol
```swift
protocol ProjectValidatorProtocol {
    func validateAndroidProject(at url: URL) -> Bool
    func validateiOSProject(at url: URL) -> Bool
    func validateBuildFolder(at url: URL, type: ProjectType) -> Bool
}
```

**Implementation**: ProjectValidator
- **Android Validation**:
  - Check for `build.gradle` or `build.gradle.kts` in parent directories
  - Check for `settings.gradle` or `settings.gradle.kts`
  - Verify typical Android build structure

- **iOS Validation**:
  - Check for `.xcodeproj` in parent directories
  - Check for `.xcworkspace`
  - Check for `Package.swift` (Swift Package Manager)
  - Verify typical Xcode build structure

#### FileSizeCalculatorProtocol
```swift
protocol FileSizeCalculatorProtocol {
    func calculateSize(of url: URL) async throws -> Int64
}
```

**Implementation**: FileSizeCalculator
- Recursively calculates total size of directory
- Returns size in bytes
- Handles errors gracefully (permission denied, etc.)

#### FileDeleterProtocol
```swift
protocol FileDeleterProtocol {
    func delete(
        folders: [BuildFolder],
        progressHandler: (Double, String) -> Void
    ) async throws
}
```

**Implementation**: FileDeleter
- Moves items to Trash (safer than permanent deletion)
- Reports progress during deletion
- Handles permission errors
- Atomic operations where possible

### 4. Data Models

#### BuildFolder
```swift
struct BuildFolder: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let projectType: ProjectType
    let size: Int64
    let projectName: String
    var isSelected: Bool

    var formattedSize: String // e.g., "125.5 MB"
    var relativePath: String // Path relative to scan root
}
```

#### ProjectType
```swift
enum ProjectType: String, Codable {
    case android
    case iOS
    case swiftPackage

    var displayName: String
    var icon: String // SF Symbol name
}
```

#### ScanResult
```swift
struct ScanResult {
    let rootPath: URL
    let scanDate: Date
    let buildFolders: [BuildFolder]
    let totalSize: Int64
    let scanDuration: TimeInterval
}
```

## Data Flow

### Scanning Flow
```
1. User selects folder → MainView
2. MainView calls MainViewModel.selectFolder()
3. User clicks "Start" → MainView
4. MainView calls MainViewModel.startScan()
5. MainViewModel calls FileScanner.scanDirectory()
6. FileScanner:
   - Traverses directory tree
   - For each potential build folder:
     - Calls ProjectValidator.validate()
     - If valid, calls FileSizeCalculator.calculateSize()
     - Creates BuildFolder model
   - Reports progress via callback
7. MainViewModel updates @Published properties
8. SwiftUI re-renders views with results
```

### Deletion Flow
```
1. User selects folders → ScanResultsView updates selection
2. User clicks "Remove Selected" → Shows confirmation dialog
3. User confirms → MainView
4. MainView calls MainViewModel.deleteSelectedFolders()
5. MainViewModel calls FileDeleter.delete()
6. FileDeleter:
   - Moves each folder to Trash
   - Reports progress via callback
7. MainViewModel updates @Published properties
8. SwiftUI removes deleted items from view
9. Shows completion summary
```

## File System Operations

### Directory Traversal Strategy
- Use `FileManager.default.enumerator(at:includingPropertiesForKeys:options:)`
- Include properties: `.isDirectoryKey`, `.totalFileSizeKey`
- Options: `.skipsHiddenFiles` (except for .build folders)
- Implement depth limit to prevent infinite loops (e.g., max 10 levels deep)

### Permission Handling
- Request Full Disk Access on first run if needed
- Handle permission errors gracefully
- Skip inaccessible directories with warning
- Use `FileManager` authorization methods

### Performance Optimizations
- Async/await with Swift 6 concurrency for all file operations
- Batch updates to UI (don't update per file)
- Use structured concurrency with `Task` and `TaskGroup` for concurrent operations
- Cancel ongoing operations with task cancellation
- Cache validation results for parent directories
- Use `@MainActor` isolation for UI updates

## Error Handling

### Error Types
```swift
enum ZeroDevCleanerError: LocalizedError {
    case permissionDenied(URL)
    case fileNotFound(URL)
    case deletionFailed(URL, Error)
    case scanCancelled
    case unknownError(Error)

    var errorDescription: String? {
        // User-friendly error messages
    }
}
```

### Error Handling Strategy
- All service methods throw specific errors
- ViewModels catch and convert to user-friendly messages
- Display errors in UI with actionable suggestions
- Log errors for debugging (with user permission)

## Testing Strategy

### Unit Tests
- Test ProjectValidator with various directory structures
- Test FileSizeCalculator with known directory sizes
- Test ViewModel state transitions
- Mock file system operations

### Integration Tests
- Test full scan flow with sample project structures
- Test deletion flow with temporary directories
- Test error scenarios (permissions, missing files)

### UI Tests
- Test user flows from folder selection to deletion
- Test cancellation scenarios
- Test error display and recovery

## Security Considerations

### File Access
- Never request more permissions than needed
- Always validate paths before operations
- Use sandboxing appropriately
- Handle symlinks safely (avoid following outside scan root)

### Data Privacy
- Don't collect or transmit user data
- Don't store scan history without permission
- Clear sensitive information from memory

## Performance Targets

### Scanning Performance
- Should handle 100GB+ directory trees
- Should scan ~1000 folders per second (modern SSD)
- UI should remain responsive during scan
- Progress updates at least every 100ms

### Memory Usage
- Keep memory usage under 100MB for typical scans
- Don't load entire directory tree into memory
- Stream results as they're found

### Deletion Performance
- Should delete folders as fast as Finder
- Progress updates for large deletions
- Don't block UI thread

## Technology Choices

### Language & Framework
- **Swift 6**: Modern, safe, performant with strict concurrency checking
- **SwiftUI**: Declarative, native macOS UI
- **@Observable macro**: Modern observable state management (replaces ObservableObject)
- **Structured concurrency**: Task-based async/await pattern
- **Swift 6 concurrency model**: Actor isolation and data-race safety

### Third-Party Dependencies
- **None recommended for MVP**: Use Foundation and FileManager
- Consider for future: Charts library for statistics visualization

### Build Tools
- Xcode 16+
- Swift Package Manager for any future dependencies
- XCTest for testing

## Deployment

### Distribution
- **Phase 1**: Direct .app download
- **Phase 2**: Consider Mac App Store

### Signing & Notarization
- Code sign with Developer ID
- Notarize for Gatekeeper
- Include proper entitlements

### Updates
- **Phase 1**: Manual updates
- **Phase 2**: Consider Sparkle framework for auto-updates
