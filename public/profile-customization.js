/* Profile appearance lives in the same device-local profile record as the photo. */
const profileFrames=[
  {id:'none',label:'Sade',src:''},
  {id:'leopard',label:'Leopar',src:'assets/frames/leopard-v2.png'},
  {id:'diamond',label:'Pırlanta',src:'assets/frames/diamond-v2.png'},
  {id:'blossom',label:'Pembe çiçek',src:'assets/frames/blossom-v2.png'},
  {id:'kitty',label:'Pembe kedi',src:'assets/frames/kitty-v2.png'},
  {id:'web',label:'Kırmızı ağ',src:'assets/frames/web-v2.png'},
  {id:'alert',label:'Kırmızı uyarı',src:'assets/frames/alert-v2.png'},
  {id:'bluekitty',label:'Mavi kedi',src:'assets/frames/bluekitty-v2.png'},
  {id:'starlight',label:'Mavi ışıltı',src:'assets/frames/starlight-v2.png'}
];

function profileGlyph(name){
  const paths={
    bell:'M8 16a2 2 0 0 0 2-2H6a2 2 0 0 0 2 2M8 1.918l-.797.161A4 4 0 0 0 4 6c0 .628-.134 2.197-.459 3.742-.16.767-.376 1.566-.663 2.258h10.244c-.287-.692-.502-1.49-.663-2.258C12.134 8.197 12 6.628 12 6a4 4 0 0 0-3.203-3.92zM14.22 12c.223.447.481.801.78 1H1c.299-.199.557-.553.78-1C2.68 10.2 3 6.88 3 6c0-2.42 1.72-4.44 4.005-4.901a1 1 0 1 1 1.99 0A5 5 0 0 1 13 6c0 .88.32 4.2 1.22 6',
    pencil:'M12.146.146a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1 0 .708l-10 10a.5.5 0 0 1-.168.11l-5 2a.5.5 0 0 1-.65-.65l2-5a.5.5 0 0 1 .11-.168zM11.207 2.5 13.5 4.793 14.793 3.5 12.5 1.207zm1.586 3L10.5 3.207 4 9.707V10h.5a.5.5 0 0 1 .5.5v.5h.5a.5.5 0 0 1 .5.5v.5h.293zm-9.761 5.175-.106.106-1.528 3.821 3.821-1.528.106-.106A.5.5 0 0 1 5 12.5V12h-.5a.5.5 0 0 1-.5-.5V11h-.5a.5.5 0 0 1-.468-.325',
    gear:'M9.405 1.05c-.413-1.4-2.397-1.4-2.81 0l-.1.34a1.464 1.464 0 0 1-2.105.872l-.31-.17c-1.283-.698-2.686.705-1.987 1.987l.169.311c.446.82.023 1.841-.872 2.105l-.34.1c-1.4.413-1.4 2.397 0 2.81l.34.1a1.464 1.464 0 0 1 .872 2.105l-.17.31c-.698 1.283.705 2.686 1.987 1.987l.311-.169a1.464 1.464 0 0 1 2.105.872l.1.34c.413 1.4 2.397 1.4 2.81 0l.1-.34a1.464 1.464 0 0 1 2.105-.872l.31.17c1.283.698 2.686-.705 1.987-1.987l-.169-.311a1.464 1.464 0 0 1 .872-2.105l.34-.1c1.4-.413 1.4-2.397 0-2.81l-.34-.1a1.464 1.464 0 0 1-.872-2.105l.17-.31c.698-1.283-.705-2.686-1.987-1.987l-.311.169a1.464 1.464 0 0 1-2.105-.872zM8 10.93a2.929 2.929 0 1 1 0-5.86 2.929 2.929 0 0 1 0 5.858z',
    image:'M8 3a1 1 0 1 0 0 2 1 1 0 0 0 0-2M2 1a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V3a2 2 0 0 0-2-2zm12 1a1 1 0 0 1 1 1v7.5l-3.086-3.086a1 1 0 0 0-1.414 0L6 12l-1.586-1.586a1 1 0 0 0-1.414 0L1 12.414V3a1 1 0 0 1 1-1z',
    frame:'M4 0a1 1 0 0 0-1 1v1H1a1 1 0 0 0-1 1v10a1 1 0 0 0 1 1h2v1a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1v-1h2a1 1 0 0 0 1-1V3a1 1 0 0 0-1-1h-2V1a1 1 0 0 0-1-1zm0 1h8v14H4zM1 3h2v10H1zm12 0h2v10h-2z'
  };
  return `<svg viewBox="0 0 16 16" fill="currentColor" aria-hidden="true"><path d="${paths[name]||''}"/></svg>`;
}

function framedProfileAvatar(p){
  const frame=profileFrames.find(f=>f.id===p.avatarFrame)||profileFrames[0];
  return `<span class="profile-avatar-stack"><span class="profile-avatar-photo">${ownerAvatar(p)}</span>${frame.src?`<img class="profile-frame-layer frame-${frame.id}" src="${frame.src}" alt="" draggable="false">`:''}</span>`;
}

const originalWallHero=wallHero;
wallHero=function(p,mine){
  if(!mine)return originalWallHero(p,mine).replace(`<div class="wall-avatar">${ownerAvatar(p)}</div>`,`<div class="wall-avatar">${framedProfileAvatar(p)}</div>`);
  return `<div class="wall-cover"><div class="wall-topbar"><div class="wall-credit-control"><button class="wall-credit-control-balance" onclick="openCreditWallet()" aria-label="Kredi bakiyesi">${creditCoin()} <b>${creditBalance()}</b></button><button class="wall-credit-control-add" onclick="openCreditWallet()" aria-label="Kredi yükle">+</button></div><div class="profile-top-actions"><button onclick="openGiftNotifications()" aria-label="Bildirimler">${profileGlyph('bell')}</button><button onclick="openProfileEditor()" aria-label="Profili düzenle">${profileGlyph('pencil')}</button><button onclick="privacySupportDialog()" aria-label="Ayarlar ve destek">${profileGlyph('gear')}</button></div></div></div><div class="wall-identity"><button class="wall-avatar wall-avatar-edit" onclick="openProfileAppearance()" aria-label="Profil görünümünü düzenle">${framedProfileAvatar(p)}<span class="wall-avatar-camera">${profileGlyph('image')}</span></button><div class="profile-name-row wall-profile-name-row"><h1>${esc(kiyiHandle(p))}</h1>${!p.verified?`<a href="#verification" class="profile-verify-cta">${typeof KiyiUIIcon==='function'?KiyiUIIcon('verify'):''}<span>Profilini doğrula</span></a>`:''}</div><p class="wall-id">${esc(p.area||'Antalya')}</p><div class="profile-vehicle-customize"><button class="profile-plate-button" onclick="openPlateAppearance()" aria-label="Araç Garajını aç">${profilePlate(p)}<span>Plakanı özelleştir <i>›</i></span></button></div><button class="wall-status" onclick="openWallStatus()">+ Durum ekle</button><p class="wall-bio">${esc(p.status||p.bio)}</p><p class="wall-car">${esc(p.car)} · ${esc(p.year||'')} · ${esc(p.color||'')}</p><div class="wall-tags"><span>Sahil turu</span><span>Otomobil tutkunu</span><span>${esc(p.area||'Antalya')}</span></div><div class="wall-stats"><a href="#follow"><b>${state.following.length}</b> Takip</a><a href="#follow"><b>${state.followers.length}</b> Takipçi</a><a href="#gifts"><b>${(state.gifts||[]).length}</b> Hediye</a></div><button class="wall-edit" onclick="openProfileEditor()">Profil bilgilerini düzenle ${profileGlyph('pencil')}</button></div>`;
};

function openProfilePhotoEditor(){
  membershipDialog(`<div class="appearance-dialog"><span class="appearance-eyebrow">PROFİL GÖRÜNÜMÜ</span><h2>Profil fotoğrafı</h2><p>Fotoğrafın profilinde ve profil kartında görünür.</p><div class="appearance-preview">${framedProfileAvatar(state.me)}</div><label class="appearance-upload">${profileGlyph('image')} ${state.me.avatar?'Fotoğrafı değiştir':'Fotoğraf ekle'}<input type="file" accept="image/jpeg,image/png,image/webp" onchange="saveProfileAvatar(this)"></label>${state.me.avatar?'<button class="appearance-remove" onclick="removeProfileAvatar()">Fotoğrafı kaldır</button>':''}<small>JPG, PNG veya WebP · En fazla 3 MB. Demo fotoğrafı bu cihazda saklanır.</small></div>`);
}
async function saveProfileAvatar(input){
  const file=input.files?.[0];if(!file)return;
  if(file.size>3*1024*1024||!['image/jpeg','image/png','image/webp'].includes(file.type)){toast('JPG, PNG veya WebP fotoğraf seç; en fazla 3 MB.');return}
  let data;try{data=await new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(reader.result);reader.onerror=()=>reject(Error('Fotoğraf okunamadı.'));reader.readAsDataURL(file)})}catch{toast('Fotoğraf okunamadı.');return}
  if(wallCommit(()=>{state.me.avatar=data})){closeModal();renderProfile();toast('Profil fotoğrafın kaydedildi.')}
}
function removeProfileAvatar(){if(wallCommit(()=>{state.me.avatar=''})){closeModal();renderProfile();toast('Profil fotoğrafı kaldırıldı.')}}

function openProfileFrameEditor(){
  membershipDialog(`<div class="appearance-dialog"><span class="appearance-eyebrow">PROFİL GÖRÜNÜMÜ</span><h2>Çerçeveni seç</h2><p>Seçtiğin çerçeve profil fotoğrafının çevresinde görünür.</p><div class="appearance-frame-grid">${profileFrames.map(frame=>`<button class="appearance-frame-choice ${frame.id===(state.me.avatarFrame||'none')?'selected':''}" onclick="chooseProfileFrame('${frame.id}')" aria-label="${frame.label} çerçevesini seç"><span class="appearance-frame-art">${framedProfileAvatar({...state.me,avatarFrame:frame.id})}</span><b>${frame.label}</b>${frame.id===(state.me.avatarFrame||'none')?'<small>Seçili</small>':''}</button>`).join('')}</div><small>Çerçeve seçimi bu cihazdaki demo profiline kaydedilir.</small></div>`);
}
function chooseProfileFrame(id){if(!profileFrames.some(f=>f.id===id))return;if(wallCommit(()=>{state.me.avatarFrame=id})){closeModal();renderProfile();toast('Profil çerçeven değiştirildi.')}}

function openProfileAppearance(){
 membershipDialog(`<div class="appearance-dialog"><span class="appearance-eyebrow">SANA ÖZEL</span><h2>Profil görünümün</h2><p>Fotoğrafını ve çerçeveni buradan düzenle.</p><div class="appearance-preview">${framedProfileAvatar(state.me)}</div><div class="avatar-action-list"><button onclick="openProfilePhotoEditor()">${profileGlyph('image')}<span><b>Profil fotoğrafı</b><small>Fotoğraf ekle, değiştir veya kaldır</small></span><i>›</i></button><button onclick="openProfileFrameEditor()">${profileGlyph('frame')}<span><b>Çerçeveni seç</b><small>Profiline kendi tarzını kat</small></span><i>›</i></button></div></div>`);
}
const PlateStyles=[{id:'classic',label:'Standart',price:0},{id:'diamond',label:'Pırlanta',price:100},{id:'kiss',label:'Öpücük',price:100},{id:'named',label:'İsimli',price:100},{id:'carbon',label:'Karbon',price:100},{id:'chrome',label:'Krom',price:100}];
function plateCanName(id){return ['kiss','named','carbon','chrome'].includes(id)}
function plateStyleOwned(id){return id==='classic'||(state.ownedPlateStyles||[]).includes(id)}
function profilePlate(p,style=p.plateStyle||'classic'){
 const valid=PlateStyles.some(x=>x.id===style)?style:'classic';
 if(typeof kiyiVehiclePlate==='function')return `<span class="custom-plate shared-plate-art">${kiyiVehiclePlate({...p,plateStyle:valid})}</span>`;
 return `<span class="custom-plate plate-${valid}${valid!=='classic'?' plate-photo-frame':''}">${valid!=='classic'?`<img class="plate-frame-image" src="${valid==='kiss'?'assets/frames/kiss-custom.png':valid==='diamond'?'assets/frames/diamond-custom.jpeg':PlateArtwork[valid]}" alt="" draggable="false">`:''}<span class="custom-plate-face"><i><b>TR</b></i><strong>${esc(p.plate)}</strong></span>${valid==='kiss'?'<span class="plate-kisses" aria-hidden="true">💋</span>':''}${plateCanName(valid)?`<span class="plate-custom-name">${esc(p.plateNames?.[valid]||(valid==='named'?p.plateName:'')||'İSMİN BURAYA')}</span>`:''}</span>`;
}
function openPlateAppearance(){
 membershipDialog(`<div class="appearance-dialog appearance-fullscreen plate-gallery-dialog"><span class="appearance-eyebrow">PLAKA TASARIMI</span><h2>Plakanı özelleştir</h2><p>Standart plaka ücretsiz. Bir kez açtığın tasarımları dilediğinde kullan.</p><div class="plate-style-grid">${PlateStyles.map(s=>`<button class="plate-style-choice ${(state.me.plateStyle||'classic')===s.id?'selected':''}" onclick="choosePlateStyle('${s.id}')" aria-label="${s.label}, ${s.price?s.price+' kredi':'ücretsiz'}" aria-pressed="${(state.me.plateStyle||'classic')===s.id}">${profilePlate(state.me,s.id)}<b>${s.label}</b><small>${plateStyleOwned(s.id)?((state.me.plateStyle||'classic')===s.id?'✓ Seçili':s.price?'Kullan':'Ücretsiz'):`${s.price} ${creditCoin()}`}</small></button>`).join('')}</div><small>Öpücük, isimli, karbon ve krom plakalarda alt yazıyı kendin belirleyebilirsin. Seçimler bu cihazda saklanır.</small></div>`);
}
function choosePlateStyle(id){const style=PlateStyles.find(s=>s.id===id);if(!style)return;
 if(plateCanName(id)){membershipDialog(`<div class="appearance-dialog appearance-fullscreen"><span class="appearance-eyebrow">SANA ÖZEL PLAKA</span><h2>Plakana ismini yaz</h2><div class="name-plate-preview">${profilePlate(state.me,id)}</div><form id="plate-name-form"><label class="field">Plakanın altındaki isim<input id="plate-custom-name" maxlength="20" value="${esc(state.me.plateNames?.[id]||(id==='named'?state.me.plateName:'')||'')}" placeholder="İsmini yaz" required></label><button class="btn plate-purchase-button" type="submit">${plateStyleOwned(id)?'Kaydet ve kullan':style.price+' '+creditCoin()}</button></form></div>`);$('#plate-custom-name').oninput=e=>{document.querySelector('.name-plate-preview').innerHTML=profilePlate({...state.me,plateNames:{...state.me.plateNames,[id]:e.target.value}},id)};$('#plate-name-form').onsubmit=e=>{e.preventDefault();applyPlateStyle(id,$('#plate-custom-name').value.trim())};return}
 if(!plateStyleOwned(id)){membershipDialog(`<div class="appearance-dialog appearance-fullscreen"><span class="appearance-eyebrow">PLAKA TASARIMI</span><h2>${esc(style.label)}</h2><div class="name-plate-preview">${profilePlate(state.me,id)}</div><p>Bu tasarımı ${style.price} kredi ile bir kez açıp istediğin zaman kullanabilirsin.</p><button class="btn plate-purchase-button" onclick="applyPlateStyle('${id}')">${style.price} ${creditCoin()}</button></div>`);return}
 applyPlateStyle(id);
}
function applyPlateStyle(id,name){const style=PlateStyles.find(s=>s.id===id);if(!style)return false;const price=plateStyleOwned(id)?0:style.price;if(creditBalance()<price){toast('Bu tasarım için '+price+' kredi gerekiyor.');openCreditWallet();return false}if(plateCanName(id)&&(!name||name.length>20))return false;
 if(wallCommit(()=>{if(price){state.credits=creditBalance()-price;state.ownedPlateStyles=[...(state.ownedPlateStyles||[]),id];state.creditLedger=[...(state.creditLedger||[]),{amount:-price,label:'Plaka tasarımı · '+style.label,createdAt:Date.now()}].slice(-100)}state.me.plateStyle=id;if(plateCanName(id)){state.me.plateNames={...(state.me.plateNames||{}),[id]:name};if(id==='named')state.me.plateName=name;}})){closeModal();renderProfile();toast('Plaka tasarımın kaydedildi.');return true}return false;
}
function openCarAppearance(){membershipDialog(`<div class="appearance-dialog appearance-fullscreen car-appearance-dialog">${renderCarColors().outerHTML}</div>`);}
