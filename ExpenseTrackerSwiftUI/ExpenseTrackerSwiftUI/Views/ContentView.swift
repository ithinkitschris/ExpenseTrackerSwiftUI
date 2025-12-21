import SwiftUI
import UniformTypeIdentifiers

/// Main content view with tabs for expenses and settings
struct ContentView: View {
    @Environment(\.theme) var theme
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ExpenseListView()
        }
        .tint(theme.appleBlue)
        .background(theme.background)
    }
}

/// Settings view with import functionality
struct SettingsView: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @State private var showingImport = false
    @State private var showingSQLiteImport = false
    @State private var importResult: String?

    var body: some View {
        List {
            Section("Data Migration") {
                Button(action: {
                    showingImport = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(theme.appleBlue)
                        Text("Import from JSON")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(theme.textTertiary)
                    }
                }
                
                Button(action: {
                    showingSQLiteImport = true
                }) {
                    HStack {
                        Image(systemName: "externaldrive")
                            .foregroundColor(theme.appleBlue)
                        Text("Import from SQLite Database")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(theme.textTertiary)
                    }
                }

                if let result = importResult {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }

            Section("Database") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)

                    Text(DatabaseManager.shared.getDatabasePath())
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(theme.textSecondary)
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(theme.textSecondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text("SwiftUI + SwiftData")
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle("Settings")
        .fileImporter(
            isPresented: $showingImport,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleJSONImport(result)
        }
        .fileImporter(
            isPresented: $showingSQLiteImport,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            handleSQLiteImport(result)
        }
    }

    private func handleJSONImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                importResult = "❌ Access denied"
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let result = try MigrationHelper.shared.importFromJSON(data)
                importResult = result.message
            } catch {
                importResult = "❌ Import failed: \(error.localizedDescription)"
                print("Import error: \(error)")
            }

        case .failure(let error):
            importResult = "❌ Error: \(error.localizedDescription)"
            print("File picker error: \(error)")
        }
    }
    
    private func handleSQLiteImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                importResult = "❌ Access denied"
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let result = try MigrationHelper.shared.importFromSQLite(at: url)
                importResult = result.message
            } catch {
                importResult = "❌ Import failed: \(error.localizedDescription)"
                print("SQLite import error: \(error)")
            }

        case .failure(let error):
            importResult = "❌ Error: \(error.localizedDescription)"
            print("File picker error: \(error)")
        }
    }
}

#Preview("Light Mode") {
    ContentView()
        .theme(.light)
}

#Preview("Dark Mode") {
    ContentView()
        .theme(.dark)
}

#Preview("Light Mode - Settings Tab") {
    ContentView()
        .theme(.light)
        .onAppear {
            // Preview opens to settings tab
        }
}
