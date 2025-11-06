import SwiftUI

// ForceIQ Brand Colors - Elite HUD Design System
struct ForceIQColors {
    // Core Backgrounds
    static let black = Color(hex: "#000000")           // Primary background
    static let iceCharcoal = Color(hex: "#0a0a0a")     // Card layer 1
    static let iceCharcoalDark = Color(hex: "#1a1a1a") // Card layer 2

    // Accents
    static let highlightYellow = Color(hex: "#F4C430")  // Primary accent
    static let electricGreen = Color(hex: "#4FFF4F")    // Primary CTA / success
    static let forceRed = Color(hex: "#C41E3A")         // Borders / alerts / danger

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textMuted = Color.white.opacity(0.4)
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// ForceIQ Card Style - HUD-inspired containers
struct ForceIQCard: ViewModifier {
    var level: Int = 1 // 1 = iceCharcoal, 2 = iceCharcoalDark

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(level == 1 ? ForceIQColors.iceCharcoal : ForceIQColors.iceCharcoalDark)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ForceIQColors.forceRed.opacity(0.3), lineWidth: 1)
            )
    }
}

// ForceIQ Button Styles - HUD CTAs
struct ForceIQButtonStyle: ButtonStyle {
    enum ButtonType {
        case primary   // Electric Green
        case secondary // Highlight Yellow
        case danger    // Force Red
    }

    let type: ButtonType
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .default))
            .textCase(.uppercase)
            .tracking(1.5)
            .foregroundColor(type == .primary ? ForceIQColors.black : ForceIQColors.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
            .shadow(color: shadowColor.opacity(isHovered ? 0.4 : 0), radius: 8, x: 0, y: 0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }

    private var backgroundColor: Color {
        switch type {
        case .primary: return ForceIQColors.electricGreen
        case .secondary: return ForceIQColors.iceCharcoalDark
        case .danger: return ForceIQColors.iceCharcoalDark
        }
    }

    private var borderColor: Color {
        switch type {
        case .primary: return ForceIQColors.electricGreen
        case .secondary: return ForceIQColors.highlightYellow
        case .danger: return ForceIQColors.forceRed
        }
    }

    private var shadowColor: Color {
        switch type {
        case .primary: return ForceIQColors.electricGreen
        case .secondary: return ForceIQColors.highlightYellow
        case .danger: return ForceIQColors.forceRed
        }
    }
}

// ForceIQ Text Field Style
struct ForceIQTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 14, weight: .regular, design: .monospaced))
            .foregroundColor(ForceIQColors.textPrimary)
            .padding(12)
            .background(ForceIQColors.iceCharcoalDark)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ForceIQColors.forceRed.opacity(0.3), lineWidth: 1)
            )
    }
}

// ForceIQ Section Header
struct ForceIQSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .black, design: .default))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundColor(ForceIQColors.highlightYellow)
            .padding(.vertical, 8)
    }
}

// View modifiers
extension View {
    func forceIQCard(level: Int = 1) -> some View {
        modifier(ForceIQCard(level: level))
    }
}
