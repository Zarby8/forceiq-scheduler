import Foundation
import Combine

public enum DayOfWeek: Int, CaseIterable, Codable {
    case monday = 1, tuesday = 2, wednesday = 3, thursday = 4, friday = 5, saturday = 6, sunday = 0

    public var displayName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }

    public var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
}

public struct TimeSlot: Codable, Identifiable {
    public var id = UUID()
    public var start: String
    public var end: String

    public init(start: String, end: String) {
        self.id = UUID()
        self.start = start
        self.end = end
    }
}

public struct RecurringTemplate: Codable, Identifiable {
    public var id = UUID()
    public var name: String
    public var description: String
    public var schedule: [DayOfWeek: [TimeSlot]]

    public init(name: String, description: String, schedule: [DayOfWeek: [TimeSlot]]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.schedule = schedule
    }
}

public class ScheduleModel: ObservableObject {
    @Published public var schedule: [DayOfWeek: [TimeSlot]] = [:]
    @Published public var sessionLength: Int = 60
    @Published public var bufferMinutes: Int = 15
    @Published public var recurringTemplates: [RecurringTemplate] = []
    @Published public var exportedCode: String = ""

    private let saveURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("ForceIQScheduler", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("schedule.json")
    }()

    public init() {
        setupDefaultTemplates()
    }

    public func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode(ScheduleData.self, from: data) else {
            loadDefaults()
            return
        }

        schedule = decoded.schedule
        sessionLength = decoded.sessionLength
        bufferMinutes = decoded.bufferMinutes
        if !decoded.templates.isEmpty {
            recurringTemplates = decoded.templates
        }
    }

    public func save() {
        let data = ScheduleData(
            schedule: schedule,
            sessionLength: sessionLength,
            bufferMinutes: bufferMinutes,
            templates: recurringTemplates
        )

        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: saveURL)
        }
    }

    public func addTemplate() {
        let template = RecurringTemplate(
            name: "New Template",
            description: "Custom schedule template",
            schedule: schedule
        )
        recurringTemplates.append(template)
    }

    public func applyTemplate(_ template: RecurringTemplate) {
        schedule = template.schedule
    }

    public func generateAppsScriptConfig() {
        var lines = ["WORKING_HOURS: {"]

        for day in DayOfWeek.allCases {
            let slots = schedule[day] ?? []
            if slots.isEmpty {
                lines.append("  \(day.rawValue): [], // \(day.displayName)")
            } else {
                let slotsStr = slots.map { slot in "['\\(slot.start)', '\\(slot.end)']" }.joined(separator: ", ")
                lines.append("  \(day.rawValue): [\(slotsStr)], // \(day.displayName)")
            }
        }

        lines.append("},")
        lines.append("SLOT_MINUTES: \(sessionLength),")
        lines.append("BUFFER_MINUTES: \(bufferMinutes),")

        exportedCode = lines.joined(separator: "\n")
    }

    private func loadDefaults() {
        // Business hours template as default
        schedule = [
            .monday: [TimeSlot(start: "10:00", end: "14:00")],
            .tuesday: [TimeSlot(start: "17:00", end: "20:00")],
            .wednesday: [TimeSlot(start: "17:00", end: "20:00")],
            .thursday: [TimeSlot(start: "17:00", end: "20:00")],
            .friday: [TimeSlot(start: "10:00", end: "13:00")],
            .saturday: [],
            .sunday: [TimeSlot(start: "10:00", end: "14:00")]
        ]
    }

    private func setupDefaultTemplates() {
        recurringTemplates = [
            RecurringTemplate(
                name: "Business Hours",
                description: "Monday-Friday 9am-5pm",
                schedule: [
                    .monday: [TimeSlot(start: "09:00", end: "17:00")],
                    .tuesday: [TimeSlot(start: "09:00", end: "17:00")],
                    .wednesday: [TimeSlot(start: "09:00", end: "17:00")],
                    .thursday: [TimeSlot(start: "09:00", end: "17:00")],
                    .friday: [TimeSlot(start: "09:00", end: "17:00")],
                    .saturday: [],
                    .sunday: []
                ]
            ),
            RecurringTemplate(
                name: "Evening Coaching",
                description: "Weekday evenings + weekend mornings",
                schedule: [
                    .monday: [TimeSlot(start: "18:00", end: "21:00")],
                    .tuesday: [TimeSlot(start: "18:00", end: "21:00")],
                    .wednesday: [TimeSlot(start: "18:00", end: "21:00")],
                    .thursday: [TimeSlot(start: "18:00", end: "21:00")],
                    .friday: [TimeSlot(start: "18:00", end: "21:00")],
                    .saturday: [TimeSlot(start: "09:00", end: "12:00")],
                    .sunday: [TimeSlot(start: "09:00", end: "12:00")]
                ]
            ),
            RecurringTemplate(
                name: "Split Schedule",
                description: "Morning + evening slots",
                schedule: [
                    .monday: [TimeSlot(start: "08:00", end: "10:00"), TimeSlot(start: "19:00", end: "21:00")],
                    .tuesday: [TimeSlot(start: "08:00", end: "10:00"), TimeSlot(start: "19:00", end: "21:00")],
                    .wednesday: [TimeSlot(start: "08:00", end: "10:00"), TimeSlot(start: "19:00", end: "21:00")],
                    .thursday: [TimeSlot(start: "08:00", end: "10:00"), TimeSlot(start: "19:00", end: "21:00")],
                    .friday: [TimeSlot(start: "08:00", end: "10:00")],
                    .saturday: [],
                    .sunday: []
                ]
            )
        ]
    }
}

private struct ScheduleData: Codable {
    let schedule: [DayOfWeek: [TimeSlot]]
    let sessionLength: Int
    let bufferMinutes: Int
    let templates: [RecurringTemplate]
}