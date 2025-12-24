import SwiftUI
import UIKit

/// Individual expense row component
struct ExpenseRow: View {
    @Environment(\.theme) var theme
    let expense: Expense
    var showDate: Bool = false
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {

        ZStack(alignment: .topTrailing) {

            // Main content
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 9) {
                    
                    // Category icon and name OR date
                    HStack(spacing: 6) {
                        if showDate {
                            // Show date when in category view
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(formatDate(expense.timestamp))
                                .font(.system(size: 11))
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            // Show category when in all expenses view
                            categoryIcon
                            
                            Text(Constants.displayNameForCategory(expense.category))
                                .font(.system(size: 11))
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    // Expense information (title)
                    Text(expense.expenseDescription)
                        .font(.system(size: 24))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 55) // Make space for menu button
                
                // Expense amount in bottom right corner
                Text(formatIntegerAmount(expense.amount))
                    .font(.system(size: 28))
                    .fontWeight(.regular)
                    .kerning(-0.5)
                    .foregroundColor(.white.opacity(1))
            }
            .padding(.bottom, 18)
            .padding(.top, 12)
            .padding(.horizontal, 24)
            
            // Three-dot menu button in top right
            if onEdit != nil || onDelete != nil {
                Menu {
                    if let onEdit = onEdit {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    
                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 16)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let onTap = onTap {
                if Constants.enableHapticFeedback {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
                onTap()
            }
        }
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
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            lightenColor(theme.colorForCategory(expense.category), brightnessIncrease: 0.6, saturationDecrease: 0.35),
                            lightenColor(shiftHueAndDarken(theme.colorForCategory(expense.category), hueShift: 12, brightnessReduction: 0), brightnessIncrease: 0, saturationDecrease: 0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 2)
    }

    // MARK: - Subviews

    private var categoryIcon: some View {
        Image(systemName: Constants.iconForCategory(expense.category))
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.8))
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatIntegerAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    private func lightenColor(_ color: Color, brightnessIncrease: CGFloat, saturationDecrease: CGFloat) -> Color {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // If color can't be converted to HSB (e.g., grayscale), lighten using RGB
        guard uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            // Move RGB values closer to white
            return Color(
                red: min(1.0, red + (1.0 - red) * brightnessIncrease),
                green: min(1.0, green + (1.0 - green) * brightnessIncrease),
                blue: min(1.0, blue + (1.0 - blue) * brightnessIncrease),
                opacity: alpha
            )
        }
        
        // Decrease saturation (move toward white/gray)
        let lightenedSaturation = max(0, saturation * (1.0 - saturationDecrease))
        
        // Increase brightness (move toward white)
        let lightenedBrightness = min(1.0, brightness + (1.0 - brightness) * brightnessIncrease)
        
        return Color(hue: hue, saturation: lightenedSaturation, brightness: lightenedBrightness, opacity: alpha)
    }
    
    private func brightenColor(_ color: Color, brightnessIncrease: CGFloat) -> Color {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // If color can't be converted to HSB (e.g., grayscale), brighten using RGB
        guard uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return Color(
                red: min(1.0, red * (1.0 + brightnessIncrease)),
                green: min(1.0, green * (1.0 + brightnessIncrease)),
                blue: min(1.0, blue * (1.0 + brightnessIncrease)),
                opacity: alpha
            )
        }
        
        // Increase brightness by the specified percentage
        let brightenedBrightness = min(1.0, brightness * (1.0 + brightnessIncrease))
        
        return Color(hue: hue, saturation: saturation, brightness: brightenedBrightness, opacity: alpha)
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

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        ExpenseRow(expense: Expense(
            amount: 45.99,
            category: "groceries",
            description: "Whole Foods",
            timestamp: Date()
        ))

        ExpenseRow(expense: Expense(
            amount: 12.50,
            category: "food",
            description: "Coffee shop",
            timestamp: Date().addingTimeInterval(-3600)
        ))

        ExpenseRow(expense: Expense(
            amount: 150.00,
            category: "fashion",
            description: "New shoes",
            timestamp: Date().addingTimeInterval(-7200)
        ))
    }
    .padding()
    .background(Color(red: 242/255, green: 242/255, blue: 247/255))
    .theme(.light)
}
