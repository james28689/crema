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
        ZStack(alignment: .bottomTrailing) {
            Color.cremaBgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                CremaDivider()
                content
            }

            fab
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showLogShot) {
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

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Shot Log")
                .font(.cremaDisplay(size: 28))
                .foregroundStyle(Color.cremaTextPrimary)
            Spacer()
            Text("\(viewModel.shots.count) shots")
                .font(.cremaMono(size: 9))
                .tracking(0.08 * 9)
                .foregroundStyle(Color.cremaTextSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.shots.isEmpty {
            Spacer()
            ProgressView().tint(Color.cremaCopper)
            Spacer()
        } else if viewModel.shots.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Text("No shots logged yet.")
                    .font(.cremaBody(size: 14))
                    .foregroundStyle(Color.cremaTextSecondary)
                Text("Tap + to log your first shot.")
                    .font(.cremaBody(size: 13))
                    .foregroundStyle(Color.cremaTextSecondary.opacity(0.6))
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.shots.enumerated()), id: \.element.id) { idx, shot in
                        ShotListRow(
                            shot: shot,
                            beanName: shot.beanId.flatMap { viewModel.beanNames[$0] }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(shot) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }

                        if idx < viewModel.shots.count - 1 {
                            CremaDivider(inset: 24)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .scrollBounceBehavior(.basedOnSize)
            .refreshable { await viewModel.load() }
        }
    }

    private var fab: some View {
        Button { showLogShot = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Color.cremaBgPrimary)
                .frame(width: 52, height: 52)
                .background(Color.cremaCopper)
                .clipShape(Circle())
                .shadow(color: Color.cremaCopper.opacity(0.45), radius: 12, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Row

private struct ShotListRow: View {
    let shot: Shot
    let beanName: String?

    private var ratio: String {
        guard shot.doseG > 0 else { return "—" }
        return String(format: "1:%.2f", shot.yieldG / shot.doseG)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    if let name = beanName {
                        Text(name)
                            .font(.cremaBody(size: 14, weight: .medium))
                            .foregroundStyle(Color.cremaTextPrimary)
                    }
                    Text(shot.pulledAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.cremaMono(size: 8))
                        .tracking(0.08 * 8)
                        .foregroundStyle(Color.cremaTextSecondary)
                }
                Spacer()
                CremaStarRating(value: shot.rating)
            }

            // Metrics row
            HStack(spacing: 16) {
                metricCell(label: "dose", value: String(format: "%.1f", shot.doseG), unit: "g")
                metricCell(label: "yield", value: String(format: "%.1f", shot.yieldG), unit: "g")
                metricCell(label: "time", value: "\(shot.timeSec)", unit: "s")
                if let grind = shot.grinderSetting {
                    metricCell(label: "grind", value: grind, unit: "")
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("ratio")
                        .font(.cremaMono(size: 8))
                        .tracking(0.08 * 8)
                        .foregroundStyle(Color.cremaTextSecondary)
                    Text(ratio)
                        .font(.cremaDisplay(size: 16))
                        .foregroundStyle(Color.cremaCopper)
                }
            }

            if let notes = shot.notes, !notes.isEmpty {
                Text("\u{201C}\(notes)\u{201D}")
                    .font(.cremaBody(size: 12))
                    .foregroundStyle(Color.cremaTextSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private func metricCell(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.cremaMono(size: 8))
                .tracking(0.08 * 8)
                .foregroundStyle(Color.cremaTextSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.cremaDisplay(size: 16))
                    .foregroundStyle(Color.cremaTextPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.cremaBody(size: 10))
                        .foregroundStyle(Color.cremaTextSecondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ShotListView() }
}
