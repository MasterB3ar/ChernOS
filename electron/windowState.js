'use strict';

const { app } = require('electron');
const fs = require('fs');
const path = require('path');

function stateFilePath() {
  return path.join(app.getPath('userData'), 'window-state.json');
}

function clamp(n, min, max) {
  if (typeof n !== 'number' || Number.isNaN(n)) return min;
  return Math.min(max, Math.max(min, n));
}

function loadWindowState({ defaultWidth = 1280, defaultHeight = 800 } = {}) {
  const defaults = {
    width: defaultWidth,
    height: defaultHeight,
    x: undefined,
    y: undefined,
    maximized: true
  };

  try {
    const raw = fs.readFileSync(stateFilePath(), 'utf8');
    const obj = JSON.parse(raw);
    return {
      width: clamp(obj.width, 900, 3840),
      height: clamp(obj.height, 600, 2160),
      x: typeof obj.x === 'number' ? obj.x : undefined,
      y: typeof obj.y === 'number' ? obj.y : undefined,
      maximized: !!obj.maximized
    };
  } catch (_) {
    return defaults;
  }
}

function saveWindowState(win) {
  if (!win || win.isDestroyed()) return;
  const bounds = win.getBounds();
  const data = {
    width: bounds.width,
    height: bounds.height,
    x: bounds.x,
    y: bounds.y,
    maximized: win.isMaximized()
  };
  try {
    fs.mkdirSync(path.dirname(stateFilePath()), { recursive: true });
    fs.writeFileSync(stateFilePath(), JSON.stringify(data, null, 2));
  } catch (_) {}
}

function trackWindowState(win) {
  if (!win) return;
  let t = null;
  const schedule = () => {
    if (t) clearTimeout(t);
    t = setTimeout(() => saveWindowState(win), 250);
  };

  win.on('resize', schedule);
  win.on('move', schedule);
  win.on('close', () => saveWindowState(win));
}

module.exports = {
  loadWindowState,
  trackWindowState
};
