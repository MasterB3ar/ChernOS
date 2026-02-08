# Message Bus

ChernOS includes an internal **pub/sub message bus** exposed as `window.Bus`.

It is used for:
- UI telemetry
- fault and engine events
- plugin hooks
- WM events (open/close windows, wallpaper changes)

## Topic syntax

Topics are dot-separated strings, e.g. `fault.inject` or `wm.window.open`.

Subscriptions support wildcards:

- `a.b.*` matches one segment (e.g. `a.b.c`)
- `a.**` matches any remainder (including empty)

## API

`Bus` provides:

- `Bus.publish(topic, payload, { level, retain })`
- `Bus.subscribe(pattern, (payload, meta) => {}, { once, replayRetained })`
- `Bus.once(pattern, fn, opts)`
- `Bus.request(topic, payload, timeoutMs)` → Promise (request/reply helper)
- `Bus.reply(replyTopic, payload)`
- `Bus.stats()` — returns `{ seq, subs, history, retained, maxHistory }`
- `Bus.setMax(n)` — clamps max history to 50–5000
- `Bus.clearHistory()`

### Meta object

Subscribers receive `(payload, meta)` where `meta` includes:

- `meta.topic`
- `meta.ts` (epoch ms)
- `meta.seq` (monotonic sequence)
- `meta.retain` (boolean)
- `meta.level` (string)

## Terminal commands

The terminal wraps `runCommand()` and intercepts `bus ...` commands:

- `bus help`
- `bus stats`
- `bus history [n] [containsTopic]`
- `bus pub <topic> <json|text|k=v...>`
- `bus retain <topic> <json|text|k=v...>`
- `bus clear`
- `bus watch <pattern>`
- `bus unwatch [id|all]`

### Payload parsing (`bus pub/retain`)

`bus pub` tries, in order:
1. JSON (if payload starts/ends with `{}` or `[]`)
2. `key=value` pairs (space-separated) → object
3. raw string

Examples:
- `bus pub ui.note "hello"`
- `bus pub fault.inject {"type":"pump","sev":2,"ttl":220}`
- `bus pub ops.ping host=server-1 ms=12`

## Built-in topics in this build

- - `audio.state`
- - `fault.clear`
- - `fault.inject`
- - `music.state`
- - `plugin.boot`
- - `plugin.disabled`
- - `plugin.enabled`
- - `plugin.error`
- - `plugin.log`
- - `system.boot`
- - `ui.appview`
- - `wallpaper.change`
- - `wm.enable`
- - `wm.window.close`
- - `wm.window.open`

Plugins may publish any additional topics they want.
