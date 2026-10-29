/* Only a fixed event code leaves the client. Never send text, URL, stack, plate or coordinates. */
(()=>{'use strict';let last=0,sending=false;
 window.KiyiReportDiagnostic=async code=>{if(!['client_error','api_error','media_error','map_error','notification_error','offline'].includes(code)||sending||Date.now()-last<60000||!window.kiyiCloud?.active)return;last=Date.now();sending=true;try{await kiyiCloud.command('diagnostic',{code})}catch{}finally{sending=false}};
 window.addEventListener('error',()=>KiyiReportDiagnostic('client_error'));
 window.addEventListener('unhandledrejection',()=>KiyiReportDiagnostic('client_error'));
 function connectivity(){let el=document.getElementById('kiyi-network-status');if(!el){el=document.createElement('div');el.id='kiyi-network-status';el.setAttribute('role','status');el.style.cssText='position:fixed;left:8px;right:8px;bottom:calc(80px + env(safe-area-inset-bottom));z-index:5000;background:#47325e;color:white;padding:12px;border-radius:12px;text-align:center;pointer-events:none';document.body.append(el)}el.hidden=navigator.onLine!==false;el.textContent='İnternet bağlantısı yok. İşlemini bağlantı geldikten sonra yeniden dene.';}
 window.addEventListener('offline',()=>{connectivity();KiyiReportDiagnostic('offline')});window.addEventListener('online',connectivity);
 document.addEventListener('DOMContentLoaded',connectivity);
})();
