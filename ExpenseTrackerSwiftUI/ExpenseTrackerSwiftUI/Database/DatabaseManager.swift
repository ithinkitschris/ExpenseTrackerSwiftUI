import Foundation
import SwiftData

/// Manages SwiftData operations for expenses
final class DatabaseManager {
    /// Shared singleton instance
    static let shared = DatabaseManager()
    
    /// Model context for database operations
    private var modelContext: ModelContext?
    
    private init() {}
    
    /// Set the model context (should be called from the app's environment)
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Database Setup
    
    /// Get database file path (useful for debugging/migration)
    func getDatabasePath() -> String {
        // SwiftData stores data in the app's container
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.path
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new expense
    func addExpense(amount: Double, category: String, description: String, timestamp: Date = Date()) throws -> Expense {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        let expense = Expense(amount: amount, category: category, description: description, timestamp: timestamp)
        context.insert(expense)
        
        do {
            try context.save()
            print("✅ Expense added: \(expense)")
            return expense
        } catch {
            context.delete(expense)
            throw error
        }
    }
    
    /// Get all expenses with optional limit
    func getExpenses(limit: Int = 200) throws -> [Expense] {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        var descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        return try context.fetch(descriptor)
    }
    
    /// Get expenses filtered by category
    func getExpensesByCategory(_ category: String, limit: Int = 200) throws -> [Expense] {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        var descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { expense in
                expense.category == category
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        return try context.fetch(descriptor)
    }
    
    /// Update an existing expense
    func updateExpense(_ expense: Expense) throws {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        do {
            try context.save()
            print("✅ Expense updated: \(expense)")
        } catch {
            throw error
        }
    }
    
    /// Delete an expense
    func deleteExpense(_ expense: Expense) throws {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        context.delete(expense)
        
        do {
            try context.save()
            print("✅ Expense deleted")
        } catch {
            throw error
        }
    }
    
    /// Delete expense by ID
    func deleteExpense(id: PersistentIdentifier) throws {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        // Find expense by ID
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { expense in
                expense.persistentModelID == id
            }
        )
        
        guard let expense = try context.fetch(descriptor).first else {
            throw DatabaseError.invalidExpense
        }
        
        context.delete(expense)
        
        do {
            try context.save()
            print("✅ Expense deleted")
        } catch {
            throw error
        }
    }
    
    // MARK: - Aggregate Queries
    
    /// Get total amount of all expenses
    func getTotalAmount() throws -> Double {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        let descriptor = FetchDescriptor<Expense>()
        let expenses = try context.fetch(descriptor)
        
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Get total amount by category
    func getTotalAmountByCategory(_ category: String) throws -> Double {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { expense in
                expense.category == category
            }
        )
        let expenses = try context.fetch(descriptor)
        
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Get expense count
    func getExpenseCount() throws -> Int {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        let descriptor = FetchDescriptor<Expense>()
        return try context.fetchCount(descriptor)
    }
    
    /// Get summary by category
    func getSummaryByCategory() throws -> [String: Double] {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        let descriptor = FetchDescriptor<Expense>()
        let expenses = try context.fetch(descriptor)
        
        var summary: [String: Double] = [:]
        for expense in expenses {
            summary[expense.category, default: 0] += expense.amount
        }
        
        return summary
    }
    
    // MARK: - Bulk Operations
    
    /// Import expenses from array (for migration)
    func importExpenses(_ expenses: [Expense]) throws -> (imported: Int, skipped: Int) {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        var imported = 0
        var skipped = 0
        
        for expense in expenses {
            do {
                // Extract values before creating predicate (SwiftData predicate limitations)
                let expenseTimestamp = expense.timestamp
                let expenseAmount = expense.amount
                let expenseDescription = expense.expenseDescription
                
                // Check if expense already exists (by timestamp, amount, and description)
                let descriptor = FetchDescriptor<Expense>(
                    predicate: #Predicate<Expense> { existingExpense in
                        existingExpense.timestamp == expenseTimestamp &&
                        existingExpense.amount == expenseAmount &&
                        existingExpense.expenseDescription == expenseDescription
                    }
                )
                
                let existingCount = try context.fetchCount(descriptor)
                
                if existingCount == 0 {
                    context.insert(expense)
                    imported += 1
                } else {
                    skipped += 1
                }
            } catch {
                print("⚠️ Error importing expense: \(error)")
                skipped += 1
            }
        }
        
        do {
            try context.save()
            print("✅ Import complete: \(imported) imported, \(skipped) skipped")
            return (imported, skipped)
        } catch {
            throw DatabaseError.importFailed(error.localizedDescription)
        }
    }
    
    /// Delete all expenses (use with caution)
    func deleteAllExpenses() throws {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        let descriptor = FetchDescriptor<Expense>()
        let expenses = try context.fetch(descriptor)
        
        for expense in expenses {
            context.delete(expense)
        }
        
        try context.save()
        print("✅ All expenses deleted")
    }
    
    // MARK: - Sample Data
    
    /// Seed placeholder expenses if database is empty
    func seedPlaceholderExpensesIfNeeded() throws {
        guard let context = modelContext else {
            throw DatabaseError.notInitialized
        }
        
        // Check if database already has expenses
        let descriptor = FetchDescriptor<Expense>()
        let existingCount = try context.fetchCount(descriptor)
        
        if existingCount > 0 {
            print("📊 Database already has \(existingCount) expenses, skipping seed")
            return
        }
        
        // Create sample expenses with varied dates
        let calendar = Calendar.current
        let now = Date()
        
        let placeholderExpenses: [(amount: Double, category: String, description: String, daysAgo: Int)] = [
            (45.99, "groceries", "Weekly grocery shopping", 0),
            (12.50, "food", "Lunch at cafe", 0),
            (29.99, "amazon", "USB-C cable", 1),
            (8.75, "transportation", "Subway fare", 1),
            (15.00, "food", "Coffee and pastries", 2),
            (89.50, "fashion", "New shirt", 3),
            (120.00, "monthly", "Gym membership", 4),
            (35.25, "groceries", "Organic produce", 5),
            (22.00, "food", "Dinner with friends", 5),
            (199.99, "furniture", "Desk lamp", 6),
            (5.50, "transportation", "Bus ticket", 7),
            (18.75, "food", "Breakfast", 7),
            (67.00, "personal", "Video game", 8),
            (45.00, "groceries", "Household items", 9),
            (150.00, "travel", "Hotel booking", 10),
            (9.99, "amazon", "Phone case", 11),
            (13.25, "food", "Fast food", 12),
            (55.00, "fashion", "Sneakers", 13),
            (25.50, "transportation", "Taxi ride", 14),
            (32.00, "food", "Restaurant dinner", 15)
        ]
        
        for expenseData in placeholderExpenses {
            let date = calendar.date(byAdding: .day, value: -expenseData.daysAgo, to: now) ?? now
            let expense = Expense(
                amount: expenseData.amount,
                category: expenseData.category,
                description: expenseData.description,
                timestamp: date
            )
            context.insert(expense)
        }
        
        try context.save()
        print("✅ Seeded \(placeholderExpenses.count) placeholder expenses")
    }
}

// MARK: - Error Types

enum DatabaseError: Error, LocalizedError {
    case notInitialized
    case invalidExpense
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database not initialized"
        case .invalidExpense:
            return "Invalid expense (missing ID)"
        case .importFailed(let message):
            return "Import failed: \(message)"
        }
    }
}
