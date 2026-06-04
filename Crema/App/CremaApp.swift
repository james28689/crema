//
//  CremaApp.swift
//  Crema
//
//  Created by James Watling on 25/05/2026.
//

import SwiftUI

@main
struct CremaApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
