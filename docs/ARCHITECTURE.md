# ChernOS — Technical Architecture

Version: 2.0.0

---

## 1. Overview

ChernOS is a NixOS-based operating system environment designed as an immersive nuclear control-room simulation and workstation platform. It combines a declarative system base with a browser-driven UI, a simulation engine, and extensible subsystems.

The architecture emphasizes:

* Reproducibility
* Modularity
* Real-time simulation
* Kiosk and desktop dual-mode operation
* Extensibility through plugins

---

## 2. Layered System Model

ChernOS is structured as a layered platform:

```
Hardware
  ↓
Linux Kernel
  ↓
NixOS Base System
  ↓
Wayland + Sway
  ↓
Shell (Chromium / Electron)
  ↓
ChernOS UI & Simulation Core
```

Each layer exposes minimal interfaces to the layer above.

---

## 3. Base Platform

### 3.1 NixOS

* Declarative configuration
* Flake-based builds
* Reproducible ISO generation
* Immutable base system
* Controlled dependency graph

### 3.2 Kernel & Drivers

* Linux LTS kernel
* DRM/Mesa graphics stack
* libinput for devices
* NetworkManager for networking
* ALSA/PipeWire audio stack

---

## 4. Display & Compositor Layer

### 4.1 Wayland

* Primary display protocol
* Secure application isolation
* Modern input handling

### 4.2 Sway (Kiosk Mode)

* Fullscreen kiosk session
* Hotkey routing
* App lifecycle management
* Screen locking prevention
* Session watchdog

---

## 5. Shell Layer

### 5.1 Chromium Kiosk Shell (Default)

* Launches UI as a fullscreen web application
* Minimal overhead
* Strong VM compatibility
* Sandboxed execution

### 5.2 Electron Desktop Suite (Optional)

* Native desktop windows
* Multi-instance support
* IPC bridge to UI core
* OS-level focus handling

Shell selection may be controlled via environment variables or persistence configuration.

---

## 6. Application Core (UI Layer)

### 6.1 Monolithic UI Model

ChernOS uses a single-page application architecture:

* HTML/CSS/JavaScript
* Single DOM root
* Centralized state store
* Deterministic rendering

This simplifies synchronization between simulation and visualization.

### 6.2 State Object

All runtime data is stored in a global state tree:

```
state = {
  reactor,
  containment,
  network,
  audio,
  alarms,
  windows,
  profiles,
  plugins,
  system
}
```

---

## 7. Simulation Engine

### 7.1 Update Loop

The simulation runs in a fixed-interval loop:

```
setInterval(simTick, 40–60ms)
  → integrate physics
  → evaluate faults
  → propagate effects
  → update safeguards
  → emit events
  → request UI render
```

### 7.2 Fault System

Faults inject modifiers into the simulation:

* Pump failure
* Sensor drift
* Pressure leak
* Radiation anomaly

Modifiers cascade through dependent systems.

### 7.3 Safeguards

* Recharge timers
* Resource budgets
* Automatic and manual overrides
* Fail-safe logic

---

## 8. Reactor Subsystem

### Responsibilities

* Core temperature modeling
* Pressure regulation
* Control rod logic
* Power output simulation
* Alarm thresholds

### Interfaces

* Publishes: `reactor.*` events
* Subscribes: `fault.*`, `containment.*`

---

## 9. Containment Subsystem

### Responsibilities

* Primary/secondary containment integrity
* Pressure differential management
* Radiation containment
* Filtration and purge systems
* Cross-section visualization

### Interfaces

* Publishes: `containment.*`
* Subscribes: `reactor.*`, `fault.*`

---

## 10. Network Operations (NetOps)

### Node Model

Nodes are modeled as logical endpoints:

```
CORE-1
FLOW-A
SHIELD-X
DIAG-NET
OPS-TOWER
```

Each node contains routing, health, and bandwidth properties.

### Packet System

* Virtual packets
* Priority queues
* Throttling rules
* Inspection hooks

### Topology Engine

* Graph-based representation
* Live link metrics
* Failure injection

---

## 11. Audio & Alarm System

### Audio Pipeline

* Background music layer
* Reactive music layer
* Event-driven effects
* Alarm channels

### Alarm Engine

* Priority levels
* Escalation states
* Lockdown triggers
* Audio/visual coupling

---

## 12. Windowing & Multitasking

### 12.1 Internal Window Manager

* DOM-based windows
* Z-order management
* Focus tracking
* Resize/move handlers

### 12.2 Workstation Supervisor

* App registry
* Window registry
* Launch policies
* Cross-shell control

### 12.3 Electron Integration

* IPC channels
* Window mapping
* Focus proxies

---

## 13. Persistence Architecture

### 13.1 Overlayfs Persistence

* Optional persistent volume
* Preserves selected system paths
* Survives reboots

### 13.2 Persistence v3

Stores:

* UI preferences
* Simulation snapshots
* Profiles
* Logs

Backends:

* localStorage
* JSON bundles
* Export/import tools

---

## 14. Internal Message Bus

### Purpose

The bus decouples subsystems and enables extensibility.

### Event Format

```
{
  type: "reactor.overheat",
  source: "reactor",
  payload: {...},
  ts: 123456789
}
```

### Routing

* Publish/subscribe model
* Priority queues
* Plugin hooks

---

## 15. Plugin Framework

### Plugin Types

* UI extensions
* Terminal commands
* Event listeners

### Lifecycle

```
load → validate → register → activate → monitor → unload
```

### Security

* Namespace isolation
* Capability flags
* Sandboxed APIs

---

## 16. Installer Architecture

### Calamares Integration

* Live environment
* Partitioning module
* NixOS config generator
* nixos-install backend

### Post-Install Setup

* Bootloader configuration
* User creation
* Shell selection
* Persistence initialization

---

## 17. Security Model

* Wayland client isolation
* Limited sudo surface
* Read-only base system
* Plugin permission model
* Kiosk session confinement

---

## 18. Build Pipeline

### Flake Structure

```
inputs
 └─ nixpkgs
outputs
 ├─ packages
 ├─ nixosConfigurations
 └─ devShells
```

### ISO Generation

```
nixosSystem → isoImage → closure → ISO
```

---

## 19. Performance Considerations

* Batched rendering
* Debounced UI updates
* GPU fallback path
* Audio channel pooling
* Tunable simulation tick rate

---

## 20. Future Architecture Goals

* Distributed simulation backend
* Multiplayer state synchronization
* Modular micro-frontends
* WASM-based simulation cores
* Hardware control surface API
* Headless server mode

---

## Appendix A — Glossary

| Term   | Meaning                 |
| ------ | ----------------------- |
| WM     | Window Manager          |
| NetOps | Network Operations      |
| P3     | Persistence v3          |
| Bus    | Internal Message Bus    |
| Kiosk  | Locked fullscreen shell |

---

End of Document
