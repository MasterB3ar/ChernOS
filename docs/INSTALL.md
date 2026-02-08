# Install / Boot

This repo builds a **NixOS live ISO** that boots into a Sway + Chromium kiosk (or Electron) running the ChernOS UI.

## Default login

The ISO defines a single user:

- user: `kiosk`
- password: `kiosk`

## Boot behavior

At boot, the system starts Sway and runs the kiosk launcher script:

- `/etc/chernos-kiosk.sh`

That script decides whether to run **Chromium** or **Electron** and then launches the UI.

### Choosing Chromium vs Electron

The kiosk script uses these inputs (in this order):

1. `CHERNOS_SHELL` environment variable (`electron` / `chromium`)
2. if persistence is enabled (`CHERNOS_PERSIST=1`) and `/persist/chernos-shell` exists:
   - reads the file and uses it as shell mode
3. default: Chromium

## Installer (Calamares)

The ISO includes Calamares and binds it in Sway:

- `Ctrl+Alt+I` **or** `Super+I`

If you boot into kiosk mode, the UI also shows an on-screen installer hint (see `docs/URL_PARAMS.md`).

## Building the ISO locally

From the repo root:

```bash
nix build .#iso -L --print-build-logs
```

Output is linked at:

- `result/iso/chernos-os.iso`

## Running in a VM

For VirtualBox / QEMU tips, see `docs/TROUBLESHOOTING.md`.
