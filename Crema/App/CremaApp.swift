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

    init() {
        Self.configureNavigationBarAppearance()
    }

    /// Applies the Crema serif display font to native navigation titles so
    /// screens using `.navigationTitle` still carry the Crema look.
    private static func configureNavigationBarAppearance() {
        let textColor = UIColor(Color.cremaTextPrimary)
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont.cremaDisplay(size: 34),
            .foregroundColor: textColor,
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont.cremaDisplay(size: 17),
            .foregroundColor: textColor,
        ]
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
