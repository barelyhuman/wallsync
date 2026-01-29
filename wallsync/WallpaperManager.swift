//
//  WallpaperManager.swift
//  wallsync
//
//  Created by Siddharth Gelera on 29/01/26.
//

import AppKit
import Combine
import SwiftUI

class WallpaperManager: ObservableObject {
    static let shared = WallpaperManager()

    @Published var isMonitoring: Bool = false
    @Published var lastSyncTime: Date?
    @Published var currentWallpaper: String = "Detecting..."
    @Published var syncedDisplayCount: Int = 0

    private var previousScreenCount: Int = 0
    private var screenChangeObserver: NSObjectProtocol?
    private var wallpaperMonitorTimer: Timer?
    private var lastKnownWallpapers: [String: URL] = [:]
    private var isSyncing: Bool = false

    private init() {
        previousScreenCount = NSScreen.screens.count
        setupScreenChangeObserver()
        
        // Start monitoring after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.startMonitoring()
        }
    }

    deinit {
        stopMonitoring()
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // Set up observer for screen configuration changes
    private func setupScreenChangeObserver() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenConfigurationChange()
        }
    }
    
    // Start monitoring for wallpaper changes
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        print("Starting wallpaper monitoring...")
        isMonitoring = true
        updateLastKnownWallpapers()
        
        // Poll every 2 seconds for changes
        wallpaperMonitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForWallpaperChanges()
        }
        
        print("Wallpaper monitoring started")
    }
    
    // Stop monitoring
    func stopMonitoring() {
        wallpaperMonitorTimer?.invalidate()
        wallpaperMonitorTimer = nil
        isMonitoring = false
        print("Wallpaper monitoring stopped")
    }
    
    // Update the current state of all wallpapers
    private func updateLastKnownWallpapers() {
        lastKnownWallpapers.removeAll()
        
        for screen in NSScreen.screens {
            if let url = try? NSWorkspace.shared.desktopImageURL(for: screen) {
                lastKnownWallpapers[screen.localizedName] = url
            }
        }
        
        // Update current wallpaper display
        if let firstURL = lastKnownWallpapers.values.first {
            currentWallpaper = firstURL.lastPathComponent
        }
    }
    
    // Check for wallpaper changes and sync if needed
    private func checkForWallpaperChanges() {
        guard !isSyncing else { return }
        
        var changedScreen: NSScreen?
        var changedURL: URL?
        
        // Check each screen for changes
        for screen in NSScreen.screens {
            guard let currentURL = try? NSWorkspace.shared.desktopImageURL(for: screen) else {
                continue
            }
            
            let screenID = screen.localizedName
            
            if let lastURL = lastKnownWallpapers[screenID], lastURL != currentURL {
                print("Wallpaper change detected on \(screenID): \(currentURL.lastPathComponent)")
                changedScreen = screen
                changedURL = currentURL
                break
            }
        }
        
        // If a change was detected, sync to all other screens
        if let screen = changedScreen, let url = changedURL {
            syncWallpaperToAllScreens(from: screen, url: url)
        }
    }
    
    // Sync wallpaper from one screen to all others
    private func syncWallpaperToAllScreens(from sourceScreen: NSScreen, url: URL) {
        isSyncing = true
        defer { isSyncing = false }
        
        let screens = NSScreen.screens
        var syncCount = 0
        
        print("Syncing wallpaper '\(url.lastPathComponent)' to all displays...")
        
        for screen in screens {
            do {
                try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
                lastKnownWallpapers[screen.localizedName] = url
                syncCount += 1
                print("  ✓ Synced to \(screen.localizedName)")
            } catch {
                print("  ✗ Failed to sync to \(screen.localizedName): \(error.localizedDescription)")
            }
        }
        
        // Update published properties
        currentWallpaper = url.lastPathComponent
        syncedDisplayCount = syncCount
        lastSyncTime = Date()
        
        print("Sync complete: \(syncCount)/\(screens.count) displays updated")
    }

    // Handle screen configuration changes (new monitor connected/disconnected)
    private func handleScreenConfigurationChange() {
        let currentScreenCount = NSScreen.screens.count

        if currentScreenCount != previousScreenCount {
            if currentScreenCount > previousScreenCount {
                print("New monitor detected: \(currentScreenCount - previousScreenCount) screen(s) added")
            } else {
                print("Monitor disconnected: \(previousScreenCount - currentScreenCount) screen(s) removed")
            }
            
            // Update our tracking and trigger a sync
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.syncToCurrentWallpaper()
            }
        }

        previousScreenCount = currentScreenCount
    }
    
    // Sync all screens to match the first screen's wallpaper
    private func syncToCurrentWallpaper() {
        guard let firstScreen = NSScreen.screens.first,
              let wallpaperURL = try? NSWorkspace.shared.desktopImageURL(for: firstScreen) else {
            return
        }
        
        syncWallpaperToAllScreens(from: firstScreen, url: wallpaperURL)
    }
    
    // Get number of connected displays
    func getDisplayCount() -> Int {
        return NSScreen.screens.count
    }
}
