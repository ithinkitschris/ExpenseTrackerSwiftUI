import SwiftUI

/// Theme system matching the React Native app's Apple color palette
struct Theme {
    let background: Color
    let itemCardBackground: Color
    let text: Color
    let textInvert: Color
    let textSecondary: Color
    let textTertiary: Color
    let borderColor: Color
    let glassBackground: Color
    let categorySelected: Color
    let categoryIconColor: Color

    // Apple system colors
    let appleBlue: Color
    let systemRed: Color
    let systemOrange: Color
    let systemYellow: Color
    let systemGreen: Color
    let systemMint: Color
    let systemTeal: Color
    let systemCyan: Color
    let systemIndigo: Color
    let systemPurple: Color
    let systemPink: Color
    let systemBrown: Color
    let systemGray: Color

    // Shadow properties
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowOpacity: Double

    static let light = Theme(
        background: Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.98),
        itemCardBackground: Color(red: 252/255, green: 252/255, blue: 252/255),
        text: .black,
        textInvert: .white,
        textSecondary: Color(red: 60/255, green: 60/255, blue: 67/255),
        textTertiary: Color(red: 120/255, green: 120/255, blue: 128/255),
        borderColor: Color(red: 198/255, green: 198/255, blue: 200/255),
        glassBackground: Color.white.opacity(0.3),
        categorySelected: Color(red: 229/255, green: 229/255, blue: 234/255),
        categoryIconColor: Color(red: 142/255, green: 142/255, blue: 147/255),
        appleBlue: Color(red: 0/255, green: 149/255, blue: 255/255),
        systemRed: Color(red: 255/255, green: 69/255, blue: 58/255),
        systemOrange: Color(red: 255/255, green: 159/255, blue: 10/255),
        systemYellow: Color(red: 255/255, green: 214/255, blue: 10/255),
        systemGreen: Color(red: 74/255, green: 217/255, blue: 105/255),
        systemMint: Color(red: 99/255, green: 230/255, blue: 226/255),
        systemTeal: Color(red: 64/255, green: 200/255, blue: 224/255),
        systemCyan: Color(red: 100/255, green: 210/255, blue: 255/255),
        systemIndigo: Color(red: 94/255, green: 92/255, blue: 230/255),
        systemPurple: Color(red: 191/255, green: 90/255, blue: 242/255),
        systemPink: Color(red: 255/255, green: 55/255, blue: 95/255),
        systemBrown: Color(red: 162/255, green: 132/255, blue: 94/255),
        systemGray: Color(red: 142/255, green: 142/255, blue: 147/255),
        shadowColor: .black,
        shadowRadius: 8,
        shadowOpacity: 0.1
    )

    static let dark = Theme(
        background: Color(red: 0, green: 0, blue: 0),
        itemCardBackground: Color.white.opacity(0.11),
        text: .white,
        textInvert: .black,
        textSecondary: Color.white.opacity(0.5),
        textTertiary: Color(red: 235/255, green: 235/255, blue: 245/255, opacity: 0.6),
        borderColor: Color(red: 56/255, green: 56/255, blue: 58/255),
        glassBackground: Color.white.opacity(0.1),
        categorySelected: Color.white.opacity(0.2),
        categoryIconColor: Color(red: 142/255, green: 142/255, blue: 147/255),
        appleBlue: Color(red: 0/255, green: 149/255, blue: 255/255),
        systemRed: Color(red: 255/255, green: 69/255, blue: 58/255),
        systemOrange: Color(red: 255/255, green: 159/255, blue: 10/255),
        systemYellow: Color(red: 255/255, green: 214/255, blue: 10/255),
        systemGreen: Color(red: 74/255, green: 217/255, blue: 105/255),
        systemMint: Color(red: 99/255, green: 230/255, blue: 226/255),
        systemTeal: Color(red: 64/255, green: 200/255, blue: 224/255),
        systemCyan: Color(red: 100/255, green: 210/255, blue: 255/255),
        systemIndigo: Color(red: 94/255, green: 92/255, blue: 230/255),
        systemPurple: Color(red: 191/255, green: 90/255, blue: 242/255),
        systemPink: Color(red: 255/255, green: 55/255, blue: 95/255),
        systemBrown: Color(red: 162/255, green: 132/255, blue: 94/255),
        systemGray: Color(red: 142/255, green: 142/255, blue: 147/255),
        shadowColor: .black,
        shadowRadius: 6,
        shadowOpacity: 0.2
    )
}

// MARK: - Category Color Mapping

extension Theme {
    /// Get color for expense category (matching React Native app)
    func colorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "amazon": return systemBrown
        case "personal": return systemPurple
        case "fashion": return systemPink
        case "food": return systemRed
        case "furniture": return systemOrange
        case "groceries": return systemMint
        case "monthly": return systemGray
        case "transportation": return systemIndigo
        case "travel": return systemCyan
        default: return appleBlue
        }
    }
}

// MARK: - Environment Key

struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .light
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}
