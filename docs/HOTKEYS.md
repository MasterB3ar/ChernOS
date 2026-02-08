# Hotkeys

ChernOS has a **rebindable hotkey system** used by the internal Window Manager (WM) and app routing.

## Storage

Hotkey overrides are stored in localStorage:

- key: `chernos_hotkeys_v1`
- value: JSON object `{ actionId: [combo, ...] }`

If a key is missing, defaults are used.

## Action list and defaults

| Group | Action ID | What it does | Default bindings |
| --- | --- | --- | --- |
| Core | `core.hotkeys` | Toggle hotkeys overlay | `f1`, `ctrl+alt+keyh` |
| Core | `core.escape` | Close menus / hotkeys overlay | `escape` |
| Core | `wm.toggle` | Toggle Windows Mode | `ctrl+alt+keyw` |
| Apps | `app.reactor` | Open Reactor | `ctrl+alt+keyr` |
| Apps | `app.terminal` | Open Terminal | `ctrl+alt+keyt` |
| Apps | `app.netops` | Open NetOps | `ctrl+alt+keyn` |
| Apps | `app.containment` | Open Containment | `ctrl+alt+keyc` |
| Apps | `app.comms` | Open Comms | `ctrl+alt+keyo` |
| Apps | `app.workstation` | Open Workstation | `ctrl+alt+keyx` |
| Apps | `app.logs` | Open Logs | `ctrl+alt+keyg` |
| Apps | `app.diagnostics` | Open Diagnostics | `ctrl+alt+keyd` |
| Apps | `app.soundscape` | Open Soundscape | `ctrl+alt+keyp` |
| Windows | `wm.next` | Focus next window | `ctrl+alt+tab` |
| Windows | `wm.prev` | Focus previous window | `ctrl+alt+shift+tab` |
| Windows | `wm.max` | Maximize / restore focused window | `ctrl+alt+keyf` |
| Windows | `wm.min` | Minimize focused window | `ctrl+alt+minus` |
| Windows | `wm.close` | Close focused window | `ctrl+alt+keyq` |
| Windows | `wm.start` | Toggle Start menu | `ctrl+alt+space` |
| Windows | `wm.wall` | Toggle Wallpapers panel | `ctrl+alt+keyu` |
| Windows | `wm.wall.1` | Wallpaper: Reactor Glow | `ctrl+alt+shift+digit1` |
| Windows | `wm.wall.2` | Wallpaper: Containment Fog | `ctrl+alt+shift+digit2` |
| Windows | `wm.wall.3` | Wallpaper: Black Chamber | `ctrl+alt+shift+digit3` |
| Windows | `wm.wall.4` | Wallpaper: Grid Lines | `ctrl+alt+shift+digit4` |
| Windows | `wm.wall.5` | Wallpaper: Blueprint | `ctrl+alt+shift+digit5` |
| Windows | `wm.wall.0` | Wallpaper: Reset | `ctrl+alt+shift+digit0` |
| Audio+Theme | `sys.audio` | Toggle Audio (master) | `ctrl+alt+keya` |
| Audio+Theme | `sys.music` | Toggle Music | `ctrl+alt+keym` |
| Audio+Theme | `sys.black` | Toggle Black Chamber theme | `ctrl+alt+keyb` |
| Display | `sys.night` | Toggle Night Shift | `ctrl+alt+shift+keyn` |
| Audio+Theme | `sys.diag` | Toggle Diagnostics card (classic UI) | `ctrl+alt+shift+keyd` |
| Audio+Theme | `sys.sound` | Toggle Soundscape mixer (classic UI) | `ctrl+alt+shift+keyp` |


## Aliases

The terminal hotkeys commands accept either the full action ID (e.g. `app.terminal`) or an alias (e.g. `terminal`).

| Alias | Action ID |
| --- | --- |
| `audio` | `sys.audio` |
| `black` | `sys.black` |
| `close` | `wm.close` |
| `comms` | `app.comms` |
| `containment` | `app.containment` |
| `diagnostics` | `app.diagnostics` |
| `escape` | `core.escape` |
| `hotkeys` | `core.hotkeys` |
| `logs` | `app.logs` |
| `max` | `wm.max` |
| `min` | `wm.min` |
| `music` | `sys.music` |
| `netops` | `app.netops` |
| `next` | `wm.next` |
| `prev` | `wm.prev` |
| `reactor` | `app.reactor` |
| `soundscape` | `app.soundscape` |
| `start` | `wm.start` |
| `terminal` | `app.terminal` |
| `wall` | `wm.wall` |
| `windows` | `wm.toggle` |
| `wm` | `wm.toggle` |
| `workstation` | `app.workstation` |


## Combo format

Combos are normalized to a lower-case string like:

- `ctrl+alt+keyt`
- `f1`
- `escape`
- `ctrl+alt+shift+digit1`

The terminal accepts friendlier input like:

- `Ctrl+Alt+T`
- `Ctrl Alt Shift 1`
- `F1`
- `Esc`

## Terminal commands

Type `hotkeys help` for the built-in help. The supported subcommands are:

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

### Conflicts and `--force`

By default, a combo can only map to one action. If you set/add a combo already used by another action:

- without `--force`, the command reports a conflict
- with `--force`, the combo is “stolen” from the other action and assigned to your target action

## UI hotkeys overlay

The hotkeys overlay is toggled by the `core.hotkeys` action (default: **F1**). In WM mode, it appears as a dedicated overlay panel.
