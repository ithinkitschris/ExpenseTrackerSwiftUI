import Foundation
import GRDB

/// Manages SQLite database operations using GRDB
final class DatabaseManager {
    /// Shared singleton instance
    static let shared = DatabaseManager()

    /// Database queue for thread-safe operations
    private var dbQueue: DatabaseQueue?

    /// Database file path in Documents directory
    private var dbPath: String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent("expenses.db").path
    }

    private init() {
        setupDatabase()
    }

    // MARK: - Database Setup

    /// Initialize database and create tables
    private func setupDatabase() {
        do {
            dbQueue = try DatabaseQueue(path: dbPath)
            try dbQueue?.write { db in
                try Expense.createTable(db)
            }
            print("✅ Database initialized at: \(dbPath)")
        } catch {
            print("❌ Database setup error: \(error)")
        }
    }

    /// Get database file path (useful for debugging/migration)
    func getDatabasePath() -> String {
        return dbPath
    }

    // MARK: - CRUD Operations

    /// Add a new expense
    func addExpense(amount: Double, category: String, description: String, timestamp: Date = Date()) throws -> Expense {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        var expense = Expense(amount: amount, category: category, description: description, timestamp: timestamp)

        try dbQueue.write { db in
            try expense.insert(db)
        }

        print("✅ Expense added: \(expense)")
        return expense
    }

    /// Get all expenses with optional limit
    func getExpenses(limit: Int = 200) throws -> [Expense] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        let expenses = try dbQueue.read { db in
            try Expense
                .order(Expense.Columns.timestamp.desc)
                .limit(limit)
                .fetchAll(db)
        }

        return expenses
    }

    /// Get expenses filtered by category
    func getExpensesByCategory(_ category: String, limit: Int = 200) throws -> [Expense] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        let expenses = try dbQueue.read { db in
            try Expense
                .filter(Expense.Columns.category == category)
                .order(Expense.Columns.timestamp.desc)
                .limit(limit)
                .fetchAll(db)
        }

        return expenses
    }

    /// Update an existing expense
    func updateExpense(_ expense: Expense) throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        guard expense.id != nil else {
            throw DatabaseError.invalidExpense
        }

        try dbQueue.write { db in
            try expense.update(db)
        }

        print("✅ Expense updated: \(expense)")
    }

    /// Delete an expense
    func deleteExpense(_ expense: Expense) throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        guard let id = expense.id else {
            throw DatabaseError.invalidExpense
        }

        try dbQueue.write { db in
            try Expense.deleteOne(db, id: id)
        }

        print("✅ Expense deleted: \(id)")
    }

    /// Delete expense by ID
    func deleteExpense(id: Int64) throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try dbQueue.write { db in
            try Expense.deleteOne(db, id: id)
        }

        print("✅ Expense deleted: \(id)")
    }

    // MARK: - Aggregate Queries

    /// Get total amount of all expenses
    func getTotalAmount() throws -> Double {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        let total = try dbQueue.read { db in
            try Expense
                .select(Expense.Columns.amount.sum)
                .fetchOne(db) ?? 0
        }

        return total
    }

    /// Get total amount by category
    func getTotalAmountByCategory(_ category: String) throws -> Double {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        let total = try dbQueue.read { db in
            try Expense
                .filter(Expense.Columns.category == category)
                .select(Expense.Columns.amount.sum)
                .fetchOne(db) ?? 0
        }

        return total
    }

    /// Get expense count
    func getExpenseCount() throws -> Int {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        let count = try dbQueue.read { db in
            try Expense.fetchCount(db)
        }

        return count
    }

    /// Get summary by category
    func getSummaryByCategory() throws -> [String: Double] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        let rows = try dbQueue.read { db -> [[String: Any]] in
            let rows = try Row.fetchAll(db, sql: """
                SELECT category, SUM(amount) as total
                FROM expenses
                GROUP BY category
                ORDER BY total DESC
                """)
            return rows.map { row in
                ["category": row["category"] as String, "total": row["total"] as Double]
            }
        }

        var summary: [String: Double] = [:]
        for row in rows {
            if let category = row["category"] as? String,
               let total = row["total"] as? Double {
                summary[category] = total
            }
        }

        return summary
    }

    // MARK: - Bulk Operations

    /// Import expenses from array (for migration)
    func importExpenses(_ expenses: [Expense]) throws -> (imported: Int, skipped: Int) {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        var imported = 0
        var skipped = 0

        try dbQueue.write { db in
            for var expense in expenses {
                do {
                    // Check if expense already exists (by timestamp, amount, and description)
                    let existingCount = try Expense
                        .filter(Expense.Columns.timestamp == expense.timestamp &&
                               Expense.Columns.amount == expense.amount &&
                               Expense.Columns.description == expense.description)
                        .fetchCount(db)

                    if existingCount == 0 {
                        try expense.insert(db)
                        imported += 1
                    } else {
                        skipped += 1
                    }
                } catch {
                    print("⚠️ Error importing expense: \(error)")
                    skipped += 1
                }
            }
        }

        print("✅ Import complete: \(imported) imported, \(skipped) skipped")
        return (imported, skipped)
    }

    /// Delete all expenses (use with caution)
    func deleteAllExpenses() throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        try dbQueue.write { db in
            try Expense.deleteAll(db)
        }

        print("✅ All expenses deleted")
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
