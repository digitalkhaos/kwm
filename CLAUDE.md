# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**kwn** is a macOS menu bar application that manages window layouts when docking/undocking your Mac. Built with SwiftUI and Xcode, targeting macOS 26.0+ with Swift 6.2.

**Key Features:**
- Automatically saves and restores window positions based on display configuration
- Auto-zoom all windows when undocked for single-app workflow
- Menu bar interface for managing layouts
- Uses macOS Accessibility APIs for window management

- **Bundle Identifier**: DKS.kwn
- **Development Team**: 2BW83Y789K
- **Swift Version**: 6.2 with approachable concurrency and MainActor isolation by default

## Build and Run Commands

Since this requires Xcode, use the following approaches:

### Opening in Xcode
```bash
open kwn.xcodeproj
```

### Building
```bash
xcodebuild -project kwn.xcodeproj -scheme kwn -configuration Debug build
```

### Running Tests
```bash
# Run all tests
xcodebuild test -project kwn.xcodeproj -scheme kwn

# Run only unit tests
xcodebuild test -project kwn.xcodeproj -scheme kwn -only-testing:kwnTests

# Run only UI tests
xcodebuild test -project kwn.xcodeproj -scheme kwn -only-testing:kwnUITests

# Run a specific test
xcodebuild test -project kwn.xcodeproj -scheme kwn -only-testing:kwnTests/kwnTests/example
```

### Clean Build
```bash
xcodebuild clean -project kwn.xcodeproj -scheme kwn
```

## Project Structure

```
kwn/
├── kwn/                          # Main application code
│   ├── kwnApp.swift             # App entry point (@main) - MenuBarExtra app
│   ├── MenuBarView.swift        # SwiftUI menu bar interface
│   ├── MenuBarController.swift  # Menu bar logic and event handling
│   ├── DisplayMonitor.swift     # Tracks display configuration changes
│   ├── WindowManager.swift      # Window position management via Accessibility API
│   ├── LayoutStorage.swift      # Persistent storage of window layouts
│   ├── PermissionsManager.swift # Accessibility permissions handling
│   ├── Info.plist              # App permissions and configuration
│   └── Assets.xcassets/         # App assets (icons, colors)
├── kwnTests/                    # Unit tests (Swift Testing framework)
│   └── kwnTests.swift
├── kwnUITests/                  # UI tests (XCTest framework)
│   ├── kwnUITests.swift
│   └── kwnUITestsLaunchTests.swift
└── kwn.xcodeproj/               # Xcode project configuration
```

## Architecture

### Application Type
**kwn** is a menu bar-only application (LSUIElement=true) with no dock icon. It runs in the menu bar and manages window layouts automatically.

### Core Components

#### 1. DisplayMonitor
- Monitors display configuration changes via `NSApplication.didChangeScreenParametersNotification`
- Detects docking/undocking events
- Creates unique fingerprints for display configurations
- Posts notifications when docking state changes

#### 2. WindowManager
- Uses macOS Accessibility APIs (`AXUIElement`) to interact with windows
- Captures window positions, sizes, and states for all running applications
- Restores window layouts by matching apps and window titles
- Implements "zoom all windows" functionality for undocked mode
- **Requires**: Accessibility permissions granted by user

#### 3. LayoutStorage
- Persists window layouts to `~/Library/Application Support/kwn/layouts.json`
- Matches layouts to display configurations automatically
- Supports multiple saved layouts for different display setups
- Uses JSON encoding with ISO8601 dates

#### 4. MenuBarController
- Manages the menu bar interface and status item
- Coordinates between DisplayMonitor, WindowManager, and LayoutStorage
- Handles automatic restore-on-dock and zoom-on-undock behaviors
- Provides user notifications via `UNUserNotificationCenter`
- Maintains user preferences in `UserDefaults`

#### 5. PermissionsManager
- Checks and requests Accessibility permissions
- Uses `AXIsProcessTrustedWithOptions` API
- Provides UI to open System Settings for permission grants

### User Preferences
Stored in `UserDefaults`:
- `autoRestoreEnabled`: Auto-restore layout when docking (default: true)
- `autoZoomEnabled`: Auto-zoom windows when undocking (default: true)

### Automatic Behaviors
1. **On Dock**: If auto-restore enabled and a layout exists for current config, restore it
2. **On Undock**: If auto-zoom enabled, zoom all windows to maximize screen space

### Testing Strategy
- **Unit Tests**: Uses Swift Testing framework (`import Testing`) with async test support
- **UI Tests**: Uses XCTest framework for automated UI testing
- Both test targets depend on the main app target

### Build Configuration
- **Menu Bar Only**: LSUIElement set to hide from Dock
- **Sandbox**: App sandbox is enabled (`ENABLE_APP_SANDBOX = YES`)
- **Hardened Runtime**: Enabled for security
- **Accessibility Usage**: Required permission described in Info.plist
- **Swift Concurrency**: Approachable concurrency enabled with MainActor default isolation

## Required Setup

### First Time Setup in Xcode
1. Open `kwn.xcodeproj` in Xcode
2. Select the project in the navigator, then select the "kwn" target
3. Go to "Signing & Capabilities" tab
4. Ensure your Development Team is selected
5. In "Info" tab, verify that Info.plist is set correctly
6. Build and run the app (⌘R)
7. Grant Accessibility permissions when prompted (or go to System Settings → Privacy & Security → Accessibility)

### Permissions Required
The app will not function without Accessibility permissions. On first launch:
1. Click the menu bar icon
2. Click "Grant Accessibility Permission"
3. Follow the system prompt to System Settings
4. Enable "kwn" in the Accessibility list
5. Restart the app if needed

## Development Notes

### Swift Version Features
This project uses Swift 6.2 with the following features enabled:
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`

This means all code is MainActor-isolated by default unless explicitly specified otherwise.

### Adding New Swift Files
New `.swift` files added to the `kwn/`, `kwnTests/`, or `kwnUITests/` folders are automatically included in their respective targets due to the `PBXFileSystemSynchronizedRootGroup` configuration.

### Testing Framework
- Unit tests use the modern Swift Testing framework (not XCTest)
- Use `@Test` attribute instead of XCTest's test methods
- Use `#expect(...)` assertions instead of XCTest assertions
- Async tests are supported with `async throws`
