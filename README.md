# Homelab Glance (iOS)

A read-only iOS client for self-hosted services. Surfaces status at a glance.

**v1 scope:** Proxmox backup run history.

## Build

No `.xcodeproj` is committed — `project.yml` is the source of truth and XcodeGen
generates the project in CI.

| Workflow | Trigger | Output |
|---|---|---|
| `build` | every push | light + dark simulator screenshots, as a run artifact |
| `testflight` | manual, or a `v*` tag | signed IPA uploaded to TestFlight |

Signing is cloud-managed via an App Store Connect API key. Required repo secrets:
`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `ASC_TEAM_ID`, and the `BUNDLE_ID` variable.

## Status

Scaffold with placeholder data. No Proxmox API wiring yet.
