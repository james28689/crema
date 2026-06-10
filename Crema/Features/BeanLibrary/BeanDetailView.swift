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

    @Environment(\.dismiss) private var dismiss
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
        ZStack {
            Color.cremaBgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                beanHeader
                CremaDivider()
                statsCard
                CremaDivider()
                shotHistoryHeader
                CremaDivider()
                shotList
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: refreshID) { await viewModel.load(beanId: bean.id) }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    // MARK: Sub-views

    private var beanHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            CremaBackButton { dismiss() }
                .padding(.bottom, 14)

            if let roaster = bean.roaster {
                Text(roaster)
                    .font(.cremaMono(size: 9))
                    .tracking(0.08 * 9)
                    .foregroundStyle(Color.cremaTextSecondary)
                    .padding(.bottom, 4)
            }

            Text(bean.name)
                .font(.cremaDisplay(size: 24))
                .foregroundStyle(Color.cremaTextPrimary)

            HStack(spacing: 6) {
                if let origin = bean.origin { CremaPillTag(label: origin) }
                if let process = bean.process { CremaPillTag(label: process.displayName) }
                if let roastLevel = bean.roastLevel { CremaPillTag(label: roastLevel.displayName) }
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            CremaStatBlock(label: "shots", value: "\(viewModel.shots.count)")
            statDivider
            CremaStatBlock(label: "avg yield", value: avgYield, unit: "g")
            statDivider
            CremaStatBlock(label: "avg time", value: avgTime, unit: "s")
            statDivider
            CremaStatBlock(label: "avg ★", value: avgRating)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Color.cremaBgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cremaBorder, lineWidth: 0.5))
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var statDivider: some View {
        Rectangle().fill(Color.cremaBorder).frame(width: 0.5)
    }

    private var shotHistoryHeader: some View {
        HStack {
            Text("shot history")
                .font(.cremaMono(size: 9))
                .tracking(0.08 * 9)
                .foregroundStyle(Color.cremaTextSecondary)
            Spacer()
            Button {
                onLogShot(bean)
            } label: {
                Text("+ log shot")
                    .font(.cremaBody(size: 12, weight: .medium))
                    .foregroundStyle(Color.cremaBgPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.cremaCopper)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var shotList: some View {
        if viewModel.isLoading && viewModel.shots.isEmpty {
            Spacer()
            ProgressView().tint(Color.cremaCopper)
            Spacer()
        } else if viewModel.shots.isEmpty {
            VStack {
                Spacer()
                Text("No shots logged yet.")
                    .font(.cremaBody(size: 13))
                    .foregroundStyle(Color.cremaTextSecondary)
                Text("Tap + log shot to start.")
                    .font(.cremaBody(size: 12))
                    .foregroundStyle(Color.cremaTextSecondary.opacity(0.6))
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.shots.enumerated()), id: \.element.id) { idx, shot in
                        ShotHistoryRow(shot: shot)
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
                .padding(.bottom, 32)
            }
            .refreshable { await viewModel.load(beanId: bean.id) }
        }
    }
}

// MARK: - Shot history row

private struct ShotHistoryRow: View {
    let shot: Shot

    private var ratio: String {
        guard shot.doseG > 0 else { return "—" }
        return String(format: "1:%.2f", shot.yieldG / shot.doseG)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                // Metrics
                HStack(spacing: 0) {
                    metricCell(label: "dose", value: String(format: "%.1f", shot.doseG), unit: "g")
                    metricDivider
                    metricCell(label: "yield", value: String(format: "%.1f", shot.yieldG), unit: "g")
                    metricDivider
                    metricCell(label: "time", value: "\(shot.timeSec)", unit: "s")
                    if let grind = shot.grinderSetting {
                        metricDivider
                        metricCell(label: "grind", value: grind, unit: "")
                    }
                }
                Spacer()
                CremaStarRating(value: shot.rating)
            }

            HStack(spacing: 4) {
                Text(ratio)
                    .font(.cremaMono(size: 10))
                    .tracking(0.06 * 10)
                    .foregroundStyle(Color.cremaCopper)
            }

            if let notes = shot.notes, !notes.isEmpty {
                Text(""\(notes)"")
                    .font(.cremaBody(size: 12))
                    .foregroundStyle(Color.cremaTextSecondary)
                    .lineSpacing(3)
            }

            Text(shot.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.cremaMono(size: 8))
                .tracking(0.08 * 8)
                .foregroundStyle(Color.cremaTextSecondary.opacity(0.7))
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
                    .font(.cremaDisplay(size: 18))
                    .foregroundStyle(Color.cremaTextPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.cremaBody(size: 10))
                        .foregroundStyle(Color.cremaTextSecondary)
                }
            }
        }
        .padding(.horizontal, 10)
    }

    private var metricDivider: some View {
        Rectangle().fill(Color.cremaBorder).frame(width: 0.5).padding(.vertical, 4)
    }
}
