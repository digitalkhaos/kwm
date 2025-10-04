//
//  MenuBarView.swift
//  kwn
//
//  SwiftUI interface for the menu bar
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var menuBarController: MenuBarController
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var displayMonitor: DisplayMonitor
    @ObservedObject var layoutStorage: LayoutStorage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status
            HStack {
                Image(systemName: displayMonitor.isDocked ? "display.2" : "laptopcomputer")
                Text(displayMonitor.isDocked ?
                     "Docked (\(displayMonitor.currentConfiguration.externalDisplayCount) display\(displayMonitor.currentConfiguration.externalDisplayCount == 1 ? "" : "s"))" :
                     "Undocked")
                    .font(.headline)
            }
            .padding(.bottom, 4)

            Divider()

            // Permissions
            if !permissionsManager.hasAccessibilityPermission {
                Button(action: {
                    permissionsManager.requestAccessibilityPermission()
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Grant Accessibility Permission")
                    }
                }
                .buttonStyle(.plain)

                Divider()
            }

            // Save Layout
            Button(action: {
                menuBarController.saveCurrentLayout()
            }) {
                Label("Save Current Layout", systemImage: "square.and.arrow.down")
            }
            .disabled(!permissionsManager.hasAccessibilityPermission)
            .help("Save window positions for current display configuration")

            // Restore Layout
            if let layout = layoutStorage.findLayoutForConfiguration(displayMonitor.currentConfiguration) {
                Button(action: {
                    menuBarController.restoreLayout()
                }) {
                    Label("Restore Layout", systemImage: "arrow.clockwise")
                }
                .disabled(!permissionsManager.hasAccessibilityPermission)
                .help("Restore saved window positions")

                Text("Saved: \(layout.savedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 24)
            } else {
                Text("No layout saved for this configuration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 24)
            }

            Divider()

            // Zoom All
            Button(action: {
                menuBarController.zoomAllWindows()
            }) {
                Label("Zoom All Windows", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .disabled(!permissionsManager.hasAccessibilityPermission)
            .help("Maximize all windows")

            Divider()

            // Auto-restore toggle
            Toggle(isOn: $menuBarController.isAutoRestoreEnabled) {
                Label("Auto-Restore on Dock", systemImage: "arrow.triangle.2.circlepath")
            }
            .onChange(of: menuBarController.isAutoRestoreEnabled) { newValue in
                UserDefaults.standard.set(newValue, forKey: "autoRestoreEnabled")
            }
            .help("Automatically restore window layout when docking")

            // Auto-zoom toggle
            Toggle(isOn: $menuBarController.isAutoZoomEnabled) {
                Label("Auto-Zoom on Undock", systemImage: "arrow.up.backward.and.arrow.down.forward")
            }
            .onChange(of: menuBarController.isAutoZoomEnabled) { newValue in
                UserDefaults.standard.set(newValue, forKey: "autoZoomEnabled")
            }
            .help("Automatically zoom windows when undocking")

            Divider()

            // Manage Layouts
            Button(action: {
                menuBarController.showManageLayouts()
            }) {
                Label("Manage Layouts", systemImage: "list.bullet.rectangle")
            }

            Text("\(layoutStorage.getLayoutCount()) saved layout\(layoutStorage.getLayoutCount() == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 24)

            Divider()

            // Quit
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit kwn", systemImage: "xmark.circle")
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(minWidth: 280)
    }
}

#Preview {
    MenuBarView(
        menuBarController: MenuBarController(
            displayMonitor: DisplayMonitor(),
            windowManager: WindowManager(),
            layoutStorage: LayoutStorage(),
            permissionsManager: PermissionsManager()
        ),
        permissionsManager: PermissionsManager(),
        displayMonitor: DisplayMonitor(),
        layoutStorage: LayoutStorage()
    )
}
