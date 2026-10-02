# Homelab Glance (iOS)

A glanceable, read-only iOS client for self-hosted services. Not a management app —
it surfaces the one thing worth checking from a phone, natively.

**v1 scope:** Proxmox backup run history. One screen, nothing else.

## Why native / why this setup

Development happens on Linux, so there is no local Xcode. The loop is:

1. Edit SwiftUI sources here.
2. Push.
3. GitHub Actions (free macOS runners on a public repo) generates the Xcode project
   with XcodeGen, builds for the simulator, boots it, and uploads **light and dark
   screenshots** as a workflow artifact.

That makes the UI reviewable without a Mac. It is slow, not blind.

No `.xcodeproj` is committed — `project.yml` is the source of truth and the project is
generated in CI.

## Status

Scaffold with placeholder data. No Proxmox API wiring yet.
