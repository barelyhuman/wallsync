//
//  ContentView.swift
//  wallsync
//
//  Created by Reaper on 23/03/22.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var wallpaperManager = WallpaperManager.shared

    var body: some View {
        VStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                StatusRow(
                    label: "Status",
                    value: wallpaperManager.isMonitoring ? "Monitoring" : "Stopped",
                    color: wallpaperManager.isMonitoring ? .green : .gray
                )
                
                StatusRow(
                    label: "Displays",
                    value: "\(wallpaperManager.getDisplayCount())",
                    color: .blue
                )
                
                StatusRow(
                    label: "Current",
                    value: wallpaperManager.currentWallpaper,
                    color: .primary
                )
                
                if let lastSync = wallpaperManager.lastSyncTime {
                    StatusRow(
                        label: "Last Sync",
                        value: timeAgoString(from: lastSync),
                        color: .secondary
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Actions
            VStack(spacing: 4) {
                MenuRow(
                    title: wallpaperManager.isMonitoring ? "Stop Monitoring" : "Start Monitoring",
                    icon: wallpaperManager.isMonitoring ? "pause.circle" : "play.circle"
                ) {
                    toggleMonitoring()
                }
                
                Divider().padding(.horizontal, 12)
                
                MenuRow(title: "Quit", icon: "xmark.circle") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.bottom, 4)
        }
        .frame(width: 280)
    }
    
    private func toggleMonitoring() {
        if wallpaperManager.isMonitoring {
            wallpaperManager.stopMonitoring()
        } else {
            wallpaperManager.startMonitoring()
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "\(seconds)s ago"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else {
            let hours = seconds / 3600
            return "\(hours)h ago"
        }
    }
}

// Status row component
struct StatusRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// Menu row button component
struct MenuRow: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .frame(width: 16)
                }

                Text(title)
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(background)
        }
        .padding(.horizontal, 6)
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var background: some View {
        Group {
            if isPressed {
                Color.accentColor.opacity(0.35)
            } else if isHovering {
                Color.accentColor.opacity(0.20)
            } else {
                Color.clear
            }
        }
        .cornerRadius(6)
    }
}

#Preview {
    ContentView()
}



