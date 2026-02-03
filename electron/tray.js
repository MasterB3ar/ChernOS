'use strict';

const { Tray, Menu, nativeImage } = require('electron');
const fs = require('fs');

function loadIcon(iconPath) {
  try {
    if (iconPath && fs.existsSync(iconPath)) {
      const img = nativeImage.createFromPath(iconPath);
      // Resize to something tray-friendly; Electron will choose best size.
      return img.isEmpty() ? nativeImage.createEmpty() : img;
    }
  } catch (_) {}
  return nativeImage.createEmpty();
}

function createTray({ app, getMainWindow, iconPath }) {
  const tray = new Tray(loadIcon(iconPath));
  tray.setToolTip('ChernOS');

  const win = () => getMainWindow();

  const toggleWindow = () => {
    const w = win();
    if (!w) return;
    if (w.isVisible()) w.hide();
    else {
      w.show();
      w.focus();
    }
  };

  const buildContextMenu = () => {
    const w = win();
    const visible = !!(w && w.isVisible());
    const fsOn = !!(w && w.isFullScreen());
    const kioskOn = !!(w && w.isKiosk());
    const topOn = !!(w && w.isAlwaysOnTop());

    return Menu.buildFromTemplate([
      { label: visible ? 'Hide ChernOS' : 'Show ChernOS', click: toggleWindow },
      { type: 'separator' },
      {
        label: fsOn ? 'Exit Fullscreen' : 'Enter Fullscreen',
        click: () => { const ww = win(); if (ww) ww.setFullScreen(!ww.isFullScreen()); }
      },
      {
        label: kioskOn ? 'Disable Kiosk' : 'Enable Kiosk',
        click: () => {
          const ww = win();
          if (!ww) return;
          const next = !ww.isKiosk();
          ww.setKiosk(next);
          if (next) ww.setFullScreen(true);
        }
      },
      {
        label: topOn ? 'Disable Always on Top' : 'Always on Top',
        click: () => { const ww = win(); if (ww) ww.setAlwaysOnTop(!ww.isAlwaysOnTop()); }
      },
      { type: 'separator' },
      { label: 'Quit', click: () => app.quit() }
    ]);
  };

  tray.setContextMenu(buildContextMenu());
  tray.on('click', toggleWindow);

  return {
    tray,
    attachWindow: () => tray.setContextMenu(buildContextMenu()),
    destroy: () => { try { tray.destroy(); } catch (_) {} }
  };
}

module.exports = { createTray };
