import { contextBridge, ipcRenderer } from "electron";

contextBridge.exposeInMainWorld("chernosAPI", {
  onHotkey(callback: (payload: any) => void) {
    ipcRenderer.on("chernos/hotkey", (_event, payload) => callback(payload));
  },
  // For future: persist, logs, etc.
});
