/* Public featured profiles use demo road positions, never live location. */
for(const [id,routeSource,demoOffset] of [['fenomen-1786','d4',180],['fenomen-1783','d2',260],['fenomen-1785','d2',980]]){
 const p=profiles.find(x=>x.id===id);if(p)Object.assign(p,{sharing:true,visibility:'all',routeSource,demoOffset});
}
const demoSurnames=['Yılmaz','Demir','Kaya','Çelik','Aydın','Koç','Yıldız','Arslan','Şahin','Aksoy'];
profiles.filter(p=>p.id.startsWith('traffic-')).forEach((p,i)=>p.surname=demoSurnames[i]);
function ghostInitials(p){return [p.ownerName||p.name,p.surname].filter(Boolean).join(' ').trim().split(/\s+/).map(w=>w[0].toLocaleUpperCase('tr-TR')+'.').join(' ')}
function ghostPlate(p){return (String(p.plate||'').trim().match(/^\d{2}/)?.[0]||'**')+' ***'}
function ghostProfileBody(p){return `<div class="ghost-profile-header"><span class="ghost-profile-symbol">${ghostIcon}</span><span class="ghost-profile-eyebrow">HAYALET PROFİL</span><h2>${esc(ghostInitials(p))}</h2><span class="ghost-profile-plate">${esc(ghostPlate(p))}</span><p>${esc(p.area)}</p></div><div class="ghost-profile-message"><h3>Şu an hayalet modunda.</h3><p>Bu harita işaretinin kimliği gizli. Premium, hayalet tercihini açmaz.</p><small>Demo görünüm · Gerçek kullanıcı konumu paylaşılmaz.</small></div>`}
function openGhostProfile(id,onMap=false){const p=profiles.find(x=>x.id===id);if(!p||state.blocked.includes(id))return;if(!profileLocked(p))return openProfile(id);const sheet=$('#vehicle-sheet');if(onMap&&sheet){selectedCar=id;document.querySelector('.map-sheet')?.classList.add('is-profile');$('#tour-sheet').hidden=true;sheet.hidden=false;sheet.classList.add('ghost-vehicle-sheet');sheet.innerHTML=`<button class="profile-sheet-close" onclick="clearSelectedCar()" aria-label="Profili kapat">×</button>${ghostProfileBody(p)}`;return}$('#modal').innerHTML=`<section class="dialog ghost-profile-dialog" role="dialog" aria-modal="true" aria-label="Hayalet profil"><button class="close" onclick="closeModal()" aria-label="Kapat">×</button>${ghostProfileBody(p)}</section>`;$('#modal').hidden=false;$('#modal .close').focus()}
const ghostSelectCar=selectCar;
selectCar=function(id){const p=profiles.find(x=>x.id===id);if(p&&profileLocked(p))return openGhostProfile(id,true);$('#vehicle-sheet')?.classList.remove('ghost-vehicle-sheet');ghostSelectCar(id)};
const ghostOpenProfile=openProfile;
openProfile=function(id){const p=profiles.find(x=>x.id===id);if(p&&profileLocked(p))return openGhostProfile(id);ghostOpenProfile(id)};
const ghostSearchResult=profileSearchResult;
profileSearchResult=function(p){return profileLocked(p)?`<button class="search-profile-result" onclick="openGhostProfile('${p.id}')"><span class="locked-owner-avatar owner-photo">${ghostIcon}</span><span><b>${esc(ghostInitials(p))}</b><small>${esc(p.area)} · Hayalet modunda</small></span><span class="search-profile-plate">${esc(ghostPlate(p))}</span></button>`:ghostSearchResult(p)};
// Spread each region across its full road loop, rather than a tight fixed-offset convoy.
for(const [source,ids] of [['d4',['d4','traffic-0','traffic-1','traffic-2','traffic-3','traffic-4','fenomen-1786']],['d2',['d2','traffic-5','traffic-6','traffic-7','traffic-8','traffic-9','fenomen-1783','fenomen-1785']]]){
 const route=demoRoutes[source];if(!route)continue;ids.forEach((id,i)=>{const p=profiles.find(x=>x.id===id);if(p){p.routeSource=source;p.motion=TrafficMotion.settings(i+(source==='d2'?13:0),route.length)}});
}
