const { app, BrowserWindow } = require('electron');

// Allow audio to start without requiring a user gesture (kiosk-friendly)
try { app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required'); } catch (e) {}
const path = require('path');

function createWindow () {
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    backgroundColor: '#020806',
    autoHideMenuBar: true,
    webPreferences: {
      contextIsolation: true,
      sandbox: true
    }
  });

  win.loadFile(path.join(__dirname, '..', 'ui', 'index.html'));
  win.setFullScreen(true);
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
})
