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
