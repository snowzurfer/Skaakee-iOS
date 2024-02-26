//
//  ContentView.swift
//  skaakee
//
//  Created by Alberto on 2/14/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var showWindow = false
    @State private var windowIsShown = false

    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow

    var body: some View {
        VStack {
//            Model3D(named: "Scene", bundle: realityKitContentBundle)
//                .padding(.bottom, 50)
            VStack {
                Text("Welcome to Skaakee!").font(.extraLargeTitle)
                    .foregroundStyle(.black)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color.white)

            VStack {
                Button {
                    print("start new room")
                    openWindow(id: volumetricViewID)
                    windowIsShown = true
                } label: {
                    Text("Start Game")
                }.buttonStyle(.bordered)
                
                Button {
                    print("enter room code")
                } label: {
                    Text("Enter Game Code")
                }
            }
            .frame(maxHeight: .infinity)
        }
        .onChange(of: showWindow) { _, newValue in
            if newValue {
                openWindow(id: volumetricViewID)
                windowIsShown = true
            } else if windowIsShown {
                dismissWindow(id: volumetricViewID)
                windowIsShown = false
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
