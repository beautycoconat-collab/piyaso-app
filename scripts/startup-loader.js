/* Independent critical path. Application code is fetched only when it is needed. */
(()=>{
 const config=__STARTUP_CONFIG__,images=new Map(),readyCallbacks=[];
 let appPromise=null,scriptPromise=null,stylePromise=null,loaded=false;
 function showError(){const host=document.getElementById('piyaso-startup');if(host)host.innerHTML='<div style="text-align:center;padding:24px">Yükleme tamamlanamadı.<br><button type="button" onclick="location.reload()" style="margin-top:16px;padding:12px 20px;border:0;border-radius:20px;background:#8136ee;color:white">Yeniden dene</button></div>';}
 function imageReady(src,priority='auto'){
  if(images.has(src))return images.get(src);
  const task=new Promise((resolve,reject)=>{const img=new Image();img.decoding='async';img.fetchPriority=priority;img.onload=()=>{(img.decode?img.decode():Promise.resolve()).then(resolve,resolve)};img.onerror=()=>{images.delete(src);reject(new Error('Image load failed: '+src))};img.src=src;});
  images.set(src,task);return task;
 }
 function sceneReady(scene){return Promise.all((config.scenes[scene]||[]).map(src=>imageReady(src,scene==='welcome'?'high':'auto'))).catch(error=>{showError();throw error});}
 function removeCover(){document.documentElement.classList.remove('piyaso-boot-pending');document.getElementById('piyaso-startup')?.remove();}
 function warmNext(scene){const next={welcome:'plate',plate:'garage',garage:'map',map:'email'}[scene];if(!next)return;const warm=()=>{for(const src of config.scenes[next]||[])imageReady(src,'low').catch(()=>{});if(scene==='map')prefetchApp();};if(window.requestIdleCallback)requestIdleCallback(warm,{timeout:500});else setTimeout(warm,60);}
 function prefetchApp(){if(document.querySelector('link[data-piyaso-prefetch]'))return;const link=document.createElement('link');link.rel='prefetch';link.as='script';link.href=config.js;link.dataset.piyasoPrefetch='true';document.head.append(link);}
 function loadApp(){
  if(appPromise)return appPromise;
  if(!stylePromise)stylePromise=new Promise((resolve,reject)=>{const link=document.createElement('link');link.rel='stylesheet';link.href=config.css;link.onload=resolve;link.onerror=()=>{stylePromise=null;link.remove();reject(new Error('Application stylesheet could not be loaded'))};document.head.append(link)});
  if(!scriptPromise)scriptPromise=new Promise((resolve,reject)=>{const script=document.createElement('script');script.src=config.js;script.async=true;script.onerror=()=>{scriptPromise=null;script.remove();reject(new Error('Application script could not be loaded'))};window.PiyasoBoot.didLoad=resolve;document.head.append(script)});
  appPromise=Promise.all([stylePromise,scriptPromise]).then(()=>{
   loaded=true;window.PiyasoBoot.ready=true;
   for(const fn of readyCallbacks.splice(0)){try{const result=fn(new Event('DOMContentLoaded'));result?.catch?.(console.error)}catch(error){console.error(error)}}
   window.dispatchEvent(new Event('piyaso:app-ready'));
  }).catch(error=>{appPromise=null;showError();throw error});
  return appPromise;
 }
 window.PiyasoBoot={ready:false,carArt:config.carArt,sceneReady,warmNext,loadApp,prefetchApp,revealEntry:removeCover,revealApp:removeCover,didLoad(){},onReady(fn){if(loaded)fn(new Event('DOMContentLoaded'));else readyCallbacks.push(fn)}};
})();
