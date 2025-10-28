# ZeroDevCleaner - UI/UX Design Specification

## Design Principles

### Core Principles
1. **Clarity**: Every action should be obvious and unambiguous
2. **Safety**: Prevent accidental deletions through clear confirmations
3. **Efficiency**: Minimize clicks and steps to complete tasks
4. **Native Feel**: Look and feel like a native macOS application
5. **Responsiveness**: Provide immediate feedback for all actions

## Visual Design

### Design System

#### Color Palette
```
Primary Colors:
- Accent Blue: System blue (for primary actions)
- Destructive Red: System red (for delete actions)
- Success Green: System green (for completion states)
- Warning Orange: System orange (for warnings)

Background Colors:
- Window Background: System background
- Content Background: System secondary background
- List Row: Alternating system list colors

Text Colors:
- Primary Text: System primary label
- Secondary Text: System secondary label
- Tertiary Text: System tertiary label
```

#### Typography
```
- Title: SF Pro Display, 24pt, Bold
- Headline: SF Pro Display, 17pt, Semibold
- Body: SF Pro Text, 13pt, Regular
- Caption: SF Pro Text, 11pt, Regular
- Monospace: SF Mono, 12pt (for paths)
```

#### Spacing
```
- XXS: 4pt
- XS: 8pt
- S: 12pt
- M: 16pt
- L: 24pt
- XL: 32pt
- XXL: 48pt
```

#### Corner Radius
```
- Small: 4pt (for buttons, badges)
- Medium: 8pt (for cards, containers)
- Large: 12pt (for modals, sheets)
```

## Window Layout

### Main Window Specifications
```
Default Size: 900 x 650 points
Minimum Size: 700 x 500 points
Resizable: Yes
Full Screen Support: Yes
```

### Layout Structure
```
┌─────────────────────────────────────────────────────┐
│  ZeroDevCleaner                          [- □ ×]    │ Title Bar
├─────────────────────────────────────────────────────┤
│  Toolbar                                             │
│  [Select Folder] [Start Scan]                       │
│  Selected: /Users/username/Developer                 │
├─────────────────────────────────────────────────────┤
│                                                      │
│  Scan Results                                        │
│  ┌─────────────────────────────────────────────┐   │
│  │ ☑  Name/Path          Type      Size        │   │
│  ├─────────────────────────────────────────────┤   │
│  │ ☑  MyApp/build       Android   125.5 MB    │   │
│  │ □  MyProject/.build  iOS        89.2 MB    │   │
│  │ ☑  TestApp/build     Android   256.8 MB    │   │
│  │                                              │   │
│  │                                              │   │
│  └─────────────────────────────────────────────┘   │
│                                                      │
│  [Select All] [Deselect All]                        │
│  3 selected • 471.5 MB                               │
│                              [Remove Selected]       │
└─────────────────────────────────────────────────────┘
  Status Bar: Ready • Last scan: Never
```

## Screen Designs

### 1. Initial State (Empty State)

```
┌─────────────────────────────────────────────────────┐
│                                                      │
│                    📁                                │
│                                                      │
│         Welcome to ZeroDevCleaner                    │
│                                                      │
│     Clean up Android and iOS build folders          │
│     to free up disk space on your Mac               │
│                                                      │
│              [Select Root Folder]                    │
│                                                      │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Elements:**
- Large folder icon (SF Symbol: `folder`)
- Welcome text (Title style)
- Description text (Body style, secondary color)
- Primary button: "Select Root Folder"

### 2. Folder Selected State

```
┌─────────────────────────────────────────────────────┐
│  [📁 Select Folder]  [▶ Start Scan]                 │
│                                                      │
│  Scan Location:                                      │
│  /Users/username/Developer/Projects                  │
│  [Change]                                            │
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │                                               │  │
│  │          Ready to scan                        │  │
│  │                                               │  │
│  │  The app will search for:                     │  │
│  │  • Android build folders                      │  │
│  │  • iOS .build folders                         │  │
│  │                                               │  │
│  │  Click "Start Scan" to begin                  │  │
│  │                                               │  │
│  └──────────────────────────────────────────────┘  │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Elements:**
- Toolbar with two buttons: "Select Folder" and "Start Scan"
- Selected path display (monospace font)
- Info card with instructions
- Primary action button highlighted

### 3. Scanning State

```
┌─────────────────────────────────────────────────────┐
│  [📁 Select Folder]  [■ Stop Scan]                  │
│                                                      │
│  Scanning: /Users/username/Developer/MyApp/src      │
│  ████████████████░░░░░░░░░░ 65%                     │
│                                                      │
│  Found so far: 15 build folders (1.2 GB)            │
│                                                      │
│  ┌─────────────────────────────────────────────┐   │
│  │ ☑  MyApp/build          Android   125.5 MB │   │
│  │ ☑  OldProject/.build    iOS        89.2 MB │   │
│  │ ☑  TestApp/build        Android   256.8 MB │   │
│  │ ☑  SwiftPkg/.build      Swift      45.1 MB │   │
│  │ ... (11 more)                                │   │
│  └─────────────────────────────────────────────┘   │
│                                                      │
└─────────────────────────────────────────────────────┘
  Scanning... • 1,234 folders checked
```

**Elements:**
- Stop button (replaces Start button)
- Current path being scanned (truncated if long)
- Progress bar with percentage
- Running count of found items
- Live-updating results list
- Status bar with scan progress

### 4. Results State (Scan Complete)

```
┌─────────────────────────────────────────────────────┐
│  [📁 Select Folder]  [🔄 Scan Again]                │
│                                                      │
│  Scan Results                      [🔍 Filter] [⚙️] │
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │ ☑ │ Project Path              │Type │ Size   │  │
│  ├──────────────────────────────────────────────┤  │
│  │ ☑ │ MyApp/build               │ 🤖  │125.5MB│  │
│  │ □ │ OldProject/.build         │ 🍎  │ 89.2MB│  │
│  │ ☑ │ TestApp/build             │ 🤖  │256.8MB│  │
│  │ ☑ │ ClientProject/build       │ 🤖  │ 45.3MB│  │
│  │ ☑ │ SwiftPackage/.build       │ 📦  │ 12.1MB│  │
│  │ □ │ Legacy/ios/.build         │ 🍎  │156.7MB│  │
│  │ ☑ │ Demo/android/build        │ 🤖  │ 78.9MB│  │
│  │ ... (23 more rows)                            │  │
│  └──────────────────────────────────────────────┘  │
│                                                      │
│  [☑ Select All] [□ Deselect All]                    │
│  21 of 30 selected • 1.2 GB of 1.8 GB total         │
│                                      [Remove Sel.]   │
└─────────────────────────────────────────────────────┘
  Scan complete • Found 30 build folders • 1.8 GB total
```

**Elements:**
- Table with sortable columns
- Checkbox for each row
- Icon indicating project type
- Size formatted (KB, MB, GB)
- Select All/Deselect All buttons
- Selection summary
- Destructive action button (red)

### 5. Confirmation Dialog

```
        ┌──────────────────────────────────────┐
        │  ⚠️  Confirm Deletion                │
        ├──────────────────────────────────────┤
        │                                       │
        │  You are about to delete:             │
        │                                       │
        │  • 21 build folders                   │
        │  • Total size: 1.2 GB                 │
        │                                       │
        │  These items will be moved to Trash   │
        │  and can be restored if needed.       │
        │                                       │
        │                                       │
        │         [Cancel]  [Move to Trash]     │
        └──────────────────────────────────────┘
```

**Elements:**
- Modal dialog (sheet style)
- Warning icon
- Clear summary of action
- Reassuring message about Trash
- Cancel button (secondary)
- Destructive action button (primary)

### 6. Deletion Progress

```
        ┌──────────────────────────────────────┐
        │  Deleting Build Folders...            │
        ├──────────────────────────────────────┤
        │                                       │
        │  Deleting: MyApp/build                │
        │  ████████████░░░░░░░░░ 12/21          │
        │                                       │
        │  Deleted: 612 MB of 1.2 GB            │
        │                                       │
        │                                       │
        │                    [Cancel]           │
        └──────────────────────────────────────┘
```

**Elements:**
- Progress sheet
- Current item being deleted
- Progress bar with count
- Size progress indicator
- Cancel button

### 7. Completion State

```
        ┌──────────────────────────────────────┐
        │  ✅ Cleanup Complete!                 │
        ├──────────────────────────────────────┤
        │                                       │
        │  Successfully deleted:                │
        │                                       │
        │  • 21 build folders                   │
        │  • 1.2 GB freed                       │
        │                                       │
        │  Your Mac just got lighter!           │
        │                                       │
        │                                       │
        │                        [Done]         │
        └──────────────────────────────────────┘
```

**Elements:**
- Success icon
- Summary of deleted items
- Friendly completion message
- Done button to close

## Interactive Components

### Buttons

#### Primary Button
```
Style: Filled, rounded corners
Color: System blue background, white text
Size: Medium (32pt height)
Padding: 12pt horizontal, 8pt vertical
States: Normal, Hover, Pressed, Disabled
```

#### Secondary Button
```
Style: Outlined, rounded corners
Color: System blue border/text
Size: Medium (32pt height)
Padding: 12pt horizontal, 8pt vertical
States: Normal, Hover, Pressed, Disabled
```

#### Destructive Button
```
Style: Filled, rounded corners
Color: System red background, white text
Size: Medium (32pt height)
Padding: 12pt horizontal, 8pt vertical
States: Normal, Hover, Pressed, Disabled
```

### Table/List View

#### Specifications
```
Row Height: 44pt
Alternating Rows: Yes (subtle)
Hover Effect: Yes (highlight row)
Selection: Multiple via checkboxes
Sort: Click column headers
Scroll: Vertical, with bounce
```

#### Columns
1. **Checkbox**: 44pt width
2. **Project Path**: Flexible, min 250pt
3. **Type**: 80pt width, centered
4. **Size**: 100pt width, right-aligned

### Progress Indicators

#### Linear Progress Bar
```
Height: 8pt
Corner Radius: 4pt
Color: System blue (indeterminate) or gradient
Background: System tertiary fill
Animation: Smooth, 60fps
```

#### Spinner
```
Size: 20pt
Color: System secondary label
Use: Next to text for inline loading
```

## Interactions & Animations

### Hover Effects
- Buttons: Slight brightness increase
- Table rows: Subtle background highlight
- Checkboxes: Border color change

### Click Feedback
- Buttons: Scale down 98% on press
- Checkboxes: Toggle animation
- Table rows: Brief highlight pulse

### Transitions
- View changes: 0.3s ease-in-out fade
- Dialog appearance: 0.25s spring animation
- Progress updates: Smooth interpolation

### Loading States
- Scanning: Pulsing progress bar
- Calculating: Spinning indicator
- Deleting: Animated progress fill

## Accessibility

### VoiceOver Support
- All buttons labeled clearly
- Table content readable row by row
- Progress announcements
- Completion alerts

### Keyboard Navigation
- Tab through all interactive elements
- Space to toggle checkboxes
- Return to activate focused button
- Cmd+A to select all
- Cmd+Shift+A to deselect all

### Color Contrast
- WCAG AA compliant (4.5:1 minimum)
- System colors for automatic dark mode
- Icons with sufficient contrast

### Text Size
- Respect system text size settings
- Scale UI proportionally
- Maintain readability at all sizes

## Error States

### Permission Error
```
┌─────────────────────────────────────────────────────┐
│                                                      │
│                    🔒                                │
│                                                      │
│           Permission Required                        │
│                                                      │
│  ZeroDevCleaner needs Full Disk Access               │
│  to scan your development folders.                   │
│                                                      │
│  [Cancel]  [Open System Settings]                   │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Scan Error
```
┌─────────────────────────────────────────────────────┐
│  ⚠️ Scan Error                                       │
│                                                      │
│  Could not complete scan:                            │
│  Permission denied for: /Users/username/Private      │
│                                                      │
│  4 folders were skipped due to permissions.          │
│  Showing results for accessible folders.             │
│                                                      │
│                                 [OK]                 │
└─────────────────────────────────────────────────────┘
```

### Deletion Error
```
┌─────────────────────────────────────────────────────┐
│  ⚠️ Deletion Error                                   │
│                                                      │
│  Could not delete some items:                        │
│                                                      │
│  • MyApp/build (in use)                             │
│  • TestApp/build (permission denied)                │
│                                                      │
│  Successfully deleted: 19 of 21 items                │
│                                                      │
│                  [Show Details]  [OK]               │
└─────────────────────────────────────────────────────┘
```

## Settings/Preferences (Future)

```
┌─────────────────────────────────────────────────────┐
│  Settings                                       [×]  │
├─────────────────────────────────────────────────────┤
│                                                      │
│  Scanning                                            │
│  ☑ Include hidden folders (.build)                  │
│  ☑ Validate project structure                       │
│  ☐ Follow symbolic links                            │
│                                                      │
│  Deletion                                            │
│  ● Move to Trash (recommended)                      │
│  ○ Permanent deletion                               │
│                                                      │
│  Exclusions                                          │
│  Skip folders named:                                 │
│  [node_modules, venv, ...]                          │
│                                                      │
│                              [Cancel]  [Save]       │
└─────────────────────────────────────────────────────┘
```

## Responsive Behavior

### Window Resizing
- Minimum width: 700pt
  - Stack toolbar buttons vertically if needed
  - Hide secondary info columns

- Medium width: 700-900pt
  - Show all essential columns
  - Truncate long paths with ellipsis

- Large width: 900pt+
  - Show full paths where possible
  - Add more whitespace for comfort

### Content Scaling
- Table adjusts number of visible rows
- Keep toolbar and status bar fixed
- Results area grows/shrinks with window

## Platform Integration

### macOS Native Features
- Native file picker (NSOpenPanel)
- Native alerts and sheets
- System accent color support
- Dark mode automatic switching
- Touch Bar support (if applicable)
- Translucent window effects

### Context Menus
- Right-click on table row:
  - Show in Finder
  - Copy Path
  - Deselect this item

### Drag & Drop
- Drag folder onto window to select it
- Visual feedback during drag

## Performance Considerations

### Large Result Sets
- Virtual scrolling for 1000+ items
- Lazy loading of size calculations
- Progressive rendering
- Smooth 60fps scrolling

### Real-time Updates
- Throttle progress updates (max 30fps)
- Batch UI updates
- Background thread for calculations
