# ZeroDevCleanerTests

## Setup Required

This test folder contains comprehensive unit tests for the ZeroDevCleaner project. However, the test target needs to be added to the Xcode project.

### To Add Test Target:

1. Open `ZeroDevCleaner.xcodeproj` in Xcode
2. Go to File → New → Target
3. Choose "Unit Testing Bundle" for macOS
4. Name it "ZeroDevCleanerTests"
5. Add the test files from this folder to the test target
6. Ensure the test target depends on the main app target

### Test Files Included:

- `ModelTests/ModelTests.swift` - Comprehensive tests for all model types (ProjectType, BuildFolder, ScanResult, ZeroDevCleanerError)

### Test Coverage:

The ModelTests file includes 15+ unit tests covering:
- ProjectType enum properties and encoding
- BuildFolder initialization, formatting, and Hashable conformance
- ScanResult calculations and computed properties
- ZeroDevCleanerError descriptions and recovery suggestions

All tests are ready to run once the test target is properly configured in Xcode.
