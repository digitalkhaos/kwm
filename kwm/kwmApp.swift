//
//  kwmApp.swift
//  kwm
//
//  Created by john on 10/6/25.
//

import SwiftUI
import CoreData

@main
struct kwmApp: App {
    @StateObject private var appController = AppController()

    var body: some Scene {
        MenuBarExtra("KWM", systemImage: "display.2") {
            MenuBarView()
                .environmentObject(appController)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appController)
        }
    }
}
