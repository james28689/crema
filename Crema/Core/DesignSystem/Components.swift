//
//  Components.swift
//  Crema
//
//  Shared UI primitives used across features.
//

import SwiftUI

// MARK: - Pill tag

struct CremaPillTag: View {
    enum Tint { case neutral, copper, slate }

    let label: String
    var tint: Tint = .neutral

    private var foreground: Color {
        switch tint {
        case .neutral: return Color.cremaTextSecondary
        case .copper:  return Color.cremaCopper
        case .slate:   return Color.cremaSlate
        }
    }

    private var background: Color {
        switch tint {
        case .neutral: return Color.cremaBgSurface
        case .copper:  return Color.cremaBgCopperTint
        case .slate:   return Color.cremaBgSlateTint
        }
    }

    private var border: Color {
        tint == .neutral ? Color.cremaBorder : .clear
    }

    var body: some View {
        Text(label)
            .font(.cremaMono(size: 11))
            .tracking(0.06 * 11)
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(background)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(border, lineWidth: 0.5))
    }
}

// MARK: - Taste badge

/// Renders a taste tag ("balanced" / "sour" / "bitter") with the semantic
/// colours from the design system's status palette — the app's only cool
/// accent (slate) and only distinct warm-dark accent (bitter) live here.
struct CremaTasteBadge: View {
    let tag: String

    private var foreground: Color {
        switch tag.lowercased() {
        case "sour":  return Color.cremaSlate
        case "bitter": return Color.cremaBitter
        default:      return Color.cremaCopper
        }
    }

    private var background: Color {
        switch tag.lowercased() {
        case "sour":  return Color.cremaBgSlateTint
        case "bitter": return Color.cremaBgBitterTint
        default:      return Color.cremaBgCopperTint
        }
    }

    var body: some View {
        Text(tag)
            .font(.cremaBody(size: 11, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(background)
            .clipShape(Capsule())
    }
}

// MARK: - Star rating

/// Read-only rating display. Shots are rated 1–10 (see crema-db-schema.md) —
/// shown as a number rather than stars since 10 discrete icons reads poorly.
struct CremaRatingBadge: View {
    let value: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("\(value)")
                .font(.cremaDisplay(size: 20))
                .foregroundStyle(Color.cremaCopper)
            Text("/10")
                .font(.cremaBody(size: 12))
                .foregroundStyle(Color.cremaTextSecondary)
        }
    }
}

/// Interactive 1–10 rating picker.
struct CremaRatingSlider: View {
    @Binding var value: Int

    var body: some View {
        HStack(spacing: 12) {
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0.rounded()) }
                ),
                in: 1...10,
                step: 1
            )
            .tint(Color.cremaCopper)

            Text("\(value)")
                .font(.cremaDisplay(size: 20))
                .foregroundStyle(Color.cremaCopper)
                .frame(minWidth: 24, alignment: .trailing)
        }
    }
}

// MARK: - Stat block

struct CremaStatBlock: View {
    let label: String
    let value: String
    var unit: String = ""

    var body: some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.cremaDisplay(size: 20))
                    .foregroundStyle(Color.cremaTextPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.cremaBody(size: 12))
                        .foregroundStyle(Color.cremaTextSecondary)
                }
            }
            Text(label)
                .font(.cremaMono(size: 11))
                .tracking(0.08 * 11)
                .foregroundStyle(Color.cremaTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shot row

/// A single shot entry — used by both the Shots tab (all shots, with the bean
/// name shown) and a bean's detail screen (shot history, name omitted since
/// the screen title already gives that context).
struct ShotRow: View {
    let shot: Shot
    var beanName: String? = nil

    private var ratio: String {
        guard shot.doseG > 0 else { return "—" }
        return String(format: "1:%.2f", shot.yieldG / shot.doseG)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    if let beanName {
                        Text(beanName)
                            .font(.cremaBody(size: 17, weight: .medium))
                            .foregroundStyle(Color.cremaTextPrimary)
                    }
                    Text(shot.pulledAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.cremaMono(size: 11))
                        .tracking(0.08 * 11)
                        .foregroundStyle(Color.cremaTextSecondary)
                }
                Spacer(minLength: 8)
                CremaRatingBadge(value: shot.rating)
            }

            HStack(alignment: .top, spacing: 8) {
                metricCell(label: "dose", value: String(format: "%.1f", shot.doseG), unit: "g")
                metricDivider
                metricCell(label: "yield", value: String(format: "%.1f", shot.yieldG), unit: "g")
                metricDivider
                metricCell(label: "time", value: "\(shot.timeSec)", unit: "s")
                if let grind = shot.grinderSetting {
                    metricDivider
                    metricCell(label: "grind", value: grind, unit: "", valueColor: Color.cremaSlate)
                }
                metricDivider
                metricCell(label: "ratio", value: ratio, unit: "", valueColor: Color.cremaCopper)
            }

            if let tags = shot.tasteTags, !tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { CremaTasteBadge(tag: $0) }
                }
            }

            if let notes = shot.notes, !notes.isEmpty {
                Text("\u{201C}\(notes)\u{201D}")
                    .font(.cremaBody(size: 14))
                    .foregroundStyle(Color.cremaTextSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func metricCell(label: String, value: String, unit: String, valueColor: Color = Color.cremaTextPrimary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.cremaMono(size: 11))
                .tracking(0.08 * 11)
                .foregroundStyle(Color.cremaTextSecondary)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.cremaDisplay(size: 20))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.cremaBody(size: 12))
                        .foregroundStyle(Color.cremaTextSecondary)
                        .lineLimit(1)
                }
            }
            .fixedSize()
        }
    }

    private var metricDivider: some View {
        Rectangle().fill(Color.cremaBorder).frame(width: 0.5).padding(.vertical, 4)
    }
}

// MARK: - Divider

struct CremaDivider: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Color.cremaBorder)
            .frame(height: 0.5)
            .padding(.horizontal, inset)
    }
}

// MARK: - Error alert

extension View {
    /// Standard "Error" alert used by list-backed screens whose view model
    /// exposes an optional `error: String?`. Presents whenever `message` is
    /// non-nil and calls `onDismiss` (typically `{ viewModel.error = nil }`)
    /// when the user taps OK.
    func cremaErrorAlert(_ message: String?, onDismiss: @escaping () -> Void) -> some View {
        alert("Error", isPresented: .constant(message != nil)) {
            Button("OK", action: onDismiss)
        } message: {
            Text(message ?? "")
        }
    }
}

// MARK: - Primary button

struct CremaPrimaryButton: View {
    let label: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(Color.cremaBgPrimary)
                } else {
                    Text(label).font(.cremaBody(size: 17, weight: .medium))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .foregroundStyle(isEnabled ? Color.cremaBgPrimary : Color.cremaTextSecondary)
        .background(isEnabled ? Color.cremaCopper : Color.cremaBorder)
        .clipShape(Capsule())
        .disabled(!isEnabled || isLoading)
        .opacity(isLoading ? 0.8 : 1)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
        .animation(.easeInOut(duration: 0.15), value: isEnabled)
    }
}

// MARK: - Bean picker sheet

/// Shared bean-selection sheet used wherever a bean needs to be picked from a
/// list (logging a shot, filtering insights). Fetches its own bean list so
/// callers don't need to plumb one through.
struct CremaBeanPickerSheet: View {
    @Binding var selected: Bean?
    /// When true, shows a leading "All Beans" row that sets `selected` to nil.
    var includeAllOption: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var beans: [Bean] = []
    @State private var isLoading = false
    private let repo: BeanRepositoryProtocol = BeanRepository()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().tint(Color.cremaCopper)
                } else {
                    List {
                        if includeAllOption {
                            Button {
                                selected = nil
                                dismiss()
                            } label: {
                                HStack {
                                    Text("All Beans")
                                        .font(.cremaBody(size: 17, weight: .medium))
                                        .foregroundStyle(Color.cremaTextPrimary)
                                    Spacer()
                                    if selected == nil {
                                        Image(systemName: "checkmark")
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.cremaCopper)
                                    }
                                }
                            }
                            .listRowBackground(Color.cremaBgPrimary)
                            .listRowSeparatorTint(Color.cremaBorder)
                        }
                        ForEach(beans) { bean in
                            Button {
                                selected = bean
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(bean.name)
                                            .font(.cremaBody(size: 17, weight: .medium))
                                            .foregroundStyle(Color.cremaTextPrimary)
                                        if let roaster = bean.roaster {
                                            Text(roaster)
                                                .font(.cremaBody(size: 14))
                                                .foregroundStyle(Color.cremaTextSecondary)
                                        }
                                    }
                                    Spacer()
                                    if selected?.id == bean.id {
                                        Image(systemName: "checkmark")
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.cremaCopper)
                                    }
                                }
                            }
                            .listRowBackground(Color.cremaBgPrimary)
                            .listRowSeparatorTint(Color.cremaBorder)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.cremaBgPrimary.ignoresSafeArea())
                }
            }
            .navigationTitle("Select Bean")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Color.cremaCopper)
        .task {
            isLoading = true
            beans = (try? await repo.fetchBeans()) ?? []
            isLoading = false
        }
    }
}
