//
//  skaakeeApp.swift
//  skaakee
//
//  Created by Alberto on 2/14/24.
//

import SwiftUI

@main
struct skaakeeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
