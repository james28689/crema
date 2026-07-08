//
//  DesignTokens.swift
//  Crema
//
//  Created by James Watling on 25/05/2026.
//

import SwiftUI

// MARK: - Hex Colour Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)         / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Colour Tokens

extension Color {

    // ── Fixed (same in both modes) ────────────────────────────────────────
    static let cremaCopper   = Color(hex: "B87A4E")
    static let cremaEspresso = Color(hex: "3D2B1F")

    // ── Adaptive ─────────────────────────────────────────────────────────
    static let cremaBgPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.118, green: 0.078, blue: 0.035, alpha: 1)  // #1E1409
            : UIColor(red: 0.992, green: 0.980, blue: 0.961, alpha: 1)  // #FDFAF5
    })

    static let cremaBgSurface = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.173, green: 0.122, blue: 0.078, alpha: 1)  // #2C1F14
            : UIColor(red: 0.961, green: 0.933, blue: 0.894, alpha: 1)  // #F5EEE4
    })

    static let cremaTextPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.992, green: 0.980, blue: 0.961, alpha: 1)  // #FDFAF5
            : UIColor(red: 0.239, green: 0.169, blue: 0.122, alpha: 1)  // #3D2B1F
    })

    static let cremaTextSecondary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.784, green: 0.663, blue: 0.494, alpha: 1)  // #C8A97E
            : UIColor(red: 0.620, green: 0.533, blue: 0.471, alpha: 1)  // #9E8878
    })

    static let cremaBorder = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.07)
            : UIColor(red: 0.910, green: 0.867, blue: 0.816, alpha: 1)  // #E8DDD0
    })

    static let cremaInputBg = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.173, green: 0.122, blue: 0.078, alpha: 1)  // #2C1F14
            : UIColor(red: 0.961, green: 0.933, blue: 0.894, alpha: 1)  // #F5EEE4
    })

    /// Semantic error colour. Dark: #E07070 (warm red on dark bg), Light: #791F1F (deep crimson).
    static let cremaError = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.878, green: 0.439, blue: 0.439, alpha: 1)  // #E07070
            : UIColor(red: 0.475, green: 0.122, blue: 0.122, alpha: 1)  // #791F1F
    })

    // ── Cool accent (from crema-design-system.html §02) ────────────────────
    //
    // Slate Blue is the palette's "cool accent" — used for technical/info
    // data points and the "sour" taste tag. Lightened in dark mode (#8AAAC8)
    // to hold contrast against the espresso surfaces, same pattern as
    // `cremaTextSecondary`'s parchment shift.
    static let cremaSlate = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.541, green: 0.667, blue: 0.784, alpha: 1)  // #8AAAC8
            : UIColor(red: 0.290, green: 0.376, blue: 0.502, alpha: 1)  // #4A6080
    })

    /// Semantic "bitter" (over-extracted) taste-tag colour.
    static let cremaBitter = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.816, green: 0.608, blue: 0.451, alpha: 1)  // lightened for dark legibility
            : UIColor(red: 0.478, green: 0.243, blue: 0.125, alpha: 1)  // #7A3E20
    })

    // ── Tinted fills, for badges & tags ─────────────────────────────────────
    static let cremaBgCopperTint = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.722, green: 0.478, blue: 0.306, alpha: 0.15)
            : UIColor(red: 0.961, green: 0.910, blue: 0.875, alpha: 1)  // #F5E8DF
    })

    static let cremaBgSlateTint = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.290, green: 0.376, blue: 0.502, alpha: 0.2)
            : UIColor(red: 0.902, green: 0.925, blue: 0.953, alpha: 1)  // #E6ECF3
    })

    static let cremaBgBitterTint = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.478, green: 0.243, blue: 0.125, alpha: 0.2)
            : UIColor(red: 0.961, green: 0.910, blue: 0.875, alpha: 1)  // #F5E8DF
    })
}

// MARK: - Typography
//
// Three-tier system matching the Crema design language:
//   Display  → New York (Apple serif) — wordmarks, headings
//   Body     → SF Pro                 — all UI copy, inputs, buttons
//   Mono     → SF Mono                — labels, parameters, data tokens

extension Font {
    /// New York serif — wordmarks and screen headings.
    /// `.regular` weight lets the optical size do the heavy lifting at large sizes;
    /// use `.semibold` for smaller display headings (28 pt and below).
    static func cremaDisplay(size: CGFloat) -> Font {
        .system(size: size, weight: size >= 36 ? .regular : .semibold, design: .serif)
    }

    /// SF Pro — body copy, captions, button labels.
    /// Default weight is `.light` (300) to match the airy, refined feel of the design.
    static func cremaBody(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// SF Mono — ALL CAPS labels, parameter tokens, data values.
    static func cremaMono(size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension UIFont {
    /// UIKit equivalent of `Font.cremaDisplay`, for styling `UINavigationBar` title attributes.
    static func cremaDisplay(size: CGFloat) -> UIFont {
        let weight: UIFont.Weight = size >= 36 ? .regular : .semibold
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
