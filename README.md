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

## New in 2.0.0
- Reproducible ISO build via pinned `flake.lock` (NixOS 24.05).
- Software rendering fallback for Chromium (SwiftShader) when no GPU is detected.
- Fast boot pipeline: quieter boot, 0-second GRUB timeout, reduced systemd overhead.
- Real persistence (overlayfs): optional persistent state via a `CHERNOS_PERSIST` partition.
- Background music system with UI controls and terminal commands (`music on/off`, `music vol`).
