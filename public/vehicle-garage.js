/* One profile entry point. Paid paint/plate operations retain their existing server handlers. */
let kiyiGarageWrapPreview=null,kiyiGarageSaving=false,kiyiGaragePlatePreview=null;
let kiyiGarageRimPreview=null,kiyiGarageTab='plate',kiyiGaragePlateZoom=true,kiyiGarageRimZoom=true;
let kiyiGarageAccessoryPreview={window:null,roof:null,text:'Piyaso'};
function kiyiGaragePerson(){const p=kiyiGaragePlatePreview?{...state.me,plateStyle:kiyiGaragePlatePreview.id,plateNames:{...state.me.plateNames,[kiyiGaragePlatePreview.id]:kiyiGaragePlatePreview.name}}:{...state.me};return {...p,vehicleRim:kiyiGarageRimPreview,vehicleAccessories:{...kiyiGarageAccessoryPreview}};}
function kiyiGaragePaint(){return typeof pendingCarColor==='string'&&/^#[0-9a-f]{6}$/i.test(pendingCarColor)?pendingCarColor:activeCarColor();}
function kiyiBlueDiamond(){return '<svg class="blue-diamond" viewBox="0 0 36 32" aria-hidden="true"><path d="m8 2 20 0 8 10-18 20L0 12Z" fill="#36bff0"/><path d="M8 2h20L18 12 0 12Z" fill="#a6eeff"/><path d="m8 2 10 10L28 2M0 12h36L18 32Z" fill="none" stroke="#dcfbff" stroke-width="1.2"/><path d="m18 12 18 0-18 20Z" fill="#087cc3"/><path d="M8 2h7L8 10H2Z" fill="#fff" opacity=".7"/></svg>';}
function openKiyiDiamondWallet(){toast('Mavi elmas yükleme ve satın alma henüz aktif değil.');return false;}
function kiyiGarageWallet(){return `<div class="garage-wallets"><div class="garage-blue-wallet"><button type="button" onclick="openKiyiDiamondWallet()" aria-label="Mavi elmas bakiyesi">${kiyiBlueDiamond()}<b>0</b></button><button type="button" onclick="openKiyiDiamondWallet()" aria-label="Mavi elmas yükle">+</button></div></div>`;}
function kiyiGarageCurrency(body){if(!body)return;body.querySelectorAll('.gift-gold-coin').forEach(el=>el.outerHTML=kiyiBlueDiamond());body.querySelectorAll('[aria-label]').forEach(el=>{const label=el.getAttribute('aria-label');if(label?.includes('kredi'))el.setAttribute('aria-label',label.replaceAll('kredi','mavi elmas'));});const paid=body.querySelector('.car-inline-unlock');if(paid)paid.remove();}
function kiyiGarageArt(tab=kiyiGarageTab){const person={...kiyiGaragePerson(),...(kiyiGarageHeroModel?{vehicleModel:kiyiGarageHeroModel}:{})};let art=kiyiSedanShowcase(person,kiyiGaragePaint(),kiyiGarageWrapPreview);const m=kiyiVehicleModel(person)||KiyiLegacyVehicle;art=kiyiGarageFitPlate(art,person,m);if(tab==='rims'&&kiyiGarageRimZoom){const rims=KiyiWrapFits[m.id].rims,left=Math.min(...rims.map(([x,y,rx])=>x-rx))-105,right=Math.max(...rims.map(([x,y,rx])=>x+rx))+65,bottom=Math.max(...rims.map(([x,y,rx,ry])=>y+ry))+50,w=right-left,h=w*740/1536;return art.replace(/viewBox="[^"]+"/,`viewBox="${left} ${bottom-h} ${w} ${h}"`);}if(tab!=='plate'||!kiyiGaragePlateZoom)return art;const [x,y,w,h]=m.plate,zoomWidth=Math.max(500,Math.min(850,w*2.65)),zoomHeight=zoomWidth*740/1536;return art.replace(/viewBox="[^"]+"/,`viewBox="${Math.max(0,x+w/2-zoomWidth/2)} ${y+h/2-zoomHeight/2} ${zoomWidth} ${zoomHeight}"`);}
function toggleKiyiRimZoom(){kiyiGarageRimZoom=!kiyiGarageRimZoom;const body=document.querySelector('.vehicle-garage');if(!body)return false;body.querySelector('.car-paint-display').innerHTML=kiyiGarageArt();body.classList.toggle('garage-rim-zoomed',kiyiGarageRimZoom);const button=body.querySelector('.garage-zoom-button');if(button){button.textContent=kiyiGarageRimZoom?'Aracın tamamı':'Jantlara yaklaş';button.setAttribute('aria-pressed',String(kiyiGarageRimZoom));}return true;}

function toggleKiyiPlateZoom(){kiyiGaragePlateZoom=!kiyiGaragePlateZoom;const body=document.querySelector('.vehicle-garage');if(!body)return false;body.querySelector('.car-paint-display').innerHTML=kiyiGarageArt();body.classList.toggle('garage-plate-zoomed',kiyiGaragePlateZoom);const button=body.querySelector('.garage-zoom-button');if(button){button.textContent=kiyiGaragePlateZoom?'Aracın tamamı':'Plakaya yaklaş';button.setAttribute('aria-pressed',String(kiyiGaragePlateZoom));}return true;}

const kiyiGaragePlateEditor=openPlateAppearance;
function garageSymbol(name){if(typeof KiyiUIIcon==='function')return KiyiUIIcon(name);const paths={car:'<path d="m5 17-1 3m15-3 1 3M5 6l-2 6v5h18v-5l-2-6ZM3 12h18M7 15h1m8 0h1"/>',plate:'<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M6 9v6m4-5h7m-7 4h7"/>',paint:'<rect x="3" y="3" width="16" height="6" rx="2"/><path d="M19 6h2v6H11v3m-2 0h4v6H9Z"/>',wheel:'<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3"/><path d="m12 3 0 6m9 3h-6m-3 9v-6m-9-3h6m-3-6 4 4m8-4-4 4m4 8-4-4m-8 4 4-4"/>',edit:'<path d="m16 3 5 5L9 20l-6 1 1-6ZM13 6l5 5"/>',search:'<circle cx="10" cy="10" r="7"/><path d="m15 15 6 6"/>',filter:'<path d="M3 4h18l-7 8v7l-4 2v-9Z"/>',back:'<path d="m15 5-7 7 7 7"/>',next:'<path d="m9 5 7 7-7 7"/>',check:'<path d="m5 12 4 4L19 6"/>',bike:'<circle cx="5" cy="17" r="4"/><circle cx="19" cy="17" r="4"/><path d="m5 17 5-9 5 9h4l-5-13h-3m-4 4h7"/>',crown:'<path d="m3 6 5 4 4-7 4 7 5-4-2 13H5Z"/>'};return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths[name]||paths.car}</svg>`;}
function garageModelParts(m){const name=m?.name||state.me.car||'Aracın';const brand=['Mercedes-Benz','Alfa Romeo','Land Rover'].find(b=>name.startsWith(b))||name.split(' ')[0];return {brand,model:name.slice(brand.length).trim()||name};}
let kiyiGarageHeroModel=null;
function kiyiGaragePreview(tab=kiyiGarageTab){const m=kiyiVehicleModel(state.me)||KiyiLegacyVehicle,parts=garageModelParts(m);return `<div class="car-color-preview garage-shared-preview"><div class="car-paint-display">${kiyiGarageArt(tab)}</div><button class="garage-hero-prev" aria-label="Önceki modeli önizle" onclick="cycleKiyiGaragePreview(-1)">${garageSymbol('back')}</button><button class="garage-hero-next" aria-label="Sonraki modeli önizle" onclick="cycleKiyiGaragePreview(1)">${garageSymbol('next')}</button><div class="garage-hero-dots" aria-hidden="true"><i class="active"></i><i></i><i></i></div><span class="garage-hero-count">${Math.max(0,KiyiVehicleModels.findIndex(x=>x.id===m.id))+1} / ${KiyiVehicleModels.length}</span>${tab==='rims'?`<button type="button" class="garage-zoom-button" aria-pressed="${kiyiGarageRimZoom}" onclick="toggleKiyiRimZoom()">${kiyiGarageRimZoom?'Aracın tamamı':'Jantlara yaklaş'}</button>`:tab==='plate'?`<button type="button" class="garage-zoom-button" aria-pressed="${kiyiGaragePlateZoom}" onclick="toggleKiyiPlateZoom()">${kiyiGaragePlateZoom?'Aracın tamamı':'Plakaya yaklaş'}</button>`:''}</div>`;}
/* Garage-only preview navigation: cycling never purchases or saves an option. */
let kiyiGarageOptionCursor={};
function kiyiGarageOptions(tab=kiyiGarageTab){
 if(tab==='plate')return PlateStyles.map(p=>({key:p.id,id:p.id,type:'plate',label:p.label}));
 if(tab==='finish')return [...CarColors.map(c=>({key:'color:'+c.id,id:c.id,type:'color',label:c.name})),...KiyiCarWraps.map(w=>({key:'wrap:'+w.id,id:w.id,type:'wrap',label:w.name}))];
 if(tab==='rims')return [{key:'original',id:null,type:'rim',label:'Orijinal jant'},...KiyiRimCatalog.map(r=>({key:r.id,id:r.id,type:'rim',label:r.name}))];
 if(tab==='accessories')return KiyiAccessoryCatalog.map(a=>({key:a.id,id:a.id,slot:a.slot,type:'accessory',label:a.name}));
 if(tab==='model'){
  const host=document.querySelector('.vehicle-garage[data-garage-tab="model"]');
  const cards=host?.querySelectorAll('[data-model],[data-motorcycle-model]');
  if(cards?.length)return [...cards].filter(c=>!c.hidden&&!c.disabled).map(c=>({key:c.dataset.model||c.dataset.motorcycleModel,id:c.dataset.model||c.dataset.motorcycleModel,type:c.dataset.model?'model':'motorcycle',label:c.dataset.name}));
  if(kiyiGarageModelType==='motorcycle')return Object.entries(globalThis.KiyiMotorcycleAssets||{}).filter(([,m])=>m.reviewed).map(([id,m])=>({key:id,id,type:'motorcycle',label:m.name}));
  const order=['renault-clio','peugeot-208','tofas-sahin','vw-golf','bmw-3','mercedes-a'],rank=m=>order.includes(m.id)?order.indexOf(m.id):order.length;
  return [...KiyiVehicleModels].sort((a,b)=>rank(a)-rank(b)).map(m=>({key:m.id,id:m.id,type:'model',label:m.name}));
 }
 return [];
}
function kiyiGarageCurrentOption(tab=kiyiGarageTab){
 if(tab==='plate')return kiyiGaragePlatePreview?.id||state.me.plateStyle||'classic';
 if(tab==='rims')return kiyiGarageRimPreview||'original';
 if(tab==='finish')return kiyiGarageWrapPreview?'wrap:'+kiyiGarageWrapPreview:'color:'+kiyiGaragePaint();
 if(tab==='accessories')return kiyiGarageOptionCursor.accessories||Object.values(kiyiGarageAccessoryPreview).find(id=>KiyiAccessoryCatalog.some(a=>a.id===id));
 return kiyiGarageOptionCursor.model||kiyiGarageHeroModel||kiyiVehicleModel(state.me)?.id;
}
function syncKiyiGaragePreviewControls(){
 const host=document.querySelector('.vehicle-garage');if(!host)return;
 const tab=kiyiGarageTab,items=kiyiGarageOptions(tab),index=items.findIndex(o=>o.key===kiyiGarageCurrentOption(tab));
 const title={plate:'plaka tasarımı',finish:'renk veya kaplama',model:'araç modeli',accessories:'aksesuar',rims:'jant'}[tab];
 const count=host.querySelector('.garage-hero-count');if(count){count.textContent=`${index<0?0:index+1} / ${items.length}`;count.setAttribute?.('aria-label',`${title}: ${index<0?0:index+1} / ${items.length}${index<0?'':', '+items[index].label}`);}
 for(const [selector,label]of [['.garage-hero-prev','Önceki'],['.garage-hero-next','Sonraki']]){const button=host.querySelector(selector);if(button){button.disabled=items.length<2;button.setAttribute?.('aria-label',`${label} ${title} önizle`);}}
 host.querySelectorAll('.garage-hero-dots i').forEach((el,i)=>el.classList.toggle('active',i===(Math.max(0,index)%3)));
}
function cycleKiyiGaragePreview(direction){
 const host=document.querySelector('.vehicle-garage');if(!host||kiyiGarageSaving)return false;
 const items=kiyiGarageOptions();if(items.length<2)return false;
 const current=items.findIndex(o=>o.key===kiyiGarageCurrentOption()),step=direction<0?-1:1;
 const index=current<0?(step>0?0:items.length-1):(current+step+items.length)%items.length,item=items[index];
 if(item.type==='plate')previewKiyiGaragePlate(item.id);
 else if(item.type==='rim')previewKiyiRim(item.id);
 else if(item.type==='accessory')previewKiyiAccessory(item.slot,item.id);
 else if(item.type==='wrap')previewCarWrap(item.id);
 else if(item.type==='color'){pendingCarColor=item.id;previewCarColor(item.id);}
 else if(item.type==='model'){
  kiyiGarageHeroModel=item.id;kiyiGarageOptionCursor.model=item.id;
  host.querySelector('.car-paint-display').innerHTML=kiyiGarageArt();
  host.querySelectorAll('[data-model]').forEach(card=>{const selected=card.dataset.model===item.id;card.classList.toggle('garage-model-previewing',selected);card.setAttribute('data-previewing',String(selected));});
 }else if(item.type==='motorcycle'){
  const m=globalThis.KiyiMotorcycleAssets[item.id];kiyiGarageOptionCursor.model=item.id;
  host.querySelector('.car-paint-display').innerHTML=`<div class="vehicle-showcase garage-bike-preview" data-motorcycle-model="${esc(item.id)}"><img src="${esc(m.image)}" alt="${esc(m.name)}"></div>`;
  host.querySelectorAll('[data-motorcycle-model]').forEach(card=>card.classList.toggle('garage-model-previewing',card.dataset.motorcycleModel===item.id));
 }
 syncKiyiGaragePreviewControls();return true;
}
/* Clip the native frame in this screen, including its letterboxed card slot. */
let kiyiGaragePlateSerial=0;
function kiyiGaragePlateArtwork(p){
 const source=kiyiVehiclePlate(p),box=source.match(/viewBox="([^"]+)"/)[1].split(/\s+/).map(Number),[x,y,w,h]=box,key='garage-plate-clip-'+(++kiyiGaragePlateSerial);
 return source.replace(/^(<svg[^>]*>)([\s\S]*)(<\/svg>)$/,`$1<defs><clipPath id="${key}" clipPathUnits="userSpaceOnUse"><rect x="${x}" y="${y}" width="${w}" height="${h}" rx="3"/></clipPath></defs><g clip-path="url(#${key})">$2</g>$3`);
}
/* The mount fills its measured rectangle; lettering keeps a uniform scale. */
function kiyiGarageFitPlate(art,p,model){
 if(!art.includes('class="sedan-license-plate"'))return art;
 const [mx,my,mw,mh]=model.plate,w=mw*1.24,h=mh*1.24,x=mx-(w-mw)/2,y=my-(h-mh)/2,scale=w/430,H=h/scale,source=kiyiVehiclePlate(p);
 const [vx,vy,vw,vh]=source.match(/viewBox="([^"]+)"/)[1].split(/\s+/).map(Number);
 const face=source.match(/<rect x="([^"]+)" y="([^"]+)" width="([^"]+)" height="([^"]+)"/),[fx,fy,fw,fh]=face.slice(1).map(Number);
 const faceX=(fx-vx)/vw*430,faceY=(fy-vy)/vh*H,faceW=fw/vw*430,faceH=fh/vh*H;
 const text=String(p.plate||'PLAKAN').trim(),font=Math.min(46,faceH*.62,faceW*.78/(Math.max(7,text.length)*.62));
 let frame=kiyiGaragePlateArtwork(p).replace(/<text\b[^>]*>[\s\S]*?<\/text>/g,'').replace(/\bheight="[^"]+"/,`height="${H}"`);
 frame=frame.includes('preserveAspectRatio=')?frame.replace(/preserveAspectRatio="[^"]+"/,'preserveAspectRatio="none"'):frame.replace('<svg ','<svg preserveAspectRatio="none" ');
 const caption=source.match(/<text class="vehicle-plate-name"[^>]*\sy="([^"]+)"[^>]*>([\s\S]*?)<\/text>/),style=p.plateStyle||'classic';
 const lettering=`<text class="garage-plate-country" x="${faceX+faceW*.05}" y="${faceY+faceH/2+5}" text-anchor="middle" fill="white" font-family="Arial,sans-serif" font-size="15" font-weight="700">TR</text><text class="garage-plate-number" x="${faceX+faceW*.55}" y="${faceY+faceH/2+font*.34}" text-anchor="middle" fill="#11141b" font-family="Arial,sans-serif" font-size="${font}" font-weight="700">${esc(text)}</text>${caption?`<text class="garage-plate-caption" x="215" y="${(Number(caption[1])-vy)/vh*H}" dominant-baseline="middle" text-anchor="middle" fill="${style==='kiss'?'#74223c':style==='chrome'?'#171923':'#fff'}" font-family="Arial,sans-serif" font-size="12" font-weight="700">${caption[2]}</text>`:''}`;
 return art.replace(/<g class="sedan-license-plate"[^>]*>[\s\S]*?<\/svg><\/g>/,()=>`<g class="sedan-license-plate garage-fitted-plate" transform="matrix(${scale} ${scale*.025} 0 ${scale} ${x} ${y})"><rect width="430" height="${H}" rx="7" fill="#24252b"/>${frame}${lettering}</g>`);
}

function kiyiGarageHeader(tab){kiyiGarageHeroModel=null;delete kiyiGarageOptionCursor.model;return `<div class="garage-heading"><div class="garage-title-row"><div class="garage-title-main"><button class="garage-back" type="button" aria-label="Garajdan çık" onclick="closeModal()">${garageSymbol('back')}</button><span class="garage-title-icon">${garageSymbol('car')}</span><div><h2>Garajım</h2></div></div>${kiyiGarageWallet()}</div><p>Plakanı, görünümünü ve araç modelini buradan düzenle.</p></div>${kiyiGaragePreview(tab)}<nav class="garage-tabs" aria-label="Araç düzenleme">${[['plate','Plaka','plate'],['finish','Renk ve Kaplama','paint'],['model','Araç Modeli','car'],['accessories','Aksesuar','accessory'],['rims','Jant','wheel']].map(([id,label,icon])=>`<button type="button" ${tab===id?'aria-current="page"':''} onclick="openVehicleGarage('${id}')">${garageSymbol(icon)}<span>${label}</span></button>`).join('')}</nav>`;}
function kiyiGarageCarModels(){const current=kiyiVehicleModel(state.me);return `<section class="garage-model-panel"><div class="garage-model-tools"><label class="garage-model-search">${garageSymbol('search')}<input type="search" placeholder="Araç modeli ara…" aria-label="Araç modeli ara" oninput="filterKiyiGarageModels()"></label><label class="garage-brand-filter">${garageSymbol('filter')}<select aria-label="Marka filtresi" onchange="filterKiyiGarageModels()"><option value="">Marka</option>${[...new Set(KiyiVehicleModels.map(m=>garageModelParts(m).brand))].sort().map(b=>`<option>${esc(b)}</option>`).join('')}</select></label></div><div class="garage-model-grid">${[...KiyiVehicleModels].sort((a,b)=>{const order=['renault-clio','peugeot-208','tofas-sahin','vw-golf','bmw-3','mercedes-a'];const rank=m=>order.includes(m.id)?order.indexOf(m.id):order.length;return rank(a)-rank(b);}).map(m=>{const parts=garageModelParts(m),selected=current?.id===m.id;return `<button type="button" class="garage-model-choice ${selected?'selected':''}" data-model="${m.id}" data-brand="${esc(parts.brand)}" data-name="${esc(m.name)}" aria-pressed="${selected}" onclick="chooseKiyiVehicleModel('${m.id}')"><span class="garage-model-name"><span><span>${esc(parts.brand)}</span><b>${esc(parts.model)}</b></span></span>${selected?`<span class="garage-model-check">${garageSymbol('check')}</span>`:''}<img src="assets/models/${m.id}-v1.webp" width="1536" height="1024" loading="lazy" alt="${esc(m.name)}"><small>${selected?garageSymbol('check')+' Model seçildi':'Modeli seç'}</small></button>`;}).join('')}</div><p class="garage-model-status" role="status" aria-live="polite"></p></section>`;}
function filterKiyiGarageModels(){const host=document.querySelector('.garage-model-panel');if(!host)return;const query=host.querySelector('input[type="search"]').value.toLocaleLowerCase('tr-TR').trim(),brand=host.querySelector('select').value;let count=0;host.querySelectorAll('[data-model],[data-motorcycle-model]').forEach(card=>{card.hidden=!(card.dataset.name.toLocaleLowerCase('tr-TR').includes(query)&&(!brand||card.dataset.brand===brand));if(!card.hidden)count++;});host.querySelector('.garage-model-status').textContent=count?'': 'Bu aramada model bulunamadı.';syncKiyiGaragePreviewControls();}
let kiyiGarageModelType='car';
function kiyiGarageModels(){const types=`<nav class="garage-vehicle-type" aria-label="Model türü"><button type="button" aria-pressed="${kiyiGarageModelType==='car'}" onclick="setKiyiGarageModelType('car')">${garageSymbol('car')} Otomobil</button><button type="button" aria-pressed="${kiyiGarageModelType==='motorcycle'}" onclick="setKiyiGarageModelType('motorcycle')">${garageSymbol('bike')} Motosiklet</button></nav>`;if(kiyiGarageModelType==='car')return types+kiyiGarageCarModels();const models=Object.entries(globalThis.KiyiMotorcycleAssets||{}),brands=[...new Set(models.map(([,m])=>m.name.split(' ')[0]))].sort();return types+`<section class="garage-model-panel"><div class="garage-model-tools"><label class="garage-model-search">${garageSymbol('search')}<input type="search" placeholder="Motosiklet modeli ara…" aria-label="Motosiklet modeli ara" oninput="filterKiyiGarageModels()"></label><label class="garage-brand-filter">${garageSymbol('filter')}<select aria-label="Marka filtresi" onchange="filterKiyiGarageModels()"><option value="">Marka</option>${brands.map(brand=>`<option>${esc(brand)}</option>`).join('')}</select></label></div><div class="garage-model-grid">${models.map(([id,m])=>`<button type="button" class="garage-model-choice" data-motorcycle-model="${esc(id)}" data-brand="${esc(m.name.split(' ')[0])}" data-name="${esc(m.name)}" onclick="openMotorcycleWrapPreview('${esc(id)}')" ${m.reviewed?'':'disabled'}><img src="${esc(m.image)}" width="1536" height="1024" loading="lazy" alt="${esc(m.name)}"><b>${esc(m.name)}</b></button>`).join('')}</div><p class="garage-model-status" role="status" aria-live="polite"></p></section>`;}

function setKiyiGarageModelType(kind){if(!['car','motorcycle'].includes(kind))return;kiyiGarageModelType=kind;openVehicleGarage('model');}
async function openGarageMotorcycleModel(id){if(!globalThis.KiyiMotorcycleAssets?.[id]?.reviewed)return;if(!globalThis.kiyiCloud?.active){openKiyiAccount();return;}try{const data=await kiyiCloud.command('garage_list');garageData={...data,owner:true,target:'me'};const own=data.vehicles.find(v=>v.kind==='motorcycle'&&v.model_id===id);if(own){openGarageDetail(own.id);return;}openGarageAdd('motorcycle');const host=document.querySelector('.simple-vehicle-dialog'),model=data.models.find(m=>m.id===id);if(!host||!model)return;const brand=host.querySelector('.garage-add-brand');brand.value=garageBrand(model);brand.onchange({target:brand});host.querySelector('.garage-add-model').value=id;host.querySelector('[name=plate]').focus();}catch(e){toast(e.message);}}
function openVehicleGarage(tab='plate'){
 if(!['plate','finish','model','accessories','rims'].includes(tab))tab='plate';
 kiyiGarageTab=tab;
 if(tab==='plate'){
  kiyiGaragePlateEditor();const body=document.querySelector('.plate-gallery-dialog');if(!body)return;body.classList.add('vehicle-garage');body.classList.toggle('garage-plate-zoomed',kiyiGaragePlateZoom);body.dataset.garageTab=tab;
  body.querySelectorAll(':scope > .appearance-eyebrow,:scope > h2,:scope > p').forEach(el=>el.remove());body.insertAdjacentHTML('afterbegin',kiyiGarageHeader(tab));
  body.querySelectorAll('.plate-style-choice').forEach((button,index)=>{const style=PlateStyles[index];button.querySelector('.custom-plate').innerHTML=kiyiGaragePlateArtwork({...state.me,plateStyle:style.id});button.setAttribute('onclick',`previewKiyiGaragePlate('${style.id}')`);if(plateCanName(style.id))button.insertAdjacentHTML('beforeend','<span class="plate-name-badge">İsim ekle</span>');});
  body.querySelector('.garage-tabs').insertAdjacentHTML('afterend','<div class="garage-plate-controls" aria-live="polite"></div>');
  if(kiyiGaragePlatePreview)previewKiyiGaragePlate(kiyiGaragePlatePreview.id);
  body.querySelector(':scope > small')?.remove();kiyiGarageCurrency(body);installKiyiGarageScroll(body);syncKiyiGaragePreviewControls();
  return;
 }
 let content;if(tab==='finish'){const panel=renderCarColors();panel.querySelector('.car-color-preview')?.remove();panel.querySelector('.customizer-heading')?.remove();content=panel.outerHTML;}else content=tab==='accessories'?kiyiGarageAccessories():tab==='rims'?kiyiGarageRims():kiyiGarageModels();
 membershipDialog(`<div class="appearance-dialog appearance-fullscreen vehicle-garage ${tab==='rims'&&kiyiGarageRimZoom?'garage-rim-zoomed':''} ${tab==='finish'?'car-appearance-dialog':''}" data-garage-tab="${tab}">${kiyiGarageHeader(tab)}${content}</div>`);
 if(tab==='finish'&&kiyiGarageWrapPreview)previewCarWrap(kiyiGarageWrapPreview);
 kiyiGarageCurrency(document.querySelector('.vehicle-garage'));installKiyiGarageScroll(document.querySelector('.vehicle-garage'));syncKiyiGaragePreviewControls();
}
openPlateAppearance=function(){kiyiGaragePlatePreview=null;kiyiGarageWrapPreview=null;kiyiGarageRimPreview=null;kiyiGaragePlateZoom=true;kiyiGarageAccessoryPreview={window:null,roof:null,text:'Piyaso'};openVehicleGarage('plate');};
openCarAppearance=function(){openVehicleGarage('finish');};
async function chooseKiyiVehicleModel(id){
 const model=KiyiVehicleModels.find(m=>m.id===id);if(!model||kiyiGarageSaving)return false;
 const body=document.querySelector('.vehicle-garage'),buttons=body?.querySelectorAll('.garage-model-choice')||[],status=body?.querySelector('.garage-model-status');
 kiyiGarageSaving=true;buttons.forEach(b=>b.disabled=true);if(status)status.textContent='Modelin kaydediliyor…';
 try{
  if(globalThis.kiyiCloud?.active){await kiyiCloud.command('vehicle_model',{model:id});await kiyiCloud.refresh();}
  else if(globalThis.kiyiCloud?.supportActive){throw Error('Hesabın henüz hazır değil. Girişini kontrol et.');}
  else{const previous=structuredClone(state);state.me.vehicleModel=id;state.me.car=model.name;if(!save()){state=previous;throw Error('Model kaydedilemedi. Yeniden dene.');}}
  renderProfile();openVehicleGarage('model');toast(model.name+' seçildi.');return true;
 }catch(e){if(status)status.textContent=e.message;toast(e.message||'Model kaydedilemedi.');return false;}
 finally{kiyiGarageSaving=false;buttons.forEach(b=>b.disabled=false);}
}

function previewKiyiGaragePlate(id){
 const style=PlateStyles.find(s=>s.id===id),body=document.querySelector('.vehicle-garage');if(!style||!body)return false;
 const name=kiyiGaragePlatePreview?.id===id?kiyiGaragePlatePreview.name:state.me.plateNames?.[id]||(id==='named'?state.me.plateName:'')||'';
 kiyiGaragePlatePreview={id,name};
 body.querySelector('.car-paint-display').innerHTML=kiyiGarageArt();
 body.querySelectorAll('.plate-style-choice').forEach((b,index)=>{const selected=PlateStyles[index].id===id;b.classList.toggle('selected',selected);b.setAttribute('aria-pressed',String(selected));});
 body.querySelector('.garage-plate-controls').innerHTML=plateCanName(id)?`<label class="field"><b>Plakana ismini yaz</b><input maxlength="20" value="${esc(name)}" placeholder="İsmini buraya yaz" aria-label="Plakana yazılacak isim" oninput="updateKiyiGaragePlateName(this.value)"><small>Yazdığın isim yukarıdaki plakada anında görünür.</small></label>`:'';
 syncKiyiGaragePreviewControls();
 if(plateCanName(id))body.querySelector('.garage-plate-controls').scrollIntoView?.({block:'nearest',behavior:'auto'});

 return true;
}
function updateKiyiGaragePlateName(value){if(!kiyiGaragePlatePreview)return;kiyiGaragePlatePreview.name=String(value).slice(0,20);const body=document.querySelector('.vehicle-garage');if(body){body.querySelector('.car-paint-display').innerHTML=kiyiGarageArt();const card=body.querySelector('.plate-style-choice.selected .custom-plate');if(card)card.innerHTML=kiyiGaragePlateArtwork(kiyiGaragePerson());}}
async function saveKiyiGaragePlate(){
 const selected=kiyiGaragePlatePreview;if(!selected||kiyiGarageSaving)return false;
 if(!plateStyleOwned(selected.id)){openKiyiDiamondWallet();return false;}
 const name=selected.name.trim();if(plateCanName(selected.id)&&!name){toast('Plaka alt yazısını gir.');return false;}
 kiyiGarageSaving=true;try{const ok=await applyPlateStyle(selected.id,name);if(ok){kiyiGaragePlatePreview=null;openVehicleGarage('plate');}return !!ok;}finally{kiyiGarageSaving=false;}
}

function kiyiGarageAccessories(){return `<section class="garage-accessory-panel">${['headlights','underglow','window','roof'].map(slot=>`<div class="garage-accessory-heading"><h3>${({headlights:'Far aydınlatması',underglow:'Araç altı aydınlatması',window:'Cam aksesuarları',roof:'Tavan aksesuarları'})[slot]}</h3><button type="button" class="textbtn" onclick="previewKiyiAccessory('${slot}',null)">Kaldır</button></div><div class="garage-accessory-grid">${KiyiAccessoryCatalog.filter(a=>a.slot===slot).map(a=>`<button type="button" class="garage-accessory-card ${kiyiGarageAccessoryPreview[slot]===a.id?'selected':''}" data-accessory="${a.id}" aria-pressed="${kiyiGarageAccessoryPreview[slot]===a.id}" onclick="previewKiyiAccessory('${slot}','${a.id}')"><span>${kiyiAccessoryGlyph(a.id)}</span><b>${a.name}</b><small>Önizle</small></button>`).join('')}</div>`).join('')}<label class="field garage-led-text" ${kiyiGarageAccessoryPreview.window==='neon-text'?'':'hidden'}>LED yazısı<input maxlength="12" value="${esc(kiyiGarageAccessoryPreview.text)}" placeholder="Piyaso" oninput="updateKiyiAccessoryText(this.value)"></label><p class="garage-accessory-status" role="status">Aksesuarlar şimdilik ücretsiz önizleme içindir. Far, araç altı, cam ve tavan tasarımlarını birlikte deneyebilirsin.</p></section>`;}
function refreshKiyiAccessoryPreview(){const body=document.querySelector('.vehicle-garage');if(!body)return false;const display=body.querySelector('.car-paint-display');if(display)display.innerHTML=kiyiGarageArt();return true;}
function previewKiyiAccessory(slot,id){if(!['headlights','underglow','window','roof'].includes(slot)||id!==null&&!KiyiAccessoryCatalog.some(a=>a.id===id&&a.slot===slot))return false;kiyiGarageAccessoryPreview[slot]=id;kiyiGarageOptionCursor.accessories=id;const body=document.querySelector('.vehicle-garage');if(!body)return false;refreshKiyiAccessoryPreview();body.querySelectorAll('[data-accessory]').forEach(b=>{const a=KiyiAccessoryCatalog.find(x=>x.id===b.dataset.accessory),selected=kiyiGarageAccessoryPreview[a.slot]===a.id;b.classList.toggle('selected',selected);b.setAttribute('aria-pressed',String(selected));});const field=body.querySelector('.garage-led-text');if(field)field.hidden=kiyiGarageAccessoryPreview.window!=='neon-text';syncKiyiGaragePreviewControls();return true;}
function updateKiyiAccessoryText(value){kiyiGarageAccessoryPreview.text=String(value).slice(0,12);return refreshKiyiAccessoryPreview();}

function kiyiGarageRims(){return `<section class="garage-rim-panel"><div class="garage-accessory-heading"><h3>Jant modelleri</h3><button type="button" class="textbtn" onclick="previewKiyiRim(null)">Orijinal jant</button></div><div class="garage-rim-grid">${KiyiRimCatalog.map(r=>`<button type="button" class="garage-rim-card ${kiyiGarageRimPreview===r.id?'selected':''}" data-rim="${r.id}" aria-pressed="${kiyiGarageRimPreview===r.id}" onclick="previewKiyiRim('${r.id}')"><span>${kiyiRimSwatch(r.id)}</span><b>${r.name}</b><small>Önizle</small></button>`).join('')}</div><p class="garage-accessory-status">Bir janta dokunarak aracında dene. Jantlar şimdilik önizleme içindir.</p></section>`;}
function previewKiyiRim(id){if(id!==null&&!KiyiRimCatalog.some(r=>r.id===id))return false;const body=document.querySelector('.vehicle-garage');if(!body)return false;kiyiGarageRimPreview=id;refreshKiyiAccessoryPreview();body.querySelectorAll('[data-rim]').forEach(b=>{const selected=b.dataset.rim===id;b.classList.toggle('selected',selected);b.setAttribute('aria-pressed',String(selected));});syncKiyiGaragePreviewControls();return true;}
// Keep the new garage currency separate from the existing gold-credit wallet.
if(typeof previewCarColor==='function'){const beforeKiyiGarageColorPreview=previewCarColor;previewCarColor=function(id){const out=beforeKiyiGarageColorPreview(id);const body=document.querySelector('.vehicle-garage');kiyiGarageCurrency(body);if(body){refreshKiyiAccessoryPreview();syncKiyiGaragePreviewControls();}return out;};}
if(typeof unlockCarColor==='function'){const beforeKiyiGarageColorUnlock=unlockCarColor;unlockCarColor=function(){if(document.querySelector('.vehicle-garage'))return openKiyiDiamondWallet();return beforeKiyiGarageColorUnlock();};}

let kiyiVehicleCollection=null;
async function openMyVehicleGarage(){
 if(!globalThis.kiyiCloud?.active){openKiyiAccount();return;}
 try{const data=await kiyiCloud.command('garage_list');kiyiVehicleCollection=data;
 membershipDialog(`<div class="appearance-dialog"><h2>Garajım</h2><p>Her aracın görünümü ayrı kaydedilir.</p>${data.vehicles.map(v=>`<section class="panel"><b>${esc(v.plate||'Plakasız')} · ${esc(v.name||'Mevcut aracın')}</b><p>${v.is_primary?'Profildeki aracın':v.kind==='motorcycle'?'Motosiklet':'Otomobil'}${v.ready?'':' · Görseller ve parçalar henüz hazır değil'}</p>${v.ready?`<button class="btn" onclick="editMyVehicle('${v.id}')">Özelleştir</button>`:''}</section>`).join('')}<form id="my-vehicle-add"><h3>Araç ekle</h3><label class="field">Model<select name="model">${data.models.map(m=>`<option value="${esc(m.id)}">${esc(m.name)}${m.ready?'':' · yalnız garaj kaydı, özelleştirme kapalı'}</option>`).join('')}</select></label><label class="field">Plaka<input name="plate" maxlength="30" required></label><button class="btn">Garaja ekle</button><p role="status" id="my-vehicle-message"></p></form></div>`);
 document.getElementById('my-vehicle-add').onsubmit=async e=>{e.preventDefault();const button=e.target.querySelector('button');button.disabled=true;try{await kiyiCloud.command('vehicle_create',Object.fromEntries(new FormData(e.target)));await openMyVehicleGarage();}catch(err){document.getElementById('my-vehicle-message').textContent=err.message;}finally{button.disabled=false;}};
 }catch(e){toast(e.message);}
}
function editMyVehicle(id){const v=kiyiVehicleCollection?.vehicles.find(x=>x.id===id);if(!v?.ready)return;const a=v.appearance||{},acc=a.accessories||{};
 const select=(name,label,catalog,value)=>`<label class="field">${label}<select name="${name}"><option value="">Orijinal / kapalı</option>${catalog.map(x=>`<option value="${esc(x.id)}" ${x.id===value?'selected':''}>${esc(x.name)}</option>`).join('')}</select></label>`;
 membershipDialog(`<div class="appearance-dialog"><h2>${esc(v.plate)} · ${esc(v.name)}</h2><div class="car-paint-display">${kiyiSedanShowcase({...state.me,plate:v.plate,vehicleModel:v.model_id,vehicleRim:a.rim,vehicleAccessories:acc,plateStyle:a.plateStyle||'classic',plateNames:a.plateNames||{}},a.paint||'#ffffff',a.wrap)}</div><form id="my-vehicle-edit"><label class="field">Araç rengi<input type="color" name="paint" value="${esc(a.paint||'#ffffff')}"></label><p>Renk kaydı mevcut satın alma ve kredi kurallarını kullanır.</p>${select('wrap','Kaplama',KiyiCarWraps,a.wrap)}${select('rim','Jant',KiyiRimCatalog,a.rim)}${['headlights','underglow','window','roof'].map(slot=>select(slot,({headlights:'Far',underglow:'Araç altı',window:'Cam aksesuarı',roof:'Tavan aksesuarı'})[slot],KiyiAccessoryCatalog.filter(x=>x.slot===slot),acc[slot])).join('')}<label class="field">LED yazısı<input name="text" maxlength="12" value="${esc(acc.text||'Piyaso')}"></label><button class="btn">Bu araca kaydet</button><p role="status" id="my-vehicle-message"></p></form><button class="textbtn" onclick="openMyVehicleGarage()">Garajıma dön</button></div>`);
 document.getElementById('my-vehicle-edit').onsubmit=async e=>{e.preventDefault();const b=e.target.querySelector('button');b.disabled=true;const f=Object.fromEntries(new FormData(e.target));try{
 if(f.paint!==(a.paint||'#ffffff'))await kiyiCloud.command('appearance',{vehicle_id:id,kind:'color',value:f.paint,request_id:crypto.randomUUID()});
 const current=(await kiyiCloud.command('garage_list')).vehicles.find(x=>x.id===id);
 await kiyiCloud.command('vehicle_customize',{vehicle_id:id,version:current.version,appearance:{wrap:f.wrap||null,rim:f.rim||null,accessories:Object.fromEntries(['headlights','underglow','window','roof','text'].map(k=>[k,f[k]||null]))}});
 await kiyiCloud.refresh();await openMyVehicleGarage();toast('Aracın görünümü kaydedildi.');
 }catch(err){document.getElementById('my-vehicle-message').textContent=err.message;}finally{b.disabled=false;}};
}

function installKiyiGarageScroll(body){if(!body||body.querySelector(':scope > .garage-scroll-content'))return;const tabs=body.querySelector(':scope > .garage-tabs');if(!tabs)return;const scroll=document.createElement('div');scroll.className='garage-scroll-content';scroll.setAttribute('aria-label','Garaj seçenekleri');while(tabs.nextSibling)scroll.append(tabs.nextSibling);body.append(scroll);}

if(typeof previewCarWrap==='function'){const originalGarageWrapPreview=previewCarWrap;previewCarWrap=function(id){const result=originalGarageWrapPreview(id);if(result&&document.querySelector('.vehicle-garage')){refreshKiyiAccessoryPreview();syncKiyiGaragePreviewControls();}return result;};}
