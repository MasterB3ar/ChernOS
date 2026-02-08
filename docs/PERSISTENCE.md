# Persistence

ChernOS has two layers of “persistence”:

1. **System persistence (live ISO)** via overlayfs (optional).
2. **UI persistence v3** (profiles/states/logs) stored in browser/Electron storage.

## 1) Live ISO persistence (overlayfs)

The ISO supports an optional persistence partition:

- expected device path: `/dev/disk/by-label/CHERNOS_PERSIST`
- mountpoint: `/persist`
- overlay targets created:
  - `/home/kiosk` (Chromium profile + downloads, etc.)
  - `/var/lib` (system state used by services)

When detected, the boot process writes:

- `/run/chernos-persist.env` → `export CHERNOS_PERSIST=1`

and the kiosk launcher adds `&persist=1` to the UI URL.

### Creating a persistence partition

On a USB stick / disk, create an ext4 partition and label it `CHERNOS_PERSIST`.

Example (Linux, **destructive** — verify the device path first):

```bash
# example device: /dev/sdX2
sudo mkfs.ext4 -L CHERNOS_PERSIST /dev/sdX2
```

Then boot the ISO from that same device. If the label is present, ChernOS will mount it and enable overlays automatically.

### Switching shell mode persistently

With persistence enabled, you can drop a file:

- `/persist/chernos-shell`

containing either:
- `electron`
- `chromium`

On next boot, if `CHERNOS_PERSIST=1`, the kiosk script reads this file and prefers its value (unless `CHERNOS_SHELL` is explicitly set in the environment).

## 2) UI Persistence v3 (Profiles • States • Logs)

Inside the UI there is a “Persistence v3” panel with:

- **Profiles** — named collections
- **States** — snapshots saved under a profile
- **Logs** — UI event log

This data is stored in **localStorage** (best-effort).

### Terminal commands

Type `profile help` for details. Core operations:

- `profile list`
- `profile new <name>`
- `profile use <id>`
- `profile save [state name]`
- `profile restore [stateId|latest|auto]`
- `profile export [active|all]`
- `profile import <json>`
- `profile open` (alias: `persist open`)

### What “persist=1” does in the UI

If the UI is launched with `?persist=1`, the UI sets `state.persistEnabled=true` and may attempt to log to `/persist/...` paths.

**Important:** In Chromium `file://` kiosk mode, direct writes to `/persist` are not possible from web JS. The robust persistence mechanism on the ISO is the **overlayfs** that keeps the browser profile itself persistent.

## Electron persistence

In the Electron build, localStorage and app data live in the OS user’s app data directory, so the UI Persistence v3 features persist across restarts by default.
