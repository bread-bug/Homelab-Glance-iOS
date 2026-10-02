import SwiftUI

struct BackupListView: View {
    private let runs = BackupRun.samples

    var body: some View {
        NavigationStack {
            List(runs) { run in
                HStack(spacing: 12) {
                    StatusDot(status: run.status)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(run.target)
                            .font(.body)
                        Text(run.startedAt, format: .relative(presentation: .named))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(Duration.seconds(run.duration), format: .units(allowed: [.minutes, .seconds], width: .narrow))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .navigationTitle("Backups")
        }
    }
}

struct StatusDot: View {
    let status: RunStatus

    private var color: Color {
        switch status {
        case .ok: .green
        case .failed: .red
        case .running: .orange
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }
}

#Preview {
    BackupListView()
}
