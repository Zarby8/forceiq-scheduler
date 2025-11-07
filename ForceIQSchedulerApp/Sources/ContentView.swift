import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        NavigationView {
            // Sidebar
            SidebarView()

            // Main content
            Group {
                switch appModel.selectedTab {
                case .dashboard:
                    DashboardView()
                case .clients:
                    ClientsView()
                case .booking:
                    BookingView()
                case .availability:
                    AvailabilityView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(ForceIQColors.black)
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(ForceIQColors.highlightYellow)

                Text("FORCEIQ")
                    .font(.system(size: 18, weight: .black, design: .default))
                    .tracking(2)
                    .foregroundColor(ForceIQColors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)

            Divider()
                .background(ForceIQColors.forceRed.opacity(0.3))

            // Navigation
            VStack(alignment: .leading, spacing: 4) {
                ForEach(AppModel.Tab.allCases, id: \.self) { tab in
                    SidebarButton(
                        icon: tab.icon,
                        title: tab.rawValue,
                        isSelected: appModel.selectedTab == tab
                    ) {
                        appModel.selectedTab = tab
                    }
                }
            }
            .padding(.vertical, 12)

            Spacer()

            // Status indicator
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                    .background(ForceIQColors.forceRed.opacity(0.3))

                HStack(spacing: 8) {
                    Circle()
                        .fill(appModel.config.sundayConfig.enabled ? ForceIQColors.electricGreen : ForceIQColors.textMuted)
                        .frame(width: 8, height: 8)

                    Text(appModel.config.sundayConfig.enabled ? "SCHEDULER ACTIVE" : "SCHEDULER OFF")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(ForceIQColors.textMuted)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .frame(width: 240)
        .background(ForceIQColors.iceCharcoal)
    }
}

struct SidebarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? ForceIQColors.black : ForceIQColors.textPrimary)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .default))
                    .tracking(1)
                    .foregroundColor(isSelected ? ForceIQColors.black : ForceIQColors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
            )
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return ForceIQColors.electricGreen
        } else if isHovered {
            return ForceIQColors.iceCharcoalDark
        } else {
            return .clear
        }
    }
}
