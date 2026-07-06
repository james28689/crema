//
//  BeanDetailView.swift
//  Crema
//

import SwiftUI

// MARK: - ViewModel

@Observable @MainActor
private final class BeanDetailViewModel {
    var shots: [Shot] = []
    var isLoading = false
    var error: String?

    private let repo: ShotRepositoryProtocol

    init(repo: ShotRepositoryProtocol = ShotRepository()) {
        self.repo = repo
    }

    func load(beanId: UUID) async {
        isLoading = true
        error = nil
        do { shots = try await repo.fetchShots(beanId: beanId) }
        catch { self.error = error.localizedDescription }
        isLoading = false
    }

    func delete(_ shot: Shot) async {
        do {
            try await repo.deleteShot(id: shot.id)
            shots.removeAll { $0.id == shot.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - View

struct BeanDetailView: View {
    let bean: Bean
    let onLogShot: (Bean) -> Void

    @State private var viewModel = BeanDetailViewModel()
    @State private var refreshID = UUID()

    private var avgRating: String {
        guard !viewModel.shots.isEmpty else { return "—" }
        let avg = Double(viewModel.shots.reduce(0) { $0 + $1.rating }) / Double(viewModel.shots.count)
        return String(format: "%.1f", avg)
    }

    private var avgYield: String {
        guard !viewModel.shots.isEmpty else { return "—" }
        let avg = viewModel.shots.reduce(0.0) { $0 + $1.yieldG } / Double(viewModel.shots.count)
        return String(format: "%.1f", avg)
    }

    private var avgTime: String {
        guard !viewModel.shots.isEmpty else { return "—" }
        let avg = viewModel.shots.reduce(0) { $0 + $1.timeSec } / viewModel.shots.count
        return "\(avg)"
    }

    var body: some View {
        List {
            beanSubheader
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.cremaBgPrimary)

            CremaDivider()
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.cremaBgPrimary)

            statsCard
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.cremaBgSurface)

            CremaDivider()
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.cremaBgPrimary)

            shotRows
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .scrollContentBackground(.hidden)
        .background(Color.cremaBgPrimary)
        .refreshable { await viewModel.load(beanId: bean.id) }
        .navigationTitle(bean.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onLogShot(bean)
                } label: {
                    Label("Log Shot", systemImage: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .task(id: refreshID) { await viewModel.load(beanId: bean.id) }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: Sub-views

    private var beanSubheader: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let roaster = bean.roaster {
                Text(roaster)
                    .font(.cremaMono(size: 11))
                    .tracking(0.08 * 11)
                    .foregroundStyle(Color.cremaTextSecondary)
            }
            HStack(spacing: 6) {
                if let origin = bean.origin { CremaPillTag(label: origin) }
                if let process = bean.process { CremaPillTag(label: process.displayName) }
                if let roastLevel = bean.roastLevel { CremaPillTag(label: roastLevel.displayName) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            CremaStatBlock(label: viewModel.shots.count == 1 ? "shot" : "shots", value: "\(viewModel.shots.count)")
            statDivider
            CremaStatBlock(label: "avg yield", value: avgYield, unit: "g")
            statDivider
            CremaStatBlock(label: "avg time", value: avgTime, unit: "s")
            statDivider
            CremaStatBlock(label: "avg ★", value: avgRating)
        }
        .padding(.vertical, 12)
        .background(Color.cremaBgSurface)
    }

    private var statDivider: some View {
        Rectangle().fill(Color.cremaBorder).frame(width: 0.5, height: 28)
    }

    @ViewBuilder
    private var shotRows: some View {
        if viewModel.isLoading && viewModel.shots.isEmpty {
            HStack {
                Spacer()
                ProgressView().tint(Color.cremaCopper)
                Spacer()
            }
            .padding(.vertical, 40)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.cremaBgPrimary)
        } else if viewModel.shots.isEmpty {
            ContentUnavailableView(
                "No Shots Yet",
                systemImage: "cup.and.saucer",
                description: Text("Tap + to log your first shot with this bean.")
            )
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.cremaBgPrimary)
        } else {
            ForEach(viewModel.shots) { shot in
                ShotRow(shot: shot)
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
    }
}
