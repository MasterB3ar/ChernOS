/* ChernOS Desktop Suite (Electron) */
'use strict';

const { app, BrowserWindow, shell, Menu, dialog } = require('electron');
const path = require('path');
const fs = require('fs');

// Kiosk-friendly audio: still subject to OS mixer + device availability.
try { app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required'); } catch (_) {}

const isDev = !app.isPackaged || process.env.ELECTRON_DEV === '1';

const { loadWindowState, trackWindowState } = require('./windowState');
const { buildAppMenu } = require('./menu');
const { createTray } = require('./tray');
const { registerIpc } = require('./ipc');

let mainWindow = null;
let tray = null;

// App windows (separate "apps" inside ChernOS Desktop Suite)
const appWindows = new Map();

const APP_PRESETS = {
  reactor:      { title: 'Reactor Console',   w: 1500, h: 920 },
  containment:  { title: 'Containment',      w: 1200, h: 860 },
  netops:       { title: 'NetOps',           w: 1280, h: 880 },
  comms:        { title: 'Comms & Link',     w: 1200, h: 840 },
  terminal:     { title: 'Terminal',         w: 1280, h: 820 },
  logs:         { title: 'Event Log',        w: 1200, h: 820 },
  workstation:  { title: 'Workstation',      w: 1200, h: 860 },
  diagnostics:  { title: 'Diagnostics',      w: 1200, h: 860 },
  soundscape:   { title: 'Soundscape',       w: 1100, h: 820 }
};

function normalizeAppId(x) {
  const id = String(x || '').trim().toLowerCase();
  // keep it tight: letters, numbers, dashes/underscores only
  if (!/^[a-z0-9_-]{1,32}$/.test(id)) return '';
  return id;
}

function getUiIndexPath() {
  // In packaged apps, UI is shipped as an extraResource at: <resources>/ui/index.html
  const packagedPath = path.join(process.resourcesPath, 'ui', 'index.html');
  const devPath = path.join(__dirname, '..', 'ui', 'index.html');
  if (app.isPackaged) {
    if (safeExists(packagedPath)) return packagedPath;
    // Fallback (e.g., custom packaging): try relative dev layout.
    if (safeExists(devPath)) return devPath;
  }
  return devPath;
}

function getIconPath(kind = 'png') {
  return path.join(__dirname, 'assets', kind === 'ico' ? 'icon.ico' : 'icon.png');
}

function safeExists(p) {
  try { return fs.existsSync(p); } catch (_) { return false; }
}

function createMainWindow() {
  const state = loadWindowState({ defaultWidth: 1440, defaultHeight: 900 });
  const iconPng = getIconPath('png');

  const win = new BrowserWindow({
    x: state.x,
    y: state.y,
    width: state.width,
    height: state.height,
    minWidth: 1100,
    minHeight: 720,
    backgroundColor: '#020806',
    show: false,
    autoHideMenuBar: false,
    icon: safeExists(iconPng) ? iconPng : undefined,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
      devTools: isDev
    }
  });

  trackWindowState(win);

  // Keep navigation contained: open external links in the OS browser.
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (!url.startsWith('file:')) shell.openExternal(url);
    return { action: 'deny' };
  });
  win.webContents.on('will-navigate', (e, url) => {
    if (url.startsWith('file:')) return;
    e.preventDefault();
    shell.openExternal(url);
  });

  const uiIndex = getUiIndexPath();
  win.loadFile(uiIndex, { query: { desktop: '1' } }).catch((err) => {
    dialog.showErrorBox('ChernOS failed to load UI', String(err));
  });

  win.once('ready-to-show', () => {
    if (state.maximized) win.maximize();
    win.show();
  });

  // Optional env toggles.
  if (process.env.CHERNOS_FULLSCREEN === '1') win.setFullScreen(true);
  if (process.env.CHERNOS_KIOSK === '1') win.setKiosk(true);

  win.on('closed', () => {
    mainWindow = null;
  });

  return win;
}

function createAppWindow(appId, opts = {}) {
  const id = normalizeAppId(appId);
  if (!id) return null;

  const iconPng = getIconPath('png');
  const preset = APP_PRESETS[id] || { title: `App: ${id}`, w: 1200, h: 840 };

  const win = new BrowserWindow({
    width: Math.max(900, preset.w),
    height: Math.max(650, preset.h),
    minWidth: 900,
    minHeight: 650,
    backgroundColor: '#020806',
    show: false,
    title: `ChernOS — ${preset.title}`,
    icon: safeExists(iconPng) ? iconPng : undefined,
    autoHideMenuBar: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
      devTools: isDev
    }
  });

  // Contain navigation.
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (!url.startsWith('file:')) shell.openExternal(url);
    return { action: 'deny' };
  });
  win.webContents.on('will-navigate', (e, url) => {
    if (url.startsWith('file:')) return;
    e.preventDefault();
    shell.openExternal(url);
  });

  const uiIndex = getUiIndexPath();
  const query = {
    desktop: '1',
    standalone: '1',
    app: id
  };

  // Optional per-window toggles.
  if (opts && typeof opts === 'object') {
    if (opts.kiosk === true) query.kiosk = '1';
    if (opts.op) query.op = String(opts.op);
    if (opts.lvl != null) query.lvl = String(opts.lvl);
  }

  win.loadFile(uiIndex, { query }).catch((err) => {
    dialog.showErrorBox('ChernOS failed to load app window', String(err));
  });

  win.once('ready-to-show', () => {
    win.show();
    // If a caller asked to start fullscreen/kiosk for this app.
    if (opts && opts.fullscreen === true) win.setFullScreen(true);
    if (opts && opts.kiosk === true) win.setKiosk(true);
  });

  win.on('closed', () => {
    appWindows.delete(id);
  });

  return win;
}

function openAppWindow(appId, opts = {}) {
  const id = normalizeAppId(appId);
  if (!id) return null;

  const existing = appWindows.get(id);
  if (existing && !existing.isDestroyed()) {
    if (existing.isMinimized()) existing.restore();
    existing.show();
    existing.focus();
    return existing;
  }

  const win = createAppWindow(id, opts);
  if (win) appWindows.set(id, win);
  return win;
}

function showAbout() {
  const version = app.getVersion();
  dialog.showMessageBox({
    type: 'info',
    title: 'About ChernOS',
    message: 'ChernOS Desktop Suite',
    detail: `Version ${version}\n\nNuclear-reactor styled kiosk/desktop UI.`
  });
}

function wireAppLifecycle() {
  // Single-instance behavior.
  const gotLock = app.requestSingleInstanceLock();
  if (!gotLock) {
    app.quit();
    return;
  }
  app.on('second-instance', () => {
    if (!mainWindow) return;
    if (mainWindow.isMinimized()) mainWindow.restore();
    mainWindow.show();
    mainWindow.focus();
  });

  app.on('window-all-closed', () => {
    // Keep running on macOS like a normal app.
    if (process.platform !== 'darwin') app.quit();
  });

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      mainWindow = createMainWindow();
      if (tray) tray.attachWindow(mainWindow);
    }
  });
}

async function boot() {
  wireAppLifecycle();

  await app.whenReady();
  app.setName('ChernOS');

  mainWindow = createMainWindow();

  // IPC + app menu + tray.
  registerIpc({ app, getMainWindow: () => mainWindow, showAbout, openAppWindow });
  Menu.setApplicationMenu(buildAppMenu({ app, getMainWindow: () => mainWindow, showAbout, isDev }));
  tray = createTray({ app, getMainWindow: () => mainWindow, iconPath: getIconPath('png') });
}

boot().catch((err) => {
  try { dialog.showErrorBox('ChernOS failed to start', String(err)); } catch (_) {}
  process.exitCode = 1;
});
