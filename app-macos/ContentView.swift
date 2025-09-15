import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.forceBlack, .forceIceCharcoal]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                header
                config
                clientList
                footer
            }
            .padding(18)
        }
        .frame(minWidth: 900, minHeight: 640)
    }

    private var header: some View {
        HStack {
            Text("FORCEIQ SCHEDULER").font(.system(size: 22, weight: .bold, design: .monospaced))
                .kerning(2)
                .foregroundColor(.forceYellow)
            Spacer()
            Text(model.status)
                .foregroundColor(.gray)
                .font(.system(.footnote, design: .monospaced))
        }
    }

    private var config: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Link Base")
                    .foregroundColor(.forceGreen)
                TextField("https://schedule.forcehockeyiq.com", text: $model.schedulingLink)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading) {
                Text("Message Template {name} {link}").foregroundColor(.forceGreen)
                TextEditor(text: $model.messageTemplate)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 110)
                    .padding(8)
                    .background(Color.forceCard)
                    .cornerRadius(8)
            }
        }
    }

    private var clientList: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("CLIENTS").foregroundColor(.forceYellow).font(.caption).kerning(1.5)
                Spacer()
                Button("Add") { model.clients.append(Client(name: "New Client", handle: "", email: "")) }
                Button("Save List") { model.save() }
            }
            List {
                ForEach($model.clients) { $c in
                    HStack {
                        Toggle("", isOn: $c.selected).toggleStyle(.checkbox)
                        TextField("Name", text: $c.name)
                            .textFieldStyle(.roundedBorder)
                        TextField("Handle (phone/email)", text: $c.handle)
                            .textFieldStyle(.roundedBorder)
                        TextField("Email", text: $c.email)
                            .textFieldStyle(.roundedBorder)
                        Toggle("Active", isOn: $c.active)
                        TextField("Notes", text: $c.notes)
                            .textFieldStyle(.roundedBorder)
                    }
                    .listRowBackground(Color.forceCard)
                }
                .onDelete { idx in model.clients.remove(atOffsets: idx) }
            }
            .background(Color.forceIceCharcoal)
            .scrollContentBackground(.hidden)
        }
    }

    private var footer: some View {
        HStack {
            Button(action: model.sendSelected) {
                HStack {
                    if model.sending { ProgressView() }
                    Text("Send to Selected").bold()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.forceGreen)
            
            Button("Preview First Selected") {
                if let c = model.clients.first(where: { $0.selected }) {
                    let msg = model.resolvedMessage(for: c, link: model.buildSignedLink(for: c))
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(msg, forType: .string)
                    model.status = "Preview copied for \(c.name)."
                } else {
                    model.status = "Select at least one client."
                }
            }
            .tint(.forceYellow)
            .buttonStyle(.bordered)
            Spacer()
            Text("Electric analytics. Precision scheduling.")
                .foregroundColor(.gray)
                .font(.footnote)
        }
    }
}

