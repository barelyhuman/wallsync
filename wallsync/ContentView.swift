//
//  ContentView.swift
//  wallsync
//
//  Created by Reaper on 23/03/22.
//

import SwiftUI
import CoreData
import AppKit



class SelectedFolder:ObservableObject {
    @Published var foldername = "<none>"
}

func ==(lhs: SelectedFolder, rhs: SelectedFolder) -> Bool {
    return lhs.foldername == rhs.foldername
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

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
    @StateObject var selectedFolder=SelectedFolder()
    @State var images=[ImageCollection]();
    @State var recentSort = 1
    @State var alphabetSort = -1
    @State var sizeSort = 1
    @State var hasError = false
    @State var errorMessage=""
    @State private var activeAccessedURL: URL? = nil

    var folders = RecentFolders.list()
    
    var body: some View {
        ScrollViewReader{scrollProxy in
            VStack{
                if(images.count == 0){
                    if(folders.count == 0){
                        Text("Select a folder to scan").font(.title).foregroundColor(.gray)
                    }else{
                        ForEach(folders, id: \.self) { folder in
                        Button(action:{
                            self.selectedFolder.foldername = folder.path
                        }){
                            Text(folder.path).frame(maxWidth: .infinity, alignment: .leading).padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                        }.buttonStyle(PlainButtonStyle())
                    }
                    }
                }else{
                    ScrollView{
                        LazyVStack{
                            ForEach(images, id: \.id) { imageCol in
                                Button(action:{
                                    self.setWall(imageUrl:imageCol.url)
                                }){
                                    AsyncImage(
                                        url: imageCol.url
                                    ) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView().frame(width: 300, height: 200)
                                        case .success(let image):
                                            image
                                                .resizable()
                                        case .failure:
                                            Image(systemName: "exclamationmark.triangle")
                                                .resizable()
                                                .padding(100)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }

                                    .aspectRatio( contentMode: .fit)
                                    .cornerRadius(6)
                                                                        
                                    
                                }
                                .id(imageCol.id)
                                .buttonStyle(PlainButtonStyle())
                                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
                                
                                VStack(alignment: .leading){
                                    Text(getStringSize(size:Int64(imageCol.size))).font(.caption).frame(maxWidth: .infinity, alignment: .leading).padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                                    Text("\(imageCol.createdOn)").font(.caption).frame(maxWidth: .infinity, alignment: .leading).padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                                }
                                
                            }
                        }
                        .padding(EdgeInsets(top:10, leading: 0, bottom: 0, trailing: 0))
                    }
                    
                }
            }
            .onChange(of: selectedFolder.foldername) { newValue in
                // Stop previous access if any
                if let prev = activeAccessedURL, prev.path != newValue {
                    prev.stopAccessingSecurityScopedResource()
                    activeAccessedURL = nil
                }

                guard !newValue.isEmpty, newValue != "<none>" else {
                    return
                }

                let url = URL(fileURLWithPath: newValue)
                // If already active, nothing to do
                if activeAccessedURL?.path == url.path { return }

                // Attempt to start security-scoped access and show an error on failure
                guard url.startAccessingSecurityScopedResource() else {
                    DispatchQueue.main.async {
                        self.hasError = true
                        self.errorMessage = "Failed to gain access to the selected folder."
                    }
                    return
                }

                activeAccessedURL = url

                // Trigger a fresh scan now that access is held
                self.images = []
                self.searchForImages()
            }
            .alert( isPresented: $hasError){
                Alert(title: Text("Error") ,message: Text(errorMessage) )
            }
            .frame(minWidth:500,minHeight:500)
            .toolbar{
                Spacer()
                Menu {
                    Button(action:{
                        self.images = self.images.sorted{itemA,itemB in
                            return sortByCreation(itemA: itemA, itemB: itemB, direction: recentSort)
                        }
                        recentSort = recentSort == 1 ? -1 : 1
                        toTop(scroller:scrollProxy)
                    }) {
                        Text("Recent")
                        if(recentSort == 1){
                            Image(systemName: "arrow.down")
                        }else{
                            Image(systemName: "arrow.up")
                        }
                    }
                    Button(action:{
                        self.images = self.images.sorted { itemA,itemB in
                            return sortByName(itemA:itemA,itemB: itemB,direction: alphabetSort)
                        }
                        alphabetSort = alphabetSort == 1 ? -1 : 1
                        toTop(scroller:scrollProxy)
                    }){
                        Text("Alphabetically")
                        if(alphabetSort == 1){
                            Image(systemName: "arrow.down")
                        }else{
                            Image(systemName: "arrow.up")
                        }
                    }
                    Button(action:{
                        self.images = self.images.sorted{itemA,itemB in
                            return sortBySize(itemA: itemA, itemB: itemB, direction: sizeSort)
                        }
                        sizeSort = sizeSort == 1 ? -1 : 1
                        toTop(scroller:scrollProxy)
                    }){
                        Text("Size")
                        if(sizeSort == 1){
                            Image(systemName: "arrow.down")
                        }else{
                            Image(systemName: "arrow.up")
                        }
                    }
                } label: {
                    Text("Sort By")
                }
                FolderSelector(selectedFolder:selectedFolder,onChange:{
                    self.images=[]
                })
            }
            .onDisappear {
                if let prev = activeAccessedURL {
                    prev.stopAccessingSecurityScopedResource()
                    activeAccessedURL = nil
                }
            }
        }
        
    }
    
    func hasNewImages(old:ImageCollection,new:ImageCollection) -> Bool{
        return old.url.path == new.url.path
    }
    
    
    func setWall(imageUrl:URL){
        var options = [NSWorkspace.DesktopImageOptionKey: Any]()
        
        options[.imageScaling] = NSImageScaling.scaleProportionallyUpOrDown.rawValue
        options[.allowClipping] = true
        
        for screen in NSScreen.screens{
            try! NSWorkspace.shared.setDesktopImageURL(imageUrl, for: screen, options: options)
        }
    }
    
    func toTop(scroller:ScrollViewProxy){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation{
                scroller.scrollTo(self.images.first!.id,anchor: .top)
            }
        }
    }

    
    func searchForImages(){
        let path = self.selectedFolder.foldername;
        var images = [ImageCollection]()
        do{
            images = try recursiveDirectorySearch(path: path)
        }catch {
            print("Error info: \(error)")
            self.hasError = true
            self.errorMessage = "Failed to open the folder"
        }
        
        
        self.images = images.sorted { itemA,itemB in
            return sortByName(itemA:itemA,itemB: itemB,direction: 1)
        }
        
    }

    
    func sortByName(itemA:ImageCollection,itemB:ImageCollection,direction:Int)->Bool{
        if(direction == 1){
            return itemA.url.path  > itemB.url.path
        }else{
            return itemA.url.path  < itemB.url.path
        }
    }
    
    func sortByCreation(itemA:ImageCollection,itemB:ImageCollection,direction:Int)->Bool{
        if(direction == 1){
            return itemA.createdOn > itemB.createdOn
        }else{
            return itemA.createdOn < itemB.createdOn
        }
    }
    
    func sortBySize(itemA:ImageCollection,itemB:ImageCollection,direction:Int)->Bool{
        if(direction == 1){
            return itemA.size > itemB.size
        }else{
            return itemA.size < itemB.size
        }
    }
    
    func getStringSize(size:Int64)->String{
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: size)
    }
}



