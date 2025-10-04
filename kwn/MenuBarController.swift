//
//  MenuBarController.swift
//  kwn
//
//  Manages the menu bar interface
//

import SwiftUI
import Cocoa
import Combine
import UserNotifications

@MainActor
class MenuBarController: ObservableObject {
    let displayMonitor: DisplayMonitor
    let windowManager: WindowManager
    let layoutStorage: LayoutStorage
    let permissionsManager: PermissionsManager

    @Published var isAutoRestoreEnabled = true
    @Published var isAutoZoomEnabled = true

    init(displayMonitor: DisplayMonitor, windowManager: WindowManager, layoutStorage: LayoutStorage, permissionsManager: PermissionsManager) {
        self.displayMonitor = displayMonitor
        self.windowManager = windowManager
        self.layoutStorage = layoutStorage
        self.permissionsManager = permissionsManager

        setupNotifications()

        // Load preferences (default to true if not set)
        if UserDefaults.standard.object(forKey: "autoRestoreEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "autoRestoreEnabled")
        }
        if UserDefaults.standard.object(forKey: "autoZoomEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "autoZoomEnabled")
        }
        isAutoRestoreEnabled = UserDefaults.standard.bool(forKey: "autoRestoreEnabled")
        isAutoZoomEnabled = UserDefaults.standard.bool(forKey: "autoZoomEnabled")

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }


    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .displayDockingStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            Task { @MainActor in
                self.handleDockingStateChange(notification)
            }
        }
    }

    private func handleDockingStateChange(_ notification: Notification) {
        guard let isDocked = notification.userInfo?["isDocked"] as? Bool else {
            return
        }

        if isDocked {
            // Just docked - restore layout if available and auto-restore is enabled
            if isAutoRestoreEnabled {
                if let layout = layoutStorage.findLayoutForConfiguration(displayMonitor.currentConfiguration) {
                    _ = windowManager.restoreLayout(layout)
                    showNotification(title: "Windows Restored", body: "Layout restored for docked configuration")
                }
            }
        } else {
            // Just undocked - zoom all windows if auto-zoom is enabled
            if isAutoZoomEnabled {
                windowManager.zoomAllWindows()
                showNotification(title: "Windows Zoomed", body: "All windows zoomed for undocked mode")
            }
        }
    }

    func saveCurrentLayout() {
        guard permissionsManager.checkAccessibilityPermission() else {
            showNotification(title: "Permission Required", body: "Please grant Accessibility permission first")
            return
        }

        let config = displayMonitor.currentConfiguration
        let configName = displayMonitor.isDocked ? "Docked (\(config.externalDisplayCount) displays)" : "Undocked"

        if let layout = windowManager.captureCurrentLayout(for: config, name: configName) {
            layoutStorage.saveLayout(layout)
            showNotification(title: "Layout Saved", body: "Window layout saved for current configuration")
        } else {
            showNotification(title: "Save Failed", body: "Could not capture window layout")
        }
    }

    func restoreLayout() {
        guard permissionsManager.checkAccessibilityPermission() else {
            showNotification(title: "Permission Required", body: "Please grant Accessibility permission first")
            return
        }

        if let layout = layoutStorage.findLayoutForConfiguration(displayMonitor.currentConfiguration) {
            if windowManager.restoreLayout(layout) {
                showNotification(title: "Layout Restored", body: "Windows moved to saved positions")
            } else {
                showNotification(title: "Restore Failed", body: "Could not restore layout")
            }
        }
    }

    func zoomAllWindows() {
        guard permissionsManager.checkAccessibilityPermission() else {
            showNotification(title: "Permission Required", body: "Please grant Accessibility permission first")
            return
        }

        windowManager.zoomAllWindows()
        showNotification(title: "Windows Zoomed", body: "All windows have been zoomed")
    }

    func showManageLayouts() {
        let alert = NSAlert()
        alert.messageText = "Saved Layouts"
        alert.alertStyle = .informational

        let layouts = layoutStorage.getAllLayouts()

        if layouts.isEmpty {
            alert.informativeText = "No layouts saved yet. Use 'Save Current Window Layout' to create one."
        } else {
            var info = "You have \(layouts.count) saved layout(s):\n\n"
            for (index, layout) in layouts.enumerated() {
                let date = layout.savedAt.formatted(date: .abbreviated, time: .shortened)
                info += "\(index + 1). \(layout.name)\n   Saved: \(date)\n   Windows: \(layout.windows.count)\n\n"
            }
            alert.informativeText = info
        }

        alert.addButton(withTitle: "OK")

        if !layouts.isEmpty {
            alert.addButton(withTitle: "Clear All Layouts")
        }

        let response = alert.runModal()

        if response == .alertSecondButtonReturn {
            // Clear all layouts
            for layout in layouts {
                layoutStorage.deleteLayout(layout)
            }
            showNotification(title: "Layouts Cleared", body: "All saved layouts have been deleted")
        }
    }

    private func showNotification(title: String, body: String) {
        // Use UNUserNotificationCenter for modern notifications
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
