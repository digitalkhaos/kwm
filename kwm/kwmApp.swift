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
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
