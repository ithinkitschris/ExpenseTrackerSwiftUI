import SwiftUI

/// Main content view - placeholder for now
/// This will be expanded with ExpenseListView in future iterations
struct ContentView: View {
    @Environment(\.theme) var theme
    @State private var showingImport = false
    @State private var importResult: String?

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    // App Icon/Logo placeholder
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 80))
                        .foregroundColor(theme.appleBlue)

                    Text("ExpenseTracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(theme.text)

                    Text("SwiftUI Edition")
                        .font(.title3)
                        .foregroundColor(theme.textSecondary)

                    Spacer()

                    // Import button (for testing)
                    VStack(spacing: 12) {
                        Button(action: {
                            showingImport = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Import Data")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.appleBlue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        if let result = importResult {
                            Text(result)
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Database info
                        VStack(spacing: 4) {
                            Text("Database Location:")
                                .font(.caption)
                                .foregroundColor(theme.textTertiary)
                            Text(DatabaseManager.shared.getDatabasePath())
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(theme.textSecondary)
                                .lineLimit(2)
                                .truncationMode(.middle)
                        }
                        .padding()
                    }

                    Spacer()
                }
            }
            .navigationTitle("Expenses")
            .fileImporter(
                isPresented: $showingImport,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                importResult = "❌ Access denied"
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let result = try MigrationHelper.shared.importFromFile(at: url)
                importResult = "✅ Imported \(result.imported) expenses"
                print(result.message)
            } catch {
                importResult = "❌ Import failed: \(error.localizedDescription)"
                print("Import error: \(error)")
            }

        case .failure(let error):
            importResult = "❌ Error: \(error.localizedDescription)"
            print("File picker error: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .theme(.light)
}
