import SwiftUI

enum JournalTheme: String, CaseIterable {
    case calm = "Calm"
    case focus = "Focus"
    case midnight = "Midnight"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .calm: return "leaf.fill"
        case .focus: return "brain.head.profile"
        case .midnight: return "moon.stars.fill"
        }
    }
    
    // Background gradients
    var backgroundGradient: LinearGradient {
        switch self {
        case .calm:
            return LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.green.opacity(0.05),
                    Color.blue.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .focus:
            return LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.orange.opacity(0.05),
                    Color.yellow.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .midnight:
            return LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.purple.opacity(0.08),
                    Color.indigo.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // Accent colors
    var accentColor: Color {
        switch self {
        case .calm: return .green
        case .focus: return .orange
        case .midnight: return .purple
        }
    }
    
    // Secondary accent colors
    var secondaryAccentColor: Color {
        switch self {
        case .calm: return .blue
        case .focus: return .yellow
        case .midnight: return .indigo
        }
    }
    
    // Card materials
    var cardMaterial: Material {
        switch self {
        case .calm: return .regularMaterial
        case .focus: return .thickMaterial
        case .midnight: return .ultraThinMaterial
        }
    }
    
    // Card background colors
    var cardBackground: Color {
        switch self {
        case .calm: return Color(.systemBackground)
        case .focus: return Color(.systemBackground)
        case .midnight: return Color(.systemGray6)
        }
    }
    
    // Card border gradients
    var cardBorderGradient: LinearGradient {
        switch self {
        case .calm:
            return LinearGradient(
                colors: [.green.opacity(0.3), .blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .focus:
            return LinearGradient(
                colors: [.orange.opacity(0.3), .yellow.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .midnight:
            return LinearGradient(
                colors: [.purple.opacity(0.3), .indigo.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // Card fill gradients
    var cardFillGradient: LinearGradient {
        switch self {
        case .calm:
            return LinearGradient(
                colors: [.green.opacity(0.1), .blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .focus:
            return LinearGradient(
                colors: [.orange.opacity(0.1), .yellow.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .midnight:
            return LinearGradient(
                colors: [.purple.opacity(0.1), .indigo.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var selectedTheme: JournalTheme = .calm
    
    static let shared = ThemeManager()
    
    private init() {}
    
    func setTheme(_ theme: JournalTheme) {
        selectedTheme = theme
    }
}
