//
//  FolderManager.swift
//  wallsync
//
//  Created on 30/12/25.
//

import SwiftUI
import CoreData

class FolderManager: ObservableObject {
    @Published var trackedFolders: [TrackedFolder] = []
    @Published var allImages: [ImageCollection] = []
    @Published var isLoading: Bool = false
    
    private var activeAccessedURLs: Set<URL> = []
    private let persistence: PersistenceController
    
    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        loadTrackedFolders()
    }
    
    deinit {
        // Stop accessing all security-scoped resources
        stopAllSecurityScopedAccess()
    }
    
    // MARK: - Folder Management
    
    func loadTrackedFolders() {
        do {
            trackedFolders = try persistence.fetchFolders()
            refreshAllImages()
        } catch {
            print("Error loading tracked folders: \(error)")
        }
    }
    
    func addFolder(url: URL) throws {
        // Create security-scoped bookmark
        guard let bookmarkData = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else {
            throw NSError(domain: "FolderManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create bookmark"])
        }
        
        // Add to Core Data
        try persistence.addFolder(url: url, bookmarkData: bookmarkData)
        
        // Reload folders and refresh images
        loadTrackedFolders()
    }
    
    func removeFolder(_ folder: TrackedFolder) {
        // Stop accessing security-scoped resource if active
        if let url = resolveBookmark(folder.bookmarkData!) {
            stopSecurityScopedAccess(for: url)
        }
        
        do {
            try persistence.removeFolder(folder)
            loadTrackedFolders()
        } catch {
            print("Error removing folder: \(error)")
        }
    }
    
    // MARK: - Image Aggregation
    
    func refreshAllImages() {
        isLoading = true
        allImages = []
        
        // Aggregate images from all tracked folders
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var aggregatedImages: [ImageCollection] = []
            var seenPaths = Set<String>()
            
            for folder in self.trackedFolders {
                if let url = self.resolveBookmark(folder.bookmarkData!) {
                    // Start accessing security-scoped resource
                    if url.startAccessingSecurityScopedResource() {
                        self.activeAccessedURLs.insert(url)
                        
                        // Search for images in this folder
                        do {
                            let folderImages = try recursiveDirectorySearch(path: url.path)
                            // Deduplicate by file path
                            for image in folderImages {
                                let path = image.url.path
                                if !seenPaths.contains(path) {
                                    seenPaths.insert(path)
                                    aggregatedImages.append(image)
                                }
                            }
                        } catch {
                            print("Error searching folder \(url.path): \(error)")
                        }
                    }
                }
            }
            
            // Update on main thread
            DispatchQueue.main.async {
                self.allImages = aggregatedImages
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Security-Scoped Resource Management
    
    private func resolveBookmark(_ bookmarkData: Data) -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }
        
        return isStale ? nil : url
    }
    
    private func stopSecurityScopedAccess(for url: URL) {
        if activeAccessedURLs.contains(url) {
            url.stopAccessingSecurityScopedResource()
            activeAccessedURLs.remove(url)
        }
    }
    
    private func stopAllSecurityScopedAccess() {
        for url in activeAccessedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        activeAccessedURLs.removeAll()
    }
}
