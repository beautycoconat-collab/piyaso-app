/* Piyaso first launch. The entry surface is independent of the app/modal router. */
(()=>{'use strict';
const KEY='piyaso-intro-v1',DEVICE_KEY=KEY+':device';let page='welcome',slide=0,mode='login',busy=false,providers={google:null,apple:null},returnFocus=null,finishedPreview=false,authReturn={page:'welcome',slide:0};
const $=s=>document.querySelector(s);
function icon(name){const native=typeof KiyiUIIcon==='function'?KiyiUIIcon(name==='pin'?'location':name):'';if(native)return native;const paths={lock:'<rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/><path d="M12 14v3"/>',user:'<circle cx="12" cy="8" r="4"/><path d="M4 22v-3a8 8 0 0 1 16 0v3"/>',mail:'<rect x="3" y="5" width="18" height="14" rx="3"/><path d="m3 7 9 6 9-6"/>',eye:'<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',shield:'<path d="m12 2 9 4v6c0 6-9 10-9 10S3 18 3 12V6Z"/><path d="m8 12 3 3 6-7"/>'};return paths[name]?`<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths[name]}</svg>`:'';}
const E=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const guestCloud={active:false,supportActive:false};
const cloud=()=>typeof kiyiCloud==='undefined'?guestCloud:kiyiCloud;
const me=()=>typeof state==='undefined'?{}:state.me||{};
const notify=message=>typeof toast==='function'?toast(message):status(message);
let previewPlate={city:'07',letters:'PYS',number:'01'},previewColor='#0764ff',motionPaused=typeof matchMedia==='function'&&matchMedia('(prefers-reduced-motion: reduce)').matches;
let trafficFrame=0,trafficTime=0,trafficLast=0,paintTimer=0,trafficObserver=null;
let appNavigationStarted=false;const bootRoute=location.hash;
const paintPalette=[['#0764ff','Mavi'],['#8c42ff','Mor'],['#ffb000','Sarı'],['#ff27b8','Pembe'],['#24242b','Siyah'],['#c9cbd3','Gümüş']];
const guides=[
 {title:'Plakanla<br>Piyaso’ya katıl.',text:'Plakanı ekle, aracınla haritada<br>yerini al, seni kolayca tanısınlar.',art:'plate'},
 {title:'Aracını tarzına göre<br>özelleştir.',text:'Aracının rengini değiştir,<br>kendi tarzını yansıt.',art:'garage'},
 {title:'Şehirde buluş,<br>keşfet, tanış.',text:'Haritada diğer kullanıcıları gör,<br>yeni insanlarla tanış, rotanı genişlet.',art:'map'}
];
function read(key){try{return localStorage.getItem(key)}catch{return null}}
function write(key,value){try{localStorage.setItem(key,value)}catch{}}
function userKey(){return KEY+':'+(cloud().userId||'guest')}
function hasProfile(){return !!me().ownerName?.trim()&&!/^kiyi_[a-f0-9]{24}$/.test(me().username||'')}
function done(){return read(userKey())==='done'||read(DEVICE_KEY)==='done'}
function anonymous(color='#b697e8'){return `<svg viewBox="0 0 64 64" aria-hidden="true"><circle cx="32" cy="32" r="32" fill="${color}"/><circle cx="32" cy="23" r="11" fill="#fff"/><path d="M11 57c0-14 9-22 21-22s21 8 21 22" fill="#fff"/></svg>`}
function roads(){return `<svg class="entry-roads" viewBox="0 0 600 400" aria-hidden="true"><g fill="none" stroke="white" stroke-width="16" opacity=".5"><path d="M-30 284 185 215 293 244 640 90M-20 126 140 179 242 24M215 440 248 295 402 217 480-25M68-20 141 178 216 440M410 440 360 313 641 218"/></g><path d="M88 309q77-115 176-77t200-111" fill="none" stroke="#ae87e8" stroke-width="4" stroke-dasharray="6 9" stroke-linecap="round"/></svg>`}
function mapArt(){return `<div class="entry-map-art">${roads()}<div class="entry-map-zone zone-one">⌖ Konyaaltı</div><div class="entry-map-zone zone-two">⌖ Lara</div><span class="entry-person p-one">${anonymous('#a787dc')}<i></i></span><span class="entry-person p-two">${anonymous('#92b9b0')}<i></i></span><span class="entry-person p-three">${anonymous('#d7a9bb')}<i></i></span><div class="entry-main-car"><span class="entry-car-halo"></span><img src="assets/models/bmw-m4-cabrio-v1.webp" alt="Piyaso topluluğunda otomobilini keşfet"><span class="entry-car-label">${icon('car')} Senin yolun, senin topluluğun</span></div><span class="entry-map-spark">✦</span></div>`}
function garageArt(){return `<div class="entry-garage-art">${roads()}<div class="entry-art-pill">${icon('paint')} Tarzını yansıt</div><img src="assets/models/mercedes-c200-cabrio-v1.webp" alt="Kişiselleştirilebilir otomobil"><div class="entry-mini-swatches"><i style="background:#fff"></i><i style="background:#b08ce8"></i><i style="background:#ef9ebd"></i><i style="background:#9bb7d9"></i><span>+ Kaplamalar</span></div><div class="entry-mini-plate"><span>TR</span> 07 PYS 001</div></div>`}
function privacyArt(){return `<div class="entry-privacy-art">${roads()}<div class="entry-shield">${icon('shield')||'<svg viewBox="0 0 24 24"><path d="M12 2 3 6v6c0 6 9 10 9 10s9-4 9-10V6Z" fill="none" stroke="currentColor" stroke-width="1.5"/><path d="m8 12 3 3 6-7" fill="none" stroke="currentColor" stroke-width="1.7"/></svg>'}</div><div class="entry-privacy-row">${icon('pin')}<span>Konum paylaşımı<small>Sen başlatana kadar kapalı</small></span><i></i></div><span class="entry-person p-one">${anonymous('#b192dc')}</span><span class="entry-person p-three">${anonymous('#d7a9bb')}</span></div>`}
function art(which){return which==='garage'?garageArt():which==='privacy'?privacyArt():mapArt()}
function brand(){return '<span class="piyaso-entry-brand"><img src="assets/onboarding/piyaso-logo-v4.webp" alt="Piyaso" draggable="false"></span>'}
function google(){return '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="#4285F4" d="M21.6 12.23c0-.71-.06-1.39-.18-2.05H12v3.88h5.38a4.6 4.6 0 0 1-2 3.02v2.51h3.24c1.9-1.75 2.98-4.33 2.98-7.36Z"/><path fill="#34A853" d="M12 22c2.7 0 4.96-.9 6.62-2.41l-3.24-2.51c-.9.6-2.04.96-3.38.96-2.6 0-4.8-1.76-5.58-4.12H3.07v2.6A10 10 0 0 0 12 22Z"/><path fill="#FBBC05" d="M6.42 13.92a6 6 0 0 1 0-3.84v-2.6H3.07a10 10 0 0 0 0 9.04Z"/><path fill="#EA4335" d="M12 5.96c1.47 0 2.79.5 3.83 1.5l2.87-2.87A9.6 9.6 0 0 0 12 2a10 10 0 0 0-8.93 5.48l3.35 2.6C7.2 7.72 9.4 5.96 12 5.96Z"/></svg>'}
function apple(){return '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M17.3 12.5c0-2 1.6-3 1.7-3.1-1-1.5-2.6-1.7-3.2-1.7-1.4-.2-2.7.8-3.4.8-.7 0-1.8-.8-2.9-.7-1.5 0-2.9.9-3.7 2.2-1.6 2.8-.4 6.9 1.2 9.2.8 1.1 1.6 2.3 2.8 2.2 1.1 0 1.6-.7 3-.7 1.3 0 1.7.7 2.9.7 1.2 0 2-1.1 2.8-2.2.9-1.3 1.3-2.6 1.3-2.7-.1 0-2.5-1-2.5-4Zm-2.2-6.3c.6-.8 1.1-1.9 1-3-.9 0-2 .6-2.7 1.4-.6.7-1.2 1.9-1 2.9 1 .1 2-.5 2.7-1.3Z"/></svg>'}
function providerButton(id,label,svg){const enabled=providers[id]===true;return `<button class="entry-provider ${id}" data-entry-provider="${id}" type="button" ${enabled?'':'disabled'} onclick="PiyasoEntry.provider('${id}',this)">${svg}<span>${label}</span>${enabled?'':`<small>${providers[id]===null?'Kontrol ediliyor':'Yakında'}</small>`}</button>`}

function pin(extra=''){return `<span class="dream-pin ${extra}" aria-hidden="true"><img src="assets/onboarding/location-pin-3d.svg" alt="" draggable="false"></span>`}
// A fixed supplied road scene with independent animated actors.
function welcomeRoad(){return '<img class="dream-welcome-road" src="assets/welcome-story/coastal-road-v1.webp" alt="" draggable="false">'}

function dreamDots(current){return `<div class="dream-dots" role="group" aria-label="Tanıtım sayfaları">${['Karşılama',...guides.map(g=>g.title.replace(/<br>/g,' '))].map((g,i)=>`<button type="button" aria-label="${i+1}. sayfa: ${g}" aria-current="${i===current?'step':'false'}" onclick="${i===0?'PiyasoEntry.open()':`PiyasoEntry.guide(${i-1})`}"></button>`).join('')}</div>`}
function dreamArrowIcon(){return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12h18m-8-8 8 8-8 8"/></svg>'}
function dreamArrow(action='PiyasoEntry.next()',label='Sonraki sayfa'){return `<button type="button" class="dream-next" aria-label="${label}" onclick="${action}">${dreamArrowIcon()}</button>`}
function plateText(){return `${previewPlate.city||'07'} ${previewPlate.letters||'PYS'} ${previewPlate.number||'01'}`}
function dreamPlate(){return `<div class="dream-supplied-plate"><img src="assets/onboarding/license-plate-v2.webp" alt="TR 07 PYS 01 plaka görseli"></div>`}
const trafficRoutes=[
 {from:[100,899],to:[780,609],angle:67,seconds:23,offset:.3},
 {from:[780,629],to:[100,919],angle:247,seconds:27,offset:.22},
 {from:[90,512],to:[780,249],angle:69,seconds:29,offset:.36},
 {from:[780,269],to:[90,532],angle:249,seconds:25,offset:.64}
];
function dreamMap(){
 const people=[{id:'intro-one',ownerName:'33 AYC 048',avatar:'assets/owner-33-ayc-048.jpeg',paint:'#ffffff'},{id:'intro-two',ownerName:'07 F 7755',avatar:'assets/owner-07-f-7755.jpeg',paint:'#ffffff'},{id:'intro-three',ownerName:'Deniz',avatar:'assets/fenomen-1782.jpeg',paint:'#ffffff'},{id:'intro-four',ownerName:'Ege',avatar:'assets/fenomen-1783.jpeg',paint:'#3b4347'}];
 return `<div id="dream-moving-map" class="dream-moving-map" role="img" aria-label="Haritada hareket eden araçlar ve profil fotoğrafları"><img class="dream-city-base" src="assets/onboarding/city-map-v2.webp" alt="" draggable="false"><div class="dream-traffic-layer">${people.map((p,i)=>{const r=trafficRoutes[i],marker=`<div class="car-owner-marker"><div class="map-owner-bubble"><img class="map-owner-photo" src="${p.avatar}" alt=""></div><img class="top-car${p.paint==='#3b4347'?' dark-car':''}" src="assets/map-car.png" style="transform:rotate(${r.angle}deg)" alt=""></div>`;return `<div class="dream-traffic" data-traffic="${i}"><div class="dream-traffic-marker">${marker}</div></div>`}).join('')}</div></div><button class="dream-motion-toggle" type="button" aria-label="${motionPaused?'Harita hareketini başlat':'Harita hareketini durdur'}" aria-pressed="${motionPaused}" onclick="PiyasoEntry.motion(this)">${motionPaused?'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="m9 5 11 7-11 7Z" fill="currentColor"/></svg>':'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5v14m8-14v14" fill="none" stroke="currentColor" stroke-width="3"/></svg>'}</button>`;
}
function stopTraffic(){if(trafficFrame)cancelAnimationFrame(trafficFrame);trafficFrame=0;trafficLast=0;trafficObserver?.disconnect();trafficObserver=null;}
function startTraffic(){
 stopTraffic();const stage=$('#dream-moving-map');if(!stage)return;
 const nodes=[...stage.querySelectorAll('[data-traffic]')];let scale=1,left=0,top=0,lastDraw=0;
 const measure=()=>{const width=stage.clientWidth,height=stage.clientHeight;scale=Math.max(width/864,height/1536);left=(width-864*scale)/2;top=(height-1536*scale)/2;};
 measure();if(typeof ResizeObserver==='function'){trafficObserver=new ResizeObserver(measure);trafficObserver.observe(stage);}
 function draw(){
  nodes.forEach((node,i)=>{const route=trafficRoutes[i],progress=(route.offset+trafficTime/1000/route.seconds)%1,x=route.from[0]+(route.to[0]-route.from[0])*progress,y=route.from[1]+(route.to[1]-route.from[1])*progress;node.style.transform=`translate3d(${(left+x*scale-32).toFixed(2)}px,${(top+y*scale-81).toFixed(2)}px,0)`;});
 }
 function frame(now){if(!stage.isConnected){stopTraffic();return;}if(trafficLast&&!motionPaused)trafficTime+=Math.min(now-trafficLast,80);trafficLast=now;if(now-lastDraw>=32&&!motionPaused&&!document.hidden){draw();lastDraw=now;}trafficFrame=requestAnimationFrame(frame);}
 draw();trafficFrame=requestAnimationFrame(frame);
}

function dreamCar(){const person={vehicleModel:'vw-golf',plate:plateText(),plateStyle:'classic'};return window.PiyasoBoot?.carArt|| (typeof kiyiSedanShowcase==='function'?kiyiSedanShowcase(person,previewColor):'<img src="assets/models/vw-golf-v1.webp" alt="Araç kişiselleştirme önizlemesi">')}
function dreamOptions(){return `<div class="dream-swatches" role="group" aria-label="Araç rengi">${paintPalette.map(([c,n])=>`<button type="button" style="--swatch:${c}" aria-label="${n}" aria-pressed="${previewColor===c}" onclick="PiyasoEntry.customize('color','${c}')"></button>`).join('')}</div>`}
function dreamControls(){return `<div class="dream-customizer"><div class="dream-tabs" role="group" aria-label="Kişiselleştirme seçenekleri">${[['Renk','paint'],['Jant','wheel'],['Aksesuar','car'],['Plaka','plate']].map(([name,ic],i)=>`<button type="button" aria-pressed="${i===0}" ${i?'disabled aria-disabled="true"':''}>${icon(ic)}<span>${name}</span></button>`).join('')}</div><div class="dream-options">${dreamOptions()}</div><span class="dream-current-paint sr-only">${paintPalette.find(([c])=>c===previewColor)?.[1]||''}</span><p class="dream-preview-note">Tarzını dene, aracını garajında kaydet.</p></div>`}

function stopPaintCycle(){clearInterval(paintTimer);paintTimer=0;}
function updatePaintPreview(){
 const stage=$('#piyaso-entry .dream-garage .dream-car-stage');if(!stage)return;
 const filter=stage.querySelector('filter[id$="-paint"]');
 if(filter){['R','G','B'].forEach((channel,i)=>filter.querySelector('feFunc'+channel)?.setAttribute('slope',(parseInt(previewColor.slice(1+i*2,3+i*2),16)/255*1.02).toFixed(4)));}
 else stage.innerHTML=dreamCar();
 const color=paintPalette.find(([c])=>c===previewColor);
 const name=$('#piyaso-entry .dream-current-paint');if(name)name.textContent=color?.[1]||'';
 document.querySelectorAll('#piyaso-entry .dream-swatches button').forEach((button,i)=>button.setAttribute('aria-pressed',String(paintPalette[i][0]===previewColor)));
}
function startPaintCycle(){
 stopPaintCycle();if(!$('#piyaso-entry .dream-garage'))return;updatePaintPreview();
 paintTimer=setInterval(()=>{
  if(!$('#piyaso-entry .dream-garage')){stopPaintCycle();return;}
  if(document.hidden)return;
  const index=paintPalette.findIndex(([c])=>c===previewColor);
  previewColor=paintPalette[(index+1)%paintPalette.length][0];updatePaintPreview();
 },400);
}

function welcome(){return `<section class="dream-welcome dream-welcome-story">${welcomeRoad()}<div class="story-stage" role="img" aria-label="Siyah ve beyaz araçlar sahil yolunda karşılaşır. Siyah araç korna çalıp lale gönderir. Önce kız, ardından siyah araçtaki erkek gülümser."><div class="story-world"><div class="story-actor story-black"><img class="story-car" src="assets/welcome-story/black-car-v1.webp" alt="" draggable="false"><span class="story-horn"></span><img class="story-boy" src="assets/welcome-story/boy-smile-v1.webp" alt="" draggable="false"></div><div class="story-actor story-white"><img class="story-car" src="assets/welcome-story/white-car-v1.webp" alt="" draggable="false"><img class="story-girl" src="assets/welcome-story/smile-v1.webp" alt="" draggable="false"><span class="story-heart" aria-hidden="true">♡</span></div><div class="story-tulip"><img src="assets/welcome-story/tulip-v1.webp" alt="" draggable="false"></div></div></div><div class="story-tools"><div class="story-playback-tools"><button type="button" data-story-replay aria-label="Hikâyeyi yeniden oynat"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 11a9 9 0 1 1 2 7M3 4v7h7"/></svg></button><button type="button" data-story-pause aria-label="Hikâyeyi duraklat" aria-pressed="false"><svg viewBox="0 0 24 24" aria-hidden="true"><path class="story-pause-glyph" d="M8 5v14M16 5v14"/><path class="story-play-glyph" d="m8 5 11 7-11 7Z"/></svg></button></div><button type="button" data-story-sound aria-pressed="false" aria-label="Sesi kapat"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m11 4-6 5H2v6h3l6 5ZM15 8a6 6 0 0 1 0 8M18 5a10 10 0 0 1 0 14"/></svg><span>Ses</span></button></div><div class="dream-welcome-center"><div class="dream-welcome-logo-group"><h1 class="dream-uploaded-logo"><img src="assets/onboarding/piyaso-logo-v4.webp" alt="Piyaso"></h1></div><p class="story-tagline"><span>Arabana özel</span><span>sosyal medya hesabı</span></p></div><div class="dream-welcome-bottom" inert><button class="dream-primary" onclick="PiyasoEntry.tour()">Hadi Başlayalım ${dreamArrowIcon()}</button>${dreamDots(0)}</div></section>`}

function emailPage(){const signup=mode==='signup',recover=mode==='recover';return `<div class="entry-auth-layout"><aside class="entry-auth-visual entry-auth-map">${dreamMap()}</aside><section class="entry-form-content entry-auth-card" aria-label="${recover?'Şifre yenileme':signup?'Hesap oluştur':'Giriş yap'}">${recover?'<h1>Şifreni yenileyelim.</h1><p>E-posta adresine bir sıfırlama bağlantısı gönderelim.</p>':`<h1 class="sr-only">${signup?'Hesap oluştur':'Hesabına giriş yap'}</h1><div class="entry-auth-tabs" role="group" aria-label="Hesap işlemi"><button type="button" aria-pressed="${!signup}" onclick="PiyasoEntry.email('login')">Giriş Yap</button><button type="button" aria-pressed="${signup}" onclick="PiyasoEntry.email('signup')">Hesap Oluştur</button></div>`}<form id="piyaso-entry-auth"><label class="entry-auth-field"><span class="sr-only">E-posta adresin</span><span class="entry-field-icon" aria-hidden="true">${icon('mail')}</span><input type="email" name="email" autocomplete="email" maxlength="254" placeholder="E-posta adresi" required></label>${recover?'':`<label class="entry-auth-field"><span class="sr-only">Şifren</span><div class="entry-password"><span class="entry-field-icon" aria-hidden="true">${icon('lock')}</span><input type="password" name="password" autocomplete="${signup?'new-password':'current-password'}" minlength="8" maxlength="128" placeholder="${signup?'Şifre (en az 8 karakter)':'Şifre'}" required><button type="button" aria-label="Şifreyi göster" aria-pressed="false" onclick="PiyasoEntry.password(this)">${icon('eye')}</button></div></label>`}${signup?'<label class="entry-consent"><input name="consent" type="checkbox" required><span><a href="terms.html" target="_blank" rel="noopener">Kullanım koşullarını</a> okudum ve kabul ediyorum. <a href="privacy.html" target="_blank" rel="noopener">Gizlilik politikasını</a> inceleyebilirim.</span></label>':!recover?`<div class="entry-auth-actions"><button type="button" class="entry-forgot" onclick="PiyasoEntry.email('recover')">Şifremi unuttum</button></div>`:''}<p class="entry-status" role="status" aria-live="polite"></p><button class="entry-primary" type="submit">${recover?'Bağlantıyı gönder':signup?'Hesap Oluştur':'Giriş Yap'} ${dreamArrowIcon()}</button></form>${recover?`<button class="entry-text" onclick="PiyasoEntry.email('login')">Girişe dön</button>`:`<div class="entry-login-options"><span class="entry-divider">veya</span><div class="entry-social-row">${providerButton('apple','Apple',apple())}${providerButton('google','Google',google())}</div></div>`}<p class="entry-auth-legal"><a href="terms.html" target="_blank" rel="noopener">Kullanım Koşulları</a><span> · </span><a href="privacy.html" target="_blank" rel="noopener">Gizlilik Politikası</a></p></section></div>`}

function guidePage(){const g=guides[slide];let illustration=g.art==='map'?dreamMap():g.art==='plate'?`${pin('plate-one')}${pin('plate-two')}${pin('plate-three')}<div class="dream-plate-rays" aria-hidden="true">✦</div>${dreamPlate()}`:`<div class="dream-car-stage">${dreamCar()}</div>${pin('garage-pin')}`;return `<section class="dream-guide dream-${g.art}"><div class="dream-copy"><h1>${g.title}</h1><p>${g.text}</p></div><div class="dream-illustration">${illustration}</div><div class="dream-guide-bottom">${g.art==='garage'?dreamControls():''}<div class="dream-navigation">${dreamDots(slide+1)}${g.art==='plate'?dreamArrow('PiyasoEntry.next()','Devam et'):dreamArrow('PiyasoEntry.next()',slide===guides.length-1?(cloud().active?'Devam et':'Giriş yap'):'Sonraki sayfa')}</div></div></section>`}
function profilePage(){const p=me(),automatic=/^kiyi_[a-f0-9]{24}$/.test(p.username||'');return `<section class="entry-profile"><div class="entry-profile-intro"><span class="entry-profile-avatar">${anonymous()}</span><span class="entry-eyebrow">SON BİR DOKUNUŞ</span><h1>Seni nasıl tanısınlar?</h1><p>Profilini hazırla. Aracını ve fotoğraflarını<br>birazdan garajına ekleyebilirsin.</p></div><form id="piyaso-entry-profile"><label>Profil adın<input name="name" value="${E(p.ownerName||'')}" placeholder="Adın veya takma adın" autocomplete="nickname" minlength="2" maxlength="60" required></label><label>Kullanıcı adın<div class="entry-username"><span>@</span><input name="username" value="${E(automatic?'':p.username||'')}" placeholder="kullaniciadin" pattern="[a-z0-9_.]{3,30}" minlength="3" maxlength="30" autocomplete="username" autocapitalize="none" spellcheck="false" required></div><small>Küçük harf, rakam, nokta ve alt çizgi kullanabilirsin.</small></label><label>Şehrin / semtin <span class="entry-optional">isteğe bağlı</span><input name="area" value="${E(p.area||'')}" placeholder="Antalya, Konyaaltı" maxlength="60" autocomplete="address-level2"></label><p class="entry-private-note">${icon('pin')} Bu alan canlı konumunu paylaşmaz.</p><p class="entry-status" role="status" aria-live="polite"></p><button class="entry-primary" type="submit">Profilimi hazırla ${icon('next')}</button></form><button class="entry-text" onclick="PiyasoEntry.finish()">Daha sonra tamamla</button></section>`}

function ensureRoot(){let root=$('#piyaso-entry');if(!root){root=document.createElement('div');root.id='piyaso-entry';root.setAttribute('role','dialog');root.setAttribute('aria-modal','true');root.setAttribute('aria-label','Piyaso karşılama ve giriş');document.body.append(root);returnFocus=document.activeElement;}document.documentElement.classList.add('piyaso-entry-open');for(const el of document.body.children)if(el!==root&&el.id!=='toast'){if(!el.hasAttribute('inert')){el.setAttribute('inert','');el.dataset.entryInert='true';}}return root;}
let renderSerial=0;
function render(direction=''){if(page==='welcome')window.PiyasoWelcome?.prepareAudio?.();window.PiyasoWelcome?.suspend();stopTraffic();stopPaintCycle();const root=ensureRoot(),ticket=++renderSerial;const dream=page==='welcome'||page==='guide';const content=page==='welcome'?welcome():page==='email'?emailPage():page==='guide'?guidePage():profilePage();const commit=()=>{if(ticket!==renderSerial||root.isConnected===false)return;root.removeAttribute('aria-busy');root.dataset.transition=direction;root.dataset.page=page;root.dataset.mode=mode;root.dataset.scene=page==='guide'?guides[slide].art:page;const header=dream?`<header class="dream-header"><span></span><button class="dream-login" onclick="${cloud().active?'PiyasoEntry.finish()':"PiyasoEntry.email('login')"}">${cloud().active?'Hesabıma dön':'Giriş yap'}</button></header>`:`<header class="entry-header"><button class="entry-back" aria-label="Geri" onclick="PiyasoEntry.back()">${icon('back')}</button>${brand()}<button class="entry-skip" onclick="PiyasoEntry.skip()">Atla</button></header>`;root.innerHTML=`<div class="piyaso-entry-shell ${dream?'dream-shell':page==='email'?'entry-auth-shell':''}">${header}<div class="entry-screen" tabindex="-1">${content}</div></div>`;root.querySelector('.entry-screen').focus({preventScroll:true});wire();window.PiyasoBoot?.revealEntry();window.PiyasoBoot?.warmNext(root.dataset.scene);};if(window.PiyasoBoot){root.setAttribute('aria-busy','true');window.PiyasoBoot.sceneReady(page==='guide'?guides[slide].art:page).then(commit).catch(()=>{root.removeAttribute('aria-busy');status('Görseller yüklenemedi. Bağlantını kontrol edip yeniden dene.');});}else commit();}
// Swipe only between the welcome and guide slides; form and customizer controls keep their gestures.
function moveIntro(delta){
 if(page!=='welcome'&&page!=='guide')return;
 const current=page==='welcome'?0:slide+1,next=current+delta;
 if(next===guides.length+1&&delta>0){completeIntro();return;}
 if(next<0||next>guides.length)return;
 page=next===0?'welcome':'guide';if(next)slide=next-1;
 render(delta>0?'next':'previous');
}
function wireIntroSwipe(){
 if(page!=='welcome'&&page!=='guide')return;
 const screen=$('#piyaso-entry .entry-screen');let gesture=null;
 const interactive=target=>target.closest('button,a,input,select,textarea,.dream-customizer,[contenteditable]');
 const clear=()=>{gesture=null;screen.style.removeProperty('transform');screen.classList.remove('dream-dragging');};
 screen.addEventListener('pointerdown',event=>{
  if(!event.isPrimary||event.button!==0||interactive(event.target))return;
  gesture={id:event.pointerId,x:event.clientX,y:event.clientY};
  screen.setPointerCapture(event.pointerId);
 });
 screen.addEventListener('pointermove',event=>{
  if(!gesture||gesture.id!==event.pointerId)return;
  const dx=event.clientX-gesture.x,dy=event.clientY-gesture.y;
  if(Math.abs(dy)>Math.abs(dx)&&Math.abs(dy)>12){clear();return;}
  if(Math.abs(dx)>10){screen.classList.add('dream-dragging');screen.style.transform=`translateX(${Math.max(-45,Math.min(45,dx*.22))}px)`;}
 });
 screen.addEventListener('pointerup',event=>{
  if(!gesture||gesture.id!==event.pointerId)return;
  const dx=event.clientX-gesture.x,dy=event.clientY-gesture.y;
  clear();
  if(Math.abs(dx)>Math.max(48,screen.clientWidth*.14)&&Math.abs(dx)>Math.abs(dy)*1.4)moveIntro(dx<0?1:-1);
 });
 screen.addEventListener('pointercancel',clear);
 screen.addEventListener('keydown',event=>{
  if(interactive(event.target))return;
  if(event.key==='ArrowRight'||event.key==='ArrowLeft'){event.preventDefault();moveIntro(event.key==='ArrowRight'?1:-1);}
 });
}
function status(message){const s=$('#piyaso-entry .entry-status');if(s)s.textContent=message;}
function wire(){if(page==='welcome')window.PiyasoWelcome?.mount($('#piyaso-entry'));else window.PiyasoWelcome?.leavePage();startTraffic();startPaintCycle();wireIntroSwipe();const form=$('#piyaso-entry-auth');if(form)form.onsubmit=async e=>{e.preventDefault();if(busy||!form.reportValidity())return;busy=true;const b=form.querySelector('[type=submit]'),data=Object.fromEntries(new FormData(form));b.disabled=true;status('Bağlanıyor…');try{await window.PiyasoBoot?.loadApp();if(mode==='recover'){await PiyasoAuth.recover(data.email);status('Uygun bir hesap varsa sıfırlama bağlantısı e-postana gönderilir. Gelen kutunu ve spam klasörünü kontrol et.');}else{const result=await PiyasoAuth.authenticate(mode,data);if(result.verificationRequired){form.reset();status('Hesabını doğrulamak için e-postandaki bağlantıyı aç. Ardından Giriş yap sekmesinden devam edebilirsin.');}else if($('#piyaso-entry')){if(hasProfile()){finish();}else{page='guide';slide=0;render();}}}}catch(error){status(error.message);}finally{busy=false;b.disabled=false;}};
 const profile=$('#piyaso-entry-profile');if(profile)profile.onsubmit=async e=>{e.preventDefault();if(busy||!profile.reportValidity())return;busy=true;const b=profile.querySelector('[type=submit]');b.disabled=true;status('Profilin hazırlanıyor…');try{await window.PiyasoBoot?.loadApp();await PiyasoAuth.completeProfile(Object.fromEntries(new FormData(profile)));finish();}catch(error){status(error.message);b.disabled=false;}finally{busy=false;}};
}
function dismiss(){window.PiyasoWelcome?.stop();stopTraffic();stopPaintCycle();const root=$('#piyaso-entry');if(root)root.remove();document.documentElement.classList.remove('piyaso-entry-open');for(const el of document.querySelectorAll('[data-entry-inert="true"]')){el.removeAttribute('inert');delete el.dataset.entryInert;}}
function finish(){if(window.PiyasoBoot&&!window.PiyasoBoot.ready){return window.PiyasoBoot.loadApp().then(finish).catch(()=>notify('Uygulama yüklenemedi. Yeniden dene.'));}write(userKey(),'done');write(DEVICE_KEY,'done');finishedPreview=true;dismiss();const query=new URLSearchParams(location.search);if(query.has('onboarding')){query.delete('onboarding');history.replaceState(null,'',location.pathname+(query.size?'?'+query:'')+(location.hash||''));}if(!location.hash)location.hash=cloud().active?'profile':'map';else renderAppAfterEntry();returnFocus?.focus?.({preventScroll:true});}
const renderAppAfterEntry=()=>{if(typeof window.render==='function')window.render();};
function open(next='welcome'){if(typeof closeModal==='function')closeModal();busy=false;page=next;render();if(next==='welcome'||next==='email')loadProviders();}
async function loadProviders(){if(page!=='email')return;try{await window.PiyasoBoot?.loadApp();providers=await PiyasoAuth.providers();}catch{providers={google:false,apple:false};}if((page==='welcome'||page==='email')&&$('#piyaso-entry')){const options=$('.entry-login-options');if(options){options.querySelectorAll('[data-entry-provider]').forEach(b=>{const id=b.dataset.entryProvider;b.outerHTML=providerButton(id,id==='google'?'Google':'Apple',id==='google'?google():apple());});}}}
function completeIntro(){
 if(cloud().active){if(hasProfile())finish();else{page='profile';render();}}
 else window.PiyasoEntry.email('login');
}
window.PiyasoEntry={open,email(next='login'){if(busy)return;if(page!=='email')authReturn={page,slide};mode=next;open('email');},tour(){slide=0;page='guide';render('next');},guide(i){if(i<0||i>=guides.length)return;slide=i;page='guide';render();},next(){if(slide<guides.length-1){slide++;render('next');}else completeIntro();},skip(){if(page==='email'||page==='profile')finish();else completeIntro();},back(){
 if(busy)return;
 if(page==='email'){if(mode!=='login'){mode='login';render();return;}page=authReturn.page;slide=authReturn.slide;render('previous');}
 else if(page==='guide'&&slide>0){slide--;render('previous');}
 else if(page==='profile'){page='guide';slide=guides.length-1;render('previous');}
 else{page='welcome';render('previous');loadProviders();}
},finish,

 customize(kind,value){if(kind!=='color'||!paintPalette.some(([c])=>c===value))return;previewColor=value;updatePaintPreview();startPaintCycle();},
 motion(button){motionPaused=!motionPaused;button.setAttribute('aria-pressed',String(motionPaused));button.setAttribute('aria-label',motionPaused?'Harita hareketini başlat':'Harita hareketini durdur');button.innerHTML=motionPaused?'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="m9 5 11 7-11 7Z" fill="currentColor"/></svg>':'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5v14m8-14v14" fill="none" stroke="currentColor" stroke-width="3"/></svg>';},
 password(button){const input=button.parentElement.querySelector('input'),visible=input.type==='password';input.type=visible?'text':'password';button.setAttribute('aria-pressed',String(visible));button.setAttribute('aria-label',visible?'Şifreyi gizle':'Şifreyi göster');},
 async provider(id,button){if(busy)return;busy=true;button.disabled=true;try{await PiyasoAuth.signInProvider(id);}catch(error){busy=false;button.disabled=false;notify(error.message);}}
};
let appHooksInstalled=false;
function installAppHooks(){if(appHooksInstalled)return;appHooksInstalled=true;
const originalAccount=window.openKiyiAccount;window.openKiyiAccount=function(next='login'){if(cloud().supportActive)return originalAccount(next);return PiyasoEntry.email(next);};
const beforeProfile=window.renderProfile;window.renderProfile=function(...args){const out=beforeProfile(...args);$('#kiyi-account-card')?.remove();return out;};
}
if(!window.PiyasoBoot||window.PiyasoBoot.ready)installAppHooks();
window.addEventListener('piyaso:app-ready',()=>{installAppHooks();checkAccount();});
window.addEventListener('kiyi:account-restricted',()=>{busy=false;dismiss();});
window.addEventListener('piyaso:auth-error',e=>{const message=e.detail?.message||'Giriş tamamlanamadı. Yeniden dene.';if(finishedPreview||appNavigationStarted||!$('#piyaso-entry')){notify(message);return;}open('email');status(message);});
window.addEventListener('hashchange',()=>{if(!$('#piyaso-entry'))appNavigationStarted=true;});
document.addEventListener('keydown',e=>{const root=$('#piyaso-entry');if(!root)return;if(e.key==='Escape'){e.preventDefault();return;}if(e.key!=='Tab')return;const items=[...root.querySelectorAll('button:not([disabled]),a[href],input:not([disabled])')].filter(el=>el.getClientRects().length);if(!items.length)return;const first=items[0],last=items.at(-1);if(e.shiftKey&&(document.activeElement===first||!root.contains(document.activeElement))){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}});
async function checkAccount(){
 await PiyasoAuth.ready;
 if(finishedPreview||appNavigationStarted||location.hash!==bootRoute||cloud().restricted||new URLSearchParams(location.search).get('onboarding')==='1')return;
 if(cloud().active){
  if(hasProfile()){if($('#piyaso-entry'))finish();}
  else if(!done()){page='profile';render();}
 }else if(!done()&&!$('#piyaso-entry'))open();
}
document.addEventListener('DOMContentLoaded',async()=>{
 const forced=new URLSearchParams(location.search).get('onboarding')==='1';
 if(forced){open();return;}
 if(!cloud().supportActive&&!done())open();
 if(window.PiyasoBoot){
  if(done()||read('kiyi-supabase-session')||/[#&](?:access_token|error_description)=/.test(location.hash)||new URLSearchParams(location.search).has('code'))window.PiyasoBoot.loadApp().then(()=>{if(!$('#piyaso-entry'))window.PiyasoBoot.revealApp();}).catch(()=>notify('Uygulama yüklenemedi. Yeniden dene.'));
  return;
 }
 await checkAccount();
});
})();
