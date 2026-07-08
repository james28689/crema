//
//  InsightsView.swift
//  Crema
//

import SwiftUI

// MARK: - Display helpers

private let variableOrder = ["dose_g", "yield_g", "ratio", "time_sec", "rating", "grind"]

private func displayName(_ variable: String) -> String {
    switch variable {
    case "dose_g": return "Dose"
    case "yield_g": return "Yield"
    case "ratio": return "Ratio"
    case "time_sec": return "Time"
    case "rating": return "Rating"
    case "grind": return "Grind"
    default: return variable.capitalized
    }
}

/// Below this many paired observations a coefficient is shown but visibly
/// flagged as low-confidence, per the "no hard cutoff" decision — data is
/// never hidden, only muted.
private let lowDataThreshold = 10

// MARK: - ViewModel

@Observable @MainActor
final class InsightsViewModel {
    var correlations: CorrelationsResponse?
    var selectedBean: Bean?
    var isLoading = false
    var error: String?

    private let insightsRepo: InsightsRepositoryProtocol

    init(insightsRepo: InsightsRepositoryProtocol = InsightsRepository()) {
        self.insightsRepo = insightsRepo
    }

    func loadCorrelations() async {
        isLoading = true
        error = nil
        do {
            correlations = try await insightsRepo.fetchCorrelations(beanId: selectedBean?.id)
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }
}

// MARK: - View

struct InsightsView: View {
    @State private var viewModel = InsightsViewModel()
    @State private var showBeanPicker = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.correlations == nil {
                ProgressView().tint(Color.cremaCopper)
            } else if let correlations = viewModel.correlations, correlations.sampleSize > 0 {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        beanFilterRow
                        radarSection(correlations)
                        CremaDivider()
                        heatmapSection(correlations)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            } else {
                VStack(spacing: 16) {
                    beanFilterRow
                    ContentUnavailableView(
                        "No Data Yet",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Log a few shots to see which parameters correlate with your rating.")
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .background(Color.cremaBgPrimary.ignoresSafeArea())
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showBeanPicker) {
            CremaBeanPickerSheet(selected: $viewModel.selectedBean, includeAllOption: true)
        }
        .task(id: viewModel.selectedBean?.id) { await viewModel.loadCorrelations() }
        .cremaErrorAlert(viewModel.error) { viewModel.error = nil }
    }

    // MARK: Sub-views

    private var beanFilterRow: some View {
        Button { showBeanPicker = true } label: {
            HStack {
                Text(viewModel.selectedBean?.name ?? "All Beans")
                    .font(.cremaBody(size: 15, weight: .medium))
                    .foregroundStyle(Color.cremaTextPrimary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Color.cremaTextSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.cremaInputBg)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.cremaBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func radarSection(_ correlations: CorrelationsResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VS. RATING")
                .font(.cremaMono(size: 11))
                .tracking(0.08 * 11)
                .foregroundStyle(Color.cremaTextSecondary)

            CorrelationRadarChart(values: correlations.vsRating)
                .frame(height: 260)
                .frame(maxWidth: .infinity)
        }
    }

    private func heatmapSection(_ correlations: CorrelationsResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PARAMETER HEATMAP")
                .font(.cremaMono(size: 11))
                .tracking(0.08 * 11)
                .foregroundStyle(Color.cremaTextSecondary)

            CorrelationHeatmap(matrix: correlations.matrix)
        }
    }
}

// MARK: - Radar chart

private struct CorrelationRadarChart: View {
    let values: [VariableCorrelation]

    private var ordered: [VariableCorrelation] {
        variableOrder.compactMap { key in values.first { $0.variable == key } }
    }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 28
            let axes = ordered
            guard !axes.isEmpty else { return }
            let angleStep = 2 * Double.pi / Double(axes.count)

            func point(forRadiusFraction fraction: Double, axisIndex: Int) -> CGPoint {
                let angle = angleStep * Double(axisIndex) - .pi / 2
                let r = radius * fraction
                return CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
            }

            // Grid rings, including the zero-reference ring at fraction 0.5
            // (coefficient 0), so negative correlations read as "inside the
            // ring" rather than just "small".
            for fraction in [0.25, 0.5, 0.75, 1.0] {
                var ringPath = Path()
                for i in 0..<axes.count {
                    let p = point(forRadiusFraction: fraction, axisIndex: i)
                    if i == 0 { ringPath.move(to: p) } else { ringPath.addLine(to: p) }
                }
                ringPath.closeSubpath()
                context.stroke(
                    ringPath,
                    with: .color(fraction == 0.5 ? Color.cremaBorder.opacity(0.9) : Color.cremaBorder.opacity(0.4)),
                    lineWidth: fraction == 0.5 ? 1.2 : 0.5
                )
            }

            // Axis spokes + labels
            for (i, axis) in axes.enumerated() {
                let outer = point(forRadiusFraction: 1.0, axisIndex: i)
                var spoke = Path()
                spoke.move(to: center)
                spoke.addLine(to: outer)
                context.stroke(spoke, with: .color(Color.cremaBorder.opacity(0.4)), lineWidth: 0.5)

                let labelPoint = point(forRadiusFraction: 1.18, axisIndex: i)
                let lowData = axis.sampleSize < lowDataThreshold
                var label = AttributedString(displayName(axis.variable))
                label.font = .cremaMono(size: 11)
                label.foregroundColor = lowData ? Color.cremaTextSecondary.opacity(0.6) : Color.cremaTextSecondary
                context.draw(context.resolve(Text(label)), at: labelPoint)
            }

            // Data polygon — coefficient in [-1, 1] remapped to a 0...1 radius
            // fraction so -1 sits at center and +1 sits at the outer ring.
            var dataPath = Path()
            for (i, axis) in axes.enumerated() {
                let fraction = ((axis.coefficient ?? 0) + 1) / 2
                let p = point(forRadiusFraction: fraction, axisIndex: i)
                if i == 0 { dataPath.move(to: p) } else { dataPath.addLine(to: p) }
            }
            dataPath.closeSubpath()
            context.fill(dataPath, with: .color(Color.cremaCopper.opacity(0.25)))
            context.stroke(dataPath, with: .color(Color.cremaCopper), lineWidth: 1.5)

            for (i, axis) in axes.enumerated() {
                let fraction = ((axis.coefficient ?? 0) + 1) / 2
                let p = point(forRadiusFraction: fraction, axisIndex: i)
                let lowData = axis.sampleSize < lowDataThreshold
                let dot = Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6))
                context.fill(dot, with: .color(lowData ? Color.cremaCopper.opacity(0.5) : Color.cremaCopper))
            }
        }
    }
}

// MARK: - Heatmap

private struct CorrelationHeatmap: View {
    let matrix: [CorrelationPair]

    private var vars: [String] {
        variableOrder.filter { key in matrix.contains { $0.variableX == key } }
    }

    private func pair(_ x: String, _ y: String) -> CorrelationPair? {
        matrix.first { $0.variableX == x && $0.variableY == y }
    }

    private func cellColor(_ coefficient: Double?) -> Color {
        guard let coefficient else { return Color.cremaBorder.opacity(0.3) }
        let magnitude = min(abs(coefficient), 1.0)
        return coefficient >= 0
            ? Color.cremaCopper.opacity(0.15 + 0.65 * magnitude)
            : Color.cremaSlate.opacity(0.15 + 0.65 * magnitude)
    }

    var body: some View {
        Grid(horizontalSpacing: 2, verticalSpacing: 2) {
            GridRow {
                Color.clear.frame(width: 44, height: 32)
                ForEach(vars, id: \.self) { colVar in
                    Text(displayName(colVar))
                        .font(.cremaMono(size: 9))
                        .foregroundStyle(Color.cremaTextSecondary)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            ForEach(vars, id: \.self) { rowVar in
                GridRow {
                    Text(displayName(rowVar))
                        .font(.cremaMono(size: 9))
                        .foregroundStyle(Color.cremaTextSecondary)
                        .frame(width: 44, alignment: .trailing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    ForEach(vars, id: \.self) { colVar in
                        let cell = pair(rowVar, colVar)
                        let lowData = (cell?.sampleSize ?? 0) < lowDataThreshold
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(cellColor(cell?.coefficient))
                            if let coefficient = cell?.coefficient {
                                Text(String(format: "%.2f", coefficient))
                                    .font(.cremaMono(size: 9))
                                    .foregroundStyle(Color.cremaTextPrimary.opacity(lowData ? 0.5 : 1))
                            } else {
                                Text("—")
                                    .font(.cremaMono(size: 9))
                                    .foregroundStyle(Color.cremaTextSecondary)
                            }
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { InsightsView() }
}
