# Troubleshooting

This doc focuses on issues commonly hit when running ChernOS in VMs or on live media.

## The UI is black / nothing launches

- Confirm Sway launched (you should not be at a text-only prompt).
- In the live ISO, the kiosk launcher is `/etc/chernos-kiosk.sh`.
- If you are dropped into a shell, try launching the UI manually:

```bash
/usr/bin/chernos-kiosk
```

(That wrapper comes from the `chernos-kiosk` package in the flake.)

## Mouse cursor is very laggy (VirtualBox)

Wayland + virtual GPUs can produce a laggy cursor. This build already sets:

- `WLR_NO_HARDWARE_CURSORS=1`

Additional VirtualBox suggestions:
- Try disabling **3D Acceleration**.
- Try different graphics controllers (VMSVGA vs VBoxSVGA).
- Give the VM more video memory.

## “Stage 1 must mount the root filesystem…” boot error

This often indicates:
- a corrupted ISO
- storage controller quirks
- UEFI/BIOS mismatch

Checklist:
- verify the ISO hash after download/copy
- re-create the VM and attach the ISO again
- try a different controller (SATA vs IDE) in VirtualBox
- try booting with UEFI disabled/enabled (match the VM firmware)

## No persistence across reboots

Persistence requires an ext4 partition labeled:

- `CHERNOS_PERSIST`

See `docs/PERSISTENCE.md`.

If you *do* have the partition:
- ensure it is on the same physical device and visible as `/dev/disk/by-label/CHERNOS_PERSIST`
- check that `/persist` is mounted after boot:

```bash
mount | grep /persist
```

## Audio is off

- Use `audio on` and `music on` in the terminal.
- Ensure you didn’t start with `?noaudio=1`.
- In Electron multi-window setups, child windows may intentionally pass `noaudio=1`.

## Performance mode / heavy effects

Use:

- `perf on` (or `perf off`) to toggle the “perf mode” CSS class used by the UI to reduce expensive effects.
