# Architecture

This is a high-level map of how the repo fits together (NixOS ISO + UI + Electron wrapper).

## Top-level layout

- `flake.nix` — builds the live ISO and packages
- `ui/` — the main ChernOS UI (single-page app in `index.html`)
- `electron/` — Electron wrapper for desktop packaging
- `boot-assets/` — GRUB + Plymouth theming assets
- `.github/workflows/build-iso.yml` — CI build job (artifact upload)

## Nix build outputs

The flake exposes:

- `.#iso` — NixOS ISO image build
- `.#packages.x86_64-linux.chernos-ui` — UI package (copies `ui/`)
- `.#packages.x86_64-linux.chernos-desktop` — Electron package

## Boot pipeline (ISO)

1. Bootloader (GRUB) loads the ISO (hybrid ISO with EFI support).
2. NixOS boots and starts `greetd`:
   - auto-login as `kiosk`
   - session: Sway
3. Sway reads its config and starts:
   - Calamares keybind (Ctrl+Alt+I / Super+I)
   - kiosk launcher (`/etc/chernos-kiosk.sh`)

## Kiosk launcher (`/etc/chernos-kiosk.sh`)

Responsibilities:
- set Wayland/Chromium/Electron flags
- determine “shell mode”:
  - `CHERNOS_SHELL` env (highest priority)
  - `/persist/chernos-shell` if persistence enabled
  - default Chromium
- build the final UI URL:
  - always sets `kiosk=1`
  - adds `persist=1` when persistence is active
  - appends `noaudio=1` if requested
- launch either:
  - `chromium --kiosk --app=<url> ...`
  - or `chernos-desktop` (Electron)

## Persistence overlay

When a partition labeled `CHERNOS_PERSIST` exists, the `chernos-persist` systemd service mounts it at `/persist` and overlays:

- `/home/kiosk`
- `/var/lib`

This is what makes Chromium profile + UI localStorage survive reboots.

(Details in `docs/PERSISTENCE.md`.)

## Internal UI structure (single-page)

The UI is a single HTML file with:
- “classic” reactor dashboard cards
- an internal “Windows Mode” (WM) with movable windows, taskbar, start menu, wallpapers
- terminal + command router
- NetOps simulation and packet bus
- persistence v3 profile/state manager
- message bus (pub/sub) + live viewer
- plugin system

Most advanced systems are written as IIFEs that hook into `runCommand()` and/or publish on `window.Bus`.
