import SwiftUI
import SwiftData

#Preview("Add Multiple Expenses - Empty") {
    @Previewable @State var shouldDismiss = false
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Expense.self, configurations: config)
    
    AddMultipleExpensesSheet(shouldDismissParent: $shouldDismiss)
        .modelContainer(container)
        .theme(.light)
}

#Preview("Add Multiple Expenses - Dark Mode") {
    @Previewable @State var shouldDismiss = false
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Expense.self, configurations: config)
    
    AddMultipleExpensesSheet(shouldDismissParent: $shouldDismiss)
        .modelContainer(container)
        .theme(.dark)
}
