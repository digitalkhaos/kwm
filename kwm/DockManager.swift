//
//  DockManager.swift
//  kwm
//
//  Created by john on 10/6/25.
//

import Foundation
import AppKit

/// Manages macOS Dock visibility settings
class DockManager {
    static let shared = DockManager()

    private let dockDefaults = UserDefaults(suiteName: "com.apple.dock")

    private init() {}

    /// Show the dock (disable auto-hide)
    func showDock() {
        print("Showing dock (disabling auto-hide)")
        setDockAutoHide(false)
    }

    /// Hide the dock (enable auto-hide)
    func hideDock() {
        print("Hiding dock (enabling auto-hide)")
        setDockAutoHide(true)
    }

    /// Set dock auto-hide state
    private func setDockAutoHide(_ autoHide: Bool) {
        // Set the preference
        dockDefaults?.set(autoHide, forKey: "autohide")
        dockDefaults?.synchronize()

        // Restart the Dock to apply changes
        restartDock()
    }

    /// Get current dock auto-hide state
    func getDockAutoHideState() -> Bool {
        return dockDefaults?.bool(forKey: "autohide") ?? false
    }

    /// Restart the Dock application to apply settings
    private func restartDock() {
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = ["Dock"]

        do {
            try task.run()
        } catch {
            print("Failed to restart Dock: \(error)")
        }
    }

    /// Check if we can control the dock
    func canControlDock() -> Bool {
        return dockDefaults != nil
    }
}
