# Changelog

## v28 — Persistence v3 (profiles, states, logs)
- Added Persistence v3 app (Profiles / States / Logs) with UI panel + WM start menu + dock.
- Saves/restores full sim state + key local settings (audio/music/mixer, wallpaper, WM layout, hotkeys, workstation).
- Rolling AUTO state (autosave) + manual state snapshots; export/import JSON.
- Terminal integration: `profile ...` commands.

## 2.0.0 (2026-02-05) — Patch v21

### Added
- **Network Packet Bus (sim)**: inflight packet model with delivery/drop outcomes, plus moving packet dots on the NetOps topology map.
- **NetOps Packet Panel**: sniffer toggle, filter, quick-send controls, and a scrolling packet log.
- **Terminal network tooling**: `net packets`, `net sniff on/off [filter]`, `net send <dst> [type] [units]`, `net clear` (plus working `net nodes/scan/trace/throttle`).

### Changed
- Net rate display now reflects *delivered* packet rate when the packet bus is active.

## 2.0.0 (2026-01-18)

### Added
- **Reproducible ISO builds**: repository now includes a pinned `flake.lock` (NixOS 24.05), enabling deterministic ISO output when building from the same inputs.
- **Software rendering fallback**: Chromium automatically falls back to SwiftShader when no GPU render node is present; can be forced via `CHERNOS_FORCE_SOFTWARE=1`.
- **Fast boot pipeline**: 0-second GRUB timeout, quieter kernel/systemd output, and disabled non-essential one-shot services to reduce time-to-dashboard.
- **Real persistence (overlayfs)**: optional persistence layer activated when a writable partition labeled `CHERNOS_PERSIST` is present.
- **Background music system**: procedural ambient pad with UI controls and terminal commands.

### Changed
- UI version text updated to **v2.0.0**.
- Chromium launcher is now persistence-aware:
  - default (no persist device): stateless profile under `/tmp` and `--incognito`.
  - persistence enabled: profile stored under `/home/kiosk/.config/chromium` (backed by overlayfs).
- Electron dev wrapper now points to `/ui/index.html`.

### Usage Notes
- To enable persistence, provide an **ext4** partition labeled `CHERNOS_PERSIST` (for example, a second virtual disk in a VM) and boot the ISO. The system will mount it at `/persist` and overlay:
  - `/home/kiosk`
  - `/var/lib/chernos`
  - `/var/log/chernos`

### Terminal additions
- `music on` / `music off`
- `music vol <0-100>`
