//
//  ContentView.swift
//  wallsync
//
//  Created by Reaper on 23/03/22.
//

import SwiftUI
import CoreData
import AppKit


struct ImageCollection:Hashable,Equatable {
    var id = UUID()
    var url: URL
    var size: UInt64
    var createdOn: Date
    
    static func == (lhs: ImageCollection, rhs: ImageCollection) -> Bool {
        return lhs.url.path == rhs.url.path
    }
}



struct ContentView: View {
    @StateObject private var folderManager = FolderManager()
    @State private var recentSort = 1
    @State private var alphabetSort = -1
    @State private var sizeSort = 1
    @State private var hasError = false
    @State private var errorMessage = ""
    @State private var showingFolderSelector = false
    
    var body: some View {
        if #available(macOS 13.0, *) {
            NavigationSplitView {
                // Sidebar
                VStack(spacing: 0) {
                    List {
                        ForEach(folderManager.trackedFolders, id: \.objectID) { folder in
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                Text(URL(fileURLWithPath: folder.path ?? "").lastPathComponent)
                                    .lineLimit(1)
                            }
                            .help(folder.path ?? "")
                            .contextMenu {
                                Button(role: .destructive) {
                                    folderManager.removeFolder(folder)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    
                    // Add folder button at bottom
                    Divider()
                    Button(action: {
                        showingFolderSelector = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Folder")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
            } detail: {
                // Detail View - Image Grid
                ScrollViewReader { scrollProxy in
                    VStack {
                        if folderManager.isLoading {
                            ProgressView("Loading images...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if folderManager.trackedFolders.isEmpty {
                            Text("Add a folder to get started")
                                .font(.title)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if folderManager.allImages.isEmpty {
                            Text("No images found in tracked folders")
                                .font(.title)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVStack {
                                    ForEach(folderManager.allImages, id: \.id) { imageCol in
                                        Button(action: {
                                            self.setWall(imageUrl: imageCol.url)
                                        }) {
                                            AsyncImage(url: imageCol.url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView().frame(width: 300, height: 200)
                                                case .success(let image):
                                                    image.resizable()
                                                case .failure:
                                                    Image(systemName: "exclamationmark.triangle")
                                                        .resizable()
                                                        .padding(100)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            .aspectRatio(contentMode: .fit)
                                            .cornerRadius(6)
                                        }
                                        .id(imageCol.id)
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
                                        
                                        VStack(alignment: .leading) {
                                            Text(getStringSize(size: Int64(imageCol.size)))
                                                .font(.caption)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                                            Text("\(imageCol.createdOn)")
                                                .font(.caption)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                                        }
                                    }
                                }
                                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                            }
                        }
                    }
                    .alert(isPresented: $hasError) {
                        Alert(title: Text("Error"), message: Text(errorMessage))
                    }
                    .frame(minWidth: 500, minHeight: 500)
                    .toolbar {
                        Spacer()
                        Menu {
                            Button(action: {
                                folderManager.allImages = folderManager.allImages.sorted { itemA, itemB in
                                    return sortByCreation(itemA: itemA, itemB: itemB, direction: recentSort)
                                }
                                recentSort = recentSort == 1 ? -1 : 1
                                toTop(scroller: scrollProxy)
                            }) {
                                Text("Recent")
                                if recentSort == 1 {
                                    Image(systemName: "arrow.down")
                                } else {
                                    Image(systemName: "arrow.up")
                                }
                            }
                            Button(action: {
                                folderManager.allImages = folderManager.allImages.sorted { itemA, itemB in
                                    return sortByName(itemA: itemA, itemB: itemB, direction: alphabetSort)
                                }
                                alphabetSort = alphabetSort == 1 ? -1 : 1
                                toTop(scroller: scrollProxy)
                            }) {
                                Text("Alphabetically")
                                if alphabetSort == 1 {
                                    Image(systemName: "arrow.down")
                                } else {
                                    Image(systemName: "arrow.up")
                                }
                            }
                            Button(action: {
                                folderManager.allImages = folderManager.allImages.sorted { itemA, itemB in
                                    return sortBySize(itemA: itemA, itemB: itemB, direction: sizeSort)
                                }
                                sizeSort = sizeSort == 1 ? -1 : 1
                                toTop(scroller: scrollProxy)
                            }) {
                                Text("Size")
                                if sizeSort == 1 {
                                    Image(systemName: "arrow.down")
                                } else {
                                    Image(systemName: "arrow.up")
                                }
                            }
                        } label: {
                            Text("Sort By")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFolderSelector) {
                FolderSelectorSheet(folderManager: folderManager, isPresented: $showingFolderSelector)
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
func setWall(imageUrl: URL) {
        var options = [NSWorkspace.DesktopImageOptionKey: Any]()
        
        options[.imageScaling] = NSImageScaling.scaleProportionallyUpOrDown.rawValue
        options[.allowClipping] = true
        
        for screen in NSScreen.screens {
            try! NSWorkspace.shared.setDesktopImageURL(imageUrl, for: screen, options: options)
        }
    }
    
    func toTop(scroller: ScrollViewProxy) {
        guard !folderManager.allImages.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation {
                scroller.scrollTo(folderManager.allImages.first!.id, anchor: .top)
            }
        }
    }
    
    func sortByName(itemA: ImageCollection, itemB: ImageCollection, direction: Int) -> Bool {
        if direction == 1 {
            return itemA.url.path > itemB.url.path
        } else {
            return itemA.url.path < itemB.url.path
        }
    }
    
    func sortByCreation(itemA: ImageCollection, itemB: ImageCollection, direction: Int) -> Bool {
        if direction == 1 {
            return itemA.createdOn > itemB.createdOn
        } else {
            return itemA.createdOn < itemB.createdOn
        }
    }
    
    func sortBySize(itemA: ImageCollection, itemB: ImageCollection, direction: Int) -> Bool {
        if direction == 1 {
            return itemA.size > itemB.size
        } else {
            return itemA.size < itemB.size
        }
    }
    
    func getStringSize(size: Int64) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: size)
    }
}

// MARK: - Folder Selector Sheet

struct FolderSelectorSheet: View {
    @ObservedObject var folderManager: FolderManager
    @Binding var isPresented: Bool
    @State private var hasError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select a folder to track")
                .font(.headline)
            
            Button("Choose Folder") {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = true
                
                if panel.runModal() == .OK, let url = panel.url {
                    do {
                        try folderManager.addFolder(url: url)
                        isPresented = false
                    } catch {
                        errorMessage = "Failed to add folder: \(error.localizedDescription)"
                        hasError = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") {
                isPresented = false
            }
            .buttonStyle(.bordered)
        }
        .padding(30)
        .frame(width: 400, height: 200)
        .alert(isPresented: $hasError) {
            Alert(title: Text("Error"), message: Text(errorMessage))
        }
    }
}



