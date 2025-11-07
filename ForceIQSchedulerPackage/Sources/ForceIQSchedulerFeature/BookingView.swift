import SwiftUI

struct BookingView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var selectedCoach: Coach?
    @State private var selectedClient: Client?
    @State private var selectedDate = Date()
    @State private var selectedTimeHour = 9
    @State private var selectedTimeMinute = 0
    @State private var duration = 60 // minutes
    @State private var gameRequest = ""
    @State private var isBooking = false
    @State private var bookingStatus = ""
    @State private var showingClientPicker = false
    @State private var overrideAvailability = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    ForceIQSectionHeader(title: "Admin Booking")
                    Spacer()

                    Toggle("Override Hours", isOn: $overrideAvailability)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(overrideAvailability ? ForceIQColors.electricGreen : ForceIQColors.textMuted)
                        .toggleStyle(.switch)
                        .tint(ForceIQColors.electricGreen)
                }

                // Coach Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("SELECT COACH")
                        .font(.system(size: 11, weight: .black, design: .default))
                        .tracking(1.5)
                        .foregroundColor(ForceIQColors.highlightYellow)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(appModel.config.coaches) { coach in
                            CoachSelectionCard(
                                coach: coach,
                                isSelected: selectedCoach?.id == coach.id
                            ) {
                                selectedCoach = coach
                            }
                        }
                    }
                }

                // Client Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("SELECT CLIENT")
                        .font(.system(size: 11, weight: .black, design: .default))
                        .tracking(1.5)
                        .foregroundColor(ForceIQColors.highlightYellow)

                    if let client = selectedClient {
                        HStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [ForceIQColors.highlightYellow, ForceIQColors.electricGreen],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(client.name.prefix(1)).uppercased())
                                        .font(.system(size: 14, weight: .black, design: .default))
                                        .foregroundColor(ForceIQColors.black)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(client.name)
                                    .font(.system(size: 14, weight: .bold, design: .default))
                                    .foregroundColor(ForceIQColors.textPrimary)

                                Text(client.email)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(ForceIQColors.textSecondary)
                            }

                            Spacer()

                            Button("Change") {
                                showingClientPicker = true
                            }
                            .buttonStyle(ForceIQButtonStyle(type: .secondary))
                        }
                        .padding(16)
                        .forceIQCard(level: 2)
                    } else {
                        Button(action: { showingClientPicker = true }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Select Client")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ForceIQButtonStyle(type: .secondary))
                    }
                }

                // Date & Time Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("DATE & TIME")
                        .font(.system(size: 11, weight: .black, design: .default))
                        .tracking(1.5)
                        .foregroundColor(ForceIQColors.highlightYellow)

                    VStack(spacing: 12) {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .colorScheme(.dark)
                            .accentColor(ForceIQColors.electricGreen)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("HOUR")
                                    .font(.system(size: 10, weight: .bold, design: .default))
                                    .tracking(1)
                                    .foregroundColor(ForceIQColors.textMuted)

                                Picker("Hour", selection: $selectedTimeHour) {
                                    ForEach(0..<24) { hour in
                                        Text(String(format: "%02d", hour)).tag(hour)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(height: 80)
                            }

                            Text(":")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(ForceIQColors.highlightYellow)
                                .padding(.top, 20)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("MINUTE")
                                    .font(.system(size: 10, weight: .bold, design: .default))
                                    .tracking(1)
                                    .foregroundColor(ForceIQColors.textMuted)

                                Picker("Minute", selection: $selectedTimeMinute) {
                                    ForEach([0, 15, 30, 45], id: \.self) { minute in
                                        Text(String(format: "%02d", minute)).tag(minute)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(height: 80)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("DURATION")
                                    .font(.system(size: 10, weight: .bold, design: .default))
                                    .tracking(1)
                                    .foregroundColor(ForceIQColors.textMuted)

                                Picker("Duration", selection: $duration) {
                                    Text("30 min").tag(30)
                                    Text("60 min").tag(60)
                                    Text("90 min").tag(90)
                                    Text("120 min").tag(120)
                                }
                                .pickerStyle(.menu)
                                .frame(height: 80)
                            }
                        }
                    }
                    .padding(16)
                    .forceIQCard(level: 2)
                }

                // Game Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("SESSION NOTES")
                        .font(.system(size: 11, weight: .black, design: .default))
                        .tracking(1.5)
                        .foregroundColor(ForceIQColors.highlightYellow)

                    TextField("Game request (optional)", text: $gameRequest)
                        .textFieldStyle(ForceIQTextFieldStyle())
                }

                // Status
                if !bookingStatus.isEmpty {
                    Text(bookingStatus)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(bookingStatus.contains("✓") ? ForceIQColors.electricGreen : ForceIQColors.forceRed)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(ForceIQColors.iceCharcoalDark)
                        .cornerRadius(6)
                }

                // Create Booking Button
                Button(action: createBooking) {
                    HStack {
                        if isBooking {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(ForceIQColors.black)
                        }
                        Text(isBooking ? "Creating..." : "Create Booking")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ForceIQButtonStyle(type: .primary))
                .disabled(isBooking || selectedCoach == nil || selectedClient == nil)
            }
            .padding(24)
        }
        .background(ForceIQColors.black)
        .sheet(isPresented: $showingClientPicker) {
            ClientPickerView(selectedClient: $selectedClient)
        }
    }

    private func createBooking() {
        guard let coach = selectedCoach, let client = selectedClient else {
            bookingStatus = "❌ Select coach and client"
            return
        }

        isBooking = true
        bookingStatus = ""

        Task {
            do {
                // Build start and end times
                var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
                components.hour = selectedTimeHour
                components.minute = selectedTimeMinute

                guard let startTime = Calendar.current.date(from: components) else {
                    await MainActor.run {
                        bookingStatus = "❌ Invalid date/time"
                        isBooking = false
                    }
                    return
                }

                let endTime = startTime.addingTimeInterval(TimeInterval(duration * 60))

                // Prepare booking payload
                let payload: [String: Any] = [
                    "coachId": coach.id,
                    "clientId": client.id.uuidString,
                    "clientName": client.name,
                    "clientEmail": client.email,
                    "clientPhone": client.phone,
                    "startTime": Int(startTime.timeIntervalSince1970 * 1000), // milliseconds
                    "endTime": Int(endTime.timeIntervalSince1970 * 1000),
                    "timezone": TimeZone.current.identifier,
                    "gameDetails": [
                        "game": gameRequest.isEmpty ? "Admin Booking" : gameRequest,
                        "date": "",
                        "time": "",
                        "timezone": TimeZone.current.identifier,
                        "focus": "Booked by admin",
                        "performance": "",
                        "rating": 0,
                        "source": "Admin",
                        "events": ""
                    ]
                ]

                let url = URL(string: "\(appModel.config.apiBaseUrl)/book")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)

                let (_, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw NSError(domain: "Booking", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
                }

                await MainActor.run {
                    bookingStatus = "✓ Booking created for \(client.name)"
                    isBooking = false

                    // Reset form
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        selectedClient = nil
                        gameRequest = ""
                        bookingStatus = ""
                    }

                    // Refresh bookings
                    Task {
                        await appModel.fetchUpcomingBookings()
                    }
                }
            } catch {
                await MainActor.run {
                    bookingStatus = "❌ Booking failed: \(error.localizedDescription)"
                    isBooking = false
                }
            }
        }
    }
}

// MARK: - Coach Selection Card

struct CoachSelectionCard: View {
    let coach: Coach
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: coach.color))

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ForceIQColors.electricGreen)
                    }
                }

                Text(coach.name)
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundColor(ForceIQColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let bio = coach.bio {
                    Text(bio.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .default))
                        .tracking(1)
                        .foregroundColor(ForceIQColors.textMuted)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(ForceIQColors.iceCharcoal)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: coach.color) : ForceIQColors.forceRed.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(color: (isSelected ? Color(hex: coach.color) : .clear).opacity(0.3), radius: 8)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Client Picker Sheet

struct ClientPickerView: View {
    @EnvironmentObject var appModel: AppModel
    @Binding var selectedClient: Client?
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    var filteredClients: [Client] {
        if searchText.isEmpty {
            return appModel.clients
        }
        return appModel.clients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                ForceIQSectionHeader(title: "Select Client")
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(ForceIQColors.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            Divider()
                .background(ForceIQColors.forceRed.opacity(0.3))

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ForceIQColors.textMuted)

                TextField("Search clients...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(ForceIQColors.textPrimary)
            }
            .padding(12)
            .background(ForceIQColors.iceCharcoalDark)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ForceIQColors.forceRed.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            // Client List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredClients) { client in
                        ClientPickerCard(client: client) {
                            selectedClient = client
                            dismiss()
                        }
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 500, height: 600)
        .background(ForceIQColors.iceCharcoal)
    }
}

struct ClientPickerCard: View {
    let client: Client
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ForceIQColors.highlightYellow, ForceIQColors.electricGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(client.name.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .black, design: .default))
                            .foregroundColor(ForceIQColors.black)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name)
                        .font(.system(size: 14, weight: .bold, design: .default))
                        .foregroundColor(ForceIQColors.textPrimary)

                    Text(client.email)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(ForceIQColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(ForceIQColors.textMuted)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .background(ForceIQColors.iceCharcoalDark)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ForceIQColors.forceRed.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
