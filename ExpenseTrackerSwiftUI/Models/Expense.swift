import Foundation
import GRDB

/// Core expense model matching the React Native app's schema
struct Expense: Identifiable, Codable {
    var id: Int64?
    var amount: Double
    var category: String
    var description: String
    var timestamp: Date

    /// Initialize a new expense
    init(id: Int64? = nil, amount: Double, category: String, description: String, timestamp: Date = Date()) {
        self.id = id
        self.amount = amount
        self.category = category
        self.description = description
        self.timestamp = timestamp
    }
}

// MARK: - GRDB Support

extension Expense: FetchableRecord, MutablePersistableRecord {
    /// Database table name
    static let databaseTableName = "expenses"

    /// Column names
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let amount = Column(CodingKeys.amount)
        static let category = Column(CodingKeys.category)
        static let description = Column(CodingKeys.description)
        static let timestamp = Column(CodingKeys.timestamp)
    }

    /// Update expense ID after insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Database Migrations

extension Expense {
    /// Create the expenses table
    static func createTable(_ db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("amount", .double).notNull()
            t.column("category", .text).notNull()
            t.column("description", .text).notNull()
            t.column("timestamp", .datetime).notNull()
        }
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
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: timestamp)
    }
}
