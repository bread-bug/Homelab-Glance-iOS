import Foundation

enum RunStatus {
    case ok, failed, running
}

struct BackupRun: Identifiable {
    let id = UUID()
    let target: String
    let startedAt: Date
    let duration: TimeInterval
    let status: RunStatus
}

// Placeholder data until the Proxmox task API is wired up.
extension BackupRun {
    static let samples: [BackupRun] = [
        BackupRun(target: "vm/101 — media", startedAt: .now.addingTimeInterval(-3600), duration: 412, status: .ok),
        BackupRun(target: "vm/102 — docs", startedAt: .now.addingTimeInterval(-7200), duration: 96, status: .ok),
        BackupRun(target: "ct/201 — proxy", startedAt: .now.addingTimeInterval(-10800), duration: 38, status: .failed),
        BackupRun(target: "vm/103 — db", startedAt: .now.addingTimeInterval(-86400), duration: 1180, status: .ok),
    ]
}
