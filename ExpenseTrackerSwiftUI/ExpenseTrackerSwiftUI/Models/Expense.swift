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
    
    /// Get the start of the week for this expense
    var weekStartDate: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: timestamp)
        return calendar.date(from: components) ?? timestamp
    }
    
    /// Format timestamp as week header
    var weekHeader: String {
        let calendar = Calendar.current
        let weekStart = weekStartDate
        
        // Get the week of month (1-based)
        let weekOfMonth = calendar.component(.weekOfMonth, from: weekStart)
        
        // Get the month name
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: weekStart)
        
        // Create ordinal suffix (1st, 2nd, 3rd, 4th, etc.)
        let ordinal: String
        switch weekOfMonth {
        case 1: ordinal = "1st"
        case 2: ordinal = "2nd"
        case 3: ordinal = "3rd"
        default: ordinal = "\(weekOfMonth)th"
        }
        
        return "\(ordinal) Week of \(monthName)"
    }
    
    /// Get the start of the month for this expense
    var monthStartDate: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: timestamp)
        return calendar.date(from: components) ?? timestamp
    }
    
    /// Format timestamp as month header
    var monthHeader: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: timestamp)
    }
}
