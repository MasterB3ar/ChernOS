# Terminal commands

ChernOS includes a built-in terminal in the UI (`Terminal` app). Commands are **case-insensitive** and most actions update the simulation immediately.

> Note: **TAB autocompletion** uses an internal list (`const commands = [...]`) and is **not exhaustive**. Some commands exist but won’t autocomplete.

## Basics

- `help` — print command overview (including advanced commands like `fault`, `bus`, `plugin`, `profile`).
- `status` — current sim status line (temp, pressure, rad, safeguards, etc.).
- `reset` — reset simulation state to defaults.
- `save-log` — append a snapshot to the on-screen log.

## Core controls

- `power <n>` — set **Core drive** lever value (clamped to **40–125**).
- `coolant <n>` — set **Coolant bias** lever value (clamped to **80–145**).

## Diagnostics + overdrive

- `diag on` / `diag off` — show/hide diagnostics card.
- `overdrive on` / `overdrive off` — toggle overdrive mode.

## Theme engine

The “Redline Crisis Engine” can control the theme automatically, or you can override it:

- `theme auto` — return theme to AUTO (engine-driven).
- `theme green` / `theme amber` / `theme redline` — force theme override.
- `unlock 2049` — unlock the “2049” theme.
- `theme 2049` — switch to “2049” (calls `unlock 2049` if needed).

## Operator

- `operator set <name>` — set operator name (displayed in UI).
- `operator level <0-3>` — clamp/set operator level.

> The `help` string mentions `operator name <name>`, but the implemented command in this build is `operator set <name>`.

## Satellite link

- `satlink on` / `satlink off` — toggle sat link state.

## Visual effects

- `ghost on` / `ghost off`
- `black on` / `black off` — Black Chamber theme toggle

## Audio

- `audio on` / `audio off` — master audio enable.
- `music on` / `music off`
- `music vol <0-100>` — set music volume.
- `audio test <0-5>` — play a test sound by ID.

## Performance mode (VM stability)

This toggles “perf mode” (reduced expensive effects, helps VMs / weak GPUs):

- `perf` / `perf toggle`
- `perf on`
- `perf off`

## Macros

- `macro rec` — start recording terminal actions.
- `macro stop`
- `macro play`

## NetOps (network simulation)

- `net status`
- `net nodes`
- `net scan`
- `net trace <target>`
- `net throttle <node> <0-100|off>`
- `net packets`
- `net sniff on [filter]`
- `net sniff off`
- `net send <dst> [type] [units]`
- `net clear`
- `net ping <host>`
- `net lookup <name>`
- `net stress`
- `net reset`

## Faults + scenarios

### Fault bus

- `fault` / `faults` / `fault list` — list active faults.
- `fault inject <sensor|pump|pressure|ghostrad> [sev] [ttl]`
- `fault clear <type|all>`

### `simulate` shortcut

`simulate` is syntactic sugar over `fault inject`:

- `simulate` — show usage
- `simulate <sensor|pump|pressure|ghostrad> [sev] [ttl]`

Examples:
- `simulate pump 2 220`
- `simulate sensor 1 120`

## Aftermath / decontamination

- `decon start`
- `decon abort`
- `decon status`

## Hotkeys manager (rebindable)

See `docs/HOTKEYS.md` for details.

- `hotkeys help`
- `hotkeys list`
- `hotkeys actions`
- `hotkeys conflicts`
- `hotkeys export [overrides]`
- `hotkeys import <json>`
- `hotkeys set <action|alias> <combo> [--force]`
- `hotkeys add <action|alias> <combo> [--force]`
- `hotkeys remove <action|alias> <combo>`
- `hotkeys unbind <action|alias>`
- `hotkeys restore <action|alias>`
- `hotkeys reset`

## Message bus tools

See `docs/MESSAGE_BUS.md`.

- `bus help`
- `bus stats`
- `bus history [n] [containsTopic]`
- `bus pub <topic> <json|text|k=v...>`
- `bus retain <topic> <json|text|k=v...>`
- `bus clear`
- `bus watch <pattern>`
- `bus unwatch [id|all]`

## Plugin tools

See `docs/PLUGINS.md`.

- `plugin help`
- `plugin open`
- `plugin list`
- `plugin enable <id>`
- `plugin disable <id>`
- `plugin remove <id>`
- `plugin export`
- `plugin import <json>`

## Profiles / Persistence v3 (local)

See `docs/PERSISTENCE.md`.

- `profile help`
- `profile open` (alias: `persist open`)
- `profile list`
- `profile use <id>`
- `profile new <name>`
- `profile clone`
- `profile rename <name>`
- `profile delete`
- `profile states`
- `profile save [state name]`
- `profile restore [stateId|latest|auto]`
- `profile export [active|all]`
- `profile import <json>`

## Easter egg

- `chernobyl 1986` — triggers the built-in Chernobyl playback sequence.
