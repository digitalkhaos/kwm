//
//  MonitorManager.swift
//  kwm
//
//  Created by john on 10/6/25.
//

import Foundation
import AppKit
import CoreGraphics
import IOKit.ps
import Combine

/// Manages monitor detection and display configuration changes
class MonitorManager: ObservableObject {
    static let shared = MonitorManager()

    @Published var displayCount: Int = 0
    @Published var hasExternalMonitors: Bool = false
    @Published var displays: [DisplayInfo] = []

    var onDisplayConfigurationChanged: ((DisplayChangeEvent) -> Void)?

    private var previousDisplayCount: Int = 0

    enum DisplayChangeEvent {
        case monitorsConnected
        case monitorsDisconnected
        case displayConfigurationChanged
    }

    struct DisplayInfo: Identifiable {
        let id: CGDirectDisplayID
        let bounds: CGRect
        let isMain: Bool
        let name: String

        init(id: CGDirectDisplayID) {
            self.id = id
            self.bounds = CGDisplayBounds(id)
            self.isMain = CGDisplayIsMain(id) != 0

            // Get display name
            var name = "Display \(id)"
            if let info = CoreDisplay_DisplayCreateInfoDictionary(id)?.takeRetainedValue() as? [String: Any],
               let names = info["DisplayProductName"] as? [String: String],
               let englishName = names["en_US"] ?? names.values.first {
                name = englishName
            }
            self.name = name
        }
    }

    private init() {
        updateDisplayInfo()
        registerForDisplayChanges()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Register for display configuration change notifications
    private func registerForDisplayChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    /// Handle display configuration changes
    @objc private func displayConfigurationChanged() {
        let oldCount = previousDisplayCount
        updateDisplayInfo()
        let newCount = displayCount

        print("Display configuration changed: \(oldCount) -> \(newCount) displays")

        // Determine the type of change
        if newCount > oldCount {
            print("Monitors connected")
            onDisplayConfigurationChanged?(.monitorsConnected)
        } else if newCount < oldCount {
            print("Monitors disconnected")
            onDisplayConfigurationChanged?(.monitorsDisconnected)
        } else {
            print("Display configuration changed (same count)")
            onDisplayConfigurationChanged?(.displayConfigurationChanged)
        }

        previousDisplayCount = newCount
    }

    /// Update display information
    func updateDisplayInfo() {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0

        let result = CGGetActiveDisplayList(16, &displayIDs, &displayCount)

        guard result == .success else {
            print("Failed to get active display list")
            return
        }

        self.displayCount = Int(displayCount)
        self.displays = displayIDs.prefix(Int(displayCount)).map { DisplayInfo(id: $0) }

        // Check if there are external monitors (more than 1 display or not a MacBook)
        self.hasExternalMonitors = displayCount > 1

        print("Current displays: \(displayCount)")
        for display in displays {
            print("  - \(display.name) [\(display.id)] Main: \(display.isMain) Bounds: \(display.bounds)")
        }
    }

    /// Get the main display
    func getMainDisplay() -> DisplayInfo? {
        return displays.first { $0.isMain }
    }

    /// Check if running on battery (laptop mode)
    func isOnBattery() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return false
        }

        guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [AnyObject] else {
            return false
        }

        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                if let powerSourceState = description[kIOPSPowerSourceStateKey] as? String {
                    return powerSourceState == kIOPSBatteryPowerValue
                }
            }
        }

        return false
    }
}

// Helper function to get display information
private func CoreDisplay_DisplayCreateInfoDictionary(_ display: CGDirectDisplayID) -> Unmanaged<CFDictionary>? {
    typealias CoreDisplay_DisplayCreateInfoDictionary = @convention(c) (CGDirectDisplayID) -> Unmanaged<CFDictionary>?

    guard let bundle = CFBundleGetBundleWithIdentifier("com.apple.CoreDisplay" as CFString),
          let functionPointer = CFBundleGetFunctionPointerForName(bundle, "CoreDisplay_DisplayCreateInfoDictionary" as CFString) else {
        return nil
    }

    let function = unsafeBitCast(functionPointer, to: CoreDisplay_DisplayCreateInfoDictionary.self)
    return function(display)
}
