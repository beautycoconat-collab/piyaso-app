/* Premium profile visitors. Free accounts never request or receive visitor identities. */
(()=>{
let visitors=[];
const placeholders='<i></i><i></i><i></i>';
const beforeHero=wallHero;wallHero=function(p,mine){let html=beforeHero(p,mine);if(!mine)return html;return html.replace('<div class="wall-cover">','<div class="wall-cover"><button class="profile-visitor-entry" onclick="openProfileVisitors()" aria-label="Profiline kim baktı"><span class="visitor-mini-avatars" aria-hidden="true">'+placeholders+'</span><span>Profiline</span><span class="visitor-eyes">👀</span></button>')};
function updatePreview(){if(!state.premium)visitors=[];document.querySelectorAll('.profile-visitor-entry .visitor-mini-avatars').forEach(el=>{el.innerHTML=state.premium&&visitors.length?visitors.slice(0,3).map(v=>'<span>'+framedProfileAvatar(v.profile)+'</span>').join(''):placeholders})}
const beforeRender=renderProfile;renderProfile=function(){const out=beforeRender.apply(this,arguments);updatePreview();if(statusUser&&state.premium)statusRequest('visits').then(d=>{if(!state.premium)return;visitors=(d.visitors||[]).filter(v=>!state.blocked.includes(v.id));updatePreview()}).catch(()=>{});return out};
window.openProfileVisitors=async function(){
 if(!state.premium){openKiyiPremiumPaywall('visitors');return;}
 if(!statusUser){membershipDialog('<div class="profile-visitors-dialog"><h2>Profiline bakanlar</h2><p class="hint">Gerçek profil ziyaretlerini görmek için Premium üyeliğinin bulunduğu Piyaso hesabına giriş yap.</p><button class="btn" onclick="openKiyiAccount()">Hesabına giriş yap</button></div>');return;}
 membershipDialog('<div class="profile-visitors-dialog"><h2>Profiline bakanlar</h2><div class="visitor-results" role="status">Yükleniyor…</div></div>');const host=document.querySelector('.visitor-results');
 try{const d=await statusRequest('visits');if(!state.premium||!host?.isConnected)return;visitors=(d.visitors||[]).filter(v=>!state.blocked.includes(v.id));host.innerHTML=visitors.length?visitors.map(v=>'<button class="visitor-person" data-visitor="'+esc(v.id)+'"><span class="visitor-photo">'+framedProfileAvatar(v.profile)+'</span><span><b>'+esc(kiyiHandle(v.profile))+'</b><small>'+esc(new Date(v.visited).toLocaleString('tr-TR',{day:'numeric',month:'short',hour:'2-digit',minute:'2-digit'}))+'</small></span></button>').join(''):'<p class="hint">Henüz profil ziyareti yok.</p>';host.querySelectorAll('[data-visitor]').forEach(b=>b.onclick=()=>{const v=visitors.find(v=>v.id===b.dataset.visitor);if(!profiles.some(p=>p.id===v.id))profiles.push({...v.profile,id:v.id,serverProfile:true});openProfile(v.id)});updatePreview();}
 catch(e){if(e.code==='PT402'||/Premium/.test(e.message)){visitors=[];updatePreview();if(host?.isConnected)openKiyiPremiumPaywall('visitors');return;}if(host?.isConnected)host.textContent=e.message}
};
window.addEventListener('kiyi:account-out',()=>{visitors=[];updatePreview()});window.addEventListener('kiyi:bundle',()=>{if(!state.premium){visitors=[];updatePreview()}});
const beforeOpen=openProfile;openProfile=function(id){const result=beforeOpen.apply(this,arguments);const p=profiles.find(p=>p.id===id);if(statusUser&&p?.serverProfile&&id!==statusUser&&!state.blocked.includes(id)&&!profileLocked(p))statusRequest('visits','POST',{target:id}).catch(()=>{});return result};
})();
