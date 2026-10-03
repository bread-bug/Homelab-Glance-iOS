import Foundation

/// Lets CI render the populated UI without a reachable server:
/// `simctl launch <bundle> --sample`.
enum SampleData {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("--sample")
    }

    /// Screen to open directly, from `--screen <name>`.
    static var screen: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "--screen"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static func actions() -> [HomelabAction]? {
        guard let data = actionsJSON.data(using: .utf8) else { return nil }
        return try? APIClient.decoder.decode(ActionList.self, from: data).actions
    }

    static let actionsJSON = """
    {
      "actions": [
        {"id":"host-uptime","label":"Check host agent","description":"Runs uptime on the host; proves the agent path works","kind":"command","confirm":false},
        {"id":"backup-now","label":"Run backup now","description":"Full selfhosted backup to Proton and B2","kind":"command","confirm":true},
        {"id":"backup-immich-retry","label":"Retry Immich backup","description":"Re-runs the weekly Immich job","kind":"command","confirm":true},
        {"id":"adguard-pause-5","label":"Pause AdGuard 5 min","description":"Disables filtering, then it re-enables itself","kind":"http","confirm":false},
        {"id":"adguard-pause-30","label":"Pause AdGuard 30 min","kind":"http","confirm":true},
        {"id":"adguard-resume","label":"Resume AdGuard","kind":"http","confirm":false},
        {"id":"aggregator-recommendations","label":"Refresh recommendations","description":"Webnovel Aggregator recommendation rebuild","kind":"http","confirm":false}
      ]
    }
    """

    static func services() -> [Service]? {
        guard let data = servicesJSON.data(using: .utf8) else { return nil }
        return try? APIClient.decoder.decode(ServiceList.self, from: data).services
    }

    static let servicesJSON = """
    {
      "services": [
        {"name":"flaresolverr","state":"running","health":"unhealthy","status":"Up 3 hours (unhealthy)","image":"flaresolverr:latest","project":"flaresolverr","created_at":"2026-10-03T08:00:00+05:30","cpu_percent":0.4,"mem_usage":212000000,"mem_limit":16600000000},
        {"name":"adguardhome","state":"running","status":"Up 6 hours","image":"adguard/adguardhome:latest","project":"adguard","created_at":"2026-10-03T05:30:00+05:30","cpu_percent":1.2,"mem_usage":96000000,"mem_limit":16600000000},
        {"name":"authentik-server-1","state":"running","health":"healthy","status":"Up 6 hours (healthy)","image":"authentik:2026.8","project":"authentik","created_at":"2026-10-03T05:30:00+05:30","cpu_percent":0.7,"mem_usage":821000000,"mem_limit":16600000000},
        {"name":"immich_server","state":"running","health":"healthy","status":"Up 6 hours (healthy)","image":"immich-server:v1.140","project":"immich","created_at":"2026-10-03T05:30:00+05:30","cpu_percent":0.1,"mem_usage":853000000,"mem_limit":16600000000},
        {"name":"kavita","state":"running","health":"healthy","status":"Up 6 hours (healthy)","image":"kavita:latest","project":"kavita","created_at":"2026-10-03T05:30:00+05:30","cpu_percent":0.7,"mem_usage":473000000,"mem_limit":16600000000},
        {"name":"ntfy","state":"running","status":"Up 6 hours","image":"binwiederhier/ntfy:latest","project":"ntfy","created_at":"2026-10-03T05:30:00+05:30","cpu_percent":0.0,"mem_usage":18000000,"mem_limit":16600000000},
        {"name":"uptime-kuma","state":"running","health":"healthy","status":"Up 6 hours (healthy)","image":"uptime-kuma:1","project":"uptimekuma","created_at":"2026-10-03T05:30:00+05:30","cpu_percent":0.3,"mem_usage":158000000,"mem_limit":16600000000},
        {"name":"webnovel-aggregator","state":"running","status":"Up 2 minutes","image":"webnovel-aggregator:local","project":"webnovel-aggregator","created_at":"2026-10-03T17:35:00+05:30","cpu_percent":0.2,"mem_usage":64000000,"mem_limit":16600000000}
      ]
    }
    """

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
