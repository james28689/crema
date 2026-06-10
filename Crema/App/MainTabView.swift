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
            .tabItem { Label("Beans", systemImage: "leaf") }
            .tag(AppTab.beans)

            NavigationStack {
                ShotListView()
            }
            .tabItem { Label("Shots", systemImage: "timer") }
            .tag(AppTab.shots)

            HomeView()
            .tabItem { Label("Profile", systemImage: "person") }
            .tag(AppTab.profile)
        }
        .tint(Color.cremaCopper)
        .onAppear { configureTabBar() }
    }

    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.cremaBgSurface)
        appearance.shadowColor = UIColor(Color.cremaBorder)

        let monoFont = UIFont.monospacedSystemFont(ofSize: 9, weight: .medium)
        let inactive: [NSAttributedString.Key: Any] = [.font: monoFont, .foregroundColor: UIColor(Color.cremaTextSecondary)]
        let active:   [NSAttributedString.Key: Any] = [.font: monoFont, .foregroundColor: UIColor(Color.cremaCopper)]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes   = inactive
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = active

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
