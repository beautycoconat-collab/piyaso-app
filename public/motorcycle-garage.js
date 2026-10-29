/* Motorcycles use the same fixed stage + scrollable options as the car garage. */
let kiyiMotoGarage=null;
const carGarageOpen=openVehicleGarage;
openVehicleGarage=function(tab='plate'){
 if(kiyiMotoGarage)return renderInlineMotorcycleGarage(tab==='plate'?'finish':tab);
 return carGarageOpen(tab);
};
const carGarageType=setKiyiGarageModelType;
setKiyiGarageModelType=function(kind){
 if(kind==='car')kiyiMotoGarage=null;
 else if(!kiyiMotoGarage){const id=Object.keys(KiyiMotorcycleAssets).find(id=>KiyiMotorcycleAssets[id].reviewed);if(id)setInlineMotorcycle(id);}
 return carGarageType(kind);
};
for(const key of ['openPlateAppearance','openCarAppearance']){const previous=globalThis[key];globalThis[key]=function(...args){kiyiMotoGarage=null;return previous(...args);};}
function setInlineMotorcycle(id,vehicle=null){
 const fit=KiyiMotorcycleAssets[id];if(!fit?.reviewed)return false;
 kiyiMotoGarage={modelId:id,vehicle,appearance:{...(vehicle?.appearance||{paint:'#ffffff',wrap:'none'})},cursor:'paint:'+(vehicle?.appearance?.paint||'#ffffff'),cursors:{}};
 motoLiveryModel=id;motoLiveryPreview=KiyiCarWraps.some(w=>w.id===kiyiMotoGarage.appearance.wrap)?kiyiMotoGarage.appearance.wrap:null;
 kiyiGarageModelType='motorcycle';
 if(vehicle){garageDraft={...vehicle,appearance:kiyiMotoGarage.appearance};garagePurchaseId=crypto.randomUUID();}
 return true;
}
openMotorcycleWrapPreview=function(id){if(setInlineMotorcycle(id))renderInlineMotorcycleGarage('finish');};
openMotorcycleCustomizer=function(vehicle){if(!vehicle?.ready||!setInlineMotorcycle(vehicle.model_id,vehicle)){toast('Bu modelin görsel katmanları henüz hazır değil.');return;}renderInlineMotorcycleGarage('finish');};
function inlineMotoProducts(){
 const c=kiyiMotoGarage;if(!c)return [];
 if(c.vehicle)return motoProducts(c.vehicle);
 return [...CarColors.map(p=>({slot:'paint',value:p.id,credits:0})),...['none','carbon','stripe',...KiyiCarWraps.map(w=>w.id)].map(value=>({slot:'wrap',value,credits:0})),...['rim_color','rim_stripe','headlights','underglow'].flatMap(slot=>['none','#245bf3','#7b42d4','#ff0000','#ffb627','#22cfff'].map(value=>({slot,value,credits:0})))];
}
function inlineMotoSlots(tab=kiyiGarageTab){return ({finish:['paint','wrap'],rims:['rim_color','rim_stripe'],accessories:['headlights','underglow','exhaust','mirror','windshield','seat']})[tab]||[];}
function inlineMotoOptions(tab=kiyiGarageTab){
 if(tab==='model')return kiyiGarageOptions('model');
 return inlineMotoProducts().filter(p=>inlineMotoSlots(tab).includes(p.slot)).map(p=>({...p,key:p.slot+':'+p.value,label:(MotoLabels[p.slot]||'')+' · '+motoOptionName(p.value)}));
}
function inlineMotoOptionLabel(value){return KiyiCarWraps.find(w=>w.id===value)?.name||CarColors.find(c=>c.id===value)?.name||motoOptionName(value);}
function inlineMotoPrice(product){if(!kiyiMotoGarage.vehicle)return 'Önizle';if(kiyiMotoGarage.vehicle.appearance[product.slot]===product.value)return 'Mevcut';if((state.vehicleInventory||[]).includes(product.sku))return 'Satın alındı';return product.credits?product.credits+' kredi':'Ücretsiz';}
function inlineMotoCategory(slot){
 const options=inlineMotoProducts().filter(p=>p.slot===slot&&!(slot==='wrap'&&KiyiCarWraps.some(w=>w.id===p.value)));if(!options.length)return '';
 return `<section class="moto-category"><h3>${MotoLabels[slot]}</h3><div class="moto-option-grid">${options.map(p=>`<button type="button" data-slot="${slot}" data-value="${esc(p.value)}" aria-pressed="${kiyiMotoGarage.appearance[slot]===p.value}" onclick="chooseInlineMoto('${slot}',this.dataset.value)">${slot==='paint'?`<i class="moto-color-dot" style="background:${esc(p.value)}"></i>`:''}<b>${esc(inlineMotoOptionLabel(p.value))}</b><small>${esc(inlineMotoPrice(p))}</small></button>`).join('')}</div></section>`;
}
function inlineMotoHeader(tab){
 const fit=KiyiMotorcycleAssets[kiyiMotoGarage.modelId];
 return `<div class="garage-heading"><div class="garage-title-row"><div class="garage-title-main"><button class="garage-back" type="button" aria-label="Garajdan çık" onclick="closeModal()">${garageSymbol('back')}</button><span class="garage-title-icon">${garageSymbol('bike')}</span><h2>Garajım</h2></div>${kiyiGarageWallet()}</div><p>${esc(fit.name)}${kiyiMotoGarage.vehicle?.plate?' · '+esc(kiyiMotoGarage.vehicle.plate):''}</p></div><div class="car-color-preview garage-shared-preview"><div class="moto-preview car-paint-display">${motorcycleSVG(kiyiMotoGarage.modelId,kiyiMotoGarage.appearance)}</div><button class="garage-hero-prev" aria-label="Önceki seçeneği önizle" onclick="cycleInlineMoto(-1)">${garageSymbol('back')}</button><button class="garage-hero-next" aria-label="Sonraki seçeneği önizle" onclick="cycleInlineMoto(1)">${garageSymbol('next')}</button><span class="garage-hero-count" aria-live="polite"></span></div><nav class="garage-tabs" aria-label="Araç düzenleme">${[['finish','Renk ve Kaplama','paint'],['model','Araç Modeli','bike'],['accessories','Aksesuar','accessory'],['rims','Jant','wheel']].map(([id,label,icon])=>`<button type="button" ${tab===id?'aria-current="page"':''} onclick="openVehicleGarage('${id}')">${garageSymbol(icon)}<span>${label}</span></button>`).join('')}</nav>`;
}
function renderInlineMotorcycleGarage(tab='finish'){
 if(!kiyiMotoGarage)return;kiyiGarageTab=['finish','model','accessories','rims'].includes(tab)?tab:'finish';
 let content=kiyiGarageTab==='model'?kiyiGarageModels():inlineMotoSlots().map(inlineMotoCategory).join('');
 if(kiyiGarageTab==='finish')content+=renderMotoLiveryCatalog(kiyiMotoGarage.vehicle);
 if(!content)content='<p class="garage-message">Bu model için bu kategoride parça bulunmuyor.</p>';
 membershipDialog(`<div class="appearance-dialog appearance-fullscreen vehicle-garage moto-inline-garage moto-customizer" data-garage-tab="${kiyiGarageTab}">${inlineMotoHeader(kiyiGarageTab)}${content}</div>`);
 const body=document.querySelector('.moto-inline-garage');installKiyiGarageScroll(body);
 body.insertAdjacentHTML('beforeend',`<div class="moto-inline-footer"><p class="garage-message" role="status"></p>${kiyiMotoGarage.vehicle?`<div class="moto-total"><div><b id="moto-cost"></b><small>Kaydetmeden kredi harcanmaz.</small></div><button class="btn" onclick="saveMotorcycleAppearance(this)">Kaydet</button></div>`:`<button class="btn" onclick="prepareMotoLiverySave()">Aracıma uygula</button><small>Seçimler önizlemedir. Kaydetmeden kredi harcanmaz.</small>`}</div>`);
 updateInlineMoto();
}
function chooseInlineMoto(slot,value){
 if(!kiyiMotoGarage||!inlineMotoProducts().some(p=>p.slot===slot&&p.value===value))return false;
 kiyiMotoGarage.appearance[slot]=value;if(slot==='paint'){kiyiMotoGarage.appearance.wrap='none';motoLiveryPreview=null;}kiyiMotoGarage.cursor=slot+':'+value;kiyiMotoGarage.cursors[slot==='paint'||slot==='wrap'?'finish':slot.startsWith('rim_')?'rims':'accessories']=kiyiMotoGarage.cursor;
 if(slot==='wrap')motoLiveryPreview=KiyiCarWraps.some(w=>w.id===value)?value:null;
 if(kiyiMotoGarage.vehicle)garagePurchaseId=crypto.randomUUID();
 updateInlineMoto();return true;
}
function inlineMotoCursor(){
 const c=kiyiMotoGarage;if(kiyiGarageTab==='model')return c.modelId;
 if(c.cursors[kiyiGarageTab])return c.cursors[kiyiGarageTab];
 if(kiyiGarageTab==='finish')return c.appearance.wrap&&c.appearance.wrap!=='none'?'wrap:'+c.appearance.wrap:'paint:'+c.appearance.paint;
 return inlineMotoOptions().find(p=>c.appearance[p.slot]===p.value)?.key;
}
function updateInlineMoto(){
 const host=document.querySelector('.moto-inline-garage');if(!host||!kiyiMotoGarage)return;
 host.querySelector('.moto-preview').innerHTML=motorcycleSVG(kiyiMotoGarage.modelId,kiyiMotoGarage.appearance);
 host.querySelectorAll('[data-slot]').forEach(b=>b.setAttribute('aria-pressed',String(kiyiMotoGarage.appearance[b.dataset.slot]===b.dataset.value)));
 host.querySelectorAll('[data-moto-wrap].car-wrap-choice').forEach(b=>b.setAttribute('aria-pressed',String(kiyiMotoGarage.appearance.wrap===b.dataset.motoWrap)));
 const cost=host.querySelector('#moto-cost');if(cost&&kiyiMotoGarage.vehicle)cost.textContent=motoQuote().cost+' kredi';
 const options=inlineMotoOptions(),index=options.findIndex(p=>p.key===inlineMotoCursor());
 const count=host.querySelector('.garage-hero-count');if(count)count.textContent=(index<0?'':index+1+' / ')+(index<0?(KiyiCarWraps.find(w=>w.id===kiyiMotoGarage.appearance.wrap)?.name||inlineMotoOptionLabel(kiyiMotoGarage.appearance.paint)):options.length);
 host.querySelectorAll('.garage-hero-prev,.garage-hero-next').forEach(b=>{b.disabled=options.length<2;b.setAttribute('aria-label',(b.classList.contains('garage-hero-prev')?'Önceki ':'Sonraki ')+({finish:'renk veya kaplama',model:'motosiklet modeli',accessories:'aksesuar',rims:'jant'}[kiyiGarageTab])+' önizle');});
}
function cycleInlineMoto(direction){
 const options=inlineMotoOptions();if(options.length<2)return false;
 const current=options.findIndex(p=>p.key===inlineMotoCursor()),step=direction<0?-1:1;
 const next=options[current<0?(step>0?0:options.length-1):(current+step+options.length)%options.length];
 if(kiyiGarageTab==='model'){setInlineMotorcycle(next.id);const heading=document.querySelector('.moto-inline-garage .garage-heading p');if(heading)heading.textContent=KiyiMotorcycleAssets[next.id].name;renderInlineMotorcycleGarage('model');}
 else chooseInlineMoto(next.slot,next.value);return true;
}
const legacyMotoLiveryPreview=previewMotoLivery;
previewMotoLivery=function(id){if(!kiyiMotoGarage)return legacyMotoLiveryPreview(id);return chooseInlineMoto('wrap',id||'none');};
const legacyMotoPreviewUpdate=motoPreviewUpdate;
motoPreviewUpdate=function(){if(kiyiMotoGarage)return updateInlineMoto();return legacyMotoPreviewUpdate();};
const originalMotoChoose=motoChoose;
motoChoose=function(slot,value){if(kiyiMotoGarage)return chooseInlineMoto(slot,value);return originalMotoChoose(slot,value);};

const carGarageSync=syncKiyiGaragePreviewControls;
syncKiyiGaragePreviewControls=function(){if(kiyiMotoGarage&&document.querySelector('.moto-inline-garage'))return updateInlineMoto();return carGarageSync();};
openMotoLiveryForVehicle=function(vehicleId,wrapId){
 const vehicle=garageData?.vehicles.find(v=>v.id===vehicleId&&v.kind==='motorcycle');if(!vehicle)return;
 const pending=kiyiMotoGarage?.modelId===vehicle.model_id&&!kiyiMotoGarage.vehicle?{...kiyiMotoGarage.appearance}:null;
 openMotorcycleCustomizer(vehicle);
 if(pending)for(const [slot,value]of Object.entries(pending))if(inlineMotoProducts().some(p=>p.slot===slot&&p.value===value))chooseInlineMoto(slot,value);
 previewMotoLivery(wrapId);
};
