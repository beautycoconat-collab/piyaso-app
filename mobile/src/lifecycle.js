// Pure bridge decisions are tested without pretending to be a physical device.
export function handleNativeBack({doc,win,app,canGoBack}){
 if(doc.getElementById('status-composer')&&typeof win.closeStatusComposer==='function'){win.closeStatusComposer();return;}
 const modal=doc.getElementById('modal');
 if(modal&&!modal.hidden&&typeof win.closeModal==='function'){win.closeModal();return;}
 if(canGoBack){win.history.back();return;}
 if(win.location.hash&&win.location.hash!=='#map'){win.location.hash='map';return;}
 return app.minimizeApp();
}
export function handleNativeState({isActive,doc,refresh}){
 doc.dispatchEvent(new Event(isActive?'kiyi:native-resume':'kiyi:native-pause'));
 // Resuming refreshes server state, never starts location sharing automatically.
 if(isActive)return Promise.resolve().then(refresh).catch(()=>{
  doc.dispatchEvent(new CustomEvent('kiyi:native-error',{detail:'Hesabın yenilenemedi. İnternet bağlantını kontrol et.'}));
 });
}
