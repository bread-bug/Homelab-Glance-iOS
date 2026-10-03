import SwiftUI

struct GlanceView: View {
    @State private var store = StatusStore()
    @State private var settings = AppSettings.shared
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Homelab")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .refreshable { await store.load() }
                .sheet(isPresented: $showingSettings) {
                    SettingsView(settings: settings)
                }
                .autoRefresh { await store.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading:
            ProgressView().controlSize(.large)
        case .failed(let message):
            ContentUnavailableView {
                Label("Can't reach server", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Settings") { showingSettings = true }
                Button("Retry") { Task { await store.load() } }
            }
        case .loaded(let status):
            List {
                BackupSection(backup: status.backup)
                ServicesSection(services: status.services)
                SystemSection(system: status.system)
                Section {
                    NavigationLink {
                        ActionsView()
                    } label: {
                        Label("Actions", systemImage: "bolt")
                    }
                }
            }
        }
    }
}

struct BackupSection: View {
    let backup: Backup

    var body: some View {
        Section("Backups") {
            if let last = backup.last {
                BackupRow(run: last)
            } else {
                Text("No runs recorded").foregroundStyle(.secondary)
            }
            if let next = backup.nextRun {
                LabeledContent("Next run", value: next, format: .relative(presentation: .named))
            }
            if !backup.history.isEmpty {
                NavigationLink("History") {
                    List(backup.history.reversed()) { BackupRow(run: $0) }
                        .navigationTitle("Backup history")
                }
            }
            if let error = backup.error {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
    }
}

struct BackupRow: View {
    let run: BackupRun

    var body: some View {
        HStack(spacing: 12) {
            StatusDot(result: run.result)
            VStack(alignment: .leading, spacing: 2) {
                Text(run.job.capitalized)
                Text(run.startedAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !run.failedDestinations.isEmpty {
                    Text("Failed: \(run.failedDestinations.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(durationText).font(.caption.monospacedDigit())
                if let id = run.snapshotId {
                    Text(id).font(.caption2.monospaced()).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var durationText: String {
        let total = Int(run.durationS)
        return total >= 60 ? "\(total / 60)m \(total % 60)s" : "\(total)s"
    }
}

struct StatusDot: View {
    let result: BackupResult

    private var color: Color {
        switch result {
        case .ok: .green
        case .partial: .orange
        case .failed: .red
        case .running: .blue
        }
    }

    var body: some View {
        Circle().fill(color).frame(width: 10, height: 10)
    }
}

struct ServicesSection: View {
    let services: Services

    var body: some View {
        Section("Services") {
            if let error = services.error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                NavigationLink {
                    ServicesView()
                } label: {
                    LabeledContent("Running", value: "\(services.running) of \(services.total)")
                }
                if services.degraded.isEmpty {
                    Label("All healthy", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                } else {
                    ForEach(services.degraded) { service in
                        HStack {
                            Circle()
                                .fill(service.state == "running" ? Color.orange : Color.red)
                                .frame(width: 8, height: 8)
                            Text(service.name)
                            Spacer()
                            Text(service.health ?? service.state)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct SystemSection: View {
    let system: SystemInfo

    var body: some View {
        Section("Host") {
            LabeledContent("Uptime", value: uptimeText)
            LabeledContent("Load", value: String(format: "%.2f / %.2f", system.load1, system.load5))
            LabeledContent("Memory", value: "\(bytes(system.memUsed)) of \(bytes(system.memTotal))")
            ForEach(system.disks) { disk in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(disk.mount.capitalized)
                        Spacer()
                        Text("\(bytes(disk.free)) free")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: disk.usedFraction)
                        .tint(disk.usedFraction > 0.9 ? .red : .accentColor)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var uptimeText: String {
        let days = Int(system.uptimeS) / 86_400
        let hours = (Int(system.uptimeS) % 86_400) / 3_600
        return days > 0 ? "\(days)d \(hours)h" : "\(hours)h"
    }

    private func bytes(_ value: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
    }
}
