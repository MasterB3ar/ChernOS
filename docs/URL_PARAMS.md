# URL parameters

ChernOS reads query parameters from `window.location.search` (works in Chromium `file://...` kiosk mode and in Electron).

## Mode flags

- `?kiosk=1`  
  Enables **kiosk mode** (live ISO / Chromium path). Also shows the installer hint unless hidden.

- `?desktop=1`  
  Enables **desktop mode**. Electron uses this for its main window.

- `?standalone=1`  
  Indicates a standalone instance (Electron can use this in app windows).

- `?app=<name>`  
  Requests initial app view (lowercased). Example: `?app=terminal`.

## Internal window manager

- `?wm=1`  
  Forces “Windows Mode” (internal WM overlay).

- **Default behavior:** if `kiosk=1` and neither `desktop=1` nor `standalone=1` are set, then Windows Mode is enabled automatically.

- `?wmchild=1`  
  Parsed but **not used** in this build (reserved for future multi-window behavior).

## Audio

- `?noaudio=1`  
  Forces `audioOn=false` and `musicOn=false` at startup (useful for Electron child windows).

## Persistence toggles

- `?persist=1`  
  Sets `state.persistEnabled=true` in the UI. In the live ISO, persistence is primarily achieved via the **overlayfs** system (see `docs/PERSISTENCE.md`), which makes Chromium/Electron storage survive reboots.

## Operator bootstrapping

- `?op=<name>`  
  Sets `state.operatorName` at startup (URL-decoded).

- `?lvl=<0-3>`  
  Sets `state.operatorLevel` at startup (clamped to 0–3).

## Installer hint (kiosk)

When `kiosk=1`, ChernOS shows an on-screen hint about launching the installer (Calamares hotkey is in Sway config).

- `?hideInstallHint=1` — disable the hint entirely.
- `?installHint=sticky` — keep the hint visible (no auto-fade).
- `?installHintMs=<ms>` — change auto-fade duration (default ~8000ms).
