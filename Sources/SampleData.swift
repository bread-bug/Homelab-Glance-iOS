import Foundation

/// Lets CI render the populated UI without a reachable server:
/// `simctl launch <bundle> --sample`.
enum SampleData {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("--sample")
    }

    static let json = """
    {
      "generated_at": "2026-10-03T12:39:57.123+05:30",
      "backup": {
        "last": {
          "job": "selfhosted",
          "started_at": "2026-10-02T22:00:01+05:30",
          "duration_s": 315,
          "result": "ok",
          "snapshot_id": "c676dd4b",
          "destinations": {"proton": "ok", "b2": "ok"},
          "added_primary": "236.719 MiB",
          "added_b2": "237.222 MiB"
        },
        "history": [
          {"job":"selfhosted","started_at":"2026-09-30T22:00:01+05:30","duration_s":419,"result":"ok","snapshot_id":"d9e6a09f","destinations":{"proton":"ok","b2":"ok"}},
          {"job":"immich","started_at":"2026-10-01T03:00:02+05:30","duration_s":1180,"result":"partial","snapshot_id":"7f21ac90","destinations":{"proton":"ok","b2":"failed"}},
          {"job":"selfhosted","started_at":"2026-10-02T22:00:01+05:30","duration_s":315,"result":"ok","snapshot_id":"c676dd4b","destinations":{"proton":"ok","b2":"ok"}}
        ],
        "next_run": "2026-10-03T22:00:00+05:30"
      },
      "services": {
        "total": 42,
        "running": 41,
        "degraded": [
          {"name": "flaresolverr", "state": "running", "health": "unhealthy", "status": "Up 3 hours (unhealthy)"}
        ]
      },
      "system": {
        "uptime_s": 186400,
        "load1": 0.39,
        "load5": 1.10,
        "mem_total": 16600000000,
        "mem_used": 7300000000,
        "disks": [
          {"mount": "root", "size": 211000000000, "free": 138000000000},
          {"mount": "storage", "size": 528000000000, "free": 328000000000}
        ]
      }
    }
    """
}
