//
//  LayoutStorage.swift
//  kwn
//
//  Handles persistent storage of window layouts
//

import Foundation
import Combine

@MainActor
class LayoutStorage: ObservableObject {
    @Published var savedLayouts: [WindowLayout] = []

    private let storageURL: URL

    init() {
        // Store in Application Support directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("kwn", isDirectory: true)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        storageURL = appFolder.appendingPathComponent("layouts.json")

        loadLayouts()
    }

    func saveLayout(_ layout: WindowLayout) {
        // Check if we already have a layout for this configuration
        if let existingIndex = savedLayouts.firstIndex(where: { $0.configuration.matches(layout.configuration) }) {
            // Replace existing layout
            savedLayouts[existingIndex] = layout
        } else {
            // Add new layout
            savedLayouts.append(layout)
        }

        persistLayouts()
    }

    func deleteLayout(_ layout: WindowLayout) {
        savedLayouts.removeAll { $0.savedAt == layout.savedAt }
        persistLayouts()
    }

    func findLayoutForConfiguration(_ configuration: DisplayConfiguration) -> WindowLayout? {
        return savedLayouts.first { $0.configuration.matches(configuration) }
    }

    private func loadLayouts() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            savedLayouts = try decoder.decode([WindowLayout].self, from: data)
        } catch {
            print("Failed to load layouts: \(error)")
        }
    }

    private func persistLayouts() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(savedLayouts)
            try data.write(to: storageURL)
        } catch {
            print("Failed to save layouts: \(error)")
        }
    }

    func getLayoutCount() -> Int {
        return savedLayouts.count
    }

    func getAllLayouts() -> [WindowLayout] {
        return savedLayouts.sorted { $0.savedAt > $1.savedAt }
    }
}

