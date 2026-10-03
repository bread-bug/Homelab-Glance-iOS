# Status

## Done

- **CI on GitHub (macOS runners).** Push → compile (~1 min). Manual dispatch → compile +
  light/dark simulator screenshots as a run artifact (~4.5 min). Tag or dispatch →
  signed IPA to TestFlight (~3 min).
- **Forgejo is primary**; GitHub is a push mirror used only because Swift needs macOS.
- **Glance screen** against `homelab-api`: last backup run with per-destination result,
  next scheduled run, history, degraded services, host uptime/load/memory/disks.
- **Settings**: base URL in defaults, API key in the keychain, test-connection button.
- `--sample` launch flag renders representative data so CI can screenshot the populated
  UI with no server reachable.

## M1 — done

- **Services screen**: all containers, grouped into "Needs attention" (stopped or
  unhealthy) and running, with a filter field.
- **Detail view**: state, health, status, created, image, compose project.
- **Restart**, behind a confirmation, via `POST /api/v1/services/{name}/restart`.
  The backend only restarts a name docker currently reports, and the socket proxy
  allows POST on `/containers/<name>/restart` and nothing else.
- Home screen name shortened to **Glance**.
- CI screenshots the services screen too, via `--sample --screen services`.

## M2 — done

- **Actions screen** with confirmation on destructive ones, a spinner while running,
  and a job detail view showing exit code and output tail.
- **Host agent** (`cmd/homelab-agent`, systemd, root) on a unix socket mounted into the
  API container. It accepts an **action ID from a compiled-in allowlist** — never a
  command string — so the container can start a known job but cannot express one.
- Actions: `host-uptime`, `backup-now`, `backup-immich-retry` (command);
  AdGuard pause 5/30, AdGuard resume, aggregator ingest (HTTP).
- Verified on the host: `host-uptime` exit 0 with output, `rm-rf` → 404,
  aggregator refresh → `202 queued`, AdGuard resume → `200 OK`.
- AdGuard is reached on its own docker network, not through nginx: the public host is
  behind Authentik, which would intercept any API call.

## Not done

- Backend is **not deployed** — see `homelab-api/README.md` for the remaining host steps
  (socket-proxy allowfrom, nginx vhost, `.env`, `DEPLOY_ENABLED`).
- No capture/share extension, widget, or push.
- Action credentials are configured in the server `.env`; unconfigured ones fail cleanly.
- Backup data is parsed from existing logs; the backup script is unmodified.
