# ChernOS Electron wrapper

This folder packages the `ui/` app as an Electron desktop application.

## Run locally

From `electron/`:

```bash
npm install
npm run start
```

## Dev mode

```bash
npm run dev
```

## Build installers

```bash
npm run dist
```

Platform-specific examples:

```bash
npm run dist:win
npm run dist:linux
npm run dist:mac
```

## How it loads the UI

Electron loads `ui/index.html` from disk (`file://...`) and sets URL parameters:

- main window: `desktop=1`
- child app windows may set:
  - `app=<id>`
  - `standalone=1`
  - `noaudio=1` (to avoid multi-instance audio)

See `docs/URL_PARAMS.md` for parameters consumed by the UI.

## Window state

The wrapper uses a `windowState` helper to persist main window bounds (position/size).
