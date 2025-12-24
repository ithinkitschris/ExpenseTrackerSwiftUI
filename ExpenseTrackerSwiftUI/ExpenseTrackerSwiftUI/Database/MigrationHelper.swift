import Foundation
import SQLite3

/// Helper for migrating data from the React Native app
final class MigrationHelper {
    /// Shared singleton instance
    static let shared = MigrationHelper()

    private init() {}

    // MARK: - JSON Import

    /// Import expenses from JSON file exported from React Native app
    /// - Parameter jsonData: Data object containing the JSON file
    /// - Returns: Import result with counts
    func importFromJSON(_ jsonData: Data) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData = try decoder.decode(ExportData.self, from: jsonData)

        print("📥 Starting import...")
        print("📊 Found \(exportData.expenses.count) expenses to import")

        // Convert ExpenseImport to Expense models
        let expenses = exportData.expenses.map { expenseImport in
            Expense(
                amount: expenseImport.amount,
                category: expenseImport.category,
                description: expenseImport.description,
                timestamp: expenseImport.timestamp
            )
        }

        let result = try DatabaseManager.shared.importExpenses(expenses)

        return ImportResult(
            imported: result.imported,
            skipped: result.skipped,
            total: exportData.expenses.count
        )
    }

    /// Import from JSON file URL
    /// - Parameter url: URL to the JSON file
    /// - Returns: Import result with counts
    func importFromFile(at url: URL) throws -> ImportResult {
        let jsonData = try Data(contentsOf: url)
        return try importFromJSON(jsonData)
    }

    /// Import from JSON string
    /// - Parameter jsonString: JSON string containing export data
    /// - Returns: Import result with counts
    func importFromString(_ jsonString: String) throws -> ImportResult {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw MigrationError.invalidJSON
        }
        return try importFromJSON(jsonData)
    }
    
    // MARK: - SQLite Export
    
    /// Export current SwiftData database to SQLite file
    /// - Returns: URL to the exported database file in temporary directory
    func exportToSQLite() throws -> URL {
        // Get all expenses from SwiftData
        let expenses = try DatabaseManager.shared.getExpenses(limit: 10000)
        
        // Create a temporary directory for the export
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        
        // Create a user-friendly filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        let exportFileName = "ExpenseTracker_\(dateString).db"
        let exportURL = tempDirectory.appendingPathComponent(exportFileName)
        
        // Remove existing file if it exists
        if fileManager.fileExists(atPath: exportURL.path) {
            try fileManager.removeItem(at: exportURL)
        }
        
        // Create new SQLite database
        var db: OpaquePointer?
        guard sqlite3_open(exportURL.path, &db) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            sqlite3_close(db)
            throw MigrationError.exportFailed("Failed to create database: \(errorMsg)")
        }
        
        defer {
            sqlite3_close(db)
        }
        
        // Create expenses table
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            timestamp TEXT NOT NULL
        );
        """
        
        var createTableStatement: OpaquePointer?
        guard sqlite3_prepare_v2(db, createTableSQL, -1, &createTableStatement, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            throw MigrationError.exportFailed("Failed to create table: \(errorMsg)")
        }
        
        guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            sqlite3_finalize(createTableStatement)
            throw MigrationError.exportFailed("Failed to execute create table: \(errorMsg)")
        }
        
        sqlite3_finalize(createTableStatement)
        
        // Insert all expenses
        let insertSQL = """
        INSERT INTO expenses (amount, category, description, timestamp)
        VALUES (?, ?, ?, ?);
        """
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        for expense in expenses {
            var insertStatement: OpaquePointer?
            guard sqlite3_prepare_v2(db, insertSQL, -1, &insertStatement, nil) == SQLITE_OK else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                throw MigrationError.exportFailed("Failed to prepare insert: \(errorMsg)")
            }
            
            // Bind values
            sqlite3_bind_double(insertStatement, 1, expense.amount)
            sqlite3_bind_text(insertStatement, 2, (expense.category as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, (expense.expenseDescription as NSString).utf8String, -1, nil)
            
            let timestampString = iso8601Formatter.string(from: expense.timestamp)
            sqlite3_bind_text(insertStatement, 4, (timestampString as NSString).utf8String, -1, nil)
            
            guard sqlite3_step(insertStatement) == SQLITE_DONE else {
                let errorMsg = String(cString: sqlite3_errmsg(db))
                sqlite3_finalize(insertStatement)
                throw MigrationError.exportFailed("Failed to insert expense: \(errorMsg)")
            }
            
            sqlite3_finalize(insertStatement)
        }
        
        print("✅ Database exported to: \(exportURL.path)")
        print("📊 Exported \(expenses.count) expenses")
        return exportURL
    }
    
    // MARK: - SQLite Direct Import
    
    /// Import expenses directly from SQLite database file
    /// - Parameter url: URL to the SQLite database file
    /// - Returns: Import result with counts
    func importFromSQLite(at url: URL) throws -> ImportResult {
        guard url.startAccessingSecurityScopedResource() else {
            throw MigrationError.fileNotFound
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Validate file extension
        let fileExtension = url.pathExtension.lowercased()
        guard fileExtension == "db" || fileExtension == "sqlite" || fileExtension == "sqlite3" else {
            throw MigrationError.invalidDatabase
        }
        
        var db: OpaquePointer?
        let dbPath = url.path
        
        // Open database
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            sqlite3_close(db)
            throw MigrationError.importFailed("Failed to open database: \(errorMsg)")
        }
        
        defer {
            sqlite3_close(db)
        }
        
        // Query expenses
        let query = "SELECT id, amount, category, description, timestamp FROM expenses ORDER BY timestamp DESC"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            throw MigrationError.importFailed("Failed to prepare query: \(errorMsg)")
        }
        
        var expenses: [Expense] = []
        let dateFormatter = ISO8601DateFormatter()
        
        // Fetch all rows
        while sqlite3_step(statement) == SQLITE_ROW {
            // id (column 0) - optional
            let id = sqlite3_column_int64(statement, 0)
            
            // amount (column 1)
            let amount = sqlite3_column_double(statement, 1)
            
            // category (column 2)
            guard let categoryCString = sqlite3_column_text(statement, 2) else { continue }
            let category = String(cString: categoryCString)
            
            // description (column 3)
            guard let descriptionCString = sqlite3_column_text(statement, 3) else { continue }
            let description = String(cString: descriptionCString)
            
            // timestamp (column 4)
            guard let timestampCString = sqlite3_column_text(statement, 4) else { continue }
            let timestampString = String(cString: timestampCString)
            
            // Parse timestamp - try multiple formats
            var timestamp: Date?
            
            // Try ISO8601 first
            timestamp = dateFormatter.date(from: timestampString)
            
            // If that fails, try Unix timestamp (seconds since 1970)
            if timestamp == nil, let unixTime = Double(timestampString) {
                timestamp = Date(timeIntervalSince1970: unixTime)
            }
            
            // If that fails, try RFC3339
            if timestamp == nil {
                let rfc3339Formatter = ISO8601DateFormatter()
                rfc3339Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                timestamp = rfc3339Formatter.date(from: timestampString)
            }
            
            guard let validTimestamp = timestamp else {
                print("⚠️ Skipping expense with invalid timestamp: \(timestampString)")
                continue
            }
            
            let expense = Expense(
                amount: amount,
                category: category,
                description: description,
                timestamp: validTimestamp
            )
            expenses.append(expense)
        }
        
        sqlite3_finalize(statement)
        
        print("📥 Starting SQLite import...")
        print("📊 Found \(expenses.count) expenses to import")
        
        // Import to SwiftData
        let result = try DatabaseManager.shared.importExpenses(expenses)
        
        return ImportResult(
            imported: result.imported,
            skipped: result.skipped,
            total: expenses.count
        )
    }
}

// MARK: - Data Models

/// Codable expense structure for JSON import/export
struct ExpenseImport: Codable {
    let id: Int?
    let amount: Double
    let category: String
    let description: String
    let timestamp: Date
}

/// Structure matching the React Native export format
struct ExportData: Codable {
    let version: String
    let exportedAt: Date
    let expenses: [ExpenseImport]

    enum CodingKeys: String, CodingKey {
        case version
        case exportedAt = "exported_at"
        case expenses
    }
}

/// Import result summary
struct ImportResult {
    let imported: Int
    let skipped: Int
    let total: Int

    var successRate: Double {
        guard total > 0 else { return 0 }
        return Double(imported) / Double(total) * 100
    }

    var message: String {
        """
        ✅ Import Complete
        Total: \(total)
        Imported: \(imported)
        Skipped: \(skipped)
        Success Rate: \(String(format: "%.1f", successRate))%
        """
    }
}

// MARK: - Error Types

enum MigrationError: Error, LocalizedError {
    case invalidJSON
    case fileNotFound
    case importFailed(String)
    case exportFailed(String)
    case invalidDatabase

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Invalid JSON format"
        case .fileNotFound:
            return "File not found"
        case .importFailed(let message):
            return "Import failed: \(message)"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        case .invalidDatabase:
            return "Invalid database format"
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension MigrationHelper {
    /// Create sample JSON file for testing
    func createSampleJSON() -> String {
        let sample = """
        {
          "version": "1.0",
          "exported_at": "\(ISO8601DateFormatter().string(from: Date()))",
          "expenses": [
            {
              "id": 1,
              "amount": 45.99,
              "category": "groceries",
              "description": "Whole Foods",
              "timestamp": "\(ISO8601DateFormatter().string(from: Date()))"
            },
            {
              "id": 2,
              "amount": 12.50,
              "category": "food",
              "description": "Coffee shop",
              "timestamp": "\(ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)))"
            }
          ]
        }
        """
        return sample
    }

    /// Test import with sample data
    func testImport() {
        do {
            let sampleJSON = createSampleJSON()
            let result = try importFromString(sampleJSON)
            print(result.message)
        } catch {
            print("❌ Test import failed: \(error)")
        }
    }
}
#endif
