//
//  MainTabView.swift
//  Crema
//

import SwiftUI

enum AppTab { case beans, shots, profile }

struct MainTabView: View {
    @State private var selectedTab: AppTab = .beans

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                BeanLibraryView()
            }
            .tabItem { Label("Beans", image: "CoffeeBean") }
            .tag(AppTab.beans)

            NavigationStack {
                ShotListView()
            }
            .tabItem { Label("Shots", systemImage: "cup.and.saucer.fill") }
            .tag(AppTab.shots)

            HomeView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(AppTab.profile)
        }
        .tint(Color.cremaCopper)
        .toolbarBackground(Color.cremaBgSurface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
