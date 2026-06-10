//
//  AppState.swift
//  Crema
//
//  Created by James Watling on 25/05/2026.
//

import Foundation
import Supabase

@Observable
@MainActor
final class AppState {

    var session: Session?
    var isLoading = true

    init() {
        Task { await observeAuthState() }
    }

    // Supabase emits the initial session immediately, then subsequent auth
    // events (sign-in, sign-out, token refresh, etc.) as they happen.
    private func observeAuthState() async {
        for await (_, session) in supabase.auth.authStateChanges {
            self.session = session
            self.isLoading = false
        }
    }
}
