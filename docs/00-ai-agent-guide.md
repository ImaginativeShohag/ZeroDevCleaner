# AI Agent Implementation Guide

**Last Modified**: 2025-10-29

## Quick Start for AI Agents

This guide provides step-by-step instructions for AI agents to implement ZeroDevCleaner systematically.

### Prerequisites

- Xcode 16+ installed
- macOS 15.0+ development environment
- Swift 6 compiler available
- Git initialized in project root

### Project Structure

```
ZeroDevCleaner/
├── ZeroDevCleaner/
│   ├── App/
│   │   ├── ZeroDevCleanerApp.swift
│   │   └── Assets.xcassets/
│   ├── Models/
│   ├── Services/
│   ├── ViewModels/
│   ├── Views/
│   └── Utilities/
├── ZeroDevCleanerTests/
│   ├── ModelTests/
│   ├── ServiceTests/
│   ├── ViewModelTests/
│   └── Fixtures/
└── docs/
```

## Implementation Order

Follow this exact order to avoid dependency issues:

### Current Phase Tracking

Create a file at root: `.ai-progress.json`

```json
{
  "current_phase": 1,
  "current_task": "1.1",
  "completed_tasks": [],
  "started_at": "2025-10-29T00:00:00Z"
}
```

### Phase Sequence

1. **Phase 1: Foundation** → [07-phase-1-foundation.md](./07-phase-1-foundation.md)
   - Set up project structure
   - Create all data models
   - Estimated: 3-4 hours (9 atomic tasks)

2. **Phase 2: Core Services** → [08-phase-2-services.md](./08-phase-2-services.md)
   - Implement validation, scanning, and deletion services
   - Estimated: 15-20 hours (42 atomic tasks)

3. **Phase 3: ViewModel Layer** → [09-phase-3-viewmodel.md](./09-phase-3-viewmodel.md)
   - Create MainViewModel with @Observable
   - Estimated: 4-6 hours (12 atomic tasks)

4. **Phase 4: UI Implementation** → [10-phase-4-ui.md](./10-phase-4-ui.md)
   - Build all views and user interactions
   - Estimated: 20-28 hours (48 atomic tasks)

5. **Phase 5-9**: See [05-implementation-phases.md](./05-implementation-phases.md)

## Task Execution Protocol

### Before Starting Any Task

1. **Verify dependencies**: Check that all prerequisite tasks are completed
2. **Read task card**: Review atomic task definition
3. **Check file exists**: Verify target file location
4. **Review code scaffold**: Understand the implementation template

### During Task Execution

1. **Follow the steps exactly**: Each atomic task has 3-7 steps
2. **Use provided code snippets**: Don't deviate from architecture
3. **Maintain Swift 6 compliance**: Use @Observable, Task, async/await
4. **Update progress**: Mark task as in_progress

### After Completing Task

1. **Run verification command**: Execute the specified verification step
2. **Confirm output**: Match expected output
3. **Commit changes**: Use descriptive commit message
4. **Update .ai-progress.json**: Mark task complete
5. **Move to next task**: Check dependencies for next task

## Verification Commands

### Build Project
```bash
xcodebuild -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS' clean build
```

### Run Tests
```bash
xcodebuild test -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS'
```

### Run Specific Test
```bash
xcodebuild test -project ZeroDevCleaner.xcodeproj -scheme ZeroDevCleaner -destination 'platform=macOS' -only-testing:ZeroDevCleanerTests/ModelTests
```

### Check Swift 6 Compliance
```bash
swiftc -typecheck -swift-version 6 ZeroDevCleaner/Models/*.swift
```

## Common Patterns

### Creating a Model File

**Location**: `ZeroDevCleaner/Models/[ModelName].swift`

**Template**:
```swift
//
//  [ModelName].swift
//  ZeroDevCleaner
//
//  Created by AI Agent on [DATE].
//

import Foundation

// Model implementation here
```

### Creating a Service File

**Location**: `ZeroDevCleaner/Services/[ServiceName].swift`

**Template**:
```swift
//
//  [ServiceName].swift
//  ZeroDevCleaner
//
//  Created by AI Agent on [DATE].
//

import Foundation

// Protocol first
protocol [ServiceName]Protocol {
    // Interface
}

// Implementation
final class [ServiceName]: [ServiceName]Protocol {
    // Implementation
}
```

### Creating a ViewModel File

**Location**: `ZeroDevCleaner/Views/[ViewName]/[ViewName]ViewModel.swift`

**Template**:
```swift
//
//  [ViewName]ViewModel.swift
//  ZeroDevCleaner
//
//  Created by AI Agent on [DATE].
//

import SwiftUI

@Observable
@MainActor
final class [ViewName]ViewModel {
    // State properties (no @Published needed)

    // Dependencies

    // Initializer

    // Methods
}
```

### Creating a View File

**Location**: `ZeroDevCleaner/Views/[ViewName]/[ViewName].swift`

**Template**:
```swift
//
//  [ViewName].swift
//  ZeroDevCleaner
//
//  Created by AI Agent on [DATE].
//

import SwiftUI

struct [ViewName]: View {
    @State private var viewModel: [ViewName]ViewModel

    var body: some View {
        // View implementation
    }
}

#Preview {
    [ViewName](viewModel: [ViewName]ViewModel())
}
```

### Creating a Test File

**Location**: `ZeroDevCleanerTests/[Category]Tests/[Target]Tests.swift`

**Template**:
```swift
//
//  [Target]Tests.swift
//  ZeroDevCleanerTests
//
//  Created by AI Agent on [DATE].
//

import XCTest
@testable import ZeroDevCleaner

final class [Target]Tests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Setup
    }

    override func tearDown() {
        // Cleanup
        super.tearDown()
    }

    func test_[scenario]_[expectedBehavior]() {
        // Given

        // When

        // Then
    }
}
```

## Error Resolution

### Common Issues and Solutions

#### Issue: "Module not found"
**Solution**:
1. Check that Xcode project is properly created
2. Verify target membership of files
3. Clean build folder: `xcodebuild clean`

#### Issue: "Sendable warning"
**Solution**:
1. Add `@unchecked Sendable` only if truly thread-safe
2. Use `@MainActor` for UI-related classes
3. Prefer `actor` for services with mutable state

#### Issue: "Published property in @Observable"
**Solution**:
1. Remove `@Published` - not needed with `@Observable`
2. Use plain property declarations
3. SwiftUI automatically observes changes

#### Issue: Test fixtures not found
**Solution**:
1. Check `ZeroDevCleanerTests/Fixtures/` exists
2. Verify bundle resource inclusion
3. Use `Bundle.module` or `Bundle(for: type(of: self))`

## Commit Message Format

Use conventional commit format:

```
<type>(<scope>): <subject>

<body>

Task: <task-id>
```

**Types**: feat, fix, docs, test, refactor, style, chore

**Example**:
```
feat(models): add BuildFolder model with Identifiable conformance

- Add UUID-based identification
- Include path, size, and project type properties
- Add computed properties for formatted values
- Implement Hashable for Set operations

Task: 1.2.2
```

## Progress Tracking

Update `.ai-progress.json` after each completed task:

```json
{
  "current_phase": 1,
  "current_task": "1.2.2",
  "completed_tasks": ["1.1.1", "1.1.2", "1.2.1", "1.2.2"],
  "started_at": "2025-10-29T00:00:00Z",
  "last_updated": "2025-10-29T02:30:00Z"
}
```

## Testing Requirements

### Unit Test Coverage Targets
- Models: 100% coverage
- Services: >85% coverage
- ViewModels: >80% coverage
- Overall: >80% coverage

### Test Naming Convention
```
test_[methodName]_[scenario]_[expectedBehavior]
```

**Examples**:
- `test_validateAndroidProject_withValidGradleFile_returnsTrue`
- `test_calculateSize_withEmptyDirectory_returnsZero`
- `test_scanDirectory_whenCancelled_throwsCancelledError`

## File Organization

### Before Creating Any File

1. Verify parent directory exists
2. Check if file already exists
3. Confirm correct location per architecture

### Group Files Logically

- **Models**: All data structures together
- **Services**: Each service with its protocol
- **ViewModels**: Co-located with their views
- **Views**: Group by feature (MainView/, ScanResultsView/, etc.)
- **Tests**: Mirror main app structure

## Swift 6 Requirements

### Always Use

- `@Observable` instead of `ObservableObject`
- `@MainActor` for UI-related classes
- `Task` for async operations (no `DispatchQueue`)
- `async/await` for asynchronous code
- Structured concurrency patterns

### Never Use

- `@Published` with `@Observable`
- `ObservableObject` protocol
- `DispatchQueue` for concurrency
- `@StateObject` (use `@State` instead)
- Force unwrapping without justification

## Next Steps

1. Start with Phase 1: Read [07-phase-1-foundation.md](./07-phase-1-foundation.md)
2. Create `.ai-progress.json` at project root
3. Begin with Task 1.1.1
4. Follow the atomic task breakdown exactly
5. Verify after each task completion

## Support Files

- **Architecture**: [02-technical-architecture.md](./02-technical-architecture.md)
- **UI Design**: [03-ui-ux-design.md](./03-ui-ux-design.md)
- **Test Fixtures**: [11-test-fixtures.md](./11-test-fixtures.md)
- **Task Index**: [12-task-index.md](./12-task-index.md)

## Success Criteria

After completing all phases:

- ✅ All builds compile without warnings
- ✅ All tests pass (>80% coverage)
- ✅ App runs on macOS 15.0+
- ✅ No Swift 6 concurrency violations
- ✅ UI matches design specifications
- ✅ All features functional per requirements

---

**Ready to start?** → Proceed to [07-phase-1-foundation.md](./07-phase-1-foundation.md)
