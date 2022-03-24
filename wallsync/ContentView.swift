//
//  ContentView.swift
//  wallsync
//
//  Created by Reaper on 23/03/22.
//

import SwiftUI
import CoreData



class SelectedFolder:ObservableObject {
    @Published var foldername = "<none>"
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


struct ContentView: View {
    @StateObject var selectedFolder=SelectedFolder()
    @State var images=[URL]();
    
    var body: some View {
        
        VStack{
            if(images.count == 0){
                Text("Select a folder to scan").font(.title).foregroundColor(.gray)
            }else{
                ScrollView{
                    LazyVStack{
                        
                        ForEach(images, id: \.self) { imageUrl in
                            
                            Button(action:{
                                self.setWall(imageUrl:imageUrl)
                            }){
                                
                                AsyncImage(url:imageUrl) { image in
                                    image.resizable().aspectRatio(contentMode: .fit).transition(.slide)
                                } placeholder: {
                                    ProgressView().frame(minWidth:300,minHeight: 200)
                                }.aspectRatio( contentMode: .fit).cornerRadius(6)
                                
                            }.buttonStyle(PlainButtonStyle())
                                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
                            
                        }
                        
                    }
                    
                }.padding(EdgeInsets(top:10, leading: 0, bottom: 0, trailing: 0))
            }
        }
        
        .frame(minWidth:500,minHeight:500)
        .toolbar{
            Spacer()
            FolderSelector(selectedFolder:selectedFolder,onChange:{
                self.images=[]
                self.searchForImages()
            })
        }
    }
    
    
    func setWall(imageUrl:URL){
        var options = [NSWorkspace.DesktopImageOptionKey: Any]()
        
        options[.imageScaling] = NSImageScaling.scaleProportionallyUpOrDown.rawValue
        options[.allowClipping] = true
        
        for screen in NSScreen.screens{
            try! NSWorkspace.shared.setDesktopImageURL(imageUrl, for: screen, options: options)
        }
    }
    
    func searchForImages(){
        let path = self.selectedFolder.foldername;
        let fm = FileManager.default
        let items = try! fm.contentsOfDirectory(atPath: path)
        
        for item in items {
            if(item.hasSuffix(".jpg")){
                let fileUrl = URL(fileURLWithPath:path.appending("/"+item))
                self.images.append(fileUrl)
            }
        }
        
        self.images = self.images.sorted {
            
            let c1 = $0.pathComponents.count - 1
            let c2 = $1.pathComponents.count - 1
            
            
            let v1 = $0.pathComponents[c1].components(separatedBy: ".")
            let v2 = $1.pathComponents[c2].components(separatedBy: ".")
            
            
            
            return (Int(v1[0]) ?? -1) < (Int(v2[0]) ?? -1)
            
        }
        
    }
    
    
    
}



