import Foundation

/// App constants matching the React Native configuration
enum Constants {
    // MARK: - Expense Categories

    static let expenseCategories = [
        "amazon",
        "fashion",
        "food",
        "furniture",
        "groceries",
        "monthly",
        "personal",
        "transportation",
        "travel"
    ]

    // MARK: - Category Icons (SF Symbols)

    static func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "amazon": return "shippingbox.fill"
        case "transportation": return "tram.fill"
        case "groceries": return "cart.fill"
        case "personal": return "gamecontroller.fill"
        case "fashion": return "tshirt.fill"
        case "travel": return "airplane"
        case "food": return "fork.knife"
        case "monthly": return "calendar"
        case "furniture": return "bed.double.fill"
        default: return "chart.bar.fill"
        }
    }

    // MARK: - Display Names

    static func displayNameForCategory(_ category: String) -> String {
        return category.capitalized
    }

    // MARK: - Validation

    static let maxAmount: Double = 99999
    static let minAmount: Double = 0
    static let maxDescriptionLength: Int = 100
    static let minDescriptionLength: Int = 1

    // MARK: - Defaults

    static let defaultCategory = "personal"
    static let defaultAmount: Double = 0
    static let maxExpensesLimit = 200

    // MARK: - Animation Durations

    static let buttonAnimationDuration: Double = 0.15
    static let scrollAnimationDuration: Double = 0.3
    static let modalAnimationDuration: Double = 0.3

    // MARK: - Haptics

    static let enableHapticFeedback = true
}
