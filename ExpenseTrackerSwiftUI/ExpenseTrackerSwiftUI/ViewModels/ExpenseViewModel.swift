import Foundation
import SwiftUI
import SwiftData
import Combine

/// View model for managing expense state and operations
@MainActor
class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var selectedCategory: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let databaseManager = DatabaseManager.shared

    init() {
        loadExpenses()
    }

    // MARK: - Data Loading

    /// Load expenses from database
    func loadExpenses() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                if let category = selectedCategory {
                    expenses = try databaseManager.getExpensesByCategory(category)
                } else {
                    expenses = try databaseManager.getExpenses()
                }
                isLoading = false
            } catch {
                errorMessage = "Failed to load expenses: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    // MARK: - Expense Operations

    /// Add a new expense
    func addExpense(amount: Double, category: String, description: String) {
        Task {
            do {
                let newExpense = try databaseManager.addExpense(
                    amount: amount,
                    category: category,
                    description: description
                )
                expenses.insert(newExpense, at: 0)

                // Trigger haptic feedback
                if Constants.enableHapticFeedback {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                errorMessage = "Failed to add expense: \(error.localizedDescription)"
            }
        }
    }

    /// Update an existing expense
    func updateExpense(_ expense: Expense) {
        Task {
            do {
                try databaseManager.updateExpense(expense)

                // Refresh the list
                loadExpenses()

                // Trigger haptic feedback
                if Constants.enableHapticFeedback {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            } catch {
                errorMessage = "Failed to update expense: \(error.localizedDescription)"
            }
        }
    }

    /// Delete an expense
    func deleteExpense(_ expense: Expense) {
        Task {
            do {
                try databaseManager.deleteExpense(expense)
                expenses.removeAll { $0.persistentModelID == expense.persistentModelID }

                // Trigger haptic feedback
                if Constants.enableHapticFeedback {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            } catch {
                errorMessage = "Failed to delete expense: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Filtering

    /// Set the selected category filter
    func setCategory(_ category: String?) {
        selectedCategory = category
        loadExpenses()
    }

    // MARK: - Computed Properties

    /// Get total amount of displayed expenses
    var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    /// Group expenses by day for section headers
    var groupedExpenses: [(String, [Expense])] {
        let grouped = Dictionary(grouping: expenses) { expense in
            expense.dayHeader
        }

        return grouped.sorted { first, second in
            // Sort by most recent first
            guard let firstDate = first.value.first?.timestamp,
                  let secondDate = second.value.first?.timestamp else {
                return false
            }
            return firstDate > secondDate
        }
    }

    /// Get expenses count by category
    var expensesByCategory: [String: Int] {
        Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { $0.count }
    }
}
