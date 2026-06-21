import SwiftUI

/// App-wide dark space-themed color palette inspired by the pet robot mascot.
/// The mascot is a white astronaut robot with yellow eyes and red headphones.
/// A dark background makes the white mascot and light text pop while keeping
/// the mascot's accent colors (yellow, red, green, blue) readable.
enum AppTheme {
    // MARK: - Background
    static let backgroundTop = Color(hex: "0B1026")    // deep space blue
    static let backgroundMid = Color(hex: "1A1F3C")    // midnight blue
    static let backgroundBottom = Color(hex: "2D1B4E") // deep purple

    // MARK: - Surfaces
    static let cardSurface = Color(hex: "FFFFFF").opacity(0.10)
    static let cardSurfaceSolid = Color(hex: "1E2445")
    static let cardBorder = Color(hex: "FFFFFF").opacity(0.18)
    static let divider = Color(hex: "FFFFFF").opacity(0.12)

    // MARK: - Primary / Accent
    static let primaryYellow = Color(hex: "FFD700")    // robot eyes
    static let primaryGold = Color(hex: "FFB800")
    static let primaryOrange = Color(hex: "FF8C00")

    // MARK: - Semantic
    static let successGreen = Color(hex: "4ADE80")
    static let infoBlue = Color(hex: "38BDF8")
    static let warningOrange = Color(hex: "FB923C")
    static let errorRed = Color(hex: "EF4444")
    static let accentRed = Color(hex: "FF3B30")        // headphones
    static let accentCoral = Color(hex: "FF6B6B")

    // MARK: - Text
    static let primaryText = Color.white
    static let secondaryText = Color(hex: "CBD5E1")
    static let mutedText = Color(hex: "94A3B8")

    // MARK: - Common gradients
    static var mainGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundMid, backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var homeGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundMid, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [primaryGold, primaryOrange],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var questionCardGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "3B82F6").opacity(0.9), Color(hex: "8B5CF6").opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var leaderboardGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, Color(hex: "4C1D95")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var successGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "059669"), Color(hex: "0EA5E9")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var errorGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "BE123C"), Color(hex: "EA580C")],
            startPoint: .top,
            endPoint: .bottom
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
