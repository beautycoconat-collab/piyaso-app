/* Presentation only: retain search, profile access and community actions. */
(function(){
 const original=render;
 window.render=function(){original.apply(this,arguments);if(location.hash!=='#search')return;polishDiscovery()};
 function polishDiscovery(){
  const root=document.querySelector('.plate-discovery');if(!root||root.dataset.social)return;root.dataset.social='true';
  const hero=root.querySelector('.plate-search-card');
  hero.querySelector(':scope > p')?.remove();
  const favorite=root.querySelector('.community-shortcuts a[href="#favorites"] .shortcut-icon');
  if(favorite)favorite.innerHTML='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z"/></svg>';

  hero.querySelector('.searchrow>.btn').innerHTML='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="10" cy="10" r="7"/><path d="m15 15 6 6"/></svg> Ara';
  const head=root.querySelector('.phenomenon-section .sectionhead');
  head.querySelector('.discovery-kicker')?.remove();head.querySelector('h2').insertAdjacentHTML('beforeend',' <span class="discovery-crown" aria-hidden="true"><svg viewBox="0 0 32 28" fill="none"><path d="m3 7 6 6 7-10 7 10 6-6-3 16H6L3 7Z" fill="#FFC34D" stroke="#EEA825" stroke-width="1.5" stroke-linejoin="round"/><path d="M7 26h18" stroke="#EEA825" stroke-width="2.5" stroke-linecap="round"/><circle cx="3" cy="6" r="2" fill="#FFCE62"/><circle cx="16" cy="3" r="2.5" fill="#FFCE62"/><circle cx="29" cy="6" r="2" fill="#FFCE62"/></svg></span>');
  head.querySelector('.phenomenon-pill').remove();
  root.querySelectorAll('.phenomenon-card').forEach(card=>{
   const match=card.getAttribute('onclick')?.match(/openProfile\('([^']+)'\)/);if(!match)return;
   const id=match[1];const p=profiles.find(p=>p.id===id);if(!p)return;
   if(p.verified===true)card.querySelector('h3')?.insertAdjacentHTML('beforeend','<span class="discovery-verified" role="img" aria-label="Onaylanmış hesap"><svg viewBox="0 0 24 24" aria-hidden="true"><path fill="#9239ef" stroke="white" stroke-width="1.4" d="m12 1 3 2 3.5.5 1 3.4L22 10l-1 3.5.2 3.5-3.3 1.5L15.5 21 12 20.5 8.5 22l-2.4-3-3.3-1.5.2-3.5L1 10l2.5-3.1 1-3.4L8 3Z"/><path d="m7.4 11.8 3 3 6.2-6" fill="none" stroke="white" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/></svg></span>');
   const wrap=document.createElement('article');wrap.className='discovery-person';card.before(wrap);wrap.append(card);
   const plate=card.querySelector('.phenomenon-plate');
   if(plate&&typeof profilePlate==='function'){plate.className='discovery-profile-plate';plate.innerHTML=profilePlate(p)}
   card.querySelector('.phenomenon-profile')?.remove();
   card.querySelector('.phenomenon-cover')?.remove();
   card.querySelector(':scope > p')?.remove();
   card.querySelector('.phenomenon-followers')?.insertAdjacentHTML('afterbegin','<svg class="discovery-people-icon" viewBox="0 0 32 26" fill="currentColor" aria-hidden="true"><circle cx="16" cy="6" r="5"/><circle cx="5.5" cy="8" r="3.5"/><circle cx="26.5" cy="8" r="3.5"/><path d="M7 25v-4a9 9 0 0 1 18 0v4H7ZM0 22v-4a5.5 5.5 0 0 1 9-4.2A11 11 0 0 0 5 22H0Zm32 0h-5a11 11 0 0 0-4-8.2 5.5 5.5 0 0 1 9 4.2v4Z"/></svg>');
   const details=document.createElement('div');details.className='discovery-person-details';
   [...card.children].filter(el=>!el.classList.contains('phenomenon-avatar')).forEach(el=>details.append(el));card.append(details);
   const heart=document.createElement('button');heart.className='discovery-heart';
   const update=()=>{const active=isFavorite(id);heart.setAttribute('aria-pressed',String(active));heart.setAttribute('aria-label',active?'Favorilerden çıkar':'Favorilere ekle');heart.innerHTML='<svg viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" fill="'+(active?'currentColor':'none')+'"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z"/></svg>'};
   heart.onclick=()=>{toggleFavoritePlate(id);update()};update();wrap.append(heart);
  });
 }
 const observer=new MutationObserver(()=>{if(location.hash==='#search')polishDiscovery()});
 observer.observe(document.getElementById('app'),{childList:true,subtree:true});
 if(location.hash==='#search')polishDiscovery();
})();
