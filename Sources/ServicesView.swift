import SwiftUI

@Observable
final class ServicesStore {
    enum State {
        case loading
        case loaded([Service])
        case failed(String)
    }

    private(set) var state: State = .loading
    private(set) var restarting: Set<String> = []
    var lastError: String?

    private let settings: AppSettings

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    @MainActor
    func load() async {
        if SampleData.isEnabled, let list = SampleData.services() {
            state = .loaded(list)
            return
        }
        do {
            let list = try await settings.client.services()
            state = .loaded(list.services)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    @MainActor
    func restart(_ service: Service) async {
        restarting.insert(service.name)
        defer { restarting.remove(service.name) }
        do {
            try await settings.client.restart(service: service.name)
            // docker needs a moment before the new state is visible
            try? await Task.sleep(for: .seconds(2))
            await load()
        } catch {
            lastError = error.localizedDescription
        }
    }
}

struct ServicesView: View {
    @State private var store = ServicesStore()
    @State private var query = ""

    var body: some View {
        Group {
            switch store.state {
            case .loading:
                ProgressView().controlSize(.large)
            case .failed(let message):
                ContentUnavailableView {
                    Label("Can't load services", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") { Task { await store.load() } }
                }
            case .loaded(let services):
                list(services)
            }
        }
        .navigationTitle("Services")
        .searchable(text: $query, prompt: "Filter")
        .refreshable { await store.load() }
        .task { await store.load() }
        .alert("Restart failed", isPresented: Binding(
            get: { store.lastError != nil },
            set: { if !$0 { store.lastError = nil } }
        )) {
            Button("OK", role: .cancel) { store.lastError = nil }
        } message: {
            Text(store.lastError ?? "")
        }
    }

    private func list(_ services: [Service]) -> some View {
        let filtered = query.isEmpty
            ? services
            : services.filter { $0.name.localizedCaseInsensitiveContains(query) }
        let attention = filtered.filter(\.needsAttention)
        let healthy = filtered.filter { !$0.needsAttention }

        return List {
            if !attention.isEmpty {
                Section("Needs attention") {
                    ForEach(attention) { row($0) }
                }
            }
            Section("Running \(healthy.count)") {
                ForEach(healthy) { row($0) }
            }
        }
    }

    private func row(_ service: Service) -> some View {
        NavigationLink {
            ServiceDetailView(service: service, store: store)
        } label: {
            HStack(spacing: 10) {
                ServiceDot(service: service)
                Text(service.name)
                Spacer()
                if store.restarting.contains(service.name) {
                    ProgressView()
                } else {
                    Text(service.stateLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ServiceDot: View {
    let service: Service

    private var color: Color {
        if !service.isRunning { return .red }
        if service.health == "unhealthy" { return .orange }
        if service.health == "health: starting" { return .yellow }
        return .green
    }

    var body: some View {
        Circle().fill(color).frame(width: 9, height: 9)
    }
}

struct ServiceDetailView: View {
    let service: Service
    let store: ServicesStore

    @State private var confirming = false

    var body: some View {
        List {
            Section {
                LabeledContent("State", value: service.state)
                if let health = service.health {
                    LabeledContent("Health", value: health)
                }
                if let status = service.status {
                    LabeledContent("Status", value: status)
                }
                if let created = service.createdAt {
                    LabeledContent("Created", value: created, format: .relative(presentation: .named))
                }
            }

            Section {
                if let image = service.image {
                    LabeledContent("Image", value: image)
                }
                if let project = service.project {
                    LabeledContent("Project", value: project)
                }
            }

            Section {
                Button(role: .destructive) {
                    confirming = true
                } label: {
                    if store.restarting.contains(service.name) {
                        HStack { ProgressView(); Text("Restarting…") }
                    } else {
                        Text("Restart")
                    }
                }
                .disabled(store.restarting.contains(service.name))
            }
        }
        .navigationTitle(service.name)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Restart \(service.name)?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Restart", role: .destructive) {
                Task { await store.restart(service) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
