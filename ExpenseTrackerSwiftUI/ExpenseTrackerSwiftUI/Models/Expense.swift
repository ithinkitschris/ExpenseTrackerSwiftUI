import Foundation
import SwiftData

/// Core expense model for SwiftData persistence
@Model
final class Expense {
    var amount: Double
    var category: String
    var expenseDescription: String  // 'description' is reserved in SwiftData
    var timestamp: Date
    
    /// Initialize a new expense
    init(amount: Double, category: String, description: String, timestamp: Date = Date()) {
        self.amount = amount
        self.category = category
        self.expenseDescription = description
        self.timestamp = timestamp
    }
}


// MARK: - Convenience Extensions

extension Expense {
    /// Format amount as currency string
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    /// Format timestamp as date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    /// Format timestamp as day header
    var dayHeader: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: timestamp)
    }
}
