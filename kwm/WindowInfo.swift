//
//  WindowInfo.swift
//  kwm
//
//  Created by john on 10/6/25.
//

import Foundation
import ApplicationServices
import CoreGraphics
import Combine

/// Represents a window's position and size information
struct WindowInfo: Codable, Identifiable {
    let id: String
    let appName: String
    let windowTitle: String
    var frame: CGRect
    let displayID: CGDirectDisplayID?

    init(appName: String, windowTitle: String, frame: CGRect, displayID: CGDirectDisplayID? = nil) {
        self.id = "\(appName)_\(windowTitle)_\(UUID().uuidString)"
        self.appName = appName
        self.windowTitle = windowTitle
        self.frame = frame
        self.displayID = displayID
    }
}

/// Storage for saved window positions
class WindowPositionStore: ObservableObject {
    @Published var savedPositions: [WindowInfo] = []
    @Published var excludedApps: Set<String> = []
    @Published var autoDockControl: Bool = false

    private let positionsKey = "SavedWindowPositions"
    private let excludedAppsKey = "ExcludedApplications"
    private let autoDockControlKey = "AutoDockControl"

    init() {
        loadPositions()
        loadExcludedApps()
        loadAutoDockControl()
    }

    func savePositions(_ positions: [WindowInfo]) {
        self.savedPositions = positions
        if let encoded = try? JSONEncoder().encode(positions) {
            UserDefaults.standard.set(encoded, forKey: positionsKey)
        }
    }

    func loadPositions() {
        if let data = UserDefaults.standard.data(forKey: positionsKey),
           let decoded = try? JSONDecoder().decode([WindowInfo].self, from: data) {
            self.savedPositions = decoded
        }
    }

    func saveExcludedApps(_ apps: Set<String>) {
        self.excludedApps = apps
        let array = Array(apps)
        UserDefaults.standard.set(array, forKey: excludedAppsKey)
    }

    func loadExcludedApps() {
        if let array = UserDefaults.standard.stringArray(forKey: excludedAppsKey) {
            self.excludedApps = Set(array)
        }
    }

    func addExcludedApp(_ appName: String) {
        excludedApps.insert(appName)
        saveExcludedApps(excludedApps)
    }

    func removeExcludedApp(_ appName: String) {
        excludedApps.remove(appName)
        saveExcludedApps(excludedApps)
    }

    func isExcluded(_ appName: String) -> Bool {
        return excludedApps.contains(appName)
    }

    func clearPositions() {
        savedPositions = []
        UserDefaults.standard.removeObject(forKey: positionsKey)
    }

    func setAutoDockControl(_ enabled: Bool) {
        autoDockControl = enabled
        UserDefaults.standard.set(enabled, forKey: autoDockControlKey)
    }

    func loadAutoDockControl() {
        autoDockControl = UserDefaults.standard.bool(forKey: autoDockControlKey)
    }
}

/// Represents information about a running application
struct RunningApp: Identifiable {
    let id: String
    let name: String
    let pid: pid_t

    init(name: String, pid: pid_t) {
        self.id = "\(name)_\(pid)"
        self.name = name
        self.pid = pid
    }
}
