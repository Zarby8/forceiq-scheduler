import Foundation

struct Client: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var email: String
    var phone: String
    var notes: String

    var createdAt: Date
    var lastMessageSent: Date?
    var totalBookings: Int
    var selectedForSending: Bool

    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        phone: String,
        notes: String = "",
        createdAt: Date = Date(),
        lastMessageSent: Date? = nil,
        totalBookings: Int = 0,
        selectedForSending: Bool = true
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.notes = notes
        self.createdAt = createdAt
        self.lastMessageSent = lastMessageSent
        self.totalBookings = totalBookings
        self.selectedForSending = selectedForSending
    }
}

struct Coach: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var email: String
    var calendarId: String
    var photoUrl: String?
    var bio: String?
    var color: String
    var weeklyHours: WeeklySchedule

    var isConnected: Bool

    init(
        id: String,
        name: String,
        email: String,
        calendarId: String = "",
        photoUrl: String? = nil,
        bio: String? = nil,
        color: String = "#F4C430",
        weeklyHours: WeeklySchedule = WeeklySchedule(),
        isConnected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.calendarId = calendarId
        self.photoUrl = photoUrl
        self.bio = bio
        self.color = color
        self.weeklyHours = weeklyHours
        self.isConnected = isConnected
    }
}

struct WeeklySchedule: Codable, Hashable {
    var sunday: [TimeWindow]
    var monday: [TimeWindow]
    var tuesday: [TimeWindow]
    var wednesday: [TimeWindow]
    var thursday: [TimeWindow]
    var friday: [TimeWindow]
    var saturday: [TimeWindow]

    init() {
        self.sunday = []
        self.monday = []
        self.tuesday = []
        self.wednesday = []
        self.thursday = []
        self.friday = []
        self.saturday = []
    }

    subscript(weekday: Int) -> [TimeWindow] {
        get {
            switch weekday {
            case 0: return sunday
            case 1: return monday
            case 2: return tuesday
            case 3: return wednesday
            case 4: return thursday
            case 5: return friday
            case 6: return saturday
            default: return []
            }
        }
        set {
            switch weekday {
            case 0: sunday = newValue
            case 1: monday = newValue
            case 2: tuesday = newValue
            case 3: wednesday = newValue
            case 4: thursday = newValue
            case 5: friday = newValue
            case 6: saturday = newValue
            default: break
            }
        }
    }
}

struct TimeWindow: Codable, Hashable, Identifiable {
    let id: UUID
    var start: String
    var end: String

    init(id: UUID = UUID(), start: String, end: String) {
        self.id = id
        self.start = start
        self.end = end
    }
}

struct Booking: Identifiable, Codable {
    let id: String
    let coachId: String
    let coachName: String
    let coachColor: String
    let clientName: String
    let clientEmail: String
    let startTime: Date
    let endTime: Date

    let game: String
    let date: String
    let time: String
    let timezone: String
    let focus: String
    let performance: String
    let rating: String
    let source: String
    let events: String
    let calendarLink: String

    var isPast: Bool {
        endTime < Date()
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(startTime)
    }

    var isUpcoming: Bool {
        startTime > Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, coachId, coachName, coachColor, clientName, clientEmail
        case game, date, time, timezone, focus, performance, rating, source, events, calendarLink
        case startTime, endTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        coachId = try container.decode(String.self, forKey: .coachId)
        coachName = try container.decode(String.self, forKey: .coachName)
        coachColor = try container.decode(String.self, forKey: .coachColor)
        clientName = try container.decode(String.self, forKey: .clientName)
        clientEmail = try container.decode(String.self, forKey: .clientEmail)
        game = try container.decode(String.self, forKey: .game)
        date = try container.decode(String.self, forKey: .date)
        time = try container.decode(String.self, forKey: .time)
        timezone = try container.decode(String.self, forKey: .timezone)
        focus = try container.decode(String.self, forKey: .focus)
        performance = try container.decode(String.self, forKey: .performance)
        rating = try container.decode(String.self, forKey: .rating)
        source = try container.decode(String.self, forKey: .source)
        events = try container.decode(String.self, forKey: .events)
        calendarLink = try container.decode(String.self, forKey: .calendarLink)

        let startTimeString = try container.decode(String.self, forKey: .startTime)
        let endTimeString = try container.decode(String.self, forKey: .endTime)

        let formatter = ISO8601DateFormatter()
        guard let start = formatter.date(from: startTimeString),
              let end = formatter.date(from: endTimeString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .startTime,
                in: container,
                debugDescription: "Invalid date format"
            )
        }

        startTime = start
        endTime = end
    }
}

struct SundaySendConfig: Codable {
    var enabled: Bool
    var sendTime: Date
    var messageTemplate: String
    var lastSentDate: Date?

    static let defaultTemplate = """
    Hi {name}! Ready to level up your game? 🏒

    Book your 1-on-1 session: {link}

    - ForceIQ Team
    """

    init(
        enabled: Bool = false,
        sendTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
        messageTemplate: String = SundaySendConfig.defaultTemplate,
        lastSentDate: Date? = nil
    ) {
        self.enabled = enabled
        self.sendTime = sendTime
        self.messageTemplate = messageTemplate
        self.lastSentDate = lastSentDate
    }
}

struct AppConfig: Codable {
    var bookingPageUrl: String
    var apiBaseUrl: String

    var coaches: [Coach]
    var sundayConfig: SundaySendConfig

    static let `default` = AppConfig(
        bookingPageUrl: "https://schedule.forcehockeyiq.com",
        apiBaseUrl: "https://schedule.forcehockeyiq.com/api",
        coaches: [
            Coach(id: "coach1", name: "Chris Zarb", email: "chris@forcehockeyiq.com", bio: "Lead Coach & Analytics Expert", color: "#F4C430"),
            Coach(id: "coach2", name: "Shane", email: "shaneb@forcehockeyiq.com", bio: "Performance Coach", color: "#4FFF4F")
        ],
        sundayConfig: SundaySendConfig()
    )
}
