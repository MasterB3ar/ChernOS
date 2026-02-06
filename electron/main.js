'use strict';

const path = require('path');
const { app, BrowserWindow, dialog, shell } = require('electron');
const windowStateKeeper = require('./windowState');
const { registerIpc } = require('./ipc');
const { buildMenu } = require('./menu');

let mainWindow = null;

// App windows are keyed by "<appId>:<instance>".
const appWindows = new Map();
const appWindowMeta = new Map();

function sanitizeAppId(appId) {
  return String(appId || '').trim().toLowerCase().replace(/[^a-z0-9_-]/g, '');
}

function makeKey(appId, instance) {
  return `${appId}:${instance}`;
}

function nextInstanceFor(appId) {
  let max = 0;
  for (const key of appWindows.keys()) {
    if (key.startsWith(appId + ':')) {
      const n = parseInt(key.split(':')[1], 10);
      if (Number.isFinite(n) && n > max) max = n;
    }
  }
  return max + 1;
}

function resolveUiUrl({ desktop = true, standalone = false, appId = null, instance = null, noAudio = false } = {}) {
  const uiDir = path.join(__dirname, '..', 'ui');
  const file = path.join(uiDir, 'index.html');
  const u = new URL('file://' + file);
  if (desktop) u.searchParams.set('desktop', '1');
  if (standalone) u.searchParams.set('standalone', '1');
  if (appId) u.searchParams.set('app', String(appId));
  if (instance !== null && instance !== undefined) u.searchParams.set('inst', String(instance));
  if (noAudio) u.searchParams.set('noaudio', '1');
  return u.toString();
}

function focusMainWindow() {
  if (!mainWindow || mainWindow.isDestroyed()) return;
  if (mainWindow.isMinimized()) mainWindow.restore();
  mainWindow.show();
  mainWindow.focus();
}

function createMainWindow() {
  const mainState = windowStateKeeper('main', { width: 1360, height: 820 });
  const win = new BrowserWindow({
    x: mainState.x,
    y: mainState.y,
    width: mainState.width,
    height: mainState.height,
    backgroundColor: '#000000',
    show: false,
    title: 'ChernOS — Desktop',
    webPreferences: {
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
    },
  });

  mainState.manage(win);

  win.once('ready-to-show', () => {
    win.show();
  });

  win.loadURL(resolveUiUrl({ desktop: true, standalone: false }));
  return win;
}

function createAppWindow(appId, instance) {
  const titleBase = (appId || '').toUpperCase();
  const title = `ChernOS — ${titleBase}${instance > 1 ? ` #${instance}` : ''}`;

  const win = new BrowserWindow({
    width: 980,
    height: 640,
    minWidth: 860,
    minHeight: 520,
    backgroundColor: '#000000',
    show: false,
    title,
    webPreferences: {
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
    },
  });

  win.once('ready-to-show', () => win.show());

  // Standalone app windows run with audio locked off to prevent doubled music.
  win.loadURL(resolveUiUrl({ desktop: true, standalone: true, appId, instance, noAudio: true }));
  return win;
}

function focusWindow(key) {
  if (key === 'main') {
    focusMainWindow();
    return true;
  }
  const win = appWindows.get(String(key || ''));
  if (!win || win.isDestroyed()) return false;
  if (win.isMinimized()) win.restore();
  win.show();
  win.focus();
  return true;
}

function closeWindow(key) {
  if (key === 'main') return false;
  const win = appWindows.get(String(key || ''));
  if (!win || win.isDestroyed()) return false;
  win.close();
  return true;
}

function listWindows() {
  const out = [];
  if (mainWindow && !mainWindow.isDestroyed()) {
    out.push({
      key: 'main',
      isMain: true,
      appId: '',
      instance: 0,
      title: mainWindow.getTitle() || 'ChernOS — Desktop',
    });
  }
  for (const [key, win] of appWindows.entries()) {
    if (!win || win.isDestroyed()) continue;
    const meta = appWindowMeta.get(key) || {};
    out.push({
      key,
      isMain: false,
      appId: meta.appId || '',
      instance: meta.instance ?? null,
      title: meta.title || win.getTitle() || 'ChernOS',
    });
  }
  return out;
}

function openAppWindow(appId, opts = {}) {
  const id = sanitizeAppId(appId);
  if (!id) return null;

  const o = (opts && typeof opts === 'object') ? opts : {};

  let instance = 1;
  if (typeof o.instance === 'number' && Number.isFinite(o.instance) && o.instance > 0) {
    instance = Math.max(1, Math.floor(o.instance));
  } else if (o.newInstance) {
    instance = nextInstanceFor(id);
  }

  const key = makeKey(id, instance);

  if (appWindows.has(key)) {
    focusWindow(key);
    return key;
  }

  const win = createAppWindow(id, instance);
  appWindows.set(key, win);
  appWindowMeta.set(key, { appId: id, instance, title: win.getTitle() });

  win.on('closed', () => {
    appWindows.delete(key);
    appWindowMeta.delete(key);
  });

  return key;
}

function showAbout() {
  const detail = [
    'ChernOS Desktop Suite',
    'Multi-window dashboard + standalone app windows.',
    '',
    'Tips:',
    '• Shift+click dock icons for new app instances',
    '• Workstation → Multitasking Supervisor lists/focuses windows',
  ].join('\n');

  dialog.showMessageBox({
    type: 'info',
    title: 'About ChernOS',
    message: 'ChernOS — Desktop Suite',
    detail,
  });
}

function openExternal(url) {
  return url;
}

app.whenReady().then(() => {
  mainWindow = createMainWindow();
  buildMenu({ openAppWindow, showAbout, focusMainWindow });

  registerIpc({
    openAppWindow,
    focusMainWindow,
    showAbout,
    listWindows,
    focusWindow,
    closeWindow,
    openExternal,
  });

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      mainWindow = createMainWindow();
    }
    focusMainWindow();
  });
});

app.on('window-all-closed', () => {
  // Keep on macOS by convention; quit elsewhere.
  if (process.platform !== 'darwin') app.quit();
});

app.on('web-contents-created', (_event, contents) => {
  // Harden navigation.
  contents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url).catch(() => {});
    return { action: 'deny' };
  });

  contents.on('will-navigate', (event, url) => {
    if (url.startsWith('file://')) return;
    event.preventDefault();
    shell.openExternal(url).catch(() => {});
  });
});
