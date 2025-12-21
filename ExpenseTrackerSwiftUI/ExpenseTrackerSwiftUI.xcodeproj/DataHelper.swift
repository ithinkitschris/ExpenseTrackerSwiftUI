import Foundation
import SwiftData

/// Helper utilities for SwiftData operations
struct DataHelper {
    
    /// Get the location of the SwiftData store (for debugging/migration)
    static func getDatabasePath() -> String {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let storeURL = appSupportURL.appendingPathComponent("default.store")
        return storeURL.path
    }
    
    /// Export all expenses to JSON format
    static func exportExpenses(from context: ModelContext) throws -> Data {
        let descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let expenses = try context.fetch(descriptor)
        
        let exportData = expenses.map { expense in
            [
                "amount": expense.amount,
                "category": expense.category,
                "description": expense.expenseDescription,
                "timestamp": ISO8601DateFormatter().string(from: expense.timestamp)
            ] as [String: Any]
        }
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    /// Import expenses from JSON data
    static func importExpenses(from data: Data, into context: ModelContext) throws -> Int {
        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw DataError.invalidFormat
        }
        
        let dateFormatter = ISO8601DateFormatter()
        var importedCount = 0
        
        for item in jsonArray {
            guard let amount = item["amount"] as? Double,
                  let category = item["category"] as? String,
                  let description = item["description"] as? String,
                  let timestampString = item["timestamp"] as? String,
                  let timestamp = dateFormatter.date(from: timestampString) else {
                continue
            }
            
            let expense = Expense(amount: amount, category: category, description: description, timestamp: timestamp)
            context.insert(expense)
            importedCount += 1
        }
        
        try context.save()
        return importedCount
    }
}

// MARK: - Errors

enum DataError: LocalizedError {
    case invalidFormat
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid JSON format"
        case .importFailed(let message):
            return "Import failed: \(message)"
        }
    }
}
