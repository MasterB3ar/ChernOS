'use strict';

const { ipcMain, shell } = require('electron');

function registerIpc({ app, getMainWindow, showAbout, openAppWindow }) {
  ipcMain.handle('chernos:getAppInfo', async () => {
    return {
      name: app.getName(),
      version: app.getVersion(),
      platform: process.platform,
      arch: process.arch,
      packaged: app.isPackaged
    };
  });

  ipcMain.handle('chernos:openExternal', async (_evt, url) => {
    try {
      const u = String(url || '');
      if (!u) return { ok: false, error: 'empty-url' };
      await shell.openExternal(u);
      return { ok: true };
    } catch (e) {
      return { ok: false, error: String(e) };
    }
  });

  ipcMain.handle('chernos:toggleFullscreen', async () => {
    const w = getMainWindow();
    if (!w) return { ok: false, error: 'no-window' };
    w.setFullScreen(!w.isFullScreen());
    return { ok: true, fullScreen: w.isFullScreen() };
  });

  ipcMain.handle('chernos:setFullscreen', async (_evt, enabled) => {
    const w = getMainWindow();
    if (!w) return { ok: false, error: 'no-window' };
    w.setFullScreen(!!enabled);
    return { ok: true, fullScreen: w.isFullScreen() };
  });

  ipcMain.handle('chernos:toggleKiosk', async () => {
    const w = getMainWindow();
    if (!w) return { ok: false, error: 'no-window' };
    const next = !w.isKiosk();
    w.setKiosk(next);
    if (next) w.setFullScreen(true);
    return { ok: true, kiosk: w.isKiosk() };
  });

  ipcMain.handle('chernos:setKiosk', async (_evt, enabled) => {
    const w = getMainWindow();
    if (!w) return { ok: false, error: 'no-window' };
    const next = !!enabled;
    w.setKiosk(next);
    if (next) w.setFullScreen(true);
    return { ok: true, kiosk: w.isKiosk() };
  });

  ipcMain.handle('chernos:showAbout', async () => {
    try { showAbout(); } catch (_) {}
    return { ok: true };
  });

  ipcMain.handle('chernos:openAppWindow', async (_evt, appId, options) => {
    try {
      if (typeof openAppWindow !== 'function') return { ok: false, error: 'unsupported' };
      const id = String(appId || '').trim();
      if (!id) return { ok: false, error: 'empty-app' };
      const opts = (options && typeof options === 'object') ? options : {};
      const win = openAppWindow(id, opts);
      return { ok: !!win };
    } catch (e) {
      return { ok: false, error: String(e) };
    }
  });
}

module.exports = { registerIpc };
