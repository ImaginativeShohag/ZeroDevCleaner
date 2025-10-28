# Phase 4: UI Implementation - Atomic Task Breakdown (Overview)

**Estimated Total Time**: 20-28 hours
**Number of Atomic Tasks**: 48
**Dependencies**: Phase 3 complete

---

## Overview

Phase 4 builds the complete user interface. Due to the extensive nature of UI implementation, this document provides a high-level breakdown with key views.

**Key Views to Implement**:
1. **MainView** - Root container with toolbar and content area
2. **EmptyStateView** - Initial state before folder selection
3. **ScanProgressView** - Shows scanning progress
4. **ScanResultsView** - Table displaying found build folders
5. **BuildFolderRow** - Individual row in results table
6. **DeletionConfirmationView** - Confirmation dialog
7. **DeletionProgressView** - Deletion progress sheet
8. **CompletionView** - Success summary

---

## Quick Implementation Guide

### Step 1: Create MainView (Task 4.1)

**File**: `ZeroDevCleaner/Views/Main/MainView.swift`

```swift
//
//  MainView.swift
//  ZeroDevCleaner
//

import SwiftUI

struct MainView: View {
    @State private var viewModel = MainViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.scanResults.isEmpty && !viewModel.isScanning {
                EmptyStateView(onSelectFolder: viewModel.selectFolder)
            } else if viewModel.isScanning {
                ScanProgressView(
                    progress: viewModel.scanProgress,
                    currentPath: viewModel.currentScanPath,
                    onCancel: viewModel.cancelScan
                )
            } else {
                ScanResultsView(
                    results: viewModel.scanResults,
                    onToggleSelection: viewModel.toggleSelection,
                    onSelectAll: viewModel.selectAll,
                    onDeselectAll: viewModel.deselectAll,
                    onDelete: viewModel.deleteSelectedFolders,
                    selectedSize: viewModel.formattedSelectedSize
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            if let error = viewModel.currentError {
                Text(error.localizedDescription)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Select Folder") {
                    viewModel.selectFolder()
                }
            }

            if viewModel.selectedFolder != nil {
                ToolbarItem(placement: .automatic) {
                    Button("Scan") {
                        viewModel.startScan()
                    }
                    .disabled(viewModel.isScanning)
                }
            }
        }
    }
}

#Preview {
    MainView()
}
```

**Commit**: `feat(ui): create MainView with state management`

---

### Step 2: Create EmptyStateView (Task 4.2)

**File**: `ZeroDevCleaner/Views/EmptyState/EmptyStateView.swift`

```swift
//
//  EmptyStateView.swift
//  ZeroDevCleaner
//

import SwiftUI

struct EmptyStateView: View {
    let onSelectFolder: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Folder Selected")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Select a folder to scan for build artifacts")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Button(action: onSelectFolder) {
                Label("Select Folder", systemImage: "folder")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(onSelectFolder: {})
}
```

**Commit**: `feat(ui): create EmptyStateView`

---

### Step 3: Create ScanProgressView (Task 4.3)

**File**: `ZeroDevCleaner/Views/ScanProgress/ScanProgressView.swift`

```swift
//
//  ScanProgressView.swift
//  ZeroDevCleaner
//

import SwiftUI

struct ScanProgressView: View {
    let progress: Double
    let currentPath: String
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            ProgressView(value: progress, total: 1.0) {
                Text("Scanning...")
                    .font(.headline)
            } currentValueLabel: {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .progressViewStyle(.linear)
            .frame(maxWidth: 400)

            VStack(spacing: 8) {
                Text("Current Path:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(currentPath)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }

            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ScanProgressView(
        progress: 0.45,
        currentPath: "/Users/test/Projects/MyApp/build",
        onCancel: {}
    )
}
```

**Commit**: `feat(ui): create ScanProgressView with progress indicator`

---

### Step 4: Create ScanResultsView (Task 4.4)

**File**: `ZeroDevCleaner/Views/ScanResults/ScanResultsView.swift`

```swift
//
//  ScanResultsView.swift
//  ZeroDevCleaner
//

import SwiftUI

struct ScanResultsView: View {
    let results: [BuildFolder]
    let onToggleSelection: (BuildFolder) -> Void
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    let onDelete: () -> Void
    let selectedSize: String

    var body: some View {
        VStack(spacing: 0) {
            // Summary Card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(results.count) build folders found")
                        .font(.headline)
                    Text("Selected: \(selectedCount) (\(selectedSize))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button("Select All", action: onSelectAll)
                        .buttonStyle(.bordered)

                    Button("Deselect All", action: onDeselectAll)
                        .buttonStyle(.bordered)

                    Button("Remove Selected", action: onDelete)
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedCount == 0)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Results Table
            Table(results) {
                TableColumn("") { folder in
                    Toggle("", isOn: Binding(
                        get: { folder.isSelected },
                        set: { _ in onToggleSelection(folder) }
                    ))
                    .toggleStyle(.checkbox)
                }
                .width(40)

                TableColumn("Project", value: \.projectName)

                TableColumn("Type") { folder in
                    Label(folder.projectType.displayName, systemImage: folder.projectType.iconName)
                }

                TableColumn("Size", value: \.formattedSize)

                TableColumn("Last Modified", value: \.formattedLastModified)

                TableColumn("Path") { folder in
                    Text(folder.path.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(folder.path.path)
                }
            }
        }
    }

    private var selectedCount: Int {
        results.filter(\.isSelected).count
    }
}

#Preview {
    ScanResultsView(
        results: [
            BuildFolder(
                path: URL(fileURLWithPath: "/test/build"),
                projectType: .android,
                size: 1024 * 1024 * 100,
                projectName: "TestApp",
                lastModified: Date(),
                isSelected: true
            )
        ],
        onToggleSelection: { _ in },
        onSelectAll: {},
        onDeselectAll: {},
        onDelete: {},
        selectedSize: "100 MB"
    )
}
```

**Commit**: `feat(ui): create ScanResultsView with table`

---

### Step 5: Update ZeroDevCleanerApp.swift (Task 4.5)

**File**: `ZeroDevCleaner/App/ZeroDevCleanerApp.swift`

Replace PlaceholderView with MainView:

```swift
//
//  ZeroDevCleanerApp.swift
//  ZeroDevCleaner
//

import SwiftUI

@main
struct ZeroDevCleanerApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
```

**Commit**: `feat(app): integrate MainView as root view`

---

## Complete Task List for Phase 4

### Sprint 4.1: Core UI Structure (6 hours)
- [ ] 4.1.1: Create MainView structure (45 min)
- [ ] 4.1.2: Add toolbar to MainView (30 min)
- [ ] 4.1.3: Add state management bindings (30 min)
- [ ] 4.1.4: Implement view switching logic (30 min)
- [ ] 4.1.5: Add error alert (15 min)

### Sprint 4.2: Empty State (2 hours)
- [ ] 4.2.1: Create EmptyStateView (30 min)
- [ ] 4.2.2: Add drag & drop support (45 min)
- [ ] 4.2.3: Style and polish (30 min)

### Sprint 4.3: Progress Views (3 hours)
- [ ] 4.3.1: Create ScanProgressView (45 min)
- [ ] 4.3.2: Create DeletionProgressView (45 min)
- [ ] 4.3.3: Add animations (30 min)
- [ ] 4.3.4: Test progress updates (45 min)

### Sprint 4.4: Results Table (5 hours)
- [ ] 4.4.1: Create ScanResultsView (1 hour)
- [ ] 4.4.2: Implement Table columns (1 hour)
- [ ] 4.4.3: Add sorting capability (45 min)
- [ ] 4.4.4: Add selection UI (45 min)
- [ ] 4.4.5: Add summary card (30 min)
- [ ] 4.4.6: Polish table styling (45 min)

### Sprint 4.5: Dialogs & Sheets (4 hours)
- [ ] 4.5.1: Create confirmation dialog (1 hour)
- [ ] 4.5.2: Create completion view (1 hour)
- [ ] 4.5.3: Wire up all dialogs (1 hour)
- [ ] 4.5.4: Test dialog flows (1 hour)

### Sprint 4.6: Enhancements (8 hours)
- [ ] 4.6.1: Add "Show in Finder" (1.5 hours)
- [ ] 4.6.2: Implement drag & drop (2 hours)
- [ ] 4.6.3: Add keyboard shortcuts (1.5 hours)
- [ ] 4.6.4: Implement filters (2 hours)
- [ ] 4.6.5: Add recent folders (1 hour)

### Sprint 4.7: Final Polish (2 hours)
- [ ] 4.7.1: Apply design system colors (30 min)
- [ ] 4.7.2: Add SF Symbol icons (30 min)
- [ ] 4.7.3: Test dark mode (30 min)
- [ ] 4.7.4: Fix visual bugs (30 min)

---

## Verification Checklist

After completing Phase 4:

- [ ] App builds without errors
- [ ] All views render correctly
- [ ] Can select folder and scan
- [ ] Results display in table
- [ ] Can select and delete folders
- [ ] Progress indicators work
- [ ] Error dialogs show correctly
- [ ] Dark mode works
- [ ] Keyboard shortcuts work
- [ ] All enhancements functional

**Verify**:
```bash
xcodebuild clean build -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner
# Run app and test manually
```

---

## Phase 4 Commit Summary

**Final Commit**:
```
chore(phase4): complete Enhanced MVP UI implementation

Phase 4 Summary:
- ✅ MainView with state-driven UI
- ✅ EmptyStateView with folder selection
- ✅ Progress views for scan and deletion
- ✅ Results table with sorting and selection
- ✅ Confirmation and completion dialogs
- ✅ MVP enhancements (Show in Finder, drag & drop, shortcuts, filters)
- ✅ Dark mode support
- ✅ Polished design matching specs

Stats:
- 8 view files created
- 48 tasks completed
- Enhanced MVP functional
- Time: ~28 hours

Task: 4.7.4
```

**Update .ai-progress.json**:
```json
{
  "current_phase": 5,
  "current_task": "5.1.1",
  "completed_tasks": ["1.1.1", "...", "4.7.4"],
  "phase_4_completed_at": "2025-10-29T18:00:00Z",
  "mvp_status": "enhanced_mvp_complete"
}
```

---

## Enhanced MVP Complete! 🎉

At this point, you have a fully functional Enhanced MVP that can:
- ✅ Scan directories for build folders
- ✅ Display results in a sortable table
- ✅ Filter by project type
- ✅ Select and delete folders
- ✅ Show progress for all operations
- ✅ Handle errors gracefully
- ✅ Support keyboard shortcuts
- ✅ Show in Finder
- ✅ Drag & drop folders

**Next Steps**: Phases 5-9 for production polish, comprehensive testing, and release preparation.

**Decision Point**: Test the Enhanced MVP with real projects and gather feedback before continuing to Phase 5.
