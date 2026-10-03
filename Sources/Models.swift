import Foundation

struct Status: Decodable {
    let generatedAt: Date
    let backup: Backup
    let services: Services
    let system: SystemInfo
}

struct Backup: Decodable {
    let last: BackupRun?
    let history: [BackupRun]
    let nextRun: Date?
    let error: String?
}

enum BackupResult: String, Decodable {
    case ok, partial, failed, running
}

struct BackupRun: Decodable, Identifiable {
    let job: String
    let startedAt: Date
    let durationS: Double
    let result: BackupResult
    let snapshotId: String?
    let destinations: [String: String]?
    let addedPrimary: String?
    let addedB2: String?

    var id: String { "\(job)-\(startedAt.timeIntervalSince1970)" }

    /// Destinations that did not succeed, for the partial-failure summary.
    var failedDestinations: [String] {
        (destinations ?? [:]).filter { $0.value != "ok" }.keys.sorted()
    }
}

struct Services: Decodable {
    let total: Int
    let running: Int
    let degraded: [Service]
    let error: String?
}

struct Service: Decodable, Identifiable {
    let name: String
    let state: String
    let health: String?
    let status: String?
    let image: String?
    let project: String?
    let createdAt: Date?

    var id: String { name }

    var isRunning: Bool { state == "running" }
    var needsAttention: Bool { !isRunning || health == "unhealthy" }

    /// Short label for the trailing edge of a row.
    var stateLabel: String { health ?? state }
}

struct ServiceList: Decodable {
    let services: [Service]
    let error: String?
}

struct SystemInfo: Decodable {
    let uptimeS: Double
    let load1: Double
    let load5: Double
    let memTotal: UInt64
    let memUsed: UInt64
    let disks: [Disk]
    let error: String?
}

struct Disk: Decodable, Identifiable {
    let mount: String
    let size: UInt64
    let free: UInt64

    var id: String { mount }
    var used: UInt64 { size > free ? size - free : 0 }
    var usedFraction: Double { size == 0 ? 0 : Double(used) / Double(size) }
}
