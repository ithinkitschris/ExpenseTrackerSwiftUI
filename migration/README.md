# Data Migration Tools

This folder contains tools for migrating data from the React Native ExpenseTracker app to the SwiftUI version.

## Quick Start

```bash
# Install dependencies
npm install

# Export data (auto-detect database location)
node export_expenses_for_swift.js

# Or specify custom database path
DB_PATH=/path/to/expenses.db node export_expenses_for_swift.js custom_output.json
```

## How It Works

### 1. Export Script

The `export_expenses_for_swift.js` script:
- Reads from the React Native app's SQLite database
- Exports all expenses to JSON format
- Creates a file compatible with SwiftUI app's import feature
- Includes validation and duplicate detection

### 2. Finding Your Database

For iOS Simulator:
```bash
find ~/Library/Developer/CoreSimulator -name "expenses.db" -type f
```

For React Native project (if you have a development database):
```bash
# Usually located in:
../expense-assistant/ExpenseTracker/expenses.db
```

### 3. Export Format

The script creates a JSON file with this structure:

```json
{
  "version": "1.0",
  "exported_at": "2025-12-20T10:30:00.000Z",
  "expenses": [
    {
      "id": 1,
      "amount": 45.99,
      "category": "groceries",
      "description": "Whole Foods",
      "timestamp": "2025-12-20T10:00:00.000Z"
    }
  ]
}
```

### 4. Import to SwiftUI

1. Run the export script to create `expenses_export.json`
2. Open the SwiftUI app in Xcode and run it
3. Tap "Import Data" button
4. Select the JSON file
5. The app will import all expenses and skip duplicates

## Usage Examples

### Basic Export
```bash
node export_expenses_for_swift.js
# Creates: expenses_export.json
```

### Custom Output File
```bash
node export_expenses_for_swift.js backup_2025_12_20.json
# Creates: backup_2025_12_20.json
```

### Custom Database Path
```bash
DB_PATH=/Users/chris/my_expenses.db node export_expenses_for_swift.js
# Reads from custom path, creates: expenses_export.json
```

### Both Custom
```bash
DB_PATH=/path/to/expenses.db node export_expenses_for_swift.js my_backup.json
# Custom input and output
```

## Output Information

The script provides detailed statistics:

```
✅ Found 150 expenses
✅ Export complete!
📄 File saved to: /path/to/expenses_export.json
📊 Statistics:
   - Total expenses: 150
   - By category:
     • groceries: 45
     • food: 32
     • transportation: 28
     • amazon: 20
     • personal: 15
     • fashion: 10
   - Total amount: $4,567.89
```

## Troubleshooting

### Database Not Found
```
❌ Database not found. Please specify the path as an environment variable
```

**Solution**: Use the `DB_PATH` environment variable:
```bash
DB_PATH=/full/path/to/expenses.db node export_expenses_for_swift.js
```

### Permission Denied
```
Error: Failed to open database: unable to open database file
```

**Solution**: Ensure you have read permissions for the database file:
```bash
ls -l /path/to/expenses.db
```

### Module Not Found
```
Error: Cannot find module 'sqlite3'
```

**Solution**: Install dependencies:
```bash
npm install
```

## Data Safety

The export script:
- **Read-only**: Never modifies the original database
- **Non-destructive**: The React Native app continues to work
- **Duplicate-safe**: Import process skips existing expenses
- **Validated**: Checks data integrity during export

## Next Steps

After exporting:

1. **Verify Export**: Check the JSON file is created and has your data
2. **Transfer to iOS**: Use AirDrop, Files app, or Xcode's simulated file system
3. **Import**: Use the SwiftUI app's import feature
4. **Validate**: Check that all expenses imported correctly
5. **Keep Backup**: Save the JSON file as a backup

## Script Details

### Dependencies
- `sqlite3`: SQLite database access
- `fs`: File system operations (built-in)
- `path`: Path utilities (built-in)

### Configuration
The script auto-detects:
- React Native project location (relative path)
- iOS Simulator database locations
- JSON export format for SwiftUI compatibility

### Error Handling
- Validates database exists before opening
- Handles SQLite errors gracefully
- Provides clear error messages
- Safe cleanup on failure

## Development

To modify the export script:

1. Edit `export_expenses_for_swift.js`
2. Test with your database:
   ```bash
   node export_expenses_for_swift.js test_output.json
   ```
3. Verify JSON format matches SwiftUI's `ExportData` struct

## Related Files

- `export_expenses_for_swift.js` - Main export script
- `package.json` - Node.js dependencies
- `../ExpenseTrackerSwiftUI/Database/MigrationHelper.swift` - SwiftUI import logic
