import test from 'node:test';import assert from 'node:assert/strict';import vm from 'node:vm';import fs from 'node:fs';
function fixture(overrides={}){const calls=[];const c={calls,structuredClone,PlateStyles:['classic','diamond','kiss','named','carbon','chrome'].map(id=>({id,label:id})),activeCarColor:()=> '#ffffff',kiyiSedanShowcase:()=>'<svg class="test-car"></svg>',esc:String,carColorName:()=>'',state:{me:{car:'Renault Clio',paint:'#8b4cf6',plate:'07 TEST 004'},credits:1300,carColors:['#8b4cf6'],ownedPlateStyles:['diamond']},document:{querySelector:()=>null},openPlateAppearance(){},openCarAppearance(){},renderProfile:()=>calls.push('render'),toast:t=>calls.push(t),save:()=>true,...overrides};vm.createContext(c);vm.runInContext(fs.readFileSync(new URL('../public/vehicle-models.js',import.meta.url),'utf8'),c);vm.runInContext(fs.readFileSync(new URL('../public/vehicle-garage.js',import.meta.url),'utf8'),c);c.openVehicleGarage=t=>calls.push('garage:'+t);return c;}
test('demo model choice persists without changing credits, paint, plate or inventory',async()=>{const c=fixture();let writes=0;c.save=()=>{writes++;return true};assert.equal(await c.chooseKiyiVehicleModel('bmw-3'),true);assert.equal(c.state.me.vehicleModel,'bmw-3');assert.equal(c.state.me.car,'BMW 3 Serisi');assert.equal(c.state.me.paint,'#8b4cf6');assert.equal(c.state.me.plate,'07 TEST 004');assert.equal(c.state.credits,1300);assert.deepEqual(c.state.carColors,['#8b4cf6']);assert.deepEqual(c.state.ownedPlateStyles,['diamond']);assert.equal(writes,1);assert(c.calls.includes('garage:model'));const before=JSON.stringify(c.state);assert.equal(await c.chooseKiyiVehicleModel('invalid'),false);assert.equal(JSON.stringify(c.state),before);});
test('failed local persistence rolls back the model and existing car information',async()=>{const c=fixture(),before=JSON.stringify(c.state);c.save=()=>false;assert.equal(await c.chooseKiyiVehicleModel('audi-a3'),false);assert.equal(JSON.stringify(c.state),before);assert(!c.calls.includes('garage:model'));});
test('cloud save uses authenticated command and refresh; errors never fall back to local success',async()=>{const c=fixture(),commands=[];c.save=()=>{throw Error('No local cloud writes')};c.kiyiCloud={active:true,async command(action,payload){commands.push([action,payload]);},async refresh(){c.state.me.vehicleModel='mercedes-c';}};vm.runInContext("kiyiGarageWrapPreview='race-95'",c);assert.equal(await c.chooseKiyiVehicleModel('mercedes-c'),true);assert.equal(commands[0][0],'vehicle_model');assert.equal(commands[0][1].model,'mercedes-c');assert.equal(vm.runInContext('kiyiGarageWrapPreview',c),'race-95');c.kiyiCloud.command=async()=>{throw Error('Yetki yok')};const before=JSON.stringify(c.state);assert.equal(await c.chooseKiyiVehicleModel('audi-a3'),false);assert.equal(JSON.stringify(c.state),before);});

test('all three garage tabs share a car preview above the navigation',()=>{const c=fixture();for(const tab of ['plate','finish','model']){const html=c.kiyiGarageHeader(tab);assert.match(html,/garage-shared-preview/);assert.match(html,/test-car/);assert(html.indexOf('garage-shared-preview')<html.indexOf('garage-tabs'));assert.equal((html.match(/aria-current="page"/g)||[]).length,1);assert.doesNotMatch(html,/vehicle-paint-caption/);}});

test('plate click only previews on the vehicle and never opens a name/purchase modal or charges',async()=>{
 const c=fixture(),art={innerHTML:''},controls={innerHTML:''};
 const styles=['classic','diamond','kiss','named','carbon','chrome'].map(id=>({id,label:id,price:id==='classic'?0:100}));
 c.PlateStyles=styles;c.plateCanName=id=>['kiss','named','carbon','chrome'].includes(id);c.plateStyleOwned=id=>id==='classic';
 const buttons=styles.map(()=>({classList:{toggle(){}},setAttribute(){}}));
 c.document.querySelector=()=>({querySelector:s=>s==='.car-paint-display'?art:controls,querySelectorAll:()=>buttons});
 c.membershipDialog=()=>{throw Error('No new modal on selection')};c.applyPlateStyle=()=>{throw Error('Preview must not charge')};
 c.kiyiSedanShowcase=p=>JSON.stringify(p);const before=JSON.stringify(c.state);
 for(const style of styles){assert.equal(c.previewKiyiGaragePlate(style.id),true);assert.equal(JSON.parse(art.innerHTML).plateStyle,style.id);assert.equal(JSON.stringify(c.state),before);}
 c.updateKiyiGaragePlateName('DENEME');assert.equal(JSON.parse(art.innerHTML).plateNames.chrome,'DENEME');assert.equal(JSON.stringify(c.state),before);
 let applied=null;c.applyPlateStyle=async(id,name)=>{applied={id,name};return false};assert.equal(await c.saveKiyiGaragePlate(),false);assert.equal(applied,null);c.plateStyleOwned=()=>true;assert.equal(await c.saveKiyiGaragePlate(),false);assert.deepEqual(applied,{id:'chrome',name:'DENEME'});
});

test('accessory previews keep cam/roof slots independent and never change money or the profile',()=>{
 const c=fixture(),art={innerHTML:''},field={hidden:true};c.kiyiSedanShowcase=p=>JSON.stringify(p);
 c.document.querySelector=()=>({querySelector:s=>s==='.car-paint-display'?art:field,querySelectorAll:()=>[]});
 const before=JSON.stringify(c.state);c.save=()=>{throw Error('Preview cannot save')};c.applyPlateStyle=()=>{throw Error('Preview cannot purchase')};
 assert.equal(c.previewKiyiAccessory('window','heart-pink'),true);assert.equal(c.previewKiyiAccessory('roof','roof-bow'),true);
 let p=JSON.parse(art.innerHTML);assert.equal(p.vehicleAccessories.window,'heart-pink');assert.equal(p.vehicleAccessories.roof,'roof-bow');
 assert.equal(c.previewKiyiAccessory('roof','led-cyan'),false);assert.equal(c.previewKiyiAccessory('window','neon-text'),true);assert.equal(field.hidden,false);
 c.updateKiyiAccessoryText('KIYI <HELLO> extra');assert.equal(JSON.parse(art.innerHTML).vehicleAccessories.text,'KIYI <HELLO>');
 assert.equal(c.previewKiyiAccessory('window',null),true);p=JSON.parse(art.innerHTML);assert.equal(p.vehicleAccessories.window,null);assert.equal(p.vehicleAccessories.roof,'roof-bow');assert.equal(field.hidden,true);assert.equal(JSON.stringify(c.state),before);
 const header=c.kiyiGarageHeader('accessories');assert.match(header,/garage-wallets/);assert.match(header,/Mavi elmas bakiyesi/);assert.match(header,/Aksesuar/);assert.equal((header.match(/aria-current="page"/g)||[]).length,1);
});

test('plate tab zooms to the front plate and restores the whole car without changing the profile',()=>{
 const c=fixture(),before=JSON.stringify(c.state);c.kiyiSedanShowcase=()=>'<svg viewBox="0 170 1536 740"></svg>';
 const zoomed=c.kiyiGarageArt('plate');assert.doesNotMatch(zoomed,/viewBox="0 170 1536 740"/);assert.match(c.kiyiGarageArt('finish'),/viewBox="0 170 1536 740"/);
 const art={innerHTML:''},button={setAttribute(){}};c.document.querySelector=()=>({querySelector:s=>s==='.car-paint-display'?art:button,classList:{toggle(){}}});
 assert.equal(c.toggleKiyiPlateZoom(),true);assert.match(art.innerHTML,/viewBox="0 170 1536 740"/);assert.equal(c.toggleKiyiPlateZoom(),true);assert.doesNotMatch(art.innerHTML,/viewBox="0 170 1536 740"/);assert.equal(JSON.stringify(c.state),before);
 const header=c.kiyiGarageHeader('rims');assert.match(header,/Mavi elmas/);assert.doesNotMatch(header,/gold-coin|Mor elmas|Yakında|openCreditWallet/);assert.match(header,/>Jant</);assert.equal((header.match(/aria-current="page"/g)||[]).length,1);
});
test('rim preview applies and removes independently of accessories, plate, credits and model',()=>{
 const c=fixture(),art={innerHTML:''},before=JSON.stringify(c.state);c.kiyiSedanShowcase=p=>JSON.stringify(p);c.document.querySelector=()=>({querySelector:()=>art,querySelectorAll:()=>[]});
 c.save=()=>{throw Error('Preview cannot save')};assert.equal(c.previewKiyiRim('mesh-gold'),true);assert.equal(JSON.parse(art.innerHTML).vehicleRim,'mesh-gold');assert.equal(c.previewKiyiRim('invalid'),false);assert.equal(c.previewKiyiRim(null),true);assert.equal(JSON.parse(art.innerHTML).vehicleRim,null);assert.equal(JSON.stringify(c.state),before);
});

test('garage diamond actions never debit the gold wallet, and other screens retain their original handler',()=>{
 let goldCalls=0;const c=fixture({unlockCarColor:()=>{goldCalls++;return true},previewCarColor:()=>true});
 c.document.querySelector=()=>({querySelectorAll:()=>[],querySelector:()=>null});assert.equal(c.unlockCarColor(),false);assert.equal(goldCalls,0);assert.equal(c.previewCarColor('#ed4545'),true);assert.equal(goldCalls,0);
 c.document.querySelector=()=>null;assert.equal(c.unlockCarColor(),true);assert.equal(goldCalls,1);
});

test('rim tab starts zoomed and the user can restore the whole vehicle',()=>{
 const c=fixture();vm.runInContext("kiyiGarageTab='rims'",c);c.kiyiSedanShowcase=()=>'<svg viewBox="0 170 1536 740"></svg>';
 assert.doesNotMatch(c.kiyiGarageArt('rims'),/viewBox="0 170 1536 740"/);
 const art={innerHTML:''},button={setAttribute(){}};c.document.querySelector=()=>({querySelector:s=>s==='.car-paint-display'?art:button,classList:{toggle(){}}});
 assert.equal(c.toggleKiyiRimZoom(),true);assert.match(art.innerHTML,/viewBox="0 170 1536 740"/);assert.equal(c.toggleKiyiRimZoom(),true);assert.doesNotMatch(art.innerHTML,/viewBox="0 170 1536 740"/);
});


test('rim closeup contains both complete wheel faces on every model',()=>{
 const c=fixture();c.kiyiSedanShowcase=()=>'<svg viewBox="0 170 1536 740"></svg>';
 for(const model of ['bmw-3','audi-a3','mercedes-c','vw-golf','renault-clio','fiat-egea','toyota-corolla','legacy']){
  c.state.me.vehicleModel=model;c.state.me.car='';const box=c.kiyiGarageArt('rims').match(/viewBox="([^"]+)"/)[1].split(' ').map(Number),[x,y,w,h]=box;
  const rims=vm.runInContext('KiyiWrapFits['+JSON.stringify(model)+'].rims',c);
  for(const [cx,cy,rx,ry] of rims){assert(cx-rx>x&&cx+rx<x+w,model+' horizontal crop');assert(cy-ry>y&&cy+ry<y+h,model+' vertical crop');}
 }
});

test('model browser separates 21 cars and existing 18 motorcycles without recreating records',()=>{const c=fixture();vm.runInContext(fs.readFileSync(new URL('../public/motorcycle-assets.js',import.meta.url),'utf8'),c);c.setKiyiGarageModelType('motorcycle');const bikes=c.kiyiGarageModels();assert.equal((bikes.match(/data-motorcycle-model=/g)||[]).length,18);assert.match(bikes,/Honda PCX/);assert.match(bikes,/Yamaha NMAX/);assert.match(bikes,/Motosiklet/);assert.doesNotMatch(bikes,/chooseKiyiVehicleModel/);c.setKiyiGarageModelType('car');assert.equal((c.kiyiGarageModels().match(/data-model=/g)||[]).length,21);});

test('model page renders search and brand filters without changing balances',()=>{const c=fixture(),before=JSON.stringify(c.state);const html=c.kiyiGarageModels();assert.match(html,/Araç modeli ara/);assert.match(html,/Marka filtresi/);assert.equal((html.match(/data-model=/g)||[]).length,21);assert.equal(JSON.stringify(c.state),before);});
test('motorcycle model browser includes the same search and brand filtering fields',()=>{const c=fixture();c.KiyiMotorcycleAssets={'honda-pcx-125':{name:'Honda PCX 125',reviewed:true,image:'pcx.webp'},'yamaha-r25':{name:'Yamaha R25',reviewed:true,image:'r25.webp'}};vm.runInContext("kiyiGarageModelType='motorcycle'",c);const html=c.kiyiGarageModels();assert.match(html,/Motosiklet modeli ara/);assert.match(html,/Marka filtresi/);assert.match(html,/data-brand="Honda"/);assert.match(html,/data-brand="Yamaha"/);assert.match(html,/garage-model-status/);});

function navigationFixture(tab){
 const c=fixture(),art={innerHTML:''},controls={innerHTML:'',scrollIntoView(){}},count={textContent:'',setAttribute(){}},arrow={setAttribute(){}},host={querySelector:s=>s==='.car-paint-display'?art:s==='.garage-plate-controls'?controls:s==='.garage-hero-count'?count:arrow,querySelectorAll:()=>[]};
 c.document.querySelector=()=>host;c.kiyiSedanShowcase=p=>JSON.stringify(p);c.plateCanName=id=>['kiss','named','carbon','chrome'].includes(id);c.save=()=>{throw Error('Arrow previews must not save')};c.applyPlateStyle=()=>{throw Error('Arrow previews must not purchase')};vm.runInContext(`kiyiGarageTab=${JSON.stringify(tab)}`,c);return {c,art,count};
}
test('plate arrows cycle the six styles, wrap in both directions, and keep the model/profile unchanged',()=>{
 const {c,art,count}=navigationFixture('plate'),before=JSON.stringify(c.state);
 c.cycleKiyiGaragePreview(1);assert.equal(JSON.parse(art.innerHTML).plateStyle,'diamond');assert.equal(count.textContent,'2 / 6');
 c.cycleKiyiGaragePreview(-1);assert.equal(JSON.parse(art.innerHTML).plateStyle,'classic');
 c.cycleKiyiGaragePreview(-1);assert.equal(JSON.parse(art.innerHTML).plateStyle,'chrome');assert.equal(count.textContent,'6 / 6');
 c.previewKiyiGaragePlate('named');c.cycleKiyiGaragePreview(1);assert.equal(JSON.parse(art.innerHTML).plateStyle,'carbon');assert.equal(JSON.stringify(c.state),before);
});
test('rim and accessory arrows keep independent appearance slots and never select a new vehicle',()=>{
 const {c,art,count}=navigationFixture('rims'),before=JSON.stringify(c.state);
 c.cycleKiyiGaragePreview(1);assert.equal(JSON.parse(art.innerHTML).vehicleRim,'sport-red');
 c.cycleKiyiGaragePreview(-1);assert.equal(JSON.parse(art.innerHTML).vehicleRim,null);assert.match(count.textContent,/^1 \/ /);
 vm.runInContext("kiyiGarageTab='accessories'",c);c.cycleKiyiGaragePreview(1);assert.equal(JSON.parse(art.innerHTML).vehicleAccessories.headlights,'head-ice');
 c.previewKiyiAccessory('roof','roof-bow');c.cycleKiyiGaragePreview(1);const accessories=JSON.parse(art.innerHTML).vehicleAccessories;assert.equal(accessories.roof,'roof-stars');assert.equal(accessories.headlights,'head-ice');assert.equal(JSON.stringify(c.state),before);
});
test('model arrows follow displayed car order and preview without persisting a model choice',()=>{
 const {c,art,count}=navigationFixture('model'),before=JSON.stringify(c.state);
 c.chooseKiyiVehicleModel=()=>{throw Error('Arrow previews must not commit a vehicle')};
 c.cycleKiyiGaragePreview(1);assert.equal(JSON.parse(art.innerHTML).vehicleModel,'peugeot-208');assert.equal(count.textContent,'2 / 21');
 c.cycleKiyiGaragePreview(-1);assert.equal(JSON.parse(art.innerHTML).vehicleModel,'renault-clio');assert.equal(JSON.stringify(c.state),before);
});
test('finish arrows move through color and wrap previews without calling the purchase/save handlers',()=>{
 const {c}=navigationFixture('finish'),before=JSON.stringify(c.state),selected=[];
 c.CarColors=[{id:'#ffffff',name:'Beyaz'},{id:'#20242b',name:'Siyah'}];c.KiyiCarWraps=[{id:'race-95',name:'Yarış 95'},{id:'spider-web',name:'Örümcek Ağı'}];
 c.previewCarColor=id=>{vm.runInContext('kiyiGarageWrapPreview=null',c);selected.push(id)};c.previewCarWrap=id=>{vm.runInContext(`kiyiGarageWrapPreview=${JSON.stringify(id)}`,c);selected.push(id)};
 c.cycleKiyiGaragePreview(1);assert.equal(selected.at(-1),'#20242b');c.cycleKiyiGaragePreview(1);assert.equal(selected.at(-1),'race-95');c.cycleKiyiGaragePreview(-1);assert.equal(selected.at(-1),'#20242b');assert.equal(JSON.stringify(c.state),before);
});
test('garage-only plate fitting covers each measured model mount for all six designs without modifying the shared renderer',()=>{
 const c=fixture(),models=vm.runInContext('[...KiyiVehicleModels,KiyiLegacyVehicle]',c);
 for(const model of models)for(const style of ['classic','diamond','kiss','named','carbon','chrome']){
  const p={plate:'07 TEST 004',plateStyle:style,plateNames:{[style]:'DENİZ'}},original=c.kiyiVehiclePlate(p);
  const art=`<svg><g class="sedan-license-plate" transform="matrix(1 0 0 1 0 0)">${original}</g></svg>`,fitted=c.kiyiGarageFitPlate(art,p,model);
  assert.match(fitted,/garage-fitted-plate/);assert.doesNotMatch(fitted,/NaN|undefined/);assert.match(fitted,new RegExp(`data-plate-style="${style}"`));
  const matrix=fitted.match(/transform="matrix\(([^)]+)\)"/)[1].split(' ').map(Number);
  assert(Math.abs(matrix[0]*430-model.plate[2]*1.24)<1e-8);const frameHeight=Number(fitted.match(/<svg[^>]*height="([^"]+)"/)[1]);assert(Math.abs(matrix[3]*frameHeight-model.plate[3]*1.24)<1e-8);assert.equal(matrix[0],matrix[3]);assert.match(fitted,/garage-plate-number/);assert(Math.abs(matrix[4]+model.plate[2]*1.24/2-(model.plate[0]+model.plate[2]/2))<1e-8);assert(Math.abs(matrix[5]+model.plate[3]*1.24/2-(model.plate[1]+model.plate[3]/2))<1e-8);assert.equal(c.kiyiVehiclePlate(p),original);
 }
});
