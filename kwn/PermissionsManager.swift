//
//  PermissionsManager.swift
//  kwn
//
//  Manages accessibility permissions required for window management
//

import Cocoa
import ApplicationServices
import Combine

@MainActor
class PermissionsManager: ObservableObject {
    @Published var hasAccessibilityPermission = false

    func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        hasAccessibilityPermission = hasPermission
        return hasPermission
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        hasAccessibilityPermission = hasPermission
    }

    func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

