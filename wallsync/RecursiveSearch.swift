import SwiftUI
import CoreData

func recursiveDirectorySearch(path: String)throws ->[ImageCollection] {
        var images = [ImageCollection]()
        
        let enumerator = FileManager.default.enumerator(atPath: path)
            while let item = enumerator?.nextObject() as? String {
                if let fType = enumerator?.fileAttributes?[FileAttributeKey.type] as? FileAttributeType{

                    switch fType{
                    case .typeRegular:
                        
                        if(item.hasSuffix(".jpg") || item.hasSuffix(".jpeg") || item.hasSuffix(".png")){
                            let fileUrl = URL(fileURLWithPath:path.appending("/"+item))
                            
                            do {
                                let attr = try FileManager.default.attributesOfItem(atPath: fileUrl.path)
                                let fileSize = attr[FileAttributeKey.size] as! UInt64
                            
                                let creationDate = attr[.creationDate] as! Date
                                
                                images.append(
                                    ImageCollection(
                                        url: fileUrl,
                                        size: fileSize,
                                        createdOn: creationDate
                                    )
                                )
                            } catch {
                                    throw error
                            }
                        }
                        
                    case .typeDirectory:
                        
                        do{
                            images.append(contentsOf: try recursiveDirectorySearch(path: item))
                        }catch{
                            throw error
                        }
                    default:
                        print("skipping...")
                    }
                }

            }
        return images
    }
