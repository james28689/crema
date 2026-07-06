//
//  ShotListView.swift
//  Crema
//

import SwiftUI

// MARK: - ViewModel

@Observable @MainActor
final class ShotListViewModel {
    var shots: [Shot] = []
    var beanNames: [UUID: String] = [:]
    var isLoading = false
    var error: String?

    private let shotRepo: ShotRepositoryProtocol
    private let beanRepo: BeanRepositoryProtocol

    init(shotRepo: ShotRepositoryProtocol = ShotRepository(),
         beanRepo: BeanRepositoryProtocol = BeanRepository()) {
        self.shotRepo = shotRepo
        self.beanRepo = beanRepo
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            async let shots = shotRepo.fetchShots()
            async let beans = beanRepo.fetchBeans()
            let (s, b) = try await (shots, beans)
            self.shots = s
            self.beanNames = Dictionary(uniqueKeysWithValues: b.map { ($0.id, $0.name) })
        } catch APIError.unauthenticated { /* sign-out in progress, ContentView routes to AuthView */ }
        catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func delete(_ shot: Shot) async {
        do {
            try await shotRepo.deleteShot(id: shot.id)
            shots.removeAll { $0.id == shot.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - View

struct ShotListView: View {
    @State private var viewModel = ShotListViewModel()
    @State private var showLogShot = false
    @State private var refreshID = UUID()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.shots.isEmpty {
                ProgressView().tint(Color.cremaCopper)
            } else if viewModel.shots.isEmpty {
                ContentUnavailableView(
                    "No Shots Yet",
                    systemImage: "cup.and.saucer",
                    description: Text("Tap + to log your first shot.")
                )
            } else {
                List {
                    ForEach(viewModel.shots) { shot in
                        ShotRow(
                            shot: shot,
                            beanName: shot.beanId.flatMap { viewModel.beanNames[$0] }
                        )
                        .listRowBackground(Color.cremaBgPrimary)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparatorTint(Color.cremaBorder)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await viewModel.delete(shot) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await viewModel.load() }
            }
        }
        .background(Color.cremaBgPrimary.ignoresSafeArea())
        .navigationTitle("Shot Log")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showLogShot = true } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showLogShot) {
            LogShotView(initialBean: nil) {
                showLogShot = false
                refreshID = UUID()
            }
        }
        .task(id: refreshID) { await viewModel.load() }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }
}

#Preview {
    NavigationStack { ShotListView() }
}
