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
                .onAppear {
                    DispatchQueue.main.async {
                        NSApplication.shared.windows.forEach { window in
                            window.styleMask = [.titled, .closable, .miniaturizable]
                        }
                    }
                }
        }.windowStyle(HiddenTitleBarWindowStyle())
    }
}
