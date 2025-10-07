//
//  AppController.swift
//  kwm
//
//  Created by john on 10/6/25.
//

import Foundation
import AppKit
import SwiftUI
import Combine
import UserNotifications

/// Main application controller that coordinates window management and monitor detection
class AppController: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var autoSaveOnConnect: Bool = true
    @Published var autoZoomOnDisconnect: Bool = true
    @Published var statusMessage: String = "Ready"
    @Published var lastAction: String = ""

    let windowManager = WindowManager.shared
    let monitorManager = MonitorManager.shared
    let positionStore = WindowPositionStore()
    let dockManager = DockManager.shared

    private var hasShownAccessibilityAlert = false

    init() {
        setupMonitorObserver()
        checkPermissions()
    }

    /// Setup monitor configuration change observer
    private func setupMonitorObserver() {
        monitorManager.onDisplayConfigurationChanged = { [weak self] event in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch event {
                case .monitorsConnected:
                    self.handleMonitorsConnected()
                case .monitorsDisconnected:
                    self.handleMonitorsDisconnected()
                case .displayConfigurationChanged:
                    self.statusMessage = "Display configuration changed"
                }
            }
        }
    }

    /// Check accessibility permissions
    func checkPermissions() {
        if !windowManager.checkAccessibilityPermissions() {
            statusMessage = "Accessibility permissions required"
            if !hasShownAccessibilityAlert {
                showAccessibilityAlert()
                hasShownAccessibilityAlert = true
            }
        } else {
            statusMessage = "Ready"
        }
    }

    /// Show accessibility permission alert
    private func showAccessibilityAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "KWM needs accessibility permissions to manage window positions. Please grant access in System Preferences > Privacy & Security > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }

    /// Handle monitor connection event
    private func handleMonitorsConnected() {
        print("Handling monitors connected")
        lastAction = "Monitors connected"
        statusMessage = "External monitors detected"

        // Show dock if auto-dock control is enabled
        if positionStore.autoDockControl && isEnabled {
            dockManager.showDock()
            print("Showing dock (external monitor connected)")
        }

        if autoSaveOnConnect && isEnabled {
            // Small delay to let windows settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.saveCurrentWindowPositions()
            }
        }
    }

    /// Handle monitor disconnection event
    private func handleMonitorsDisconnected() {
        print("Handling monitors disconnected")
        lastAction = "Monitors disconnected"
        statusMessage = "External monitors removed"

        // Hide dock if auto-dock control is enabled
        if positionStore.autoDockControl && isEnabled {
            dockManager.hideDock()
            print("Hiding dock (external monitor disconnected)")
        }

        if autoZoomOnDisconnect && isEnabled {
            // Small delay to let system adjust
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.zoomAllWindows()
            }
        }
    }

    /// Save current window positions for all non-excluded applications
    func saveCurrentWindowPositions() {
        guard windowManager.checkAccessibilityPermissions() else {
            statusMessage = "Error: No accessibility permissions"
            showNotification(title: "Permission Required", body: "Please grant accessibility permissions to save window positions")
            return
        }

        let windows = windowManager.getAllWindows(excludedApps: positionStore.excludedApps)
        positionStore.savePositions(windows)

        let count = windows.count
        statusMessage = "Saved \(count) window\(count == 1 ? "" : "s")"
        lastAction = "Saved \(count) window positions"

        print("Saved \(count) window positions")
        showNotification(title: "Windows Saved", body: "Saved positions for \(count) window\(count == 1 ? "" : "s")")
    }

    /// Restore saved window positions
    func restoreWindowPositions() {
        guard windowManager.checkAccessibilityPermissions() else {
            statusMessage = "Error: No accessibility permissions"
            showNotification(title: "Permission Required", body: "Please grant accessibility permissions to restore windows")
            return
        }

        let count = windowManager.restoreWindowPositions(positionStore.savedPositions)
        statusMessage = "Restored \(count) window\(count == 1 ? "" : "s")"
        lastAction = "Restored \(count) windows"

        print("Restored \(count) window positions")
        showNotification(title: "Windows Restored", body: "Restored \(count) window\(count == 1 ? "" : "s")")
    }

    /// Zoom all non-excluded windows to fill the screen
    func zoomAllWindows() {
        guard windowManager.checkAccessibilityPermissions() else {
            statusMessage = "Error: No accessibility permissions"
            showNotification(title: "Permission Required", body: "Please grant accessibility permissions to zoom windows")
            return
        }

        let count = windowManager.zoomAllWindows(excludedApps: positionStore.excludedApps)
        statusMessage = "Zoomed \(count) window\(count == 1 ? "" : "s")"
        lastAction = "Zoomed \(count) windows"

        print("Zoomed \(count) windows")
        showNotification(title: "Windows Zoomed", body: "Zoomed \(count) window\(count == 1 ? "" : "s") to full screen")
    }

    /// Clear saved window positions
    func clearSavedPositions() {
        positionStore.clearPositions()
        statusMessage = "Cleared saved positions"
        lastAction = "Cleared saved positions"

        showNotification(title: "Positions Cleared", body: "All saved window positions have been cleared")
    }

    /// Toggle automatic mode
    func toggleEnabled() {
        isEnabled.toggle()
        statusMessage = isEnabled ? "Automatic mode enabled" : "Automatic mode disabled"

        if isEnabled {
            checkPermissions()
        }
    }

    /// Show system notification
    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }

    /// Request notification permissions
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
    }

    /// Get list of running applications for exclusion settings
    func getRunningApplications() -> [RunningApp] {
        return windowManager.getRunningApplications()
    }
}
