'use strict';

const { contextBridge, ipcRenderer } = require('electron');

// Expose a small, safe bridge. The UI detects presence via `window.chernosDesktop`.
contextBridge.exposeInMainWorld('chernosDesktop', {
  isDesktop: true,

  // Open an app window. `opts` supports { newInstance?: boolean, instance?: number }.
  openAppWindow: (appId, opts = {}) => {
    try {
      ipcRenderer.send('chernos:openAppWindow', { appId, opts });
      return true;
    } catch (_) {
      return false;
    }
  },

  // List all windows known to the desktop suite.
  listWindows: () => ipcRenderer.invoke('chernos:listWindows'),

  // Focus a specific window by key.
  focusWindow: (key) => {
    try {
      ipcRenderer.send('chernos:focusWindow', key);
      return true;
    } catch (_) {
      return false;
    }
  },

  // Close a specific window by key.
  closeWindow: (key) => {
    try {
      ipcRenderer.send('chernos:closeWindow', key);
      return true;
    } catch (_) {
      return false;
    }
  },

  // Focus the main window.
  focusMainWindow: () => {
    try {
      ipcRenderer.send('chernos:focusMainWindow');
      return true;
    } catch (_) {
      return false;
    }
  },

  showAbout: () => {
    try {
      ipcRenderer.send('chernos:showAbout');
      return true;
    } catch (_) {
      return false;
    }
  },

  openExternal: (url) => {
    try {
      ipcRenderer.send('chernos:openExternal', url);
      return true;
    } catch (_) {
      return false;
    }
  },
});
