import Foundation

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

        let result = try DatabaseManager.shared.importExpenses(exportData.expenses)

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
}

// MARK: - Data Models

/// Structure matching the React Native export format
struct ExportData: Codable {
    let version: String
    let exportedAt: Date
    let expenses: [Expense]

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

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Invalid JSON format"
        case .fileNotFound:
            return "JSON file not found"
        case .importFailed(let message):
            return "Import failed: \(message)"
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
