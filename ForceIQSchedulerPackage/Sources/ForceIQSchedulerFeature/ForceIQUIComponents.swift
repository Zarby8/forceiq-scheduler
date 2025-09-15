import SwiftUI

// MARK: - ForceIQ Button Styles
public struct ForceIQButtonStyle: ButtonStyle {
    public enum Style {
        case primary
        case secondary
        case destructive
        case ghost
    }

    let style: Style

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundFor(style, pressed: configuration.isPressed))
            .foregroundColor(foregroundFor(style))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderFor(style), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private func backgroundFor(_ style: Style, pressed: Bool) -> Color {
        switch style {
        case .primary:
            return pressed ? .forceYellow.opacity(0.8) : .forceYellow
        case .secondary:
            return pressed ? .forceCard.opacity(0.8) : .forceCard
        case .destructive:
            return pressed ? .forceRed.opacity(0.8) : .forceRed
        case .ghost:
            return pressed ? .forceCard.opacity(0.5) : .clear
        }
    }

    private func foregroundFor(_ style: Style) -> Color {
        switch style {
        case .primary:
            return .forceBlack
        case .secondary, .ghost:
            return .white
        case .destructive:
            return .white
        }
    }

    private func borderFor(_ style: Style) -> Color {
        switch style {
        case .primary:
            return .forceYellow
        case .secondary:
            return .forceCard
        case .destructive:
            return .forceRed
        case .ghost:
            return .gray.opacity(0.5)
        }
    }
}

// MARK: - ForceIQ Card
public struct ForceIQCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack {
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.forceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.forceYellow.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - ForceIQ Text Field Style
public struct ForceIQTextFieldStyle: TextFieldStyle {
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, design: .monospaced))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.forceIceCharcoal)
            .foregroundColor(.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.forceYellow.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - ForceIQ Section Header
public struct ForceIQSectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    public init(_ title: String, icon: String, color: Color = .forceYellow) {
        self.title = title
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(color)

            Spacer()
        }
    }
}

// MARK: - ForceIQ Toggle Style
public struct ForceIQToggleStyle: ToggleStyle {
    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.forceGreen : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

// MARK: - ForceIQ Picker Style
public struct ForceIQPicker<SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    let content: Content

    public init(_ title: String, selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._selection = selection
        self.content = content()
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white)

            Spacer()

            Picker("", selection: $selection) {
                content
            }
            .pickerStyle(.menu)
            .accentColor(.forceYellow)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.forceIceCharcoal)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.forceYellow.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - ForceIQ Status Badge
public struct ForceIQStatusBadge: View {
    let text: String
    let status: Status

    public enum Status {
        case active, inactive, warning, error

        var color: Color {
            switch self {
            case .active: return .forceGreen
            case .inactive: return .gray
            case .warning: return .forceYellow
            case .error: return .forceRed
            }
        }

        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .inactive: return "circle"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }

    public init(_ text: String, status: Status) {
        self.text = text
        self.status = status
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - ForceIQ Loading View
public struct ForceIQLoadingView: View {
    let message: String

    public init(_ message: String = "Loading...") {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .forceYellow))
                .scaleEffect(1.2)

            Text(message)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(20)
        .background(Color.forceCard)
        .cornerRadius(12)
    }
}

// MARK: - ForceIQ Empty State
public struct ForceIQEmptyState: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?

    public init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(ForceIQButtonStyle(style: .primary))
            }
        }
        .padding(40)
    }
}

// MARK: - ForceIQ Time Slot View
public struct ForceIQTimeSlotView: View {
    let startTime: String
    let endTime: String
    let isActive: Bool
    let onToggle: () -> Void
    let onRemove: () -> Void

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Start")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.forceGreen)
                    Text(startTime)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }

                HStack {
                    Text("End")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.forceRed)
                    Text(endTime)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isActive },
                set: { _ in onToggle() }
            ))
            .toggleStyle(ForceIQToggleStyle())

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.forceRed)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.forceIceCharcoal)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.forceGreen.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}