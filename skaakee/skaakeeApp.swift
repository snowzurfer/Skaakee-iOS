//
//  skaakeeApp.swift
//  skaakee
//
//  Created by Alberto on 2/14/24.
//

import SwiftUI

@main
@MainActor
struct skaakeeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        WindowGroup(id: volumetricViewID) {
            ChessBoardGame(roomId: "visionPro")
        }
        .windowStyle(.volumetric)
    }
}
