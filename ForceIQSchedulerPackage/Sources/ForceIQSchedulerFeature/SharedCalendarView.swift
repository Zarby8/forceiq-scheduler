import SwiftUI
import Foundation

public struct SharedCalendarView: View {
    @StateObject private var calendarModel = SharedCalendarModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedView: CalendarViewType = .week
    @State private var selectedDate = Date()

    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.forceBlack, .forceIceCharcoal]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                calendarControls
                calendarContent
            }
            .padding(24)
        }
        .frame(minWidth: 1000, minHeight: 700)
        .onAppear {
            calendarModel.loadSchedules()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("SHARED CALENDAR")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .kerning(2)
                    .foregroundColor(.forceYellow)

                Text("View schedules for Christopher and Shane")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Refresh") {
                    calendarModel.refreshSchedules()
                }
                .buttonStyle(ForceIQButtonStyle(style: .ghost))

                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(ForceIQButtonStyle(style: .secondary))
            }
        }
    }

    private var calendarControls: some View {
        ForceIQCard {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("VIEW OPTIONS")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.forceYellow)

                    Picker("View Type", selection: $selectedView) {
                        Text("Daily").tag(CalendarViewType.day)
                        Text("Weekly").tag(CalendarViewType.week)
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(.forceYellow)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text("DATE NAVIGATION")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.forceGreen)

                    HStack(spacing: 8) {
                        Button(action: previousPeriod) {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(ForceIQButtonStyle(style: .ghost))

                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .accentColor(.forceYellow)

                        Button(action: nextPeriod) {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(ForceIQButtonStyle(style: .ghost))
                    }
                }
            }
        }
    }

    private var calendarContent: some View {
        ForceIQCard {
            VStack(alignment: .leading, spacing: 16) {
                ForceIQSectionHeader("TEAM SCHEDULES", icon: "calendar", color: .forceBlue)

                if calendarModel.isLoading {
                    ForceIQLoadingView("Loading schedules...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    switch selectedView {
                    case .day:
                        dailyView
                    case .week:
                        weeklyView
                    }
                }
            }
        }
    }

    private var dailyView: some View {
        ScrollView {
            HStack(spacing: 20) {
                // Christopher's Schedule
                PersonScheduleColumn(
                    person: calendarModel.christopher,
                    date: selectedDate,
                    viewType: .day
                )

                Divider()
                    .background(Color.forceYellow.opacity(0.3))

                // Shane's Schedule
                PersonScheduleColumn(
                    person: calendarModel.shane,
                    date: selectedDate,
                    viewType: .day
                )
            }
            .padding()
        }
        .frame(maxHeight: 500)
    }

    private var weeklyView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Week header
                HStack {
                    ForEach(weekDays, id: \.self) { day in
                        Text(day.formatted(.dateTime.weekday(.wide)))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.forceYellow)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Schedule grid
                HStack(spacing: 0) {
                    ForEach(weekDays, id: \.self) { day in
                        VStack(spacing: 8) {
                            // Christopher's appointments for this day
                            ForEach(calendarModel.getAppointments(for: .christopher, on: day), id: \.id) { appointment in
                                AppointmentCard(appointment: appointment, person: .christopher)
                            }

                            Divider()
                                .background(Color.forceYellow.opacity(0.2))

                            // Shane's appointments for this day
                            ForEach(calendarModel.getAppointments(for: .shane, on: day), id: \.id) { appointment in
                                AppointmentCard(appointment: appointment, person: .shane)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
                    }
                }
            }
            .padding()
        }
        .frame(maxHeight: 500)
    }

    private var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }

    private func previousPeriod() {
        let calendar = Calendar.current
        switch selectedView {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    private func nextPeriod() {
        let calendar = Calendar.current
        switch selectedView {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        }
    }
}

enum CalendarViewType: String, CaseIterable {
    case day = "Day"
    case week = "Week"
}

// MARK: - Supporting Views

struct PersonScheduleColumn: View {
    let person: Person
    let date: Date
    let viewType: CalendarViewType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(person.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name.uppercased())
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    Text(person.title)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                }

                Spacer()

                if person.isAvailable {
                    ForceIQStatusBadge("Available", status: .active)
                } else {
                    ForceIQStatusBadge("Busy", status: .warning)
                }
            }

            // Time slots for the day
            VStack(spacing: 6) {
                ForEach(person.getAppointments(for: date), id: \.id) { appointment in
                    AppointmentCard(appointment: appointment, person: person.type)
                }

                if person.getAppointments(for: date).isEmpty {
                    Text("No appointments")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.forceIceCharcoal.opacity(0.5))
                        .cornerRadius(6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppointmentCard: View {
    let appointment: CalendarAppointment
    let person: PersonType

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(appointment.startTime)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.forceGreen)
                Text("-")
                    .foregroundColor(.gray)
                Text(appointment.endTime)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.forceRed)
                Spacer()
            }

            Text(appointment.title)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(2)

            if !appointment.client.isEmpty {
                Text(appointment.client)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
        .padding(8)
        .background(appointment.type.color.opacity(0.2))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(appointment.type.color.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Data Models

@MainActor
class SharedCalendarModel: ObservableObject {
    @Published var christopher: Person
    @Published var shane: Person
    @Published var isLoading = false

    init() {
        self.christopher = Person(
            name: "Christopher",
            title: "Head Coach",
            type: .christopher,
            color: .forceYellow,
            isAvailable: true
        )

        self.shane = Person(
            name: "Shane",
            title: "Assistant Coach",
            type: .shane,
            color: .forceBlue,
            isAvailable: false
        )
    }

    func loadSchedules() {
        isLoading = true

        // Simulate loading from Google Calendar API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.loadSampleData()
            self.isLoading = false
        }
    }

    func refreshSchedules() {
        loadSchedules()
    }

    func getAppointments(for person: PersonType, on date: Date) -> [CalendarAppointment] {
        switch person {
        case .christopher:
            return christopher.getAppointments(for: date)
        case .shane:
            return shane.getAppointments(for: date)
        }
    }

    private func loadSampleData() {
        // Sample appointments for Christopher
        christopher.appointments = [
            CalendarAppointment(
                title: "Youth Training Session",
                startTime: "17:00",
                endTime: "18:30",
                client: "Tommy Miller",
                date: Date(),
                type: .training
            ),
            CalendarAppointment(
                title: "Strategy Review",
                startTime: "19:00",
                endTime: "20:00",
                client: "Sarah Johnson",
                date: Date(),
                type: .review
            )
        ]

        // Sample appointments for Shane
        shane.appointments = [
            CalendarAppointment(
                title: "Equipment Check",
                startTime: "16:00",
                endTime: "17:00",
                client: "",
                date: Date(),
                type: .admin
            ),
            CalendarAppointment(
                title: "Junior Training",
                startTime: "18:00",
                endTime: "19:30",
                client: "Alex Thompson",
                date: Date(),
                type: .training
            )
        ]
    }
}

struct Person {
    let name: String
    let title: String
    let type: PersonType
    let color: Color
    var isAvailable: Bool
    var appointments: [CalendarAppointment] = []

    func getAppointments(for date: Date) -> [CalendarAppointment] {
        let calendar = Calendar.current
        return appointments.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }.sorted { $0.startTime < $1.startTime }
    }
}

enum PersonType {
    case christopher
    case shane
}

struct CalendarAppointment: Identifiable {
    let id = UUID()
    let title: String
    let startTime: String
    let endTime: String
    let client: String
    let date: Date
    let type: AppointmentType
}

enum AppointmentType {
    case training
    case review
    case admin
    case meeting

    var color: Color {
        switch self {
        case .training: return .forceGreen
        case .review: return .forceYellow
        case .admin: return .forceBlue
        case .meeting: return .forceRed
        }
    }
}