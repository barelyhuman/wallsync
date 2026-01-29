//
//  wallsyncApp.swift
//  wallsync
//
//  Created by Reaper on 23/03/22.
//

import SwiftUI

@main
struct wallsyncApp: App {
    var body: some Scene {
            MenuBarExtra("WallSync", systemImage: "photo.on.rectangle") {
                ContentView()
            }
            .menuBarExtraStyle(.window)
    }
}
