## v44 — UI fixes (Diagnostics + install hint)
- Fixed **Diagnostics** showing blank in internal WM: the legacy diagnostics panel is only hidden in WM when it is *not* hosted inside a window.
- Made the **Install to disk** hint auto-fade so it doesn't cover UI text.
  - Disable: `?hideInstallHint=1`
  - Keep visible: `?installHint=sticky`
  - Change duration: `?installHintMs=12000`
- Fixed `chernos-desktop` ISO build: removed `set -u` from the desktop derivation/script to prevent `patchShebangs` from failing during `fixupPhase`.

## v42 — Fix ISO build (escaped comment)
- Removed an unescaped `${...}` sequence inside the generated `/etc/chernos-kiosk.sh` comments that still triggered Nix string interpolation.

## v41 — Fix ISO build (shell selector)
- Fixed a Nix parsing error in `/etc/chernos-kiosk.sh` generation by escaping shell `${...}` expansions inside the Nix indented string.

## v40 — Multitasking Supervisor + Electron Desktop Suite
- Added **Workstation → Multitasking Supervisor**: launch apps as View / Internal WM windows / Electron desktop windows; list + focus + close running windows.
- Upgraded **Electron Desktop Suite** with multi-window + multi-instance app windows, plus a safe IPC bridge (`listWindows/focus/close`).
- Added `chernos-desktop` package to the ISO and Sway hotkeys: **Mod+E** / **Ctrl+Alt+E**.
- Optional: boot directly into Electron by setting `CHERNOS_SHELL=electron` or writing `electron` to `/persist/chernos-shell`.

## v39 — Metric rings + Secondary containment
- Added **animated metric rings** around the core (Temp / Pressure / Radiation), with severity color shifts.
- Added **Secondary Containment (Barrier-2) simulation**: integrity + ΔP + internal radiation + filter load.
- New containment controls: Seal Doors, Scrubbers, Purge burst, Vent slider, Auto/Manual.
- Terminal integration: `containment status` now includes secondary containment; added `sc ...` commands.

## v38 — Plymouth + GRUB theme
- Added nuclear-glow Plymouth splash (pulsing reactor ring + logo).
- Added custom GRUB theme (Blackchamber) with background + logo + highlight.
- Boot assets stored under `boot-assets/` so they ship with the repo/ISO.

## v34 — Performance fix (VirtualBox-friendly)
- Optimized NetOps topology rendering (no full SVG rebuild on packet tick)
- Throttled Packet Bus panel updates
- Message Bus panel no longer updates when not visible; buffered DOM appends
- NetOps UI updates only when visible

# Changelog


## v33 — Plugin System (local scripts)
- Added internal plugin framework (install/enable/disable/export/import).
- Plugins can subscribe/publish on the internal message bus and register terminal commands.
- Added Plugins app panel + dock button + WM start menu entry.

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
