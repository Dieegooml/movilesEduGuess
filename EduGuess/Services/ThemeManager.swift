import SwiftUI

enum Theme: String, CaseIterable, Identifiable {
    case system = "sistema"
    case light = "claro"
    case dark = "oscuro"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "Automático"
        case .light: return "Claro"
        case .dark: return "Oscuro"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
