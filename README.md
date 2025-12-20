# ExpenseTracker SwiftUI

A native iOS expense tracking app built with SwiftUI, featuring SQLite database storage and data migration from the React Native version.

## Features

- ✅ **Core Expense Management**: Add, edit, and delete expenses
- ✅ **Category Organization**: 9 expense categories with SF Symbol icons
- ✅ **SQLite Database**: GRDB-powered local storage
- ✅ **Data Migration**: Import expenses from React Native app
- ✅ **Native Design**: SwiftUI with Apple's design system
- ✅ **Light/Dark Mode**: Automatic theme switching

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Project Structure

```
ExpenseTrackerSwiftUI/
├── App/
│   └── ExpenseTrackerSwiftUIApp.swift   # App entry point
├── Models/
│   └── Expense.swift                     # Core expense model
├── Database/
│   ├── DatabaseManager.swift             # SQLite operations
│   └── MigrationHelper.swift             # JSON import
├── Views/
│   └── ContentView.swift                 # Main view
├── ViewModels/
│   └── (Future view models)
├── Utilities/
│   ├── Theme.swift                       # Color theme system
│   └── Constants.swift                   # App constants
└── migration/
    ├── export_expenses_for_swift.js      # Export script
    └── package.json
```

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. File → New → Project
3. Select "App" under iOS
4. Project settings:
   - **Product Name**: ExpenseTrackerSwiftUI
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Minimum Deployment**: iOS 17.0
5. Save to this directory (ExpenseTrackerSwiftUI/)

### 2. Add GRDB Dependency

1. In Xcode, select your project in the navigator
2. Select your target → General tab
3. Scroll to "Frameworks, Libraries, and Embedded Content"
4. Click "+" → Add Package Dependency
5. Enter URL: `https://github.com/groue/GRDB.swift.git`
6. Select version: Up to Next Major (6.0.0)
7. Click "Add Package"

### 3. Add Source Files

Copy all Swift files from this repository into your Xcode project:

```bash
# The files are already in the correct folders
# Just drag them into Xcode's project navigator
```

### 4. Configure Build Settings

Ensure these settings in Xcode:
- **Build Settings** → **Swift Compiler - Language** → **Swift Language Version**: Swift 5
- **Info.plist**: No special permissions needed for basic functionality

## Data Migration

### Export from React Native App

1. Navigate to the migration folder:
   ```bash
   cd migration
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Find your React Native database:
   ```bash
   # For iOS Simulator
   find ~/Library/Developer/CoreSimulator -name "expenses.db" -type f
   ```

4. Export expenses:
   ```bash
   # If database is in the React Native project:
   node export_expenses_for_swift.js

   # Or specify custom path:
   DB_PATH=/path/to/expenses.db node export_expenses_for_swift.js
   ```

5. This creates `expenses_export.json` with all your expenses

### Import to SwiftUI App

1. Build and run the SwiftUI app in Xcode
2. Click "Import Data" button
3. Select the `expenses_export.json` file
4. The app will import all expenses and show the results

Alternatively, you can use AirDrop or Files app to transfer the JSON file to your device.

## Database Schema

The app uses the same schema as the React Native version:

```sql
CREATE TABLE expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount REAL NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    timestamp TEXT NOT NULL
);
```

### Database Location

The SQLite database is stored at:
```
~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/expenses.db
```

You can find the exact path in the app's debug output or on the main screen.

## Categories

The app supports these expense categories (matching React Native app):

- **Amazon** (📦 shippingbox.fill) - Brown
- **Transportation** (🚋 tram.fill) - Indigo
- **Groceries** (🛒 cart.fill) - Mint
- **Personal** (🎮 gamecontroller.fill) - Purple
- **Fashion** (👕 tshirt.fill) - Pink
- **Travel** (✈️ airplane) - Cyan
- **Food** (🍴 fork.knife) - Red
- **Monthly** (📅 calendar) - Gray
- **Furniture** (🛏️ bed.double.fill) - Orange

## Development

### Running the App

1. Open the `.xcodeproj` file in Xcode
2. Select a simulator or device
3. Press Cmd+R to build and run

### Debugging Database

```swift
// Print database path
print(DatabaseManager.shared.getDatabasePath())

// View database with sqlite3
// Run in terminal:
sqlite3 /path/to/expenses.db
.tables
SELECT * FROM expenses;
```

### Testing Import

```swift
// In MigrationHelper.swift (DEBUG mode)
MigrationHelper.shared.testImport()
```

## Roadmap

### MVP (Current Implementation)
- ✅ Expense model with GRDB
- ✅ DatabaseManager with CRUD operations
- ✅ Migration tools (export/import)
- ✅ Theme system
- ⏳ ExpenseListView (next)
- ⏳ AddExpenseSheet (next)
- ⏳ Category filtering (next)

### Future Enhancements
- [ ] Monthly summary view
- [ ] Charts with Swift Charts
- [ ] iOS widgets
- [ ] Shortcuts integration
- [ ] iCloud sync
- [ ] Export/backup features
- [ ] Search and advanced filtering

## Architecture

### Database Layer (GRDB)
- **GRDB.swift**: Modern SQLite wrapper for Swift
- **Type-safe**: Compile-time query validation
- **Performance**: Optimized for iOS
- **Migrations**: Built-in schema versioning

### Theme System
- Matches React Native app's Apple color palette
- Automatic light/dark mode support
- Consistent category colors across platforms

### Data Migration
- One-way, one-time migration
- Duplicate detection
- Error handling with detailed reporting

## Troubleshooting

### GRDB Not Found
```
Error: No such module 'GRDB'
```
**Solution**: Make sure you added the GRDB package dependency in Xcode

### Import Failed
```
Error: Access denied
```
**Solution**: Ensure the JSON file is accessible (use Files app or AirDrop to your device)

### Database Location
The database path is shown in the app. You can also find it in console output when the app launches.

## License

MIT

## Contributing

This is a personal project, but suggestions and improvements are welcome!
