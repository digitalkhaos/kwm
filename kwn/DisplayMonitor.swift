//
//  DisplayMonitor.swift
//  kwn
//
//  Monitors display configuration changes (docking/undocking)
//

import Cocoa
import SwiftUI
import Combine

@MainActor
class DisplayMonitor: ObservableObject {
    @Published var currentConfiguration: DisplayConfiguration
    @Published var isDocked: Bool

    private var previousConfiguration: DisplayConfiguration?

    init() {
        let config = DisplayConfiguration.current()
        self.currentConfiguration = config
        self.isDocked = config.externalDisplayCount > 0

        // Listen for display configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func displayConfigurationChanged() {
        let newConfig = DisplayConfiguration.current()
        let wasDockedBefore = isDocked

        previousConfiguration = currentConfiguration
        currentConfiguration = newConfig
        isDocked = newConfig.externalDisplayCount > 0

        // Notify about docking state change
        if wasDockedBefore != isDocked {
            NotificationCenter.default.post(
                name: .displayDockingStateChanged,
                object: self,
                userInfo: ["isDocked": isDocked]
            )
        }

        // Notify about configuration change
        NotificationCenter.default.post(
            name: .displayConfigurationChanged,
            object: self,
            userInfo: ["configuration": newConfig]
        )
    }
}

struct DisplayConfiguration: Codable, Hashable {
    let externalDisplayCount: Int
    let displayIDs: [String]
    let totalWidth: Int
    let totalHeight: Int
    let timestamp: Date

    static func current() -> DisplayConfiguration {
        let screens = NSScreen.screens
        let externalCount = screens.count > 1 ? screens.count - 1 : 0

        // Create unique IDs based on screen dimensions and position
        let displayIDs = screens.map { screen in
            let frame = screen.frame
            return "\(Int(frame.width))x\(Int(frame.height))@\(Int(frame.origin.x)),\(Int(frame.origin.y))"
        }.sorted()

        let totalWidth = screens.map { Int($0.frame.width) }.reduce(0, +)
        let totalHeight = screens.map { Int($0.frame.maxY) }.max() ?? 0

        return DisplayConfiguration(
            externalDisplayCount: externalCount,
            displayIDs: displayIDs,
            totalWidth: totalWidth,
            totalHeight: totalHeight,
            timestamp: Date()
        )
    }

    func matches(_ other: DisplayConfiguration) -> Bool {
        return externalDisplayCount == other.externalDisplayCount &&
               displayIDs == other.displayIDs
    }
}

extension Notification.Name {
    static let displayConfigurationChanged = Notification.Name("displayConfigurationChanged")
    static let displayDockingStateChanged = Notification.Name("displayDockingStateChanged")
}
