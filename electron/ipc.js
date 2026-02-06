'use strict';

const { ipcMain, shell } = require('electron');

function registerIpc({
  openAppWindow,
  focusMainWindow,
  showAbout,
  listWindows,
  focusWindow,
  closeWindow,
  openExternal,
}) {
  // Backward compatible: payload can be a string appId or { appId, opts }
  ipcMain.on('chernos:openAppWindow', (_event, payload) => {
    try {
      let appId = '';
      let opts = {};

      if (typeof payload === 'string') {
        appId = payload;
      } else if (payload && typeof payload === 'object') {
        appId = String(payload.appId || payload.id || '');
        opts = payload.opts || payload.options || {};
      }

      appId = String(appId || '').trim();
      if (!appId) return;
      openAppWindow(appId, opts);
    } catch (_) {}
  });

  ipcMain.handle('chernos:listWindows', async () => {
    try {
      return listWindows ? listWindows() : [];
    } catch (_) {
      return [];
    }
  });

  ipcMain.on('chernos:focusWindow', (_event, key) => {
    try {
      if (!focusWindow) return;
      focusWindow(String(key || ''));
    } catch (_) {}
  });

  ipcMain.on('chernos:closeWindow', (_event, key) => {
    try {
      if (!closeWindow) return;
      closeWindow(String(key || ''));
    } catch (_) {}
  });

  ipcMain.on('chernos:focusMainWindow', () => {
    try { focusMainWindow(); } catch (_) {}
  });

  ipcMain.on('chernos:showAbout', () => {
    try { showAbout(); } catch (_) {}
  });

  ipcMain.on('chernos:openExternal', (_event, url) => {
    try {
      const u = openExternal ? openExternal(url) : url;
      if (u) shell.openExternal(String(u));
    } catch (_) {}
  });
}

module.exports = {
  registerIpc,
};
