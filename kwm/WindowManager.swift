//
//  WindowManager.swift
//  kwm
//
//  Created by john on 10/6/25.
//

import Foundation
import ApplicationServices
import AppKit
import Combine

/// Manages window operations using Accessibility API
class WindowManager: ObservableObject {
    static let shared = WindowManager()

    @Published var lastError: String?

    private init() {}

    /// Check if the app has accessibility permissions
    func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Get all running applications
    func getRunningApplications() -> [RunningApp] {
        let workspace = NSWorkspace.shared
        return workspace.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let name = app.localizedName else { return nil }
                return RunningApp(name: name, pid: app.processIdentifier)
            }
    }

    /// Get all windows for all running applications
    func getAllWindows(excludedApps: Set<String> = []) -> [WindowInfo] {
        var windowInfos: [WindowInfo] = []

        for app in getRunningApplications() {
            if excludedApps.contains(app.name) {
                continue
            }

            let windows = getWindowsForApp(pid: app.pid, appName: app.name)
            windowInfos.append(contentsOf: windows)
        }

        return windowInfos
    }

    /// Get all windows for a specific application
    func getWindowsForApp(pid: pid_t, appName: String) -> [WindowInfo] {
        let appRef = AXUIElementCreateApplication(pid)
        var windowInfos: [WindowInfo] = []

        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value)

        guard result == .success, let windows = value as? [AXUIElement] else {
            return []
        }

        for window in windows {
            if let windowInfo = getWindowInfo(window: window, appName: appName, pid: pid) {
                windowInfos.append(windowInfo)
            }
        }

        return windowInfos
    }

    /// Get information for a specific window
    private func getWindowInfo(window: AXUIElement, appName: String, pid: pid_t) -> WindowInfo? {
        // Get window title
        var titleValue: AnyObject?
        var title = "Untitled"
        if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue) == .success,
           let titleString = titleValue as? String {
            title = titleString
        }

        // Get window position
        var positionValue: AnyObject?
        var windowPosition = CGPoint.zero
        if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success {
            var position = CGPoint.zero
            if AXValueGetValue(positionValue as! AXValue, .cgPoint, &position) {
                windowPosition = position
            }
        }

        // Get window size
        var sizeValue: AnyObject?
        var windowSize = CGSize.zero
        if AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success {
            var size = CGSize.zero
            if AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) {
                windowSize = size
            }
        }

        let frame = CGRect(origin: windowPosition, size: windowSize)

        // Get the display ID where the window is located
        let displayID = getDisplayIDForPoint(windowPosition)

        return WindowInfo(appName: appName, windowTitle: title, frame: frame, displayID: displayID)
    }

    /// Get the display ID for a given point
    private func getDisplayIDForPoint(_ point: CGPoint) -> CGDirectDisplayID? {
        var displayCount: UInt32 = 0
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)

        let result = CGGetDisplaysWithPoint(point, 16, &displays, &displayCount)

        if result == .success && displayCount > 0 {
            return displays[0]
        }

        return nil
    }

    /// Set window position and size
    func setWindowFrame(pid: pid_t, windowTitle: String, frame: CGRect) -> Bool {
        let appRef = AXUIElementCreateApplication(pid)

        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value)

        guard result == .success, let windows = value as? [AXUIElement] else {
            lastError = "Failed to get windows for application"
            return false
        }

        // Find the window with matching title
        for window in windows {
            var titleValue: AnyObject?
            if AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue) == .success,
               let title = titleValue as? String,
               title == windowTitle {

                // Set position
                var position = frame.origin
                let positionValue = AXValueCreate(.cgPoint, &position)!
                let posResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)

                // Set size
                var size = frame.size
                let sizeValue = AXValueCreate(.cgSize, &size)!
                let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)

                if posResult == .success && sizeResult == .success {
                    return true
                } else {
                    lastError = "Failed to set window position or size"
                    return false
                }
            }
        }

        lastError = "Window not found: \(windowTitle)"
        return false
    }

    /// Zoom window to fill the screen
    func zoomWindow(pid: pid_t, windowTitle: String) -> Bool {
        guard let screen = NSScreen.main else {
            lastError = "No main screen found"
            return false
        }

        let visibleFrame = screen.visibleFrame
        return setWindowFrame(pid: pid, windowTitle: windowTitle, frame: visibleFrame)
    }

    /// Zoom all windows for a specific app
    func zoomAllWindowsForApp(pid: pid_t, appName: String) -> Int {
        let windows = getWindowsForApp(pid: pid, appName: appName)
        var successCount = 0

        guard let screen = NSScreen.main else {
            lastError = "No main screen found"
            return 0
        }

        let visibleFrame = screen.visibleFrame

        for window in windows {
            if setWindowFrame(pid: pid, windowTitle: window.windowTitle, frame: visibleFrame) {
                successCount += 1
            }
        }

        return successCount
    }

    /// Restore saved window positions
    func restoreWindowPositions(_ positions: [WindowInfo]) -> Int {
        var successCount = 0

        // Group positions by app name
        let positionsByApp = Dictionary(grouping: positions) { $0.appName }

        for (appName, windows) in positionsByApp {
            // Find the running app
            if let app = getRunningApplications().first(where: { $0.name == appName }) {
                for windowInfo in windows {
                    if setWindowFrame(pid: app.pid, windowTitle: windowInfo.windowTitle, frame: windowInfo.frame) {
                        successCount += 1
                    }
                }
            }
        }

        return successCount
    }

    /// Zoom all windows on the main screen
    func zoomAllWindows(excludedApps: Set<String> = []) -> Int {
        var successCount = 0

        guard let screen = NSScreen.main else {
            lastError = "No main screen found"
            return 0
        }

        let visibleFrame = screen.visibleFrame

        for app in getRunningApplications() {
            if excludedApps.contains(app.name) {
                continue
            }

            let windows = getWindowsForApp(pid: app.pid, appName: app.name)
            for window in windows {
                if setWindowFrame(pid: app.pid, windowTitle: window.windowTitle, frame: visibleFrame) {
                    successCount += 1
                }
            }
        }

        return successCount
    }
}
