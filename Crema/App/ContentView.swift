//
//  ContentView.swift
//  Crema
//
//  Created by James Watling on 25/05/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isLoading {
                // Splash — shows briefly while Supabase resolves the initial session.
                ZStack {
                    Color.cremaBgPrimary.ignoresSafeArea()
                    Text("Crema")
                        .font(.cremaDisplay(size: 52))
                        .foregroundStyle(Color.cremaCopper)
                        .kerning(-0.02 * 52)
                }
            } else if appState.session != nil {
                MainTabView()
            } else {
                AuthView()
            }
        }
        // Animate on a stable boolean so token refreshes don't trigger spurious cross-fades.
        .animation(.easeInOut(duration: 0.3), value: appState.session != nil)
        .animation(.easeInOut(duration: 0.3), value: appState.isLoading)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
