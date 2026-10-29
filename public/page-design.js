/* Reuse the existing profile form and save handlers, refresh its presentation. */
const originalProfilePage=renderProfile;
renderProfile=function(){
 originalProfilePage();const app=$('#app');app.classList.add('profile-redesign');
 const split=app.querySelector('.split');if(!split)return;
 // Drop the old title and advertising blocks; keep working forms and privacy tools.
 while(app.firstChild&&app.firstChild!==split)app.firstChild.remove();
 app.querySelector('.campaign')?.remove();
 const p=state.me;
 app.insertAdjacentHTML('afterbegin',`<section class="my-profile-overview"><div class="profile-cover-art"><span>senin şehrin.<br>senin hikâyen.</span><i>✦</i></div><div class="my-profile-identity"><div class="my-profile-portrait">${ownerAvatar(p)}</div><div class="my-profile-title"><span class="discovery-kicker">BENİM PROFİLİM</span><h1>${esc(kiyiHandle(p))}</h1><p>${esc(p.car)} · ${esc(p.area||'Antalya')}</p></div><button class="profile-edit-shortcut" onclick="document.querySelector('#profileform input').focus();document.querySelector('#profileform').scrollIntoView({behavior:'smooth',block:'start'})">Düzenle ↗</button></div><div class="my-profile-stats"><button onclick="location.hash='follow'"><b>${state.followers.length}</b><span>Takipçi</span></button><button onclick="location.hash='follow'"><b>${state.following.length}</b><span>Takip</span></button><div><b>${(state.gifts||[]).length}</b><span>Demo hediye</span></div></div></section>`);
 const main=split.querySelector(':scope > .panel');if(main){main.classList.add('profile-edit-panel');main.querySelector('h2').textContent='Profil bilgilerin';}
 const premium=split.querySelector('.premium');if(premium){premium.classList.add('profile-membership');premium.innerHTML=`<span class="discovery-kicker">PİYASO PREMIUM</span><h3>Biraz daha sana özel.</h3><p>Harita ve görünürlük seçeneklerini keşfet.</p><button class="btn" onclick="premiumModal()">${state.premium?'Demo Premium açık':'Premium’u keşfet'} ↗</button>`}
 document.body.classList.add('profile-design-page');
};
window.addEventListener('hashchange',()=>{if(location.hash!=='#profile'){document.body.classList.remove('profile-design-page');$('#app')?.classList.remove('profile-redesign')}});

function profileSearchResult(p){return `<button class="search-profile-result" onclick="openProfile('${p.id}')">${ownerAvatar(p)}<span><b>${esc(kiyiHandle(p))}</b><small>${esc(p.car)} · ${esc(p.area)}</small></span><span class="search-profile-plate">${esc(p.plate)}</span><i>↗</i></button>`}
