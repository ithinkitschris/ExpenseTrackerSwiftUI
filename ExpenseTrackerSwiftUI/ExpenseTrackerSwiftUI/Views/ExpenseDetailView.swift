import SwiftUI
import SwiftData

/// Detail view for a single expense with similar expenses section
struct ExpenseDetailView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Expense.timestamp, order: .reverse) private var allExpenses: [Expense]
    
    let expense: Expense
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Selected expense card at top
                        ExpenseRow(expense: expense)
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                        
                        // Similar expenses section
                        if !similarExpenses.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Similar Expenses")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .foregroundColor(theme.text)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Text("Total:")
                                            .font(.title3)
                                            .foregroundColor(theme.text.opacity(0.5))
                                        
                                        Text(formatIntegerAmount(similarExpensesTotal))
                                            .font(.title3)
                                            .foregroundColor(theme.text.opacity(0.6))
                                    }
                                }
                                .padding(.horizontal, 26)
                                .padding(.top, 40)
                                .padding(.bottom, 4)
                                
                                VStack(spacing: 8) {
                                    ForEach(similarExpenses) { similarExpense in
                                        SimilarExpenseRow(expense: similarExpense)
                                            .padding(.horizontal, 16)
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(theme.textTertiary)
                                    .padding(.top, 60)
                                
                                Text("No Similar Expenses")
                                    .font(.headline)
                                    .foregroundColor(theme.text)
                                
                                Text("This expense is unique!")
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)
                                    .padding(.bottom, 40)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Expense Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if Constants.enableHapticFeedback {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.text)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Find similar expenses based on category and description
    private var similarExpenses: [Expense] {
        let candidates = allExpenses.filter { $0.id != expense.id }
        
        var scoredExpenses: [(expense: Expense, score: Double)] = []
        
        for candidate in candidates {
            var score: Double = 0
            
            // Same category: +70 points (primary factor)
            if candidate.category == expense.category {
                score += 70
            }
            
            // Description similarity: +30 points (secondary factor)
            let descriptionSimilarity = calculateDescriptionSimilarity(
                expense.expenseDescription,
                candidate.expenseDescription
            )
            score += 30 * descriptionSimilarity
            
            // Only include if score is meaningful (at least 20 points)
            // This allows same-category matches even with no description overlap
            if score >= 20 {
                scoredExpenses.append((candidate, score))
            }
        }
        
        // Sort by timestamp descending (most recent first)
        return scoredExpenses
            .map { $0.expense }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Calculate total amount of all similar expenses
    private var similarExpensesTotal: Double {
        similarExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Helpers
    
    /// Calculate similarity between two descriptions using keyword matching
    private func calculateDescriptionSimilarity(_ desc1: String, _ desc2: String) -> Double {
        let words1 = Set(desc1.lowercased().split(separator: " ").map(String.init))
        let words2 = Set(desc2.lowercased().split(separator: " ").map(String.init))
        
        guard !words1.isEmpty && !words2.isEmpty else { return 0 }
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        // Jaccard similarity coefficient
        return Double(intersection.count) / Double(union.count)
    }
    
    private func formatIntegerAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Similar Expense Row

/// Row for displaying similar expenses with inverted color scheme
struct SimilarExpenseRow: View {
    @Environment(\.theme) var theme
    let expense: Expense
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 9) {
                
                // Category icon and date
                HStack(spacing: 6) {
                    categoryIcon
                    
                    Text(formatDate(expense.timestamp))
                        .font(.system(size: 11))
                        .fontWeight(.medium)
                        .foregroundColor(theme.colorForCategory(expense.category))
                }
                
                // Expense information (title)
                Text(expense.expenseDescription)
                    .font(.system(size: 20))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 50)
            
            // Expense amount in bottom right corner
            Text(formatIntegerAmount(expense.amount))
                .font(.system(size: 28))
                .fontWeight(.regular)
                .kerning(-0.5)
                .foregroundColor(theme.colorForCategory(expense.category))
        }
        .padding(.bottom, 18)
        .padding(.top, 12)
        .padding(.horizontal, 24)
        .background(
            Color.gray.opacity(0.3)
        )
        .cornerRadius(25)
        .padding(.horizontal, 2)
    }
    
    // MARK: - Subviews
    
    private var categoryIcon: some View {
        Image(systemName: Constants.iconForCategory(expense.category))
            .font(.system(size: 14))
            .foregroundColor(theme.colorForCategory(expense.category))
    }
    
    // MARK: - Helpers
    
    private func formatIntegerAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ExpenseDetailView(
        expense: Expense(
            amount: 45.99,
            category: "groceries",
            description: "Whole Foods",
            timestamp: Date()
        )
    )
    .modelContainer(for: Expense.self, inMemory: true)
    .theme(.dark)
}

