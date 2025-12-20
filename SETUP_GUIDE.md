# Setup Guide

This guide walks you through setting up the SwiftUI ExpenseTracker project in Xcode.

## Current Status

✅ **Completed (Todos 1-3)**:
- Project structure created
- Expense model with GRDB
- DatabaseManager with CRUD operations
- Data migration tools (export/import)
- Theme system
- Constants and configuration

## Next Steps

### 1. Create Xcode Project (5 minutes)

1. Open Xcode
2. **File → New → Project**
3. Select **iOS → App**
4. Configure project:
   ```
   Product Name: ExpenseTrackerSwiftUI
   Team: Your Team
   Organization Identifier: com.yourname
   Interface: SwiftUI
   Language: Swift
   Storage: None (we're using GRDB)
   Include Tests: ✓ (optional)
   ```
5. Save location: **Choose this folder** (`~/Documents/GitHub/ExpenseTrackerSwiftUI`)
6. When asked about creating Git repository, select **No** (we already have one)

### 2. Add Swift Files to Xcode (2 minutes)

1. In Xcode's Project Navigator (left sidebar), **delete** the default files:
   - `ContentView.swift` (we have our own)
   - `ExpenseTrackerSwiftUIApp.swift` (we have our own)

2. **Drag and drop** these folders from Finder into Xcode:
   - `ExpenseTrackerSwiftUI/App/`
   - `ExpenseTrackerSwiftUI/Models/`
   - `ExpenseTrackerSwiftUI/Database/`
   - `ExpenseTrackerSwiftUI/Views/`
   - `ExpenseTrackerSwiftUI/Utilities/`

3. When prompted, ensure:
   - ✓ **Copy items if needed**
   - ✓ **Create groups** (not folder references)
   - ✓ **Add to targets: ExpenseTrackerSwiftUI**

### 3. Add GRDB Dependency (3 minutes)

1. In Xcode, select your project in the navigator (top item)
2. Select the **ExpenseTrackerSwiftUI** target
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Click **+** button
6. Click **Add Package Dependency...**
7. Enter URL: `https://github.com/groue/GRDB.swift.git`
8. Version: **Up to Next Major Version** → `6.0.0`
9. Click **Add Package**
10. Select **GRDB** library
11. Click **Add Package**

### 4. Build and Run (1 minute)

1. Select a simulator: **iPhone 15 Pro** (or any iOS 17+ device)
2. Press **Cmd+R** to build and run
3. You should see the app launch with:
   - ExpenseTracker logo
   - Import Data button
   - Database path display

### 5. Test Data Migration (Optional)

If you want to test the migration from your React Native app:

```bash
# Navigate to migration folder
cd ~/Documents/GitHub/ExpenseTrackerSwiftUI/migration

# Install dependencies
npm install

# Export data from React Native app
# Option 1: Auto-detect database
node export_expenses_for_swift.js

# Option 2: Specify database path
DB_PATH=/path/to/expenses.db node export_expenses_for_swift.js

# This creates expenses_export.json
```

Then in the SwiftUI app:
1. Click **Import Data**
2. Select `expenses_export.json`
3. See import results

## Troubleshooting

### "No such module 'GRDB'"
- Make sure you completed step 3 (Add GRDB Dependency)
- Try **Product → Clean Build Folder** (Shift+Cmd+K)
- Restart Xcode

### Files not showing in Xcode
- Make sure you dragged folders into the **project navigator** (left sidebar)
- Ensure "Add to targets" was checked
- Try removing and re-adding the files

### Build errors
- Check that all files are added to the target
- Ensure deployment target is iOS 17.0+
- Clean and rebuild (Shift+Cmd+K, then Cmd+B)

## Project Structure After Setup

```
ExpenseTrackerSwiftUI/
├── ExpenseTrackerSwiftUI.xcodeproj    # Created by Xcode
├── ExpenseTrackerSwiftUI/
│   ├── App/
│   │   └── ExpenseTrackerSwiftUIApp.swift
│   ├── Models/
│   │   └── Expense.swift
│   ├── Database/
│   │   ├── DatabaseManager.swift
│   │   └── MigrationHelper.swift
│   ├── Views/
│   │   └── ContentView.swift
│   ├── Utilities/
│   │   ├── Theme.swift
│   │   └── Constants.swift
│   ├── Assets.xcassets/              # Created by Xcode
│   └── Preview Content/              # Created by Xcode
├── migration/
│   ├── export_expenses_for_swift.js
│   ├── package.json
│   └── README.md
├── .gitignore
└── README.md
```

## What's Next?

After completing this setup, you can continue with the plan:

**Todo 4: Core UI Components**
- [ ] Build ExpenseListView
- [ ] Create ExpenseRow component
- [ ] Add grouping by day functionality

**Todo 5: Add Expense UI**
- [ ] Implement AddExpenseSheet
- [ ] Create WheelAmountPicker
- [ ] Add CategoryPicker

**Todo 6: Polish**
- [ ] Add haptic feedback
- [ ] Implement animations
- [ ] Create empty states
- [ ] Error handling with alerts

## Verification Checklist

After setup, verify:
- [ ] App builds without errors
- [ ] App launches in simulator
- [ ] You can see the main screen
- [ ] Database path is displayed
- [ ] Import button is visible
- [ ] No GRDB import errors

## Getting Help

If you encounter issues:
1. Check the Troubleshooting section above
2. Review [README.md](README.md) for detailed information
3. Check GRDB documentation: https://github.com/groue/GRDB.swift
4. Ensure you're using Xcode 15+ and iOS 17+ simulator

---

**Estimated Setup Time**: 10-15 minutes

Once setup is complete, you'll have a working SwiftUI app ready for building out the expense list and input UI!
