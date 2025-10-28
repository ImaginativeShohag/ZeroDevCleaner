# ZeroDevCleaner - Project Overview

## Project Name
**ZeroDevCleaner** - A macOS app to find and clean development build folders

## Purpose
A native macOS application that helps developers reclaim disk space by finding and safely removing build artifacts from Android and iOS projects.

## Target Platforms
- macOS 15.0+ (Sequoia and later)
- Apple Silicon support

## Core Functionality

### What the App Does
1. Allows users to select a root directory to scan
2. Recursively searches for Android and iOS project build folders
3. Validates that folders are part of actual development projects (not random folders)
4. Displays found folders with their paths, sizes, last modified date (human redable format like 5 days ago) and project type (Android or Xcode)
5. Allows users to select which folders to delete
6. Safely removes selected build folders

### What to Find and Delete

#### Android Projects
- **Target Folder**: `build/` folders
- **Validation Criteria**:
  - Must be inside a directory containing `build.gradle` or `build.gradle.kts`
  - OR inside a directory containing `settings.gradle` or `settings.gradle.kts`
  - OR inside a directory with an `app/` subfolder that contains `build.gradle`
  - The build folder should contain typical Android build artifacts (e.g., `intermediates/`, `outputs/`, `tmp/`)

#### iOS/Xcode Projects
- **Target Folder**: `.build/` folders (hidden folders with dot prefix)
- **Validation Criteria**:
  - Must be inside a directory containing a `.xcodeproj` file
  - OR inside a directory containing a `.xcworkspace` file
  - OR inside a directory containing `Package.swift` (Swift Package Manager)
  - The .build folder typically contains `debug/`, `release/`, or other build configurations

### Additional Considerations
- **DerivedData**: Consider also scanning for Xcode's DerivedData folders
- **Gradle Cache**: Consider Android's `.gradle` cache folders (optional)
- **Pods**: Consider CocoaPods `Pods/` folders (optional for future phases)

## Key Features

### Must Have (MVP)
1. Clean, modern macOS-native UI
2. Folder selection dialog
3. Recursive directory scanning with validation
4. Display results in a list with:
   - Project name/path
   - Folder type (Android/iOS)
   - Size of build folder
   - Last modified date (human redable format like 5 days ago)
5. Multi-select capability for deletion
6. Safe deletion with confirmation
7. Progress indicators during scanning and deletion
8. Dark mode support

### Nice to Have (Future Enhancements)
1. Save/load scan results
2. Schedule automatic scans
3. Exclude certain directories from scanning
4. Estimate time saved based on size
5. Statistics (total space cleaned, number of projects, etc.)
7. Export scan results

## Technology Stack

### Recommended Technologies
- **Language**: Swift 6 with strict concurrency checking
- **Framework**: SwiftUI for UI, Foundation for file operations
- **State Management**: @Observable macro (Swift 6)
- **Concurrency**: Structured concurrency with Task and async/await
- **Minimum Target**: macOS 15.0
- **Architecture**: MVVM (Model-View-ViewModel) with ViewModels co-located with view files

### Alternative Options
- **Language**: Swift (AppKit for traditional UI)
- **Cross-platform**: Could use Swift for macOS, but AppKit would give more control

## User Flow

```
1. Launch App
   ↓
2. Click "Select Folder" → Choose root directory
   ↓
3. Click "Start Scan" → App begins scanning
   ↓
4. View Results → List of found build folders with sizes
   ↓
5. Select Folders → Check which ones to remove
   ↓
6. Click "Remove Selected" → Confirmation dialog
   ↓
7. Confirm → Deletion process with progress
   ↓
8. View Summary → Show how much space was freed
```

## Success Criteria
- Accurately identifies Android and iOS project build folders
- Never deletes non-build folders or folders outside valid projects
- Provides clear feedback during all operations
- Handles errors gracefully (permission issues, disk full, etc.)
- Clean, intuitive UI that requires minimal learning
- Fast scanning even with large directory trees

## Risks and Mitigations

### Risks
1. **Accidental deletion of important files**
   - Mitigation: Strong validation logic, confirmation dialogs, move to trash instead of permanent deletion

2. **Performance issues with large directory trees**
   - Mitigation: Async scanning, progress indicators, ability to cancel operations

3. **Permission errors**
   - Mitigation: Clear error messages, request necessary permissions, handle denied access gracefully

4. **False positives (deleting wrong folders)**
   - Mitigation: Multiple validation checks, show full paths, clear labeling

## Out of Scope (Phase 1)
- Cloud storage integration
- Network drive scanning
- Automatic scheduled cleaning
- Command-line interface
- Support for other build systems (Flutter, React Native, etc.)
