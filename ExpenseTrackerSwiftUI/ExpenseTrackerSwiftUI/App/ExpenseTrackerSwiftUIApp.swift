import SwiftUI
import SwiftData

@main
struct ExpenseTrackerSwiftUIApp: App {
    // SwiftData model container
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Configure the SwiftData container with our Expense model
            modelContainer = try ModelContainer(for: Expense.self)
            // Initialize DatabaseManager with model context
            DatabaseManager.shared.setModelContext(modelContainer.mainContext)
            
            // Seed placeholder expenses if database is empty
            do {
                try DatabaseManager.shared.seedPlaceholderExpensesIfNeeded()
            } catch {
                print("⚠️ Failed to seed placeholder expenses: \(error)")
                // Don't crash the app if seeding fails
            }
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ThemeWrapperView()
        }
        .modelContainer(modelContainer)
    }
}

/// Wrapper view that detects color scheme and applies appropriate theme
struct ThemeWrapperView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ContentView()
            .theme(colorScheme == .dark ? Theme.dark : Theme.light)
    }
}
