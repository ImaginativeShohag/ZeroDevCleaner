# Task Index - Complete Implementation Roadmap

**Last Modified**: 2025-10-29
**Total Estimated Time**: 88-108 hours
**Total Tasks**: ~120 atomic tasks

---

## How to Use This Index

1. **Follow the order exactly** - Tasks have dependencies
2. **Check off tasks** as you complete them
3. **Update `.ai-progress.json`** after each task
4. **Commit after each task** - Use provided commit messages
5. **Verify before proceeding** - Run verification commands

---

## Phase 1: Foundation (3-4 hours)

**Goal**: Set up project and create data models
**Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Complete

### 1.1 Project Initialization (1 hour)
- [ ] 1.1.1 - Create Xcode Project (15 min) → [07-phase-1-foundation.md](./07-phase-1-foundation.md#task-111-create-xcode-project)
- [ ] 1.1.2 - Configure Project Settings (10 min) → Swift 6, macOS 15.0
- [ ] 1.1.3 - Create Folder Structure (10 min) → App, Models, Services, Views, etc.
- [ ] 1.1.4 - Initialize Git Repository (5 min) → .gitignore

### 1.2 Create Data Models (2 hours)
- [ ] 1.2.1 - Create ProjectType Enum (20 min) → android, iOS, swiftPackage
- [ ] 1.2.2 - Create BuildFolder Model (30 min) → Identifiable, Hashable, Codable
- [ ] 1.2.3 - Create ScanResult Model (20 min) → Aggregation model
- [ ] 1.2.4 - Create Error Type (20 min) → LocalizedError
- [ ] 1.2.5 - Create Model Unit Tests (30 min) → 100% coverage

### 1.3 Update App Entry Point (30 min)
- [ ] 1.3.1 - Update ZeroDevCleanerApp.swift (15 min) → Placeholder view
- [ ] 1.3.2 - Final Phase 1 Verification (15 min) → All tests pass

**Phase 1 Deliverables**:
- ✅ Xcode project configured for Swift 6
- ✅ All models implemented
- ✅ Unit tests passing
- ✅ App builds and runs

---

## Phase 2: Core Services (15-20 hours)

**Goal**: Implement validation, scanning, calculation, and deletion services
**Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Complete

### 2.1 ProjectValidator Service (4 hours)
- [ ] 2.1.1 - Create ProjectValidatorProtocol (15 min)
- [ ] 2.1.2 - Create ProjectValidator Implementation (30 min)
- [ ] 2.1.3 - Implement Android Validation (25 min)
- [ ] 2.1.4 - Implement iOS Validation (25 min)
- [ ] 2.1.5 - Create ProjectValidator Tests (45 min)

### 2.2 FileSizeCalculator Service (2 hours)
- [ ] 2.2.1 - Create FileSizeCalculatorProtocol (10 min)
- [ ] 2.2.2 - Implement FileSizeCalculator (45 min)
- [ ] 2.2.3 - Add Size Formatting Extensions (30 min)
- [ ] 2.2.4 - Create Calculator Tests (35 min)

### 2.3 FileScanner Service (6 hours)
- [ ] 2.3.1 - Create FileScannerProtocol (15 min)
- [ ] 2.3.2 - Implement FileScanner Core (1 hour)
- [ ] 2.3.3 - Add Progress Reporting (45 min)
- [ ] 2.3.4 - Implement Cancellation Support (30 min)
- [ ] 2.3.5 - Add Depth Limit Logic (30 min)
- [ ] 2.3.6 - Handle Edge Cases (1 hour)
- [ ] 2.3.7 - Create Scanner Tests (1.5 hours)

### 2.4 FileDeleter Service (3 hours)
- [ ] 2.4.1 - Create FileDeleterProtocol (10 min)
- [ ] 2.4.2 - Implement FileDeleter (45 min)
- [ ] 2.4.3 - Add Safety Checks (30 min)
- [ ] 2.4.4 - Handle Batch Deletion (30 min)
- [ ] 2.4.5 - Create Deleter Tests (45 min)

### 2.5 Integration Testing (1 hour)
- [ ] 2.5.1 - Create Integration Tests (1 hour)

### 2.6 Final Phase 2 Verification (30 min)
- [ ] 2.6.1 - Run All Service Tests (30 min)

**Phase 2 Deliverables**:
- ✅ All 4 services implemented
- ✅ All services have protocols
- ✅ Comprehensive unit tests
- ✅ Integration tests passing

---

## Phase 3: ViewModel Layer (4-6 hours)

**Goal**: Create MainViewModel with @Observable
**Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Complete

### 3.1 Create MainViewModel Foundation (2 hours)
- [ ] 3.1.1 - Create MainViewModel File Structure (20 min) → [09-phase-3-viewmodel.md](./09-phase-3-viewmodel.md#task-311)
- [ ] 3.1.2 - Implement Folder Selection (20 min)
- [ ] 3.1.3 - Implement Start Scan Method (45 min)
- [ ] 3.1.4 - Implement Selection Management (20 min)
- [ ] 3.1.5 - Implement Deletion Method (45 min)
- [ ] 3.1.6 - Implement Error Handling (15 min)

### 3.2 Create ViewModel Tests (2 hours)
- [ ] 3.2.1 - Create Mock Services (45 min)
- [ ] 3.2.2 - Create MainViewModel Tests (1 hour)

### 3.3 Final Phase 3 Verification (30 min)
- [ ] 3.3.1 - Verify All Tests Pass (15 min)
- [ ] 3.3.2 - Update Progress File (15 min)

**Phase 3 Deliverables**:
- ✅ MainViewModel with @Observable
- ✅ All business logic implemented
- ✅ Mock services created
- ✅ ViewModel tests >80% coverage

---

## Phase 4: UI Implementation (20-28 hours)

**Goal**: Build complete user interface
**Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Complete

### 4.1 Core UI Structure (6 hours)
- [ ] 4.1.1 - Create MainView Structure (45 min) → [10-phase-4-ui.md](./10-phase-4-ui.md#step-1-create-mainview-task-41)
- [ ] 4.1.2 - Add Toolbar to MainView (30 min)
- [ ] 4.1.3 - Add State Management Bindings (30 min)
- [ ] 4.1.4 - Implement View Switching Logic (30 min)
- [ ] 4.1.5 - Add Error Alert (15 min)

### 4.2 Empty State (2 hours)
- [ ] 4.2.1 - Create EmptyStateView (30 min)
- [ ] 4.2.2 - Add Drag & Drop Support (45 min)
- [ ] 4.2.3 - Style and Polish (30 min)

### 4.3 Progress Views (3 hours)
- [ ] 4.3.1 - Create ScanProgressView (45 min)
- [ ] 4.3.2 - Create DeletionProgressView (45 min)
- [ ] 4.3.3 - Add Animations (30 min)
- [ ] 4.3.4 - Test Progress Updates (45 min)

### 4.4 Results Table (5 hours)
- [ ] 4.4.1 - Create ScanResultsView (1 hour)
- [ ] 4.4.2 - Implement Table Columns (1 hour)
- [ ] 4.4.3 - Add Sorting Capability (45 min)
- [ ] 4.4.4 - Add Selection UI (45 min)
- [ ] 4.4.5 - Add Summary Card (30 min)
- [ ] 4.4.6 - Polish Table Styling (45 min)

### 4.5 Dialogs & Sheets (4 hours)
- [ ] 4.5.1 - Create Confirmation Dialog (1 hour)
- [ ] 4.5.2 - Create Completion View (1 hour)
- [ ] 4.5.3 - Wire Up All Dialogs (1 hour)
- [ ] 4.5.4 - Test Dialog Flows (1 hour)

### 4.6 MVP Enhancements (8 hours)
- [ ] 4.6.1 - Add "Show in Finder" (1.5 hours)
- [ ] 4.6.2 - Implement Drag & Drop (2 hours)
- [ ] 4.6.3 - Add Keyboard Shortcuts (1.5 hours)
- [ ] 4.6.4 - Implement Filters (2 hours)
- [ ] 4.6.5 - Add Recent Folders (1 hour)

### 4.7 Final Polish (2 hours)
- [ ] 4.7.1 - Apply Design System Colors (30 min)
- [ ] 4.7.2 - Add SF Symbol Icons (30 min)
- [ ] 4.7.3 - Test Dark Mode (30 min)
- [ ] 4.7.4 - Fix Visual Bugs (30 min)

**Phase 4 Deliverables**:
- ✅ Complete functional UI
- ✅ All views implemented
- ✅ MVP enhancements working
- ✅ Enhanced MVP ready for testing

**🎉 ENHANCED MVP COMPLETE - Decision Point**

---

## Phase 5: Error Handling & Edge Cases (6-8 hours)

**Goal**: Make app robust and production-ready
**Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Complete
**Dependencies**: Phase 4
**Reference**: [05-implementation-phases.md](./05-implementation-phases.md#phase-6-error-handling--edge-cases-week-4)

### 5.1 Error UI (3 hours)
- [ ] 5.1.1 - Create Generic ErrorView
- [ ] 5.1.2 - Create PermissionErrorView
- [ ] 5.1.3 - Implement Error Alerts
- [ ] 5.1.4 - Add Helpful Error Messages

### 5.2 Permission Handling (2 hours)
- [ ] 5.2.1 - Check for Full Disk Access
- [ ] 5.2.2 - Show Permission Request Dialog
- [ ] 5.2.3 - Link to System Settings
- [ ] 5.2.4 - Handle Denied Permissions

### 5.3 Edge Cases (3 hours)
- [ ] 5.3.1 - Handle Empty Scan Results
- [ ] 5.3.2 - Handle Scan Cancellation
- [ ] 5.3.3 - Handle Partial Deletion Failures
- [ ] 5.3.4 - Handle Very Large Folders
- [ ] 5.3.5 - Handle Special Characters in Paths
- [ ] 5.3.6 - Handle Symlinks Safely

**Phase 5 Deliverables**:
- ✅ Comprehensive error handling
- ✅ Permission handling working
- ✅ No unhandled crashes

---

## Phase 6: Testing & QA (12-16 hours)

**Goal**: Ensure stability and reliability
**Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Complete
**Dependencies**: Phase 5
**Reference**: [05-implementation-phases.md](./05-implementation-phases.md#phase-7-testing--quality-assurance-week-4-5)

### 6.1 Unit Testing (4 hours)
- [ ] 6.1.1 - Complete Service Tests
- [ ] 6.1.2 - Complete ViewModel Tests
- [ ] 6.1.3 - Achieve >80% Code Coverage
- [ ] 6.1.4 - Fix Bugs Found in Testing

### 6.2 Integration Testing (3 hours)
- [ ] 6.2.1 - Test Complete Scan Flow
- [ ] 6.2.2 - Test Complete Deletion Flow
- [ ] 6.2.3 - Test Error Scenarios
- [ ] 6.2.4 - Test with Real Project Structures

### 6.3 UI Testing (3 hours)
- [ ] 6.3.1 - Write UI Tests for Main Flows
- [ ] 6.3.2 - Test Accessibility Features
- [ ] 6.3.3 - Test Keyboard Navigation
- [ ] 6.3.4 - Test VoiceOver Support

### 6.4 Manual Testing (4 hours)
- [ ] 6.4.1 - Test on Different macOS Versions
- [ ] 6.4.2 - Test on Intel Macs
- [ ] 6.4.3 - Test on Apple Silicon Macs
- [ ] 6.4.4 - Test with Various Project Types
- [ ] 6.4.5 - Test with Large Directory Trees
- [ ] 6.4.6 - Fix All Critical Bugs

**Phase 6 Deliverables**:
- ✅ All tests passing
- ✅ >80% code coverage
- ✅ No critical bugs

---

## Phase 7: Performance & Polish (6-8 hours)

**Goal**: Optimize and add final polish
**Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Complete
**Dependencies**: Phase 6
**Reference**: [05-implementation-phases.md](./05-implementation-phases.md#phase-8-performance--polish-week-5)

### 7.1 Performance Optimization (3 hours)
- [ ] 7.1.1 - Profile with Instruments
- [ ] 7.1.2 - Optimize Slow Operations
- [ ] 7.1.3 - Reduce Memory Usage
- [ ] 7.1.4 - Improve UI Responsiveness

### 7.2 Final UI Polish (3 hours)
- [ ] 7.2.1 - Refine All Animations
- [ ] 7.2.2 - Fix Visual Glitches
- [ ] 7.2.3 - Perfect Spacing and Alignment
- [ ] 7.2.4 - Ensure Dark Mode Works Well

### 7.3 App Icon & Branding (2 hours)
- [ ] 7.3.1 - Design App Icon
- [ ] 7.3.2 - Create All Icon Sizes
- [ ] 7.3.3 - Add to Project
- [ ] 7.3.4 - Verify Icon Displays

**Phase 7 Deliverables**:
- ✅ Scans >1000 folders/second
- ✅ Memory usage <100MB
- ✅ Professional appearance
- ✅ App icon complete

---

## Phase 8: Documentation (6-8 hours)

**Goal**: Prepare documentation for release
**Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Complete
**Dependencies**: Phase 7
**Reference**: [05-implementation-phases.md](./05-implementation-phases.md#phase-9-documentation--release-prep-week-5-6)

### 8.1 Code Documentation (2 hours)
- [ ] 8.1.1 - Add Doc Comments to Public APIs
- [ ] 8.1.2 - Create README.md
- [ ] 8.1.3 - Document Architecture
- [ ] 8.1.4 - Add Usage Examples

### 8.2 User Documentation (2 hours)
- [ ] 8.2.1 - Create User Guide
- [ ] 8.2.2 - Add Screenshots
- [ ] 8.2.3 - Create FAQ Section
- [ ] 8.2.4 - Add Troubleshooting Guide

### 8.3 Release Preparation (3 hours)
- [ ] 8.3.1 - Set Up Code Signing
- [ ] 8.3.2 - Archive for Distribution
- [ ] 8.3.3 - Notarize with Apple
- [ ] 8.3.4 - Create DMG Installer
- [ ] 8.3.5 - Test Installation

### 8.4 Release (1 hour)
- [ ] 8.4.1 - Create GitHub Release
- [ ] 8.4.2 - Upload DMG
- [ ] 8.4.3 - Write Release Notes
- [ ] 8.4.4 - Announce Release

**Phase 8 Deliverables**:
- ✅ Complete documentation
- ✅ Signed and notarized app
- ✅ DMG installer ready
- ✅ Public release

---

## Quick Reference: Critical Path

**Minimum Viable Path** (Enhanced MVP):
```
Phase 1 → Phase 2 → Phase 3 → Phase 4
(3-4h)    (15-20h)   (4-6h)     (20-28h)
Total: ~58 hours
```

**Full Production Path**:
```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase 8
Total: ~88-108 hours
```

---

## Progress Tracking Template

Update `.ai-progress.json` after each task:

```json
{
  "current_phase": 1,
  "current_task": "1.1.1",
  "completed_tasks": [],
  "started_at": "2025-10-29T00:00:00Z",
  "last_updated": "2025-10-29T00:00:00Z",
  "phase_1_completed_at": null,
  "phase_2_completed_at": null,
  "phase_3_completed_at": null,
  "phase_4_completed_at": null,
  "mvp_status": "not_started"
}
```

---

## Success Metrics by Phase

### Phase 1 Complete
- ✅ Project builds without errors
- ✅ All 4 models implemented
- ✅ Model tests passing (100% coverage)
- ✅ Swift 6 compliance

### Phase 4 Complete (Enhanced MVP)
- ✅ Can scan and find build folders
- ✅ Can display results
- ✅ Can delete selected folders
- ✅ All MVP enhancements working
- ✅ Ready for user testing

### Phase 8 Complete (Full Release)
- ✅ All tests passing (>80% coverage)
- ✅ No critical bugs
- ✅ Signed and notarized
- ✅ Documentation complete
- ✅ Public release ready

---

**Ready to start?** → Begin with [00-ai-agent-guide.md](./00-ai-agent-guide.md) then [07-phase-1-foundation.md](./07-phase-1-foundation.md)
