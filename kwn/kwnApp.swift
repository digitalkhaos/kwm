//
//  kwnApp.swift
//  kwn
//
//  Created by john on 10/4/25.
//

import SwiftUI
import Combine

@main
@MainActor
struct kwnApp: App {    
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Menu bar only app - no main window
        MenuBarExtra("kwn", systemImage: "rectangle.on.rectangle") {
            MenuBarView(
                menuBarController: appState.menuBarController,
                permissionsManager: appState.permissionsManager,
                displayMonitor: appState.displayMonitor,
                layoutStorage: appState.layoutStorage
            )
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
class AppState: ObservableObject {
    let displayMonitor: DisplayMonitor
    let windowManager: WindowManager
    let layoutStorage: LayoutStorage
    let permissionsManager: PermissionsManager
    let menuBarController: MenuBarController

    init() {
        self.displayMonitor = DisplayMonitor()
        self.windowManager = WindowManager()
        self.layoutStorage = LayoutStorage()
        self.permissionsManager = PermissionsManager()
        self.menuBarController = MenuBarController(
            displayMonitor: displayMonitor,
            windowManager: windowManager,
            layoutStorage: layoutStorage,
            permissionsManager: permissionsManager
        )
    }
}
