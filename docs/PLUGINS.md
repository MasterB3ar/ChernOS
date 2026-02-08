# Plugins

ChernOS includes an internal plugin system (“local scripts”) that can:

- register terminal commands
- subscribe to Bus topics
- run intervals/timers safely (auto-cleaned)
- store plugin-local data in localStorage

## Storage format

Plugins are stored in localStorage:

- key: `chernos_plugins_v1`
- schema: `1`
- value:

```json
{
  "schema": 1,
  "plugins": [
    {
      "id": "example.hello",
      "name": "Example: Hello",
      "version": "1.0.0",
      "enabled": false,
      "createdAt": "...ISO...",
      "updatedAt": "...ISO...",
      "code": "return { ... }"
    }
  ]
}
```

If the store is missing/invalid, ChernOS seeds an **example plugin** (disabled).

## Plugin object contract

Your plugin code must **RETURN** a plugin object, e.g.:

```js
return {
  id: "ops.hello",
  name: "Hello",
  version: "1.0.0",
  init(api, ctx) {
    api.toast("Hello");
    api.command("hello", (args)=> api.term("hello " + (args[0]||"world")));
    api.subscribe("fault.**", (payload, meta)=> api.log("fault event: " + meta.topic));
  },
  tick(api, dt) { /* optional */ },
  dispose(api, ctx) { /* optional */ }
};
```

### Returning vs `api.register()`

The plugin evaluator supports both patterns:

- return the plugin object
- or call `api.register(pluginObject)` and return nothing

## Reserved command names

Plugins cannot register commands that collide with reserved prefixes/commands:

- - `help`
- - `status`
- - `scram`
- - `relief`
- - `stress`
- - `chaos`
- - `reset`
- - `power`
- - `coolant`
- - `safeguard`
- - `operator`
- - `engine`
- - `save-log`
- - `unlock`
- - `satlink`
- - `ghost`
- - `black`
- - `macro`
- - `net`
- - `fault`
- - `simulate`
- - `audio`
- - `bus`
- - `profile`
- - `perf`
- - `wm`
- - `wall`
- - `hotkeys`
- - `plugins`
- - `plugin`

(Also avoid names that shadow existing single-word commands.)

## Plugin API surface

Inside `init(api, ctx)`, the `api` object provides:

- `api.id` — plugin id
- `api.version` — ChernOS version string (currently `2.0.0`)
- `api.state` — live global state object
- `api.Bus` — bus reference
- `api.publish(topic, payload, opts)`
- `api.subscribe(pattern, handler, opts)` → unsubscribe fn (auto-cleaned on dispose)
- `api.once(pattern, handler)`
- `api.request(topic, payload, timeoutMs)` / `api.reply(replyTopic, payload)`
- `api.term(msg, level)` — print to terminal output panel
- `api.log(msg)` — append to main log
- `api.toast(msg)` — transient UI toast + plugin log
- `api.command(name, fn, help)` — register terminal command
- `api.interval(fn, ms)` — register an interval (auto-cleared on dispose)
- `api.open(view)` — open a view (classic routing)
- `api.wmOpen(view)` — open view in WM mode (if WM APIs available)
- `api.storage.get(key, fallback)` / `api.storage.set(key, value)` — plugin-scoped storage:
  - keys are namespaced as `chernos_plugin_<pluginId>_<key>`
- `api.onDispose(fn)` — register cleanup callbacks

## UI workflow

Open the **Plugins** panel:

- in UI routing (`app=plugins`), or
- via terminal: `plugin open`

From the panel you can:
- install/update a plugin (id/name/version/code)
- validate plugin code (syntax)
- run once (init + immediate dispose)
- enable/disable installed plugins
- export/import the full plugin store JSON

## Terminal commands

- `plugin help`
- `plugin open`
- `plugin list`
- `plugin enable <id>`
- `plugin disable <id>`
- `plugin remove <id>`
- `plugin export`
- `plugin import <json>`

## Failure behavior

Plugin errors are caught; the OS attempts to:
- log the error to the plugin log
- publish `plugin.error` on the bus
- keep the rest of ChernOS running
