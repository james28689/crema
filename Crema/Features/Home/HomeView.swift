//
//  HomeView.swift
//  Crema
//
//  Created by James Watling on 25/05/2026.
//

import SwiftUI
import Supabase

struct HomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.cremaBgPrimary.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Wordmark
                Text("Crema")
                    .font(.cremaDisplay(size: 48))
                    .foregroundStyle(Color.cremaCopper)
                    .kerning(-0.02 * 48)

                // Signed-in proof
                VStack(spacing: 6) {
                    Text("SIGNED IN AS")
                        .font(.cremaMono(size: 9))
                        .foregroundStyle(Color.cremaTextSecondary)
                        .textCase(.uppercase)

                    Text(appState.session?.user.email ?? "—")
                        .font(.cremaBody(size: 14))
                        .foregroundStyle(Color.cremaTextPrimary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.cremaBgSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cremaBorder, lineWidth: 0.5)
                )

                Spacer()

                // Sign out
                Button {
                    Task {
                        try? await supabase.auth.signOut()
                    }
                } label: {
                    Text("sign out")
                        .font(.cremaBody(size: 14, weight: .medium))
                        .foregroundStyle(Color.cremaBgPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.cremaCopper)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
}
