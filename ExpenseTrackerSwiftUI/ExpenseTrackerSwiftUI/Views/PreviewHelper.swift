import Foundation

#if DEBUG
/// Helper for creating preview data
enum PreviewHelper {
    /// Sample expenses for previews
    static let sampleExpenses: [Expense] = [
        Expense(
            amount: 45.99,
            category: "groceries",
            description: "Whole Foods",
            timestamp: Date()
        ),
        Expense(
            amount: 12.50,
            category: "food",
            description: "Coffee shop",
            timestamp: Date().addingTimeInterval(-3600)
        ),
        Expense(
            amount: 89.99,
            category: "transportation",
            description: "Gas station",
            timestamp: Date().addingTimeInterval(-7200)
        ),
        Expense(
            amount: 156.00,
            category: "fashion",
            description: "Nike store",
            timestamp: Date().addingTimeInterval(-86400)
        ),
        Expense(
            amount: 23.45,
            category: "personal",
            description: "Pharmacy",
            timestamp: Date().addingTimeInterval(-172800)
        )
    ]
    
    /// Sample expense view model for previews
    @MainActor
    static func createSampleViewModel() -> ExpenseViewModel {
        let viewModel = ExpenseViewModel()
        viewModel.expenses = sampleExpenses
        return viewModel
    }
}
#endif
