import SwiftUI

@Observable
final class ActionsStore {
    private(set) var actions: [HomelabAction] = []
    private(set) var loadError: String?
    private(set) var runningID: String?
    var job: Job?

    private let settings: AppSettings

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    @MainActor
    func load() async {
        if SampleData.isEnabled, let list = SampleData.actions() {
            actions = list
            return
        }
        do {
            actions = try await settings.client.actions().actions
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    @MainActor
    func run(_ action: HomelabAction) async {
        runningID = action.id
        defer { runningID = nil }
        do {
            var current = try await settings.client.run(action: action.id)
            job = current

            // command actions finish later; poll until they settle
            let deadline = Date().addingTimeInterval(600)
            while current.isRunning, Date() < deadline {
                try await Task.sleep(for: .seconds(2))
                current = try await settings.client.job(id: current.id)
                job = current
            }
        } catch {
            loadError = error.localizedDescription
        }
    }
}

struct ActionsView: View {
    @State private var store = ActionsStore()
    @State private var pending: HomelabAction?

    var body: some View {
        List {
            if let loadError = store.loadError {
                Section {
                    Text(loadError).font(.caption).foregroundStyle(.red)
                }
            }

            if let job = store.job {
                Section("Last run") {
                    NavigationLink {
                        JobDetailView(job: job)
                    } label: {
                        JobRow(job: job)
                    }
                }
            }

            Section("Actions") {
                ForEach(store.actions) { action in
                    Button {
                        if action.needsConfirmation {
                            pending = action
                        } else {
                            Task { await store.run(action) }
                        }
                    } label: {
                        row(action)
                    }
                    .disabled(store.runningID != nil)
                }
            }
        }
        .navigationTitle("Actions")
        .refreshable { await store.load() }
        .task { await store.load() }
        .confirmationDialog(
            pending.map { "Run \($0.label)?" } ?? "",
            isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }),
            titleVisibility: .visible
        ) {
            if let action = pending {
                Button(action.label) {
                    Task { await store.run(action) }
                    pending = nil
                }
            }
            Button("Cancel", role: .cancel) { pending = nil }
        }
    }

    private func row(_ action: HomelabAction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(action.label).foregroundStyle(.primary)
                if let description = action.description {
                    Text(description).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if store.runningID == action.id {
                ProgressView()
            }
        }
    }
}

struct JobRow: View {
    let job: Job

    var body: some View {
        HStack(spacing: 10) {
            JobDot(state: job.state)
            VStack(alignment: .leading, spacing: 2) {
                Text(job.action)
                Text(job.startedAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if job.isRunning {
                ProgressView()
            } else {
                Text(job.state.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct JobDot: View {
    let state: JobState

    private var color: Color {
        switch state {
        case .running: .blue
        case .succeeded: .green
        case .failed: .red
        }
    }

    var body: some View {
        Circle().fill(color).frame(width: 9, height: 9)
    }
}

struct JobDetailView: View {
    let job: Job

    var body: some View {
        List {
            Section {
                LabeledContent("State", value: job.state.rawValue)
                if let code = job.exitCode {
                    LabeledContent("Exit code", value: String(code))
                }
                LabeledContent("Started", value: job.startedAt, format: .relative(presentation: .named))
                if let error = job.error {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
            if let tail = job.tail, !tail.isEmpty {
                Section("Output") {
                    ForEach(Array(tail.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .navigationTitle(job.action)
        .navigationBarTitleDisplayMode(.inline)
    }
}
