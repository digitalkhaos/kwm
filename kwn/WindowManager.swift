//
//  WindowManager.swift
//  kwn
//
//  Manages window positions using macOS Accessibility APIs
//

import Cocoa
import ApplicationServices
import Combine

struct WindowInfo: Codable {
    let appName: String
    let bundleIdentifier: String?
    let windowTitle: String
    let frame: CGRect
    let isMinimized: Bool
    let screen: Int // Index of the screen
}

struct WindowLayout: Codable {
    let configuration: DisplayConfiguration
    let windows: [WindowInfo]
    let name: String
    let savedAt: Date
}

@MainActor
class WindowManager: ObservableObject {
    @Published var lastError: String?

    func captureCurrentLayout(for configuration: DisplayConfiguration, name: String = "Auto-saved") -> WindowLayout? {
        guard AXIsProcessTrusted() else {
            lastError = "Accessibility permissions not granted"
            return nil
        }

        var allWindows: [WindowInfo] = []

        // Get all running applications
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications.filter { app in
            app.activationPolicy == .regular
        }

        for app in runningApps {
            guard let appName = app.localizedName,
                  let pid = app.processIdentifier as pid_t? else {
                continue
            }

            let axApp = AXUIElementCreateApplication(pid)
            var windowsRef: CFTypeRef?

            // Get all windows for this app
            let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)

            guard result == .success,
                  let windows = windowsRef as? [AXUIElement] else {
                continue
            }

            for window in windows {
                if let windowInfo = getWindowInfo(window: window, appName: appName, bundleId: app.bundleIdentifier) {
                    allWindows.append(windowInfo)
                }
            }
        }

        return WindowLayout(
            configuration: configuration,
            windows: allWindows,
            name: name,
            savedAt: Date()
        )
    }

    private func getWindowInfo(window: AXUIElement, appName: String, bundleId: String?) -> WindowInfo? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        var titleRef: CFTypeRef?
        var minimizedRef: CFTypeRef?

        // Get window position
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef) == .success,
              let position = positionRef else {
            return nil
        }

        // Get window size
        guard AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let size = sizeRef else {
            return nil
        }

        var point = CGPoint.zero
        var windowSize = CGSize.zero

        AXValueGetValue(position as! AXValue, .cgPoint, &point)
        AXValueGetValue(size as! AXValue, .cgSize, &windowSize)

        // Get window title
        var title = ""
        if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
           let titleString = titleRef as? String {
            title = titleString
        }

        // Get minimized state
        var isMinimized = false
        if AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedRef) == .success,
           let minimizedValue = minimizedRef as? Bool {
            isMinimized = minimizedValue
        }

        let frame = CGRect(origin: point, size: windowSize)

        // Determine which screen the window is on
        let screens = NSScreen.screens
        var screenIndex = 0
        for (index, screen) in screens.enumerated() {
            if screen.frame.contains(point) {
                screenIndex = index
                break
            }
        }

        return WindowInfo(
            appName: appName,
            bundleIdentifier: bundleId,
            windowTitle: title,
            frame: frame,
            isMinimized: isMinimized,
            screen: screenIndex
        )
    }

    func restoreLayout(_ layout: WindowLayout) -> Bool {
        guard AXIsProcessTrusted() else {
            lastError = "Accessibility permissions not granted"
            return false
        }

        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications

        var restoredCount = 0

        for windowInfo in layout.windows {
            // Find the app
            guard let app = runningApps.first(where: { $0.bundleIdentifier == windowInfo.bundleIdentifier }),
                  let pid = app.processIdentifier as pid_t? else {
                continue
            }

            let axApp = AXUIElementCreateApplication(pid)
            var windowsRef: CFTypeRef?

            guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                  let windows = windowsRef as? [AXUIElement] else {
                continue
            }

            // Try to match the window by title
            for window in windows {
                var titleRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success,
                   let title = titleRef as? String,
                   title == windowInfo.windowTitle {

                    // Restore position
                    var position = windowInfo.frame.origin
                    let positionValue = AXValueCreate(.cgPoint, &position)!
                    AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)

                    // Restore size
                    var size = windowInfo.frame.size
                    let sizeValue = AXValueCreate(.cgSize, &size)!
                    AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)

                    restoredCount += 1
                    break
                }
            }
        }

        return restoredCount > 0
    }

    func zoomAllWindows() {
        guard AXIsProcessTrusted() else {
            lastError = "Accessibility permissions not granted"
            return
        }

        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications.filter { $0.activationPolicy == .regular }

        for app in runningApps {
            guard let pid = app.processIdentifier as pid_t? else { continue }

            let axApp = AXUIElementCreateApplication(pid)
            var windowsRef: CFTypeRef?

            guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                  let windows = windowsRef as? [AXUIElement] else {
                continue
            }

            // Zoom each window
            for window in windows {
                // Check if window supports zoom button
                var zoomButtonRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(window, kAXZoomButtonAttribute as CFString, &zoomButtonRef) == .success,
                   let zoomButton = zoomButtonRef {
                    // Press the zoom button
                    AXUIElementPerformAction(zoomButton as! AXUIElement, kAXPressAction as CFString)
                }
            }
        }
    }
}

