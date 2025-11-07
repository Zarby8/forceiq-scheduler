import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appModel: AppModel

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    ForceIQSectionHeader(title: "Command Center")
                    Spacer()

                    Button(action: {
                        Task {
                            await appModel.fetchUpcomingBookings()
                        }
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(ForceIQButtonStyle(type: .secondary))
                    .disabled(appModel.isLoadingBookings)
                }

                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Total Clients",
                        value: "\(appModel.clients.count)",
                        icon: "person.3.fill",
                        color: ForceIQColors.highlightYellow
                    )

                    StatCard(
                        title: "Upcoming Sessions",
                        value: "\(appModel.upcomingBookings.filter(\.isUpcoming).count)",
                        icon: "calendar.badge.clock",
                        color: ForceIQColors.electricGreen
                    )

                    StatCard(
                        title: "Today's Sessions",
                        value: "\(appModel.upcomingBookings.filter(\.isToday).count)",
                        icon: "clock.fill",
                        color: ForceIQColors.forceRed
                    )
                }

                // Sunday Scheduler Status
                SundaySchedulerCard()

                // Upcoming Bookings
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("UPCOMING SESSIONS")
                            .font(.system(size: 12, weight: .black, design: .default))
                            .tracking(2)
                            .foregroundColor(ForceIQColors.highlightYellow)

                        Spacer()

                        if appModel.isLoadingBookings {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(ForceIQColors.electricGreen)
                        }
                    }

                    if appModel.upcomingBookings.isEmpty {
                        EmptyStateView(
                            icon: "calendar",
                            message: "No upcoming sessions",
                            submessage: "Bookings will appear here"
                        )
                    } else {
                        ForEach(appModel.upcomingBookings.filter(\.isUpcoming).prefix(10)) { booking in
                            BookingCard(booking: booking)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(ForceIQColors.black)
        .task {
            await appModel.fetchUpcomingBookings()
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.system(size: 36, weight: .black, design: .default))
                .foregroundColor(ForceIQColors.textPrimary)

            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .default))
                .tracking(1.5)
                .foregroundColor(ForceIQColors.textMuted)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ForceIQColors.iceCharcoal)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(isHovered ? 0.6 : 0.2), lineWidth: 2)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(color: color.opacity(isHovered ? 0.3 : 0), radius: 12)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Sunday Scheduler Card

struct SundaySchedulerCard: View {
    @EnvironmentObject var appModel: AppModel

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Circle()
                .fill(appModel.config.sundayConfig.enabled ? ForceIQColors.electricGreen : ForceIQColors.textMuted)
                .frame(width: 12, height: 12)
                .shadow(color: appModel.config.sundayConfig.enabled ? ForceIQColors.electricGreen : .clear, radius: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text("SUNDAY AUTO-SEND")
                    .font(.system(size: 11, weight: .black, design: .default))
                    .tracking(1.5)
                    .foregroundColor(ForceIQColors.highlightYellow)

                if appModel.config.sundayConfig.enabled {
                    Text("Active • Sends at \(appModel.config.sundayConfig.sendTime, formatter: timeFormatter)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(ForceIQColors.textSecondary)
                } else {
                    Text("Disabled • Enable in Settings")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(ForceIQColors.textMuted)
                }
            }

            Spacer()

            if let lastSent = appModel.config.sundayConfig.lastSentDate {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("LAST SENT")
                        .font(.system(size: 9, weight: .bold, design: .default))
                        .tracking(1)
                        .foregroundColor(ForceIQColors.textMuted)

                    Text(lastSent, style: .relative)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(ForceIQColors.electricGreen)
                }
            }

            Button(action: {
                Task {
                    await appModel.sendSundayMessages()
                }
            }) {
                Label("Send Now", systemImage: "paperplane.fill")
            }
            .buttonStyle(ForceIQButtonStyle(type: .secondary))
        }
        .padding(20)
        .forceIQCard(level: 1)
    }
}

// MARK: - Booking Card

struct BookingCard: View {
    let booking: Booking
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 16) {
                    // Coach color indicator
                    Rectangle()
                        .fill(Color(hex: booking.coachColor))
                        .frame(width: 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(booking.clientName)
                                .font(.system(size: 15, weight: .bold, design: .default))
                                .foregroundColor(ForceIQColors.textPrimary)

                            Spacer()

                            Text(booking.coachName)
                                .font(.system(size: 11, weight: .bold, design: .default))
                                .tracking(1)
                                .foregroundColor(Color(hex: booking.coachColor))
                        }

                        HStack(spacing: 12) {
                            Label {
                                Text(booking.startTime, style: .time)
                            } icon: {
                                Image(systemName: "clock.fill")
                            }

                            Label {
                                Text(booking.startTime, style: .date)
                            } icon: {
                                Image(systemName: "calendar")
                            }

                            if !booking.game.isEmpty {
                                Label {
                                    Text(booking.game)
                                } icon: {
                                    Image(systemName: "sportscourt.fill")
                                }
                            }
                        }
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(ForceIQColors.textSecondary)
                    }
                    .padding(.vertical, 12)

                    Image(systemName: "chevron.right")
                        .foregroundColor(ForceIQColors.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)

            // Game Details (expandable)
            if isExpanded {
                Divider()
                    .background(ForceIQColors.forceRed.opacity(0.3))
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 16) {
                    // Client Contact
                    DetailRow(label: "Email", value: booking.clientEmail, icon: "envelope.fill")

                    // Game Details Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GAME DETAILS")
                            .font(.system(size: 10, weight: .black, design: .default))
                            .tracking(1.5)
                            .foregroundColor(ForceIQColors.highlightYellow)

                        DetailRow(label: "Game", value: booking.game, icon: "sportscourt.fill")
                        DetailRow(label: "Date", value: booking.date, icon: "calendar")
                        DetailRow(label: "Time", value: "\(booking.time) (\(booking.timezone))", icon: "clock")
                        DetailRow(label: "Source", value: booking.source, icon: "video.fill")
                        DetailRow(label: "Rating", value: booking.rating, icon: "star.fill")
                    }

                    // Focus Area
                    if !booking.focus.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FOCUS")
                                .font(.system(size: 10, weight: .black, design: .default))
                                .tracking(1.5)
                                .foregroundColor(ForceIQColors.highlightYellow)

                            Text(booking.focus)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(ForceIQColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Performance Self-Assessment
                    if !booking.performance.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SELF-ASSESSMENT")
                                .font(.system(size: 10, weight: .black, design: .default))
                                .tracking(1.5)
                                .foregroundColor(ForceIQColors.highlightYellow)

                            Text(booking.performance)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(ForceIQColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Special Events
                    if !booking.events.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EVENTS")
                                .font(.system(size: 10, weight: .black, design: .default))
                                .tracking(1.5)
                                .foregroundColor(ForceIQColors.highlightYellow)

                            Text(booking.events)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(ForceIQColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Calendar Link
                    if let url = URL(string: booking.calendarLink) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                Text("Open in Google Calendar")
                            }
                            .font(.system(size: 12, weight: .bold, design: .default))
                            .foregroundColor(ForceIQColors.electricGreen)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(16)
                .background(ForceIQColors.iceCharcoalDark)
            }
        }
        .background(isExpanded ? ForceIQColors.iceCharcoal : ForceIQColors.iceCharcoal)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: booking.coachColor).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        if !value.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(ForceIQColors.textMuted)
                    .frame(width: 16)

                Text(label + ":")
                    .font(.system(size: 11, weight: .bold, design: .default))
                    .foregroundColor(ForceIQColors.textMuted)
                    .frame(width: 80, alignment: .leading)

                Text(value)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(ForceIQColors.textPrimary)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let message: String
    let submessage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(ForceIQColors.textMuted)

            Text(message.uppercased())
                .font(.system(size: 12, weight: .bold, design: .default))
                .tracking(1.5)
                .foregroundColor(ForceIQColors.textMuted)

            Text(submessage)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(ForceIQColors.textMuted.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .forceIQCard(level: 1)
    }
}
