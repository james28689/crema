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
            .font(.cremaMono(size: 9))
            .tracking(0.06 * 9)
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
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(n <= value ? Color.cremaCopper : Color.cremaBorder)
                    .contentShape(Rectangle())
                    .onTapGesture { onChange?(n) }
            }
        }
    }
}

// MARK: - Back button

struct CremaBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 13, weight: .light))
                Text("back")
                    .font(.cremaBody(size: 13))
            }
            .foregroundStyle(Color.cremaTextSecondary)
        }
    }
}

// MARK: - Stat block

struct CremaStatBlock: View {
    let label: String
    let value: String
    var unit: String = ""

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.cremaDisplay(size: 22))
                    .foregroundStyle(Color.cremaTextPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.cremaBody(size: 11))
                        .foregroundStyle(Color.cremaTextSecondary)
                }
            }
            Text(label)
                .font(.cremaMono(size: 8))
                .tracking(0.08 * 8)
                .foregroundStyle(Color.cremaTextSecondary)
        }
        .frame(maxWidth: .infinity)
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
                    Text(label).font(.cremaBody(size: 14, weight: .medium))
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

// MARK: - Segmented pill picker

struct CremaSegmentedPicker<T: Hashable>: View {
    let options: [T]
    let label: (T) -> String
    @Binding var selection: T

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(options, id: \.self) { opt in
                    let isSelected = selection == opt
                    Button { selection = opt } label: {
                        Text(label(opt))
                            .font(.cremaBody(size: 12))
                            .foregroundStyle(isSelected ? Color.cremaBgPrimary : Color.cremaTextSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isSelected ? Color.cremaCopper : Color.clear)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isSelected ? Color.cremaCopper : Color.cremaBorder, lineWidth: 0.5))
                    }
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
            }
        }
    }
}
