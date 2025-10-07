//
//  SettingsView.swift
//  kwm
//
//  Created by john on 10/6/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appController: AppController
    @StateObject private var positionStore: WindowPositionStore
    @State private var runningApps: [RunningApp] = []
    @State private var searchText = ""

    init() {
        _positionStore = StateObject(wrappedValue: WindowPositionStore())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("KWM Settings")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Configure window management behavior")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            Divider()

            // Settings Content
            Form {
                Section("Automatic Behavior") {
                    Toggle("Enable automatic window management", isOn: $appController.isEnabled)
                        .help("Automatically save/restore windows when monitors change")

                    Toggle("Auto-save positions when monitors connect", isOn: $appController.autoSaveOnConnect)
                        .disabled(!appController.isEnabled)
                        .help("Save window positions when external monitors are connected")

                    Toggle("Auto-zoom when monitors disconnect", isOn: $appController.autoZoomOnDisconnect)
                        .disabled(!appController.isEnabled)
                        .help("Zoom windows to fill screen when external monitors are removed")

                    Toggle("Auto-control dock visibility", isOn: Binding(
                        get: { appController.positionStore.autoDockControl },
                        set: { newValue in
                            appController.positionStore.setAutoDockControl(newValue)
                        }
                    ))
                        .disabled(!appController.isEnabled)
                        .help("Show dock when external monitors are connected, hide when disconnected")
                }

                Section("Excluded Applications") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select applications to exclude from window management:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("Search applications...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        List {
                            ForEach(filteredApps) { app in
                                HStack {
                                    Toggle(app.name, isOn: Binding(
                                        get: { appController.positionStore.isExcluded(app.name) },
                                        set: { isExcluded in
                                            if isExcluded {
                                                appController.positionStore.addExcludedApp(app.name)
                                            } else {
                                                appController.positionStore.removeExcludedApp(app.name)
                                            }
                                        }
                                    ))
                                    .toggleStyle(.checkbox)
                                }
                            }
                        }
                        .frame(height: 200)
                        .border(Color.gray.opacity(0.2))

                        Button("Refresh Application List") {
                            loadRunningApps()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Section("Saved Positions") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(appController.positionStore.savedPositions.count) window position(s) saved")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button("Clear All") {
                                appController.clearSavedPositions()
                            }
                            .buttonStyle(.bordered)
                            .disabled(appController.positionStore.savedPositions.isEmpty)
                        }

                        if !appController.positionStore.savedPositions.isEmpty {
                            List {
                                ForEach(appController.positionStore.savedPositions) { window in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(window.appName)
                                            .font(.headline)
                                        Text(window.windowTitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .frame(height: 150)
                            .border(Color.gray.opacity(0.2))
                        }
                    }
                }

                Section("Display Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Connected Displays:")
                                .fontWeight(.medium)
                            Text("\(appController.monitorManager.displayCount)")
                                .foregroundColor(.secondary)
                        }

                        ForEach(appController.monitorManager.displays) { display in
                            HStack {
                                Text(display.name)
                                    .font(.caption)
                                if display.isMain {
                                    Text("(Main)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Permissions") {
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Check Accessibility Permissions") {
                            appController.checkPermissions()
                        }
                        .buttonStyle(.bordered)

                        Text(appController.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .padding()
        }
        .frame(width: 600, height: 700)
        .onAppear {
            loadRunningApps()
            appController.requestNotificationPermissions()
        }
    }

    private var filteredApps: [RunningApp] {
        if searchText.isEmpty {
            return runningApps
        } else {
            return runningApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func loadRunningApps() {
        runningApps = appController.getRunningApplications().sorted { $0.name < $1.name }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppController())
}
