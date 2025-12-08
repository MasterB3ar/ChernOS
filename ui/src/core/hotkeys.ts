import { bus } from "./messageBus";

export function initHotkeys() {
  window.addEventListener("keydown", (e) => {
    if (e.key === "F9") {
      bus.emit({ type: "theme:set", payload: { theme: "night" } });
    }
  });

  if (window.chernosAPI?.onHotkey) {
    window.chernosAPI.onHotkey((payload) => {
      if (payload.action === "toggleNightShift") {
        bus.emit({ type: "theme:set", payload: { theme: "night" } });
      }
    });
  }
}
