//
//  Persistence.swift
//  wallsync
//
//  Created by Reaper on 23/03/22.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Preview with sample tracked folders
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "wallsync")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Tracked Folder Operations
    
    func addFolder(url: URL, bookmarkData: Data) throws {
        let context = container.viewContext
        
        // Check if folder already exists by path
        let fetchRequest: NSFetchRequest<TrackedFolder> = TrackedFolder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "path == %@", url.path)
        
        if let existing = try? context.fetch(fetchRequest).first {
            // Folder already tracked, skip
            return
        }
        
        let folder = TrackedFolder(context: context)
        folder.id = UUID()
        folder.path = url.path
        folder.bookmarkData = bookmarkData
        folder.dateAdded = Date()
        
        try context.save()
    }
    
    func removeFolder(_ folder: TrackedFolder) throws {
        let context = container.viewContext
        context.delete(folder)
        try context.save()
    }
    
    func fetchFolders() throws -> [TrackedFolder] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<TrackedFolder> = TrackedFolder.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrackedFolder.dateAdded, ascending: true)]
        
        return try context.fetch(fetchRequest)
    }
}
