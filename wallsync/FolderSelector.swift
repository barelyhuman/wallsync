//
//  FolderSelector.swift
//  wallsync
//
//  Created by Reaper on 23/03/22.
//

import SwiftUI
import CoreData





struct FolderSelector: View {
    @ObservedObject var selectedFolder:SelectedFolder
    var onChange:()->Void
    
    var body: some View {
        Button(action:self.selectFolder) {
                Image(systemName: "folder.fill")
            Text("Choose Folder")
        }
    }
    
    
    func selectFolder() {
        let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = true
                if panel.runModal() == .OK {
                    self.selectedFolder.foldername = panel.url?.path ?? "<none>"
                    onChange()
                }
    }

}
