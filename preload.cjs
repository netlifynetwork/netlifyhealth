const {contextBridge,ipcRenderer}=require('electron');
contextBridge.exposeInMainWorld('netlifyHealth',{
 platform:'windows',
 version:process.env.npm_package_version||'1.3.0',
 checkForUpdates:()=>ipcRenderer.invoke('updates:check'),
 downloadUpdate:()=>ipcRenderer.invoke('updates:download'),
 installUpdate:()=>ipcRenderer.invoke('updates:install'),
 onUpdate:(callback)=>{const channels=['update-checking','update-available','update-not-available','update-progress','update-downloaded','update-error'];const listeners=[];for(const channel of channels){const fn=(_event,data)=>callback(channel,data);ipcRenderer.on(channel,fn);listeners.push([channel,fn])}return()=>listeners.forEach(([channel,fn])=>ipcRenderer.removeListener(channel,fn))}
});
