# ChernOS — NixOS Kiosk ISO

Current version: **2.0.0**


This repo builds a **bootable ISO** that:
- boots into **Sway** on TTY1
- launches **Chromium** in kiosk mode
- shows a **fictional nuclear reactor control UI** (ChernOS Ultra)
- is **purely a simulation** — no real reactor control

## Build locally

Requirements: Nix

```bash
nix build .#iso
```

## Electron desktop suite

There is a standalone desktop wrapper under `electron/`.

```bash
cd electron
npm install
npm run start
```

Developer mode (enables devtools):

```bash
npm run dev
```

Build an installer/package (requires platform-specific tooling):

```bash
npm run dist
```

## New in 2.0.0
- Reproducible ISO build via pinned `flake.lock` (NixOS 24.05).
- Software rendering fallback for Chromium (SwiftShader) when no GPU is detected.
- Fast boot pipeline: quieter boot, 0-second GRUB timeout, reduced systemd overhead.
- Real persistence (overlayfs): optional persistent state via a `CHERNOS_PERSIST` partition.
- Background music system with UI controls and terminal commands (`music on/off`, `music vol`).

## Boot theming
- Plymouth splash: **ChernOS Nuclear Glow** (pulsing reactor ring).
- GRUB theme: **Blackchamber** background + logo.

## Installer
- Launch Calamares from the live session: **Ctrl+Alt+I** (or **Super+I**).

## Electron Desktop Suite (optional)
The ISO includes an Electron-based desktop shell.

- Launch from Sway: **Mod+E** (or **Ctrl+Alt+E**)
- Boot into Electron instead of Chromium:
  - set `CHERNOS_SHELL=electron` at boot, **or**
  - if persistence is enabled, create `/persist/chernos-shell` with the single word: `electron`

In Electron mode, **Workstation → Multitasking Supervisor** can list/focus/close desktop windows and open new app instances.


## Documentation

- `docs/INSTALL.md` — boot/install notes (ISO, Calamares, login)
- `docs/PERSISTENCE.md` — overlayfs persistence + UI persistence v3
- `docs/TROUBLESHOOTING.md` — VM + boot troubleshooting
- `docs/TERMINAL.md` — terminal command reference
- `docs/URL_PARAMS.md` — query parameters supported by the UI
- `docs/HOTKEYS.md` — hotkeys + rebinding reference
- `docs/ARCHITECTURE.md` — repo + runtime architecture
- `docs/PLUGINS.md` — internal plugin system
- `docs/MESSAGE_BUS.md` — internal pub/sub bus
- `docs/RELEASES.md` — CI + release guidance
- `electron/README.md` — Electron wrapper notes
