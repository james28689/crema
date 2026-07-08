//
//  HomeView.swift
//  Crema
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var signOutError: String?

    var body: some View {
        Form {
            Section {
                LabeledContent("Email") {
                    Text(appState.session?.user.email ?? "—")
                        .font(.cremaBody(size: 16))
                        .foregroundStyle(Color.cremaTextSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .listRowBackground(Color.cremaBgSurface)

            if let error = signOutError {
                Section {
                    Text(error)
                        .font(.cremaBody(size: 14))
                        .foregroundStyle(Color.cremaError)
                }
                .listRowBackground(Color.cremaBgSurface)
            }

            Section {
                Button(role: .destructive) {
                    signOutError = nil
                    Task {
                        do {
                            try await supabase.auth.signOut()
                        } catch {
                            signOutError = error.localizedDescription
                        }
                    }
                } label: {
                    Text("Sign Out")
                        .font(.cremaBody(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listRowBackground(Color.cremaBgSurface)
        }
        .scrollContentBackground(.hidden)
        .background(Color.cremaBgPrimary.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .tint(Color.cremaCopper)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(AppState())
    }
}
