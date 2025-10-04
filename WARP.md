# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**kwn** is a macOS SwiftUI application built with Xcode. This is a sandbox-enabled app targeting macOS 26.0+ with Swift 6.2.

- **Bundle Identifier**: DKS.kwn
- **Development Team**: 2BW83Y789K
- **Swift Version**: 6.2 with approachable concurrency and MainActor isolation by default

## Build and Run Commands

Since this requires Xcode, use the following approaches:

### Opening in Xcode
```bash
open kwn.xcodeproj
```

### Building (requires full Xcode installation)
```bash
xcodebuild -project kwn.xcodeproj -scheme kwn -configuration Debug build
```

### Running Tests (requires full Xcode installation)
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
├── kwn/                    # Main application code
│   ├── kwnApp.swift       # App entry point (@main)
│   ├── ContentView.swift  # Main view
│   └── Assets.xcassets/   # App assets (icons, colors)
├── kwnTests/              # Unit tests (Swift Testing framework)
│   └── kwnTests.swift
├── kwnUITests/            # UI tests (XCTest framework)
│   ├── kwnUITests.swift
│   └── kwnUITestsLaunchTests.swift
└── kwn.xcodeproj/         # Xcode project configuration
```

## Architecture

### Application Entry Point
- **kwnApp.swift**: The `@main` entry point using SwiftUI's App protocol
- Creates a single WindowGroup containing ContentView

### View Layer
- **ContentView.swift**: The root SwiftUI view
- Currently displays a basic "Hello, world!" template

### Testing Strategy
- **Unit Tests**: Uses Swift Testing framework (`import Testing`) with async test support
- **UI Tests**: Uses XCTest framework for automated UI testing
- Both test targets depend on the main app target

### Build Configuration
- **Sandbox**: App sandbox is enabled (`ENABLE_APP_SANDBOX = YES`)
- **Hardened Runtime**: Enabled for security
- **SwiftUI Previews**: Enabled (`ENABLE_PREVIEWS = YES`)
- **User Selected Files**: Read-only access enabled
- **Swift Concurrency**: Approachable concurrency enabled with MainActor default isolation

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
