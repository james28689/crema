//
//  MainTabView.swift
//  Crema
//

import SwiftUI

enum AppTab: Hashable { case beans, shots, profile }

struct MainTabView: View {
    @State private var selectedTab: AppTab = .beans

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: AppTab.beans) {
                NavigationStack {
                    BeanLibraryView()
                }
            } label: {
                Label("Beans", image: "CoffeeBean")
            }

            Tab("Shots", systemImage: "cup.and.saucer.fill", value: AppTab.shots) {
                NavigationStack {
                    ShotListView()
                }
            }

            Tab("Profile", systemImage: "person.crop.circle.fill", value: AppTab.profile) {
                HomeView()
            }
        }
        .tint(Color.cremaCopper)
    }
}
