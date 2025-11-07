# ChernOS — NixOS Kiosk ISO

This repo builds a **bootable ISO** that:
- boots into **Sway** on TTY1
- launches **Chromium** in kiosk mode
- shows a **fictional nuclear reactor control UI** (ChernOS Ultra)
- is **purely a simulation** — no real reactor control

## Build locally

Requirements: Nix

```bash
nix build .#iso
