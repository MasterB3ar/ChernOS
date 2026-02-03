'use strict';

const { contextBridge, ipcRenderer } = require('electron');

function safeStr(x) {
  try { return String(x); } catch (_) { return ''; }
}

contextBridge.exposeInMainWorld('chernosDesktop', {
  appInfo: () => ipcRenderer.invoke('chernos:getAppInfo'),
  showAbout: () => ipcRenderer.invoke('chernos:showAbout'),
  openExternal: (url) => ipcRenderer.invoke('chernos:openExternal', safeStr(url)),
  openAppWindow: (appId, options) => ipcRenderer.invoke('chernos:openAppWindow', safeStr(appId), options || {}),
  toggleFullscreen: () => ipcRenderer.invoke('chernos:toggleFullscreen'),
  setFullscreen: (enabled) => ipcRenderer.invoke('chernos:setFullscreen', !!enabled),
  toggleKiosk: () => ipcRenderer.invoke('chernos:toggleKiosk'),
  setKiosk: (enabled) => ipcRenderer.invoke('chernos:setKiosk', !!enabled)
});
