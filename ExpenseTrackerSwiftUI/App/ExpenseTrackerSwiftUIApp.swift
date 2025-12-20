import SwiftUI

@main
struct ExpenseTrackerSwiftUIApp: App {
    @Environment(\.colorScheme) var colorScheme

    var body: some Scene {
        WindowGroup {
            ContentView()
                .theme(colorScheme == .dark ? Theme.dark : Theme.light)
                .preferredColorScheme(nil) // Support system light/dark mode
        }
    }
}
