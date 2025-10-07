//
//  MenuBarView.swift
//  kwm
//
//  Created by john on 10/6/25.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appController: AppController

    var body: some View {
        VStack(spacing: 0) {
            // Status Section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: appController.isEnabled ? "circle.fill" : "circle")
                        .foregroundColor(appController.isEnabled ? .green : .gray)
                        .font(.system(size: 10))

                    Text(appController.isEnabled ? "Active" : "Inactive")
                        .font(.headline)
                }

                Text(appController.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !appController.lastAction.isEmpty {
                    Text("Last: \(appController.lastAction)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Display Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "display.2")
                        .foregroundColor(.blue)
                    Text("Displays: \(appController.monitorManager.displayCount)")
                        .font(.caption)
                }

                HStack {
                    Image(systemName: "archivebox")
                        .foregroundColor(.orange)
                    Text("Saved: \(appController.positionStore.savedPositions.count) windows")
                        .font(.caption)
                }

                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                    Text("Excluded: \(appController.positionStore.excludedApps.count) apps")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Manual Actions
            VStack(spacing: 0) {
                Button(action: {
                    appController.saveCurrentWindowPositions()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save Window Positions")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(MenuBarButtonStyle())

                Button(action: {
                    appController.restoreWindowPositions()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Restore Positions")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(MenuBarButtonStyle())
                .disabled(appController.positionStore.savedPositions.isEmpty)

                Button(action: {
                    appController.zoomAllWindows()
                }) {
                    HStack {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                        Text("Zoom All Windows")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(MenuBarButtonStyle())

                Divider()

                Button(action: {
                    appController.toggleEnabled()
                }) {
                    HStack {
                        Image(systemName: appController.isEnabled ? "pause.circle" : "play.circle")
                        Text(appController.isEnabled ? "Disable Auto Mode" : "Enable Auto Mode")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(MenuBarButtonStyle())

                Divider()

                SettingsLink {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings...")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(MenuBarButtonStyle())

                Divider()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit KWM")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(MenuBarButtonStyle())
            }
        }
        .frame(width: 280)
    }
}

/// Custom button style for menu bar items
struct MenuBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.2) : Color.clear)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppController())
}
