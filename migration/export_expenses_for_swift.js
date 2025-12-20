#!/usr/bin/env node

/**
 * Export Expenses for SwiftUI Migration
 *
 * This script exports expenses from the React Native app's SQLite database
 * to a JSON format compatible with the SwiftUI app's import functionality.
 *
 * Usage:
 *   node export_expenses_for_swift.js [output_file]
 *
 * Example:
 *   node export_expenses_for_swift.js expenses_export.json
 */

const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

// Configuration
const REACT_NATIVE_PROJECT_PATH = path.join(__dirname, '../../expense-assistant/ExpenseTracker');
const DEFAULT_OUTPUT_FILE = 'expenses_export.json';

// Get output file from command line args or use default
const outputFile = process.argv[2] || DEFAULT_OUTPUT_FILE;
const outputPath = path.join(__dirname, outputFile);

// Function to find the SQLite database file
function findDatabasePath() {
  // Common locations where Expo/React Native stores SQLite databases
  const possiblePaths = [
    // Development database in the project
    path.join(REACT_NATIVE_PROJECT_PATH, 'expenses.db'),
    // Simulator path (iOS)
    path.join(process.env.HOME, 'Library/Developer/CoreSimulator/Devices'),
  ];

  // First check the project directory
  if (fs.existsSync(possiblePaths[0])) {
    return possiblePaths[0];
  }

  console.log('⚠️  Database not found in project directory.');
  console.log('📍 Please provide the full path to your expenses.db file:');
  console.log('   Example: ~/Library/Developer/CoreSimulator/Devices/.../expenses.db');
  console.log('');
  console.log('💡 Tip: You can find it by searching for "expenses.db" in your simulator data:');
  console.log('   find ~/Library/Developer/CoreSimulator -name "expenses.db" -type f');
  return null;
}

// Export expenses from database
async function exportExpenses(dbPath) {
  return new Promise((resolve, reject) => {
    console.log('📂 Opening database:', dbPath);

    const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
      if (err) {
        reject(new Error(`Failed to open database: ${err.message}`));
        return;
      }
    });

    db.all('SELECT id, amount, category, description, timestamp FROM expenses ORDER BY timestamp DESC', [], (err, rows) => {
      if (err) {
        db.close();
        reject(new Error(`Failed to query expenses: ${err.message}`));
        return;
      }

      console.log(`✅ Found ${rows.length} expenses`);

      // Format the export data
      const exportData = {
        version: '1.0',
        exported_at: new Date().toISOString(),
        expenses: rows.map(row => ({
          id: row.id,
          amount: row.amount,
          category: row.category,
          description: row.description,
          timestamp: row.timestamp // Already in ISO8601 format from SQLite
        }))
      };

      db.close((err) => {
        if (err) {
          reject(new Error(`Error closing database: ${err.message}`));
          return;
        }
        resolve(exportData);
      });
    });
  });
}

// Write JSON file
function writeJSON(data, filePath) {
  const jsonString = JSON.stringify(data, null, 2);
  fs.writeFileSync(filePath, jsonString, 'utf8');
  console.log('✅ Export complete!');
  console.log('📄 File saved to:', filePath);
  console.log('📊 Statistics:');
  console.log(`   - Total expenses: ${data.expenses.length}`);

  // Show category breakdown
  const categoryBreakdown = data.expenses.reduce((acc, expense) => {
    acc[expense.category] = (acc[expense.category] || 0) + 1;
    return acc;
  }, {});

  console.log('   - By category:');
  Object.entries(categoryBreakdown)
    .sort((a, b) => b[1] - a[1])
    .forEach(([category, count]) => {
      console.log(`     • ${category}: ${count}`);
    });

  // Show total amount
  const totalAmount = data.expenses.reduce((sum, expense) => sum + expense.amount, 0);
  console.log(`   - Total amount: $${totalAmount.toFixed(2)}`);
}

// Main execution
async function main() {
  console.log('🚀 Starting expense export for SwiftUI migration...\n');

  try {
    // Find database
    const dbPath = findDatabasePath();

    if (!dbPath) {
      console.log('\n❌ Database not found. Please specify the path as an environment variable:');
      console.log('   DB_PATH=/path/to/expenses.db node export_expenses_for_swift.js\n');
      process.exit(1);
    }

    // Check if custom path provided via environment variable
    const customDbPath = process.env.DB_PATH;
    const finalDbPath = customDbPath || dbPath;

    if (!fs.existsSync(finalDbPath)) {
      console.error(`❌ Database file not found at: ${finalDbPath}`);
      process.exit(1);
    }

    // Export data
    const exportData = await exportExpenses(finalDbPath);

    // Write to file
    writeJSON(exportData, outputPath);

    console.log('\n📱 Next steps:');
    console.log('   1. Copy this file to your iOS device/simulator');
    console.log('   2. In the SwiftUI app, use the import feature');
    console.log('   3. Select this JSON file to import your expenses\n');

  } catch (error) {
    console.error('❌ Export failed:', error.message);
    process.exit(1);
  }
}

// Handle custom database path from command line
if (process.argv.length > 3) {
  console.log('Usage: node export_expenses_for_swift.js [output_file]');
  console.log('Or: DB_PATH=/path/to/expenses.db node export_expenses_for_swift.js [output_file]');
  process.exit(1);
}

main();
