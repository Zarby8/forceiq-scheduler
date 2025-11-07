import SwiftUI

struct AvailabilityView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var selectedCoachIndex = 0

    var selectedCoach: Coach {
        appModel.config.coaches[selectedCoachIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with coach selector
            HStack {
                ForceIQSectionHeader(title: "Weekly Availability")

                Spacer()

                // Coach Selector
                Picker("Coach", selection: $selectedCoachIndex) {
                    ForEach(Array(appModel.config.coaches.enumerated()), id: \.offset) { index, coach in
                        Text(coach.name).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .colorMultiply(ForceIQColors.highlightYellow)
            }
            .padding(24)

            Divider()
                .background(ForceIQColors.forceRed.opacity(0.3))

            // Weekly Schedule
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(0..<7) { weekday in
                        WeekdayScheduleCard(
                            weekday: weekday,
                            coach: selectedCoach,
                            onUpdate: { timeWindows in
                                updateCoachSchedule(weekday: weekday, timeWindows: timeWindows)
                            }
                        )
                    }
                }
                .padding(24)
            }
        }
        .background(ForceIQColors.black)
    }

    private func updateCoachSchedule(weekday: Int, timeWindows: [TimeWindow]) {
        var updatedCoach = selectedCoach
        updatedCoach.weeklyHours[weekday] = timeWindows
        appModel.updateCoach(updatedCoach)
    }
}

// MARK: - Weekday Schedule Card

struct WeekdayScheduleCard: View {
    let weekday: Int
    let coach: Coach
    let onUpdate: ([TimeWindow]) -> Void

    @State private var timeWindows: [TimeWindow] = []
    @State private var isExpanded = false

    var weekdayName: String {
        Calendar.current.weekdaySymbols[weekday]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(hex: coach.color))

                    Text(weekdayName.uppercased())
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .tracking(1.5)
                        .foregroundColor(ForceIQColors.textPrimary)

                    if timeWindows.isEmpty {
                        Text("UNAVAILABLE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(ForceIQColors.textMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ForceIQColors.iceCharcoalDark)
                            .cornerRadius(4)
                    } else {
                        Text("\(timeWindows.count) BLOCK\(timeWindows.count == 1 ? "" : "S")")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(ForceIQColors.electricGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ForceIQColors.iceCharcoalDark)
                            .cornerRadius(4)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(ForceIQColors.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            // Time Windows
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(Array(timeWindows.enumerated()), id: \.element.id) { index, window in
                        TimeWindowRow(
                            window: window,
                            onUpdate: { updated in
                                timeWindows[index] = updated
                                onUpdate(timeWindows)
                            },
                            onDelete: {
                                timeWindows.remove(at: index)
                                onUpdate(timeWindows)
                            }
                        )
                    }

                    // Add button
                    Button(action: {
                        let newWindow = TimeWindow(start: "09:00", end: "17:00")
                        timeWindows.append(newWindow)
                        onUpdate(timeWindows)
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Time Block")
                        }
                        .font(.system(size: 12, weight: .bold, design: .default))
                        .foregroundColor(ForceIQColors.electricGreen)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(ForceIQColors.iceCharcoalDark)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ForceIQColors.electricGreen.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .forceIQCard(level: 1)
        .onAppear {
            timeWindows = coach.weeklyHours[weekday]
        }
    }
}

// MARK: - Time Window Row

struct TimeWindowRow: View {
    let window: TimeWindow
    let onUpdate: (TimeWindow) -> Void
    let onDelete: () -> Void

    @State private var startTime: String
    @State private var endTime: String

    init(window: TimeWindow, onUpdate: @escaping (TimeWindow) -> Void, onDelete: @escaping () -> Void) {
        self.window = window
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _startTime = State(initialValue: window.start)
        _endTime = State(initialValue: window.end)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Start time
            VStack(alignment: .leading, spacing: 4) {
                Text("START")
                    .font(.system(size: 9, weight: .bold, design: .default))
                    .tracking(1)
                    .foregroundColor(ForceIQColors.textMuted)

                TextField("09:00", text: $startTime)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(ForceIQColors.textPrimary)
                    .padding(8)
                    .background(ForceIQColors.iceCharcoalDark)
                    .cornerRadius(4)
                    .onChange(of: startTime) { _, newValue in
                        var updated = window
                        updated.start = newValue
                        onUpdate(updated)
                    }
            }

            Image(systemName: "arrow.right")
                .foregroundColor(ForceIQColors.textMuted)
                .font(.system(size: 12))

            // End time
            VStack(alignment: .leading, spacing: 4) {
                Text("END")
                    .font(.system(size: 9, weight: .bold, design: .default))
                    .tracking(1)
                    .foregroundColor(ForceIQColors.textMuted)

                TextField("17:00", text: $endTime)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(ForceIQColors.textPrimary)
                    .padding(8)
                    .background(ForceIQColors.iceCharcoalDark)
                    .cornerRadius(4)
                    .onChange(of: endTime) { _, newValue in
                        var updated = window
                        updated.end = newValue
                        onUpdate(updated)
                    }
            }

            // Delete
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(ForceIQColors.forceRed)
                    .font(.system(size: 14))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(ForceIQColors.iceCharcoalDark)
        .cornerRadius(6)
    }
}
