# ChernOS v2.0.0

ChernOS is a NixOS-based, nuclear-control-room themed kiosk/desktop OS experience built around a **reactor dashboard**, **network-operations simulation**, and a **multi-window “operator workstation” UI**.

This README documents the feature set of the **v2.0.0** line as shipped in the current build (Chromium kiosk shell + internal window manager + optional Electron desktop suite, Calamares installer, persistence).

---

## Contents

- [Quick start](#quick-start)
- [What you get](#what-you-get)
- [Shell modes](#shell-modes)
- [UI overview](#ui-overview)
- [Hotkeys](#hotkeys)
- [Terminal commands](#terminal-commands)
- [Persistence](#persistence)
- [Plugins](#plugins)
- [Internal message bus](#internal-message-bus)
- [Installer](#installer)
- [Build](#build)
- [Troubleshooting](#troubleshooting)

---

## Quick start

### Build ISO
```bash
nix build .#iso -L --print-build-logs
```

The ISO output path will be printed by Nix; copy it to a USB drive or boot it in a VM.

### Boot
- Default shell: **Chromium kiosk** (full-screen UI).
- Internal **multi-window environment** is available inside the UI (open apps into WM windows).

---

## What you get

### Core platform
- **NixOS reproducible ISO** (flake-based build)
- **Wayland + Sway kiosk**
- **Chromium frontend shell**
- **Autologin + boot-to-dashboard**
- **Software rendering fallback** (for VMs / limited GPUs)
- **Fast boot pipeline** (aggressive boot timeouts and reduced chatter)
- Optional boot cosmetics:
  - **Plymouth splash** (themed, if enabled in your build)
  - **Custom GRUB theme** (when GRUB is the active bootloader)

### UI / experience
- **Blackchamber theme** (full UI styling)
- **Glow-pulse animations**
- **Reactor status flicker boards**
- **Interactive levers + sound effects**
- **Alarm sequencing engine**
- **Background music system**
- **Reactive music system** (music reacts to alarms/faults/meltdown stages)
- **Soundscape settings** (volume, intensity, toggles)
- **Night Shift mode** (warm/dim low-glare mode)

### Multi-app + windowing
- **Multi-app environment**
- **Internal windowing system**
- **Taskbar**
- **Wallpapers**
- **Configurable hotkeys system**
- **Multitasking architecture** (Workstation supervisor + window lists and controls)

### Network simulation suite (NetOps)
- **Network nodes simulation**
  - CORE-1, FLOW-A, SHIELD-X, DIAG-NET, OPS-TOWER
- **Network packet system**
  - generate, route, throttle, inspect packets
- **Network terminal tools**
  - status/scan/trace/throttle + packet tools
- **Network topology UI** (visual map of nodes and links)

### Reactor / containment simulation
- **Animated temperature rings** (reactor HUD-style dials)
- **Manual coolant routing**
- **Safeguard recharge system**
- **Fault events system**
  - sensor, pump, pressure, ghost radiation
- **Secondary containment simulation**
  - integrity, pressure differential, internal radiation, filter load
  - auto/manual controls (seal, scrub, vent, purge)
- **Containment chamber visualizer**
  - cross-section display (stylized live view)
- **Meltdown aftermath mode**
  - locks down controls, escalates alarms/music, shows aftermath state

### Commands & extensibility
- `simulate <fault>` command
- `audio test <id>` command
- **Persistence v3** (profiles, states, logs)
- **Internal message bus**
- **Plugin system** (UI + command/event hooks)

### Installer + desktop suite
- **Calamares installer** (install live ISO to disk)
- **Electron desktop suite** (optional shell)
  - multi-window, multi-instance
  - Workstation can list/focus/close Electron windows

---

## Shell modes

ChernOS can run in different “shell” modes:

### 1) Chromium kiosk shell (default)
- Full-screen Chromium running the dashboard UI.
- Recommended for the intended “control-room kiosk” feel.
- Best performance in VMs.

### 2) Electron desktop suite (optional)
- Launches an Electron wrapper around the same UI.
- Supports **true OS-level multi-window** (separate native windows).
- Workstation can manage Electron windows (list/focus/close).

**Switching shells**
- Runtime: launch Electron with the hotkey (see [Hotkeys](#hotkeys)).
- Persistent shell selection (when persistence is enabled): set a shell selector file (see Troubleshooting/notes in your build).

---

## UI overview

The UI is organized into panels (dock/sections). Typical areas include:

- **Reactor**
  - status rings (temperature/pressure/radiation)
  - lever controls + safety toggles
  - alarm state and escalation
- **Containment**
  - primary/secondary containment state
  - coolant routing + safeguards
  - containment visualizer (cross-section)
- **NetOps**
  - topology UI + node status
  - packet bus + packet inspection
  - terminal tools (scan/trace/throttle)
- **Workstation**
  - internal WM window list (focus/minimize/close)
  - Electron desktop window list (focus/close)
  - launcher to open apps into View / WM / Electron

---

## Hotkeys

Hotkeys are configurable (Hotkeys panel). Defaults commonly include:

- **Install to disk (Calamares)**
  - `Ctrl + Alt + I` or `Super + I`
- **Electron desktop suite**
  - `Ctrl + Alt + E` or `Super + E`
- **Night Shift**
  - `Ctrl + Alt + Shift + N`
- Windowing shortcuts
  - common focus/minimize/close actions are available in the taskbar/WM chrome

If you change hotkeys, they are saved and can be captured by Persistence v3 profiles.

---

## Terminal commands

The terminal exposes a set of ops commands. Exact availability may vary by build, but the v2.0.0 line includes:

### System / UX
- `help`
- `night on | off | toggle`
- `audio test <id>`

### Fault + simulation
- `simulate <fault>`
  - examples: `simulate pump`, `simulate pressure`, `simulate sensor`, `simulate ghost`

### NetOps
- `net status`
- `net scan`
- `net trace <node>`
- `net throttle <link|node> <level>`
- Packet tools (depending on build):
  - `packets` / `packet bus`
  - `sniff`
  - `send <src> <dst> <type>`

### Persistence v3 (profiles)
- `profile list`
- `profile save <name>`
- `profile load <name>`
- `profile export <name>`
- `profile import <json>`

### Plugins
- `plugin list`
- `plugin enable <name>`
- `plugin disable <name>`
- `plugin install <json>` (or via UI)

---

## Persistence

ChernOS supports two persistence layers:

### 1) Live persistence (overlayfs)
- Preserves selected state across reboots when a persistence partition is present.
- Typical setup: a dedicated partition labeled for ChernOS persistence.

### 2) Persistence v3 (profiles, states, logs)
- Profiles capture UI + simulation state into named snapshots.
- Intended for:
  - “operator profiles”
  - demo/scene presets
  - rollback after experiments
- Stored as:
  - local storage (quick state)
  - logs (event history)
  - optional export/import (portable JSON)

---

## Plugins

The plugin system supports:
- **UI plugins** (inject UI blocks/panels or extend existing ones)
- **Command plugins** (register new terminal commands)
- **Event hooks** (react to alarm/fault/bus events)

Use the Plugins panel or the `plugin` terminal commands.

---

## Internal message bus

The internal message bus is used to decouple subsystems:
- faults → alarms/music
- net events → topology + terminal
- containment → alarms + visualizer

You can inspect bus traffic in the UI and/or terminal (watch/trace style commands if enabled in your build).

---

## Installer

ChernOS includes **Calamares** for “install to disk” workflows.

### Launch installer
- `Ctrl + Alt + I` or `Super + I`

### Safety note
Calamares can **wipe disks** depending on the partitioning option you choose. Use a VM or a test machine unless you are sure.

---

## Build

### Requirements
- Nix with flakes enabled
- A recent Nixpkgs pin (provided via flake inputs)

### Common commands
```bash
# Build ISO
nix build .#iso -L --print-build-logs

# Enter a dev shell (if defined)
nix develop
```

---

## Troubleshooting

### Diagnostics window is blank
If Diagnostics opens but shows nothing:
- ensure the Diagnostics panel (`#diag-card`) isn’t forced to `display:none` in the UI
- update to the latest `ui/index.html` in your v2.0.0 branch

### “Install to disk” hint covers text
The install hint should be dismissible/fading in recent builds. If it still blocks text:
- use `?hideInstallHint=1` (if supported in your build)
- or update to the latest UI where the hint auto-fades

### Electron is installed but doesn’t open
- Try launching Electron from Workstation (Desktop) or with the hotkey.
- In a VM, ensure you have enough VRAM and that the compositor is stable.

### Networking behavior
If NetworkManager is enabled, DHCP is handled by NetworkManager (do not set `networking.useDHCP = true;` alongside it).

---

## License / credits
This project is a custom OS experience; third-party components (NixOS, Sway, Chromium, Electron, Calamares) remain under their respective licenses.

---

**Have fun — and don’t let CORE-1 go critical.**
