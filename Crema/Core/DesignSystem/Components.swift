//
//  Components.swift
//  Crema
//
//  Shared UI primitives used across features.
//

import SwiftUI

// MARK: - Pill tag

struct CremaPillTag: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.cremaMono(size: 11))
            .tracking(0.06 * 11)
            .foregroundStyle(Color.cremaTextSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.cremaBgSurface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.cremaBorder, lineWidth: 0.5))
    }
}

// MARK: - Star rating

struct CremaStarRating: View {
    let value: Int
    var onChange: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { n in
                Image(systemName: n <= value ? "star.fill" : "star")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(n <= value ? Color.cremaCopper : Color.cremaBorder)
                    .contentShape(Rectangle())
                    .onTapGesture { onChange?(n) }
            }
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
                CremaStarRating(value: shot.rating)
            }

            HStack(alignment: .top, spacing: 8) {
                metricCell(label: "dose", value: String(format: "%.1f", shot.doseG), unit: "g")
                metricDivider
                metricCell(label: "yield", value: String(format: "%.1f", shot.yieldG), unit: "g")
                metricDivider
                metricCell(label: "time", value: "\(shot.timeSec)", unit: "s")
                if let grind = shot.grinderSetting {
                    metricDivider
                    metricCell(label: "grind", value: grind, unit: "")
                }
                metricDivider
                metricCell(label: "ratio", value: ratio, unit: "", valueColor: Color.cremaCopper)
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
