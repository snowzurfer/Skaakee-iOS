//
//  skaakeeApp.swift
//  skaakee
//
//  Created by Alberto on 2/14/24.
//

import SwiftUI
import RealityKitContent

@main
@MainActor
struct skaakeeApp: App {
    
    init() {
        UUIDComponent.registerComponent()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        WindowGroup(id: volumetricViewID) {
            ChessBoardGame(roomId: "visionPro")
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.7, height: 0.7, depth: 0.7, in: .meters)
    }
}
