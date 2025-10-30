# Contributing to ZeroDevCleaner

First off, thank you for considering contributing to ZeroDevCleaner! It's people like you that make this tool better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Screenshots** if applicable
- **System information**: macOS version, app version
- **Logs** if available (found in Console.app)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful**
- **List examples** of how it would be used

### Adding Support for New Project Types

Want to add support for a new build system? Great! Here's what you need:

1. **Add to ProjectType enum** in `Models/ProjectType.swift`
2. **Add validation logic** in `Services/ProjectValidator.swift`
3. **Add tests** for the new project type
4. **Update README.md** to document the new support

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Add tests** for your changes
5. **Ensure all tests pass** (`Cmd+U` in Xcode)
6. **Commit your changes** (see [Commit Guidelines](#commit-guidelines))
7. **Push to your branch** (`git push origin feature/amazing-feature`)
8. **Open a Pull Request**

## Development Setup

### Requirements

- macOS 15.0 (Sequoia) or later
- Xcode 16.0 or later
- Swift 6.0

### Getting Started

```bash
# Clone the repository
git clone https://github.com/ImaginativeShohag/ZeroDevCleaner.git
cd ZeroDevCleaner

# Open in Xcode
open ZeroDevCleaner.xcodeproj

# Build and run (Cmd+R)
# Run tests (Cmd+U)
```

### Project Structure

```
ZeroDevCleaner/
├── Models/              # Data models
├── Services/            # Business logic
├── Views/               # SwiftUI views
│   ├── Main/           # Main window
│   ├── Settings/       # Settings panel
│   ├── ScanResults/    # Results display
│   └── Dialogs/        # Confirmation dialogs
├── Utilities/          # Helper utilities
└── Tests/              # Unit and integration tests
```

## Coding Guidelines

### Swift Style

- **Swift 6.0** with strict concurrency enabled
- **SwiftUI** for all UI components
- **@Observable** macro for state management
- **Structured concurrency** with async/await
- **No third-party dependencies**

### Architecture Principles

1. **Component Reusability**
   - Never pass ViewModels to reusable components
   - Components should be pure SwiftUI views with bindings/closures
   - Keep business logic in ViewModels and Services

2. **Separation of Concerns**
   - Models: Data structures only
   - Services: Business logic (scanning, deletion, validation)
   - ViewModels: State management and orchestration
   - Views: Pure UI, no business logic

3. **Error Handling**
   - Use typed errors (`ZeroDevCleanerError`)
   - Provide user-friendly error messages
   - Log errors with OSLog for debugging

4. **Concurrency**
   - Use `@MainActor` for UI-related code
   - Mark protocols with `Sendable` where appropriate
   - Use structured concurrency (Tasks, async/await)

### Code Style

```swift
// ✅ Good: Clear naming, proper error handling
func scanDirectory(at url: URL) async throws -> [BuildFolder] {
    guard fileManager.fileExists(atPath: url.path) else {
        throw ZeroDevCleanerError.fileNotFound(url)
    }

    // Implementation
}

// ❌ Bad: Generic naming, no error handling
func scan(path: String) -> [Any]? {
    // Implementation
}
```

### Testing

- Write tests for new features
- Maintain test coverage above 80%
- Use descriptive test names: `test_scanDirectory_withValidPath_returnsResults()`
- Mock external dependencies

```swift
func test_scanDirectory_withValidPath_returnsResults() async throws {
    // Arrange
    let scanner = FileScanner()
    let testURL = URL(fileURLWithPath: "/path/to/test")

    // Act
    let results = try await scanner.scanDirectory(at: testURL)

    // Assert
    XCTAssertFalse(results.isEmpty)
}
```

## Commit Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
feat(scanner): add support for Flutter projects

Add ProjectType.flutter and validation logic for Flutter
build directories.

feat(ui): add dark mode support

fix(deletion): handle permission errors gracefully

Improve error messages when deletion fails due to permissions.
Properly log errors for debugging.

docs: update README with new project types
```

### Important Notes

- **Do not** add signatures like "Generated with Claude" or "AI Agent" in commits
- Use your own name and email in Git config
- Keep commits focused and atomic
- Write clear, descriptive commit messages

## Pull Request Process

### Before Submitting

1. ✅ All tests pass (`Cmd+U`)
2. ✅ Code builds without warnings
3. ✅ Code follows style guidelines
4. ✅ Documentation updated if needed
5. ✅ CLAUDE.md updated for significant changes

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How was this tested?

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Code follows project style
- [ ] All tests passing
```

### Review Process

1. Maintainers will review your PR
2. Address any requested changes
3. Once approved, your PR will be merged
4. Thank you for contributing! 🎉

## Questions?

- **Issues**: [GitHub Issues](https://github.com/ImaginativeShohag/ZeroDevCleaner/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ImaginativeShohag/ZeroDevCleaner/discussions)

## Recognition

Contributors will be recognized in:
- Git commit history
- Release notes
- Special thanks in README (for significant contributions)

---

Thank you for contributing to ZeroDevCleaner! 🚀
