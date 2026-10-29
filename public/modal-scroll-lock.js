/* Freeze the page beneath dialogs, including Safari's root scroll surface. */
(()=>{
 const modal=document.getElementById('modal');if(!modal)return;
 const root=document.documentElement,body=document.body;let saved=null;
 function sync(){
  if(!modal.hidden){
   if(saved)return;
   saved={x:window.scrollX,y:window.scrollY,hash:location.hash,offset:body.style.getPropertyValue('--kiyi-modal-scroll-y'),priority:body.style.getPropertyPriority('--kiyi-modal-scroll-y')};
   body.style.setProperty('--kiyi-modal-scroll-y',-saved.y+'px');
   root.classList.add('kiyi-modal-open');body.classList.add('kiyi-modal-open');
  }else if(saved){
   const previous=saved;saved=null;
   root.classList.remove('kiyi-modal-open');body.classList.remove('kiyi-modal-open');
   if(previous.offset)body.style.setProperty('--kiyi-modal-scroll-y',previous.offset,previous.priority);else body.style.removeProperty('--kiyi-modal-scroll-y');
   window.scrollTo(location.hash===previous.hash?previous.x:0,location.hash===previous.hash?previous.y:0);
  }
 }
 new MutationObserver(sync).observe(modal,{attributes:true,attributeFilter:['hidden'],childList:true});
 sync();
})();
