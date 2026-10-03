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

## Not done

- Backend is **not deployed** — see `homelab-api/README.md` for the remaining host steps
  (socket-proxy allowfrom, nginx vhost, `.env`, `DEPLOY_ENABLED`).
- No actions screen, capture/share extension, widget, or push.
- Backup data is parsed from existing logs; the backup script is unmodified.
