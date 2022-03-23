//
//  wallsyncApp.swift
//  wallsync
//
//  Created by Reaper on 23/03/22.
//

import SwiftUI

@main
struct wallsyncApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
