# ChernOS — Plugin Developer Guide

Version: 2.0.0

---

## 1. Introduction

The ChernOS plugin system allows developers to extend the platform without modifying the core source code. Plugins can add new UI panels, terminal commands, automation logic, and event listeners.

This guide explains how to design, implement, package, and maintain ChernOS plugins.

---

## 2. Plugin Capabilities

Plugins may:

* Add new terminal commands
* Subscribe to internal bus events
* Inject UI components
* Automate simulation responses
* Provide diagnostics or analysis tools
* Extend persistence profiles

Plugins may NOT:

* Modify core system files
* Bypass security restrictions
* Access host OS resources directly
* Override core safety logic

---

## 3. Architecture Overview

Plugins interact with ChernOS through three main interfaces:

```
Plugin Loader
      ↓
Registration API
      ↓
Message Bus / State API / UI Hooks
```

Each plugin runs in a restricted JavaScript sandbox.

---

## 4. Plugin Directory Structure

Plugins are stored in:

```
/ui/plugins/
```

Recommended layout:

```
my-plugin/
 ├─ plugin.json
 ├─ main.js
 ├─ ui.js           (optional)
 ├─ commands.js     (optional)
 └─ assets/         (optional)
```

---

## 5. Plugin Manifest (plugin.json)

Every plugin must include a manifest file.

Example:

```json
{
  "id": "reactor-watchdog",
  "name": "Reactor Watchdog",
  "version": "1.0.0",
  "author": "ChernOS Labs",
  "description": "Automatic reactor protection system",
  "entry": "main.js",
  "permissions": [
    "bus",
    "state",
    "ui",
    "commands"
  ]
}
```

### Required Fields

| Field   | Description              |
| ------- | ------------------------ |
| id      | Unique plugin identifier |
| name    | Display name             |
| version | Semantic version         |
| entry   | Main script              |

---

## 6. Plugin Lifecycle

### 6.1 Load Sequence

```
discover → validate → sandbox → load → register → activate
```

1. Plugin Loader scans directories
2. Manifest is validated
3. Sandbox environment is created
4. Entry script is loaded
5. Plugin registers features
6. Plugin becomes active

### 6.2 Unload Sequence

```
deactivate → unregister → cleanup → unload
```

---

## 7. Main Entry File

Each plugin must export a `register()` function.

Example `main.js`:

```js
export function register(api) {
  api.log("Reactor Watchdog loaded");

  api.bus.subscribe("reactor.overheat", onOverheat);
  api.commands.register("watchdog", cmdWatchdog);
}

function onOverheat(event) {
  console.warn("Overheat detected", event);
}

function cmdWatchdog(args) {
  return "Watchdog active";
}
```

---

## 8. Plugin API Reference

When loaded, each plugin receives an `api` object.

### 8.1 Logging

```js
api.log(msg);
api.warn(msg);
api.error(msg);
```

### 8.2 Message Bus

```js
api.bus.subscribe(type, handler);
api.bus.publish(type, payload);
```

Example:

```js
api.bus.subscribe("fault.*", e => {
  api.log("Fault event", e);
});
```

---

### 8.3 State Access

```js
api.state.get(path);
api.state.set(path, value);
api.state.watch(path, callback);
```

Example:

```js
const temp = api.state.get("reactor.temp");
```

---

### 8.4 UI Hooks

```js
api.ui.addPanel(opts);
api.ui.removePanel(id);
api.ui.notify(msg, level);
```

Example:

```js
api.ui.addPanel({
  id: "watchdog-panel",
  title: "Watchdog",
  html: "<div>Status: OK</div>"
});
```

---

### 8.5 Command Registration

```js
api.commands.register(name, handler);
api.commands.unregister(name);
```

Example:

```js
api.commands.register("wd-status", () => "OK");
```

---

## 9. Persistence Integration

Plugins may store data in Persistence v3.

```js
api.persist.save("watchdog.enabled", true);
api.persist.load("watchdog.enabled");
```

Data is namespaced per plugin.

---

## 10. Security & Permissions

Permissions declared in `plugin.json` restrict API access.

| Permission | Enables                     |
| ---------- | --------------------------- |
| bus        | Subscribe/publish events    |
| state      | Read/write simulation state |
| ui         | Create UI components        |
| commands   | Register terminal commands  |
| persist    | Store profile data          |

Example:

```json
"permissions": ["bus","state","ui"]
```

APIs outside declared permissions are unavailable.

---

## 11. Packaging & Distribution

### 11.1 Manual Installation

Copy plugin folder into:

```
/ui/plugins/
```

Restart ChernOS or reload plugins.

### 11.2 Plugin Bundles

Plugins may be distributed as `.zip` archives:

```
reactor-watchdog.zip
 └─ reactor-watchdog/
```

Installed via UI or terminal.

---

## 12. Debugging Plugins

### 12.1 Console Logs

* Open developer console (if enabled)
* Use `api.log()`

### 12.2 Safe Mode

Boot with plugins disabled:

```
?safeMode=1
```

### 12.3 Plugin Inspector

Workstation → Plugins → Inspector

Shows:

* Loaded plugins
* Permissions
* Errors
* Event subscriptions

---

## 13. Versioning & Compatibility

* Use semantic versioning
* Declare supported ChernOS version in manifest
* Avoid internal APIs

Recommended:

```json
"compat": ">=2.0.0 <3.0.0"
```

---

## 14. Best Practices

* Keep plugins small and focused
* Avoid heavy polling
* Prefer bus events over timers
* Validate all inputs
* Clean up on unload
* Respect safety systems

---

## 15. Example Plugin: Auto Scrubber

### Purpose

Automatically activates containment scrubbers on radiation spikes.

`plugin.json`:

```json
{
  "id": "auto-scrubber",
  "name": "Auto Scrubber",
  "version": "1.0.0",
  "entry": "main.js",
  "permissions": ["bus","state"]
}
```

`main.js`:

```js
export function register(api) {
  api.bus.subscribe("containment.radiation.high", e => {
    api.state.set("containment.scrubber", true);
    api.log("Scrubber engaged");
  });
}
```

---

## 16. Future Plugin System Plans

* Signed plugins
* Dependency resolution
* Marketplace integration
* Hot-reload support
* WASM plugin sandbox

---

## Appendix A — API Summary

### Core

* api.log / warn / error
* api.bus.*
* api.state.*
* api.ui.*
* api.commands.*
* api.persist.*

---

End of Document
