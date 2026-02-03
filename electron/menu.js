'use strict';

const path = require('path');
const { shell, Menu } = require('electron');

function buildAppMenu({ app, getMainWindow, showAbout, isDev }) {
  const isMac = process.platform === 'darwin';
  const win = () => getMainWindow();

  const toggleKiosk = () => {
    const w = win();
    if (!w) return;
    const next = !w.isKiosk();
    w.setKiosk(next);
    if (next) w.setFullScreen(true);
  };

  const toggleFullscreen = () => {
    const w = win();
    if (!w) return;
    w.setFullScreen(!w.isFullScreen());
  };

  const toggleAlwaysOnTop = () => {
    const w = win();
    if (!w) return;
    w.setAlwaysOnTop(!w.isAlwaysOnTop());
  };

  const openReadme = () => {
    const readmePath = path.join(__dirname, '..', 'README.md');
    shell.openPath(readmePath);
  };

  const template = [
    ...(isMac
      ? [{
          label: app.name,
          submenu: [
            { label: 'About ChernOS', click: showAbout },
            { type: 'separator' },
            { role: 'services' },
            { type: 'separator' },
            { role: 'hide' },
            { role: 'hideOthers' },
            { role: 'unhide' },
            { type: 'separator' },
            { role: 'quit' }
          ]
        }]
      : []),
    {
      label: 'File',
      submenu: [
        { label: 'New Window', accelerator: 'CmdOrCtrl+N', click: () => app.emit('activate') },
        { type: 'separator' },
        ...(isMac ? [{ role: 'close' }] : [{ role: 'quit' }])
      ]
    },
    {
      label: 'View',
      submenu: [
        { role: 'reload' },
        { role: 'forceReload' },
        ...(isDev ? [{ role: 'toggleDevTools' }] : []),
        { type: 'separator' },
        { label: 'Toggle Fullscreen', accelerator: 'F11', click: toggleFullscreen },
        { label: 'Toggle Kiosk', accelerator: 'Ctrl+Alt+K', click: toggleKiosk },
        { type: 'separator' },
        { role: 'resetZoom' },
        { role: 'zoomIn' },
        { role: 'zoomOut' }
      ]
    },
    {
      label: 'Window',
      role: 'window',
      submenu: [
        { role: 'minimize' },
        ...(isMac ? [{ role: 'zoom' }] : []),
        { type: 'separator' },
        { label: 'Always on Top', accelerator: 'CmdOrCtrl+Shift+T', click: toggleAlwaysOnTop },
        { type: 'separator' },
        ...(isMac ? [{ role: 'front' }] : [{ role: 'close' }])
      ]
    },
    {
      label: 'Help',
      role: 'help',
      submenu: [
        ...(!isMac ? [{ label: 'About ChernOS', click: showAbout }, { type: 'separator' }] : []),
        { label: 'Open README', click: openReadme }
      ]
    }
  ];

  return Menu.buildFromTemplate(template);
}

module.exports = { buildAppMenu };
