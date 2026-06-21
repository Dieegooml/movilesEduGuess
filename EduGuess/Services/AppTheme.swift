import SwiftUI

/// App-wide color palette inspired by the pet robot mascot.
/// The mascot is white with a black visor, yellow eyes, red headphones,
/// and expressive blobs in green, yellow, orange, red, and blue.
enum AppTheme {
    // MARK: - Primary
    static let primaryYellow = Color(hex: "FFC107")
    static let primaryGold = Color(hex: "FFB300")
    static let primaryOrange = Color(hex: "FF9800")

    // MARK: - Accent
    static let accentRed = Color(hex: "FF3B30")
    static let accentCoral = Color(hex: "FF6B6B")
    static let accentGreen = Color(hex: "8BC34A")
    static let accentBlue = Color(hex: "4FC3F7")

    // MARK: - Backgrounds
    static let backgroundGradientStart = Color(hex: "FFF8E1")
    static let backgroundGradientEnd = Color(hex: "FFE0B2")
    static let cardBackground = Color.white.opacity(0.85)
    static let cardBorder = Color.white.opacity(0.5)

    // MARK: - Text
    static let primaryText = Color(hex: "1A1A1A")
    static let secondaryText = Color(hex: "666666")

    // MARK: - Common gradients
    static var mainGradient: LinearGradient {
        LinearGradient(
            colors: [primaryYellow, primaryOrange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var homeGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundGradientStart, backgroundGradientEnd],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var leaderboardGradient: LinearGradient {
        LinearGradient(
            colors: [primaryGold, accentRed],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
