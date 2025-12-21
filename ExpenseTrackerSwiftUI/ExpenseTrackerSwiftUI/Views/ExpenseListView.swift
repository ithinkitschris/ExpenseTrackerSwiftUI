import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Main expense list view with grouping, filtering, and swipe-to-delete
struct ExpenseListView: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.timestamp, order: .reverse) private var allExpenses: [Expense]
    @State private var selectedCategory: String? = nil
    @State private var showingAddExpense = false
    @State private var showingSQLiteImport = false
    @State private var importResult: String?
    @State private var errorMessage: String?
    @State private var expenseToEdit: Expense?
    @State private var scrollOffset: CGFloat = 0
    @State private var lastHapticOffset: CGFloat = 0
    
    // Filtered expenses based on category selection
    private var filteredExpenses: [Expense] {
        if let category = selectedCategory {
            return allExpenses.filter { $0.category == category }
        }
        return allExpenses
    }

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            // Expense list - extends to top
            if filteredExpenses.isEmpty {
                emptyStateView
            } else {
                expenseList
            }
            
            // Top gradient overlay
            VStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: theme.background.opacity(topGradientOpacity.start), location: 0.0),
                        .init(color: theme.background.opacity(topGradientOpacity.middle), location: 0.5),
                        .init(color: theme.background.opacity(0), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .allowsHitTesting(false)
                Spacer()
            }
            .ignoresSafeArea(.container, edges: .top)
            
            // Category filter overlay at top
            VStack {
                categoryFilterBar
                Spacer()
            }
            .safeAreaPadding(.top)
            
            // Bottom gradient overlay
            VStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(colors: [theme.background.opacity(0), theme.background.opacity(bottomGradientOpacity)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            
            // Bottom bar with add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    // Add expense button - bottom right
                    addButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .zIndex(1)
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseSheet()
        }
        .sheet(item: $expenseToEdit) { expense in
            EditExpenseSheet(expense: expense)
        }
        .fileImporter(
            isPresented: $showingSQLiteImport,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            handleSQLiteImport(result)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .alert("Import Complete", isPresented: .constant(importResult != nil)) {
            Button("OK") {
                importResult = nil
            }
        } message: {
            if let result = importResult {
                Text(result)
            }
        }
    }

    // MARK: - Subviews

    private var categoryFilterBar: some View {
        HapticScrollView {
            HStack(spacing: 8) {
                // "All" filter
                categoryChip(
                    title: "All",
                    icon: "chart.bar.fill",
                    isSelected: selectedCategory == nil,
                    color: theme.appleBlue,
                    totalSpent: selectedCategory == nil ? totalAmount : nil
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = nil
                    }
                }

                // Category filters
                ForEach(Constants.expenseCategories, id: \.self) { category in
                    categoryChip(
                        title: Constants.displayNameForCategory(category),
                        icon: Constants.iconForCategory(category),
                        isSelected: selectedCategory == category,
                        color: theme.colorForCategory(category),
                        totalSpent: selectedCategory == category ? categoryTotal(for: category) : nil
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        } onScroll: { offset in
            handleScrollOffset(offset)
        }
        .frame(height: 60)
        .background(.clear)
    }
    
    private func categoryChip(
        title: String,
        icon: String,
        isSelected: Bool,
        color: Color,
        totalSpent: Double?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let total = totalSpent {
                    Text(formatCurrencyWhole(total))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isLightMode ? .black : .white)
                } else {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .imageScale(.small)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isLightMode ? .medium : .regular)
                    .foregroundStyle(isLightMode ? .black.opacity(isSelected ? 0.9 : 0.6) : .white.opacity(isSelected ? 0.9 : 0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(
            Capsule()
                .fill(.white.opacity(0.05))
        )
        .glassEffect(
            .regular.interactive().tint(isSelected ? color.opacity(0.6) : .clear),
            in: .capsule
        )
        .overlay(
            Capsule()
                .strokeBorder(isSelected ? color : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
    }

    private var expenseList: some View {
        List {
            ForEach(Array(groupedExpenses.enumerated()), id: \.element.0) { index, group in
                let (dayHeader, expenses) = group
                Section {
                    ForEach(expenses) { expense in
                        ExpenseRow(
                            expense: expense,
                            onEdit: {
                                expenseToEdit = expense
                                if Constants.enableHapticFeedback {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                            },
                            onDelete: {
                                deleteExpense(expense)
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteExpense(expense)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                expenseToEdit = expense
                                if Constants.enableHapticFeedback {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(theme.appleBlue)
                        }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dayHeader)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.text)
                        
                        Text(dayTotal(for: expenses))
                            .font(.subheadline)
                            .foregroundColor(theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textCase(nil)
                    .padding(.top, 22)
                }
                .listSectionSeparator(.hidden)
            }
            
            // Bottom spacer
            Color.clear
                .frame(height: 80)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 80, for: .scrollContent)
    }

//    private var totalSummaryCard: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Total Spent")
//                    .font(.subheadline)
//                    .foregroundColor(theme.textSecondary)
//
//                Text(formatCurrency(totalAmount))
//                    .font(.system(size: 32, weight: .bold))
//                    .foregroundColor(theme.text)
//            }
//
//            Spacer()
//
////            VStack(alignment: .trailing, spacing: 4) {
////                Text("\(filteredExpenses.count)")
////                    .font(.system(size: 24, weight: .semibold))
////                    .foregroundColor(theme.text)
////
////                Text(filteredExpenses.count == 1 ? "expense" : "expenses")
////                    .font(.caption)
////                    .foregroundColor(theme.textSecondary)
////            }
//        }
//        .background(theme.background)
//        .padding(.horizontal, 10)
//        .shadow(color: theme.shadowColor.opacity(theme.shadowOpacity), radius: theme.shadowRadius)
//    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(theme.textTertiary)

            Text("No Expenses Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.text)

            Text("Tap the + button to add your first expense")
                .font(.body)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.bottom, 80) // Add padding for bottom bar
    }

    private var addButton: some View {
        Button {
            showingAddExpense = true
            if Constants.enableHapticFeedback {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(isLightMode ? .black : .white)
                .frame(width: 70, height: 70)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive().tint(.clear), in: .circle)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    showingSQLiteImport = true
                    if Constants.enableHapticFeedback {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
                }
        )
    }

    // MARK: - Computed Properties
    
    private var isLightMode: Bool {
        theme.text == .black
    }
    
    private var topGradientOpacity: (start: Double, middle: Double) {
        isLightMode ? (0.7, 0.3) : (0.9, 0.7)
    }
    
    private var bottomGradientOpacity: Double {
        isLightMode ? 0.7 : 0.9
    }
    
    private var totalAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var groupedExpenses: [(String, [Expense])] {
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            expense.dayHeader
        }

        return grouped.sorted { first, second in
            guard let firstDate = first.value.first?.timestamp,
                  let secondDate = second.value.first?.timestamp else {
                return false
            }
            return firstDate > secondDate
        }
    }

    // MARK: - Helpers

    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            modelContext.delete(expense)
            
            if Constants.enableHapticFeedback {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
    }
    
    private func handleSQLiteImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Access denied to file"
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let result = try MigrationHelper.shared.importFromSQLite(at: url)
                importResult = result.message
                
                if Constants.enableHapticFeedback {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                errorMessage = "Import failed: \(error.localizedDescription)"
                print("SQLite import error: \(error)")
                
                if Constants.enableHapticFeedback {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }

        case .failure(let error):
            errorMessage = "Error: \(error.localizedDescription)"
            print("File picker error: \(error)")
        }
    }

    private func categoryTotal(for category: String) -> Double {
        allExpenses
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }

    private func dayTotal(for expenses: [Expense]) -> String {
        let total = expenses.reduce(0) { $0 + $1.amount }
        return formatCurrency(total)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func formatCurrencyWhole(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    private func handleScrollOffset(_ offset: CGFloat) {
        // Trigger haptic feedback every 40 points of scrolling
        let hapticThreshold: CGFloat = 40
        
        // Only trigger if we've actually scrolled (avoid initial layout trigger)
        let offsetDelta = abs(offset - lastHapticOffset)
        
        if offsetDelta > hapticThreshold && offsetDelta < 1000 {
            // Upper bound to avoid large jumps
            if Constants.enableHapticFeedback {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            lastHapticOffset = offset
        }
        
        // Initialize lastHapticOffset on first scroll
        if lastHapticOffset == 0 && abs(offset) > 10 {
            lastHapticOffset = offset
        }
        
        scrollOffset = offset
    }
}

// MARK: - Preference Key for Scroll Offset

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Scroll View with Haptic Feedback

struct HapticScrollView<Content: View>: UIViewControllerRepresentable {
    let content: Content
    let onScroll: (CGFloat) -> Void
    
    init(@ViewBuilder content: () -> Content, onScroll: @escaping (CGFloat) -> Void) {
        self.content = content()
        self.onScroll = onScroll
    }
    
    func makeUIViewController(context: Context) -> HapticScrollViewController<Content> {
        let controller = HapticScrollViewController(content: content, onScroll: onScroll)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: HapticScrollViewController<Content>, context: Context) {
        uiViewController.updateContent(content)
    }
}

class HapticScrollViewController<Content: View>: UIViewController, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private var hostingController: UIHostingController<Content>?
    private let onScroll: (CGFloat) -> Void
    
    init(content: Content, onScroll: @escaping (CGFloat) -> Void) {
        self.onScroll = onScroll
        super.init(nibName: nil, bundle: nil)
        
        let hosting = UIHostingController(rootView: content)
        hostingController = hosting
        
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.backgroundColor = .clear
        
        view.backgroundColor = .clear
        view.addSubview(scrollView)
        addChild(hosting)
        scrollView.addSubview(hosting.view)
        hosting.didMove(toParent: self)
        hosting.view.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        if let hostingView = hostingController?.view {
            let size = hostingView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: view.bounds.height))
            hostingView.frame = CGRect(origin: .zero, size: size)
            scrollView.contentSize = size
        }
    }
    
    func updateContent(_ content: Content) {
        hostingController?.rootView = content
        view.setNeedsLayout()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll(scrollView.contentOffset.x)
    }
}

// MARK: - Add Expense Sheet

struct AddExpenseSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount = ""
    @State private var selectedCategory = Constants.expenseCategories.first ?? "other"
    @State private var description = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 24, weight: .semibold))
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Constants.expenseCategories, id: \.self) { category in
                            HStack {
                                Image(systemName: Constants.iconForCategory(category))
                                Text(Constants.displayNameForCategory(category))
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Description") {
                    TextField("Optional note", text: $description)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(amount.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }
        
        let expense = Expense(
            amount: amountValue,
            category: selectedCategory,
            description: description.isEmpty ? "No description" : description
        )
        
        modelContext.insert(expense)
        
        if Constants.enableHapticFeedback {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        dismiss()
    }
}

// MARK: - Edit Expense Sheet

struct EditExpenseSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let expense: Expense
    
    @State private var amount = ""
    @State private var selectedCategory = ""
    @State private var description = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 24, weight: .semibold))
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Constants.expenseCategories, id: \.self) { category in
                            HStack {
                                Image(systemName: Constants.iconForCategory(category))
                                Text(Constants.displayNameForCategory(category))
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Description") {
                    TextField("Optional note", text: $description)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(amount.isEmpty || Double(amount) == nil)
                }
            }
            .onAppear {
                // Initialize fields with existing expense data
                amount = String(format: "%.2f", expense.amount)
                selectedCategory = expense.category
                description = expense.expenseDescription == "No description" ? "" : expense.expenseDescription
            }
        }
    }
    
    private func saveChanges() {
        guard let amountValue = Double(amount) else { return }
        
        expense.amount = amountValue
        expense.category = selectedCategory
        expense.expenseDescription = description.isEmpty ? "No description" : description
        expense.timestamp = Date() // Update timestamp to reflect the edit
        
        if Constants.enableHapticFeedback {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        dismiss()
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Expense.self, configurations: config)
    
    // Add sample expenses
    let sampleExpenses = [
        Expense(
            amount: 45.99,
            category: "groceries",
            description: "Whole Foods",
            timestamp: Date()
        ),
        Expense(
            amount: 12.50,
            category: "food",
            description: "Coffee at Starbucks",
            timestamp: Date().addingTimeInterval(-3600)
        ),
        Expense(
            amount: 89.99,
            category: "transportation",
            description: "Gas station fill-up",
            timestamp: Date().addingTimeInterval(-7200)
        ),
        Expense(
            amount: 156.00,
            category: "fashion",
            description: "Nike store shopping",
            timestamp: Date().addingTimeInterval(-86400) // Yesterday
        ),
        Expense(
            amount: 23.45,
            category: "personal",
            description: "Pharmacy essentials",
            timestamp: Date().addingTimeInterval(-86400) // Yesterday
        ),
        Expense(
            amount: 67.80,
            category: "entertainment",
            description: "Movie tickets & snacks",
            timestamp: Date().addingTimeInterval(-172800) // 2 days ago
        ),
        Expense(
            amount: 34.20,
            category: "food",
            description: "Lunch at chipotle",
            timestamp: Date().addingTimeInterval(-172800) // 2 days ago
        )
    ]
    
    for expense in sampleExpenses {
        container.mainContext.insert(expense)
    }
    
    return NavigationStack {
        ExpenseListView()
            .modelContainer(container)
            .theme(.light)
    }
}

#Preview("Dark Mode") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Expense.self, configurations: config)
    
    // Add sample expenses
    let sampleExpenses = [
        Expense(
            amount: 45.99,
            category: "groceries",
            description: "Whole Foods",
            timestamp: Date()
        ),
        Expense(
            amount: 12.50,
            category: "food",
            description: "Coffee at Starbucks",
            timestamp: Date().addingTimeInterval(-3600)
        ),
        Expense(
            amount: 89.99,
            category: "transportation",
            description: "Gas station fill-up",
            timestamp: Date().addingTimeInterval(-7200)
        ),
        Expense(
            amount: 156.00,
            category: "fashion",
            description: "Nike store shopping",
            timestamp: Date().addingTimeInterval(-86400) // Yesterday
        ),
        Expense(
            amount: 23.45,
            category: "personal",
            description: "Pharmacy essentials",
            timestamp: Date().addingTimeInterval(-86400) // Yesterday
        ),
        Expense(
            amount: 67.80,
            category: "entertainment",
            description: "Movie tickets & snacks",
            timestamp: Date().addingTimeInterval(-172800) // 2 days ago
        ),
        Expense(
            amount: 34.20,
            category: "food",
            description: "Lunch at chipotle",
            timestamp: Date().addingTimeInterval(-172800) // 2 days ago
        )
    ]
    
    for expense in sampleExpenses {
        container.mainContext.insert(expense)
    }
    
    return NavigationStack {
        ExpenseListView()
            .modelContainer(container)
            .theme(.dark)
    }
}
