import SwiftUI
import SwiftData

/// A temporary model to hold expense data before saving to SwiftData
struct PendingExpense: Identifiable, Equatable {
    let id = UUID()
    var amount: Double
    var category: String
    var description: String
    var timestamp: Date
    
    /// Convert to a SwiftData Expense model
    func toExpense() -> Expense {
        Expense(
            amount: amount,
            category: category,
            description: description,
            timestamp: timestamp
        )
    }
}

/// Sheet for adding multiple expenses in a single session
struct AddMultipleExpensesSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Binding var shouldDismissParent: Bool

    @State private var pendingExpenses: [PendingExpense] = []
    @State private var showingAddExpense = false
    @State private var expenseToEdit: PendingExpense?
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                if pendingExpenses.isEmpty {
                    emptyStateView
                } else {
                    expenseListView
                }
            }
            .navigationTitle("Add Multiple")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.text)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveAllExpenses()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .disabled(pendingExpenses.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .tint(pendingExpenses.isEmpty ? theme.text.opacity(0.1) : theme.appleBlue)
                }
            }
            .safeAreaInset(edge: .bottom) {
                addAnotherButton
            }
            .sheet(isPresented: $showingAddExpense) {
                QuickAddExpenseSheet { expense in
                    pendingExpenses.append(expense)
                }
            }
            .sheet(item: $expenseToEdit) { expense in
                QuickAddExpenseSheet(existingExpense: expense) { updatedExpense in
                    if let index = pendingExpenses.firstIndex(where: { $0.id == expense.id }) {
                        pendingExpenses[index] = updatedExpense
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.circle")
                .font(.system(size: 60))
                .foregroundColor(theme.textTertiary)
            
            Text("No Expenses Added Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.text)
            
            Text("Tap 'Add Expense' to start adding multiple expenses in one session")
                .font(.body)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var expenseListView: some View {
        List {
            Section {
                ForEach(pendingExpenses) { expense in
                    PendingExpenseRow(expense: expense)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            expenseToEdit = expense
                            if Constants.enableHapticFeedback {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    pendingExpenses.removeAll { $0.id == expense.id }
                                }
                                if Constants.enableHapticFeedback {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onMove { indices, newOffset in
                    pendingExpenses.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.text.opacity(0.05))
            )
        }
        .scrollContentBackground(.hidden)
    }
    
    private var addAnotherButton: some View {
        Button {
            showingAddExpense = true
            if Constants.enableHapticFeedback {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Add Expense")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive().tint(theme.appleBlue), in: .rect(cornerRadius: 30))
        .padding(.horizontal, 50)
        .padding(.bottom, 8)
        .background(theme.background)
    }
    
    // MARK: - Helpers
    
    private var totalAmount: Double {
        pendingExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    private func saveAllExpenses() {
        for pendingExpense in pendingExpenses {
            let expense = pendingExpense.toExpense()
            modelContext.insert(expense)
        }

        if Constants.enableHapticFeedback {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        // Signal parent to dismiss, then dismiss child
        shouldDismissParent = true
        dismiss()
    }
}

// MARK: - Pending Expense Row

struct PendingExpenseRow: View {
    @Environment(\.theme) var theme
    let expense: PendingExpense
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 9) {
                
                // Category icon and name
                HStack(spacing: 6) {
                    categoryIcon
                    
                    Text(Constants.displayNameForCategory(expense.category))
                        .font(.system(size: 11))
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Expense information (description)
                Text(expense.description)
                    .font(.system(size: 20))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Expense amount in bottom right corner
            Text(formatCurrency(expense.amount))
                .font(.system(size: 26))
                .fontWeight(.regular)
                .kerning(-0.5)
                .foregroundColor(.white.opacity(1))
        }
        .padding(.bottom, 18)
        .padding(.top, 12)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.colorForCategory(expense.category),
                    shiftHueAndDarken(theme.colorForCategory(expense.category), hueShift: 12, brightnessReduction: 0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(25)
        .padding(.horizontal, 0)
    }
    
    // MARK: - Subviews
    
    private var categoryIcon: some View {
        Image(systemName: Constants.iconForCategory(expense.category))
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.8))
    }
    
    // MARK: - Helpers
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    private func shiftHueAndDarken(_ color: Color, hueShift: CGFloat, brightnessReduction: CGFloat) -> Color {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // If color can't be converted to HSB (e.g., grayscale), just darken it
        guard uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            // For grayscale colors, use RGB and darken
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return Color(
                red: max(0, red * (1.0 - brightnessReduction)),
                green: max(0, green * (1.0 - brightnessReduction)),
                blue: max(0, blue * (1.0 - brightnessReduction)),
                opacity: alpha
            )
        }
        
        // Shift hue by the specified degrees (convert to 0-1 range, where 360° = 1.0)
        let shiftedHue = (hue + hueShift / 360.0).truncatingRemainder(dividingBy: 1.0)
        
        // Reduce brightness by the specified percentage
        let darkenedBrightness = max(0, brightness * (1.0 - brightnessReduction))
        
        return Color(hue: shiftedHue, saturation: saturation, brightness: darkenedBrightness, opacity: alpha)
    }
}

// MARK: - Quick Add Expense Sheet

/// Single-step expense entry sheet optimized for rapid batch entry
struct QuickAddExpenseSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    let onSave: (PendingExpense) -> Void
    let existingExpense: PendingExpense?

    @State private var amountText = ""
    @State private var selectedCategory = Constants.expenseCategories.first ?? "other"
    @State private var selectedDate = Date()
    @State private var description = ""
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    @State private var lastHapticOffset: CGFloat = 0

    init(existingExpense: PendingExpense? = nil, onSave: @escaping (PendingExpense) -> Void) {
        self.existingExpense = existingExpense
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                theme.background
                    .ignoresSafeArea()
                
                contentView
            }
            .navigationTitle(existingExpense == nil ? "Add Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.text)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveExpense()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .disabled(!isValidAmount)
                    .buttonStyle(.borderedProminent)
                    .tint(isValidAmount ? theme.appleBlue : theme.text.opacity(0.1))
                }
            }
            .onAppear {
                // Load existing expense data if editing
                if let existing = existingExpense {
                    amountText = String(format: "%.0f", existing.amount)
                    selectedCategory = existing.category
                    selectedDate = existing.timestamp
                    description = existing.description == "No description" ? "" : existing.description
                } else {
                    // Auto-focus amount field for new expenses
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isAmountFocused = true
                    }
                }
            }
        }
    }
    
    private var contentView: some View {
        ScrollViewReader { proxy in
            Form {
                amountSection
                categorySection
                dateSection
                descriptionSection
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .foregroundStyle(theme.text)
            .tint(theme.appleBlue)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isAmountFocused = false
                        isDescriptionFocused = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.appleBlue)
                }
            }
            .onChange(of: isDescriptionFocused) { _, isFocused in
                if isFocused {
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            proxy.scrollTo("descriptionField", anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    private var amountSection: some View {
        Section {
            HStack {
                Text("$")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(theme.text.opacity(0.5))
                
                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.leading)
                    .focused($isAmountFocused)
                    .onChange(of: amountText) { _, newValue in
                        // Only allow whole numbers (digits only)
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered != newValue {
                            amountText = filtered
                        }
                    }
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
    }
    
    private var categorySection: some View {
        Section {
            HapticScrollView {
                HStack(spacing: 8) {
                    ForEach(Constants.expenseCategories, id: \.self) { category in
                        categoryButton(for: category)
                    }
                }
                .padding(.horizontal, 6)
            } onScroll: { offset in
                handleCategoryScrollOffset(offset)
            }
            .frame(height: 42)
            .frame(maxWidth: .infinity)
            .clipShape(Capsule())
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
        } header: {
            Text("Category")
                .foregroundColor(theme.text)
        }
    }
    
    private func categoryButton(for category: String) -> some View {
        Button(action: {
            selectedCategory = category
            if Constants.enableHapticFeedback {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: Constants.iconForCategory(category))
                    .foregroundStyle(
                        selectedCategory == category
                        ? .white
                        : theme.colorForCategory(category)
                    )
                    .imageScale(.small)
                
                Text(Constants.displayNameForCategory(category))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        selectedCategory == category
                        ? .white
                        : (theme.text.opacity(0.6))
                    )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    Capsule()
                        .fill(
                            selectedCategory == category
                            ? theme.colorForCategory(category)
                            : Color.gray.opacity(0.3)
                        )
                    
                    if selectedCategory == category {
                        Capsule()
                            .strokeBorder(theme.colorForCategory(category).opacity(0.6), lineWidth: 2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
    
    private var dateSection: some View {
        Section {
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .accentColor(theme.appleBlue)
                .colorScheme(theme.isDark ? .dark : .light)
        } header: {
            Text("Date")
                .foregroundColor(theme.text)
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.text.opacity(0.1))
        )
    }
    
    private var descriptionSection: some View {
        Section {
            ZStack(alignment: .topLeading) {
                if description.isEmpty {
                    Text("What did you purchase?")
                        .foregroundColor(theme.text.opacity(0.5))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                
                TextEditor(text: $description)
                    .focused($isDescriptionFocused)
                    .frame(minHeight: 80, maxHeight: 200)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(theme.text)
            }
            .id("descriptionField")
        } header: {
            Text("Description")
                .foregroundColor(theme.text)
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.text.opacity(0.1))
        )
    }
    
    // MARK: - Helpers
    
    private var isValidAmount: Bool {
        guard let amount = Double(amountText) else { return false }
        return amount > 0
    }
    
    private func handleCategoryScrollOffset(_ offset: CGFloat) {
        let hapticThreshold: CGFloat = 40
        let offsetDelta = abs(offset - lastHapticOffset)
        
        if offsetDelta > hapticThreshold && offsetDelta < 1000 {
            if Constants.enableHapticFeedback {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
            lastHapticOffset = offset
        }
        
        if lastHapticOffset == 0 && abs(offset) > 10 {
            lastHapticOffset = offset
        }
    }
    
    private func saveExpense() {
        guard let amount = Double(amountText), amount > 0 else { return }

        let pendingExpense = PendingExpense(
            amount: amount,
            category: selectedCategory,
            description: description.isEmpty ? "No description" : description,
            timestamp: selectedDate
        )

        onSave(pendingExpense)

        if Constants.enableHapticFeedback {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        dismiss()
    }
}
