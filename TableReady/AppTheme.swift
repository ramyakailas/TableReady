//
//  AppTheme.swift
//  TableReady
//

import SwiftUI

enum AppTheme {

    // MARK: - Core Palette (food-inspired)

    /// Warm turmeric gold — primary accent
    static let turmeric = Color(red: 0.91, green: 0.68, blue: 0.18)

    /// Deep curry orange — gradient partner
    static let curryOrange = Color(red: 0.93, green: 0.55, blue: 0.14)

    /// Rich chai brown — warm text and headings
    static let chaiBrown = Color(red: 0.55, green: 0.35, blue: 0.17)

    /// Fresh herb green — light effort, success
    static let herbGreen = Color(red: 0.30, green: 0.69, blue: 0.31)

    /// Saffron — medium effort
    static let saffron = Color(red: 0.96, green: 0.60, blue: 0.10)

    /// Warm spice red — heavy effort
    static let spiceRed = Color(red: 0.85, green: 0.25, blue: 0.20)

    // MARK: - Background Tints

    /// Warm cream (replaces systemGroupedBackground)
    static let warmCream = Color(red: 1.0, green: 0.98, blue: 0.94)

    /// Warm card background (replaces secondarySystemGroupedBackground)
    static let warmCard = Color(red: 1.0, green: 0.99, blue: 0.96)

    // MARK: - Gradients

    /// Selected tab pill gradient. Darker than the raw turmeric/curryOrange
    /// pairing so the white label/icon on top still clears 4.5:1 contrast.
    static let tabSelectedGradient = LinearGradient(
        colors: [chaiBrown, Color(red: 0.68, green: 0.34, blue: 0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle warm card gradient
    static let cardGradient = LinearGradient(
        colors: [Color.white, Color(red: 1.0, green: 0.97, blue: 0.91)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Shadows

    static let cardShadowColor = Color(red: 0.91, green: 0.68, blue: 0.18).opacity(0.15)
    static let cardShadowRadius: CGFloat = 6
    static let cardShadowY: CGFloat = 3

    // MARK: - Effort Colors

    static func effortColor(for effort: MenuEffort) -> Color {
        switch effort {
        case .light:  return herbGreen
        case .medium: return saffron
        case .heavy:  return spiceRed
        }
    }

    // MARK: - Accessible Text Variants

    /// Opaque secondary text brown — meets WCAG AA 4.5:1 on warmCream/white.
    /// Use instead of `chaiBrown.opacity(...)` for any real text; translucent
    /// chaiBrown drops well below 4.5:1 once blended with a light background.
    static let chaiBrownMuted = Color(red: 0.55, green: 0.38, blue: 0.24)

    /// Accessible amber text — darker than `saffron`, which fails contrast as text.
    static let saffronText = Color(red: 0.55, green: 0.32, blue: 0.0)

    /// Accessible green text — darker than `herbGreen`, which fails contrast as text.
    static let herbGreenText = Color(red: 0.13, green: 0.45, blue: 0.16)

    /// Accessible red text — darker than `spiceRed`, which is borderline as text.
    static let spiceRedText = Color(red: 0.62, green: 0.14, blue: 0.10)

    /// Text-safe counterpart to `effortColor(for:)` — the vibrant effort colors
    /// fail 4.5:1 contrast when used directly as text/label foreground.
    static func effortTextColor(for effort: MenuEffort) -> Color {
        switch effort {
        case .light:  return herbGreenText
        case .medium: return saffronText
        case .heavy:  return spiceRedText
        }
    }

    // MARK: - Crouton-Style Card Constants

    /// Off-white background so white cards pop
    static let offWhiteBackground = Color(red: 0.96, green: 0.95, blue: 0.93)

    /// Pure white card fill
    static let flatCardWhite = Color.white

    /// Card corner radius
    static let dayCardCornerRadius: CGFloat = 16

    /// Left bracket color
    static let bracketColor = chaiBrown.opacity(0.18)

    /// Left bracket line width
    static let bracketLineWidth: CGFloat = 2.5

    /// Thumbnail circle size
    static let thumbnailSize: CGFloat = 36

    /// Thumbnail placeholder colors
    static let thumbnailColors: [Color] = [
        turmeric.opacity(0.20),
        curryOrange.opacity(0.20),
        herbGreen.opacity(0.20),
        saffron.opacity(0.20),
        chaiBrown.opacity(0.15),
    ]

    /// Deterministic color for a food item thumbnail
    static func thumbnailColor(for item: String) -> Color {
        let index = abs(item.hashValue) % thumbnailColors.count
        return thumbnailColors[index]
    }

    /// Deterministic SF Symbol icon for a food item based on keywords
    static func foodIcon(for item: String) -> String {
        let lower = item.lowercased()
        if lower.contains("rice") || lower.contains("khichdi") || lower.contains("biryani") { return "bowl.fill" }
        if lower.contains("chapathi") || lower.contains("paratha") || lower.contains("roti") || lower.contains("thepla") { return "circle.grid.cross.fill" }
        if lower.contains("dal") || lower.contains("soup") || lower.contains("kadhi") { return "cup.and.saucer.fill" }
        if lower.contains("paneer") || lower.contains("tofu") || lower.contains("tikka") { return "square.fill" }
        if lower.contains("sandwich") || lower.contains("cheela") || lower.contains("paddu") { return "rectangle.split.1x2.fill" }
        if lower.contains("fry") || lower.contains("manchurian") || lower.contains("pakod") { return "flame.fill" }
        if lower.contains("salad") || lower.contains("sprouted") || lower.contains("misal") { return "leaf.fill" }
        if lower.contains("puri") || lower.contains("pani") { return "drop.fill" }
        if lower.contains("egg") { return "oval.fill" }
        if lower.contains("mushroom") { return "aqi.medium" }
        if lower.contains("poha") || lower.contains("muthiya") { return "takeoutbag.and.cup.and.straw.fill" }
        return "fork.knife"
    }
}
