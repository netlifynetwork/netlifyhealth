const {app,BrowserWindow,ipcMain}=require('electron');
const path=require('node:path');
const {autoUpdater}=require('electron-updater');
let win;
autoUpdater.autoDownload=false;
autoUpdater.autoInstallOnAppQuit=false;
autoUpdater.allowDowngrade=false;
function send(channel,data){if(win&&!win.isDestroyed())win.webContents.send(channel,data)}
function createWindow(){win=new BrowserWindow({width:1440,height:920,minWidth:1050,minHeight:700,backgroundColor:'#2929b9',webPreferences:{preload:path.join(__dirname,'preload.cjs'),contextIsolation:true,nodeIntegration:false}});win.loadFile('index.html');}
app.whenReady().then(()=>{
 createWindow();
 autoUpdater.on('checking-for-update',()=>send('update-checking'));
 autoUpdater.on('update-available',info=>send('update-available',{version:info.version}));
 autoUpdater.on('update-not-available',()=>send('update-not-available'));
 autoUpdater.on('download-progress',p=>send('update-progress',{percent:Math.round(p.percent),transferred:p.transferred,total:p.total}));
 autoUpdater.on('update-downloaded',info=>send('update-downloaded',{version:info.version}));
 autoUpdater.on('error',err=>send('update-error',{message:String(err.message||err)}));
 const check=()=>{if(!app.isPackaged)return;autoUpdater.checkForUpdates().catch(err=>send('update-error',{message:String(err.message||err)}));};
 setTimeout(check,8000);setInterval(check,6*60*60*1000);
 app.on('activate',()=>{if(BrowserWindow.getAllWindows().length===0)createWindow()});
});
ipcMain.handle('app:version',()=>app.getVersion());
ipcMain.handle('updates:check',async()=>{if(!app.isPackaged)return {available:false,development:true};try{const r=await autoUpdater.checkForUpdates();return {available:!!(r&&r.updateInfo&&r.updateInfo.version!==app.getVersion()),version:r?.updateInfo?.version||null}}catch(e){return {error:String(e.message||e)}}});
ipcMain.handle('updates:download',async()=>{try{await autoUpdater.downloadUpdate();return {started:true}}catch(e){return {error:String(e.message||e)}}});
ipcMain.handle('updates:install',()=>{autoUpdater.quitAndInstall(false,true);return {started:true}});
app.on('window-all-closed',()=>{if(process.platform!=='darwin')app.quit()});
