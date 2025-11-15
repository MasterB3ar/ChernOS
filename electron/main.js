const { app, BrowserWindow } = require('electron');

function createWindow () {
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    backgroundColor: '#020806',
    autoHideMenuBar: true,
    webPreferences: { contextIsolation: true, sandbox: true }
  });

  win.loadFile('../index.html'); // Reuse the same UI from flake
  win.setFullScreen(true);
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
