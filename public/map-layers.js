/* OpenFreeMap style chooser. 3D uses native MapLibre so pitch, markers and
 * selection polygons share the same camera projection. */
let mapStyleMode='street';
try{const saved=localStorage.getItem('kiyi-map-style');if(['street','fiord','3d'].includes(saved))mapStyleMode=saved}catch{}
let rasterBasemap=null;
let vectorBasemap=null,nativeMap=null,nativePins=new Map(),nativeSelf=null,styleRequest=0;
const mapStyleNames={street:'Standart',fiord:'Koyu','3d':'3D'};
function mapStyleLabel(){return 'OpenFreeMap · '+mapStyleNames[mapStyleMode]}
function mapStyleError(error){window.KiyiReportDiagnostic?.('map_error');const el=$('#maperror');if(el){el.hidden=false;el.textContent='Harita yüklenemedi. '+(error?.message||'Bağlantını kontrol et.')}console.warn('Piyaso harita:',error)}
// Share style requests and persist small style documents, never tile data.
const mapStylePromises=new Map(),styleCacheTTL=24*60*60*1000;
const copyMapStyle=s=>JSON.parse(JSON.stringify(s));
async function fetchMapStyle(mode){
 if(!mapStyleNames[mode])throw Error('Bilinmeyen harita türü');
 if(!mapStylePromises.has(mode)){
  const task=(async()=>{
   try{const cached=JSON.parse(localStorage.getItem('kiyi-style-v34-'+mode)||'null');if(cached&&Date.now()-cached.time<styleCacheTTL&&cached.style?.version===8&&Array.isArray(cached.style.layers))return cached.style}catch{}
   let style;
   if(mode==='street')style=await KIYI_CUSTOM_MAP_STYLE.load();
   else{const response=await fetch('https://tiles.openfreemap.org/styles/'+(mode==='fiord'?'fiord':'liberty'),{signal:AbortSignal.timeout(15000),cache:'default'});if(!response.ok)throw Error('OpenFreeMap bağlantısı: HTTP '+response.status);style=await response.json()}
   if(style?.version!==8||!Array.isArray(style.layers))throw Error('Harita biçimi geçersiz');
   try{localStorage.setItem('kiyi-style-v34-'+mode,JSON.stringify({time:Date.now(),style}))}catch{}
   return style;
  })();mapStylePromises.set(mode,task);task.catch(()=>{if(mapStylePromises.get(mode)===task)mapStylePromises.delete(mode)});
 }
 return copyMapStyle(await mapStylePromises.get(mode));
}
let graphicsChecked=false;
function checkMapGraphics(){if(graphicsChecked)return;const canvas=document.createElement('canvas');const gl=canvas.getContext('webgl2')||canvas.getContext('webgl');if(!gl)throw Error('Bu tarayıcıda WebGL açılamadı.');gl.getExtension('WEBGL_lose_context')?.loseContext();graphicsChecked=true}
function mapRenderOptions(){return {pixelRatio:Math.min(typeof devicePixelRatio==='number'?devicePixelRatio:1,2),fadeDuration:0,maxTileCacheSize:256}}
// Keep workers ready when moving between map, search and profile screens.
if(typeof maplibregl!=='undefined'){try{maplibregl.prewarm()}catch{}}
function activateRasterFallback(target){
 if(typeof L==='undefined'||typeof L.tileLayer!=='function'||map!==target||!target.getContainer().isConnected)return false;
 try{
  rasterBasemap=L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19,keepBuffer:1,updateWhenIdle:true,referrerPolicy:'strict-origin-when-cross-origin'}).addTo(target);
  mapStyleMode='street';
  rasterBasemap.on('load',()=>{if(map===target&&$('#maperror'))$('#maperror').hidden=true});
  rasterBasemap.on('tileerror',()=>{if(map===target)mapStyleError(Error('Standart harita bağlantısı kurulamadı.'))});
  const credit=document.querySelector('.map-source-corner');if(credit)credit.innerHTML='<a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">© OpenStreetMap katkıcıları</a>';
  const error=$('#maperror');if(error){error.hidden=false;error.textContent='Standart harita yükleniyor. Bu cihazda 3B harita kullanılamıyor.';}
  return true;
 }catch{return false}
}
async function initVectorBasemap(target){
 vectorBasemap=null;const version=++styleRequest;
 try{
  checkMapGraphics();if(mapStyleMode==='3d'){await activateNative3D();return}const style=await fetchMapStyle(mapStyleMode);
  if(map!==target||!target.getContainer().isConnected||version!==styleRequest)return;
  vectorBasemap=L.maplibreGL({style,interactive:false,...mapRenderOptions()}).addTo(target);
  if(rasterBasemap){target.removeLayer(rasterBasemap);rasterBasemap=null;}
  const gl=vectorBasemap.getMaplibreMap();gl.on('error',e=>console.warn('OpenFreeMap:',e.error));
  gl.once('load',()=>{if(map===target&&$('#maperror'))$('#maperror').hidden=true});
  if(mapStyleMode==='3d')await activateNative3D();
 }catch(error){if(map===target&&!activateRasterFallback(target))mapStyleError(error)}
}
const realMapPreviews=new Map();let previewRun=0,previewMap=null;
for(const mode of Object.keys(mapStyleNames)){try{const c=JSON.parse(localStorage.getItem('kiyi-preview-v34-'+mode)||'null');if(c&&Date.now()-c.time<7*86400000&&/^data:image\/jpeg;base64,/.test(c.image))realMapPreviews.set(mode,c.image)}catch{}}
function miniature(mode){const img=realMapPreviews.get(mode);return `<span class="real-map-preview" data-preview-mode="${mode}">${img?`<img src="${img}" alt="${mapStyleNames[mode]} gerçek harita önizlemesi">`:'<span class="preview-loading">Önizleme hazırlanıyor…</span>'}</span>`}
function stopPreviewMap(){previewRun++;if(previewMap){previewMap.remove();previewMap=null}document.querySelector('.preview-staging')?.remove()}
async function loadRealMapPreviews(){
 const modes=Object.keys(mapStyleNames).filter(mode=>!realMapPreviews.has(mode));if(!modes.length)return;
 stopPreviewMap();const run=previewRun;let staging;
 // Fetch the tiny style documents in parallel; use just one renderer for all cards.
 const styles=new Map(modes.map(mode=>[mode,fetchMapStyle(mode).then(style=>({style}),error=>({error}))]));
 try{
  checkMapGraphics();staging=document.createElement('div');staging.className='preview-staging';document.querySelector('.map-layer-dialog').append(staging);
  for(const mode of modes){
   const host=document.querySelector(`[data-preview-mode="${mode}"]`);if(!host||$('#maplayers')?.hidden||run!==previewRun)return;
   const {style,error}=await styles.get(mode);if(error){host.innerHTML='<span class="preview-loading">Önizleme alınamadı</span>';continue}if(run!==previewRun)return;
   if(!previewMap)previewMap=new maplibregl.Map({container:staging,style,center:[30.704,36.884],zoom:mode==='3d'?15.5:12.5,pitch:mode==='3d'?55:0,bearing:mode==='3d'?-20:0,interactive:false,attributionControl:false,preserveDrawingBuffer:true,pixelRatio:1,fadeDuration:0,maxTileCacheSize:32});
   else{previewMap.setStyle(style,{diff:true});previewMap.jumpTo({center:[30.704,36.884],zoom:mode==='3d'?15.5:12.5,pitch:mode==='3d'?55:0,bearing:mode==='3d'?-20:0})}
   const gl=previewMap;
   const ready=await new Promise(resolve=>{let timer;const done=ok=>{clearTimeout(timer);gl.off('idle',idle);resolve(ok)};const idle=()=>done(true);gl.once('idle',idle);timer=setTimeout(()=>done(false),5000)});
   if(run!==previewRun)return;
   if(!ready){host.innerHTML='<span class="preview-loading">Önizleme alınamadı</span>';continue}
   const img=gl.getCanvas().toDataURL('image/jpeg',.7);realMapPreviews.set(mode,img);try{localStorage.setItem('kiyi-preview-v34-'+mode,JSON.stringify({time:Date.now(),image:img}))}catch{}
   host.innerHTML=`<img src="${img}" alt="${mapStyleNames[mode]} gerçek harita önizlemesi">`;
  }
 }catch{if(run===previewRun)document.querySelectorAll('.preview-loading').forEach(e=>e.textContent='Önizleme açılamadı')}
 finally{if(run===previewRun){previewMap?.remove();previewMap=null;staging?.remove()}}
}
function mountMapLayerUI(){
 const host=document.querySelector('.map-experience');if(!host)return;
 host.insertAdjacentHTML('beforeend',`<div class="map-source-corner"><a href="https://openfreemap.org/" target="_blank" rel="noopener">OpenFreeMap</a> · <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">© OpenStreetMap</a></div><button class="map-layers-button" onclick="openMapLayers()" aria-label="Harita katmanları" aria-haspopup="dialog" aria-expanded="false"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="m12 3 9 5-9 5-9-5Z"/><path d="m3 12 9 5 9-5M3 16l9 5 9-5"/></svg></button><div class="map-layer-backdrop" id="maplayers" hidden onclick="if(event.target===this)closeMapLayers()"><section class="map-layer-dialog" role="dialog" aria-modal="true" aria-labelledby="maplayer-title"><button class="map-layer-close" onclick="closeMapLayers()" aria-label="Harita görünümünü kapat">×</button><h2 id="maplayer-title">Harita görünümü</h2><nav class="map-view-tabs" aria-label="Harita görünümü"><button aria-pressed="true" onclick="mapViewTab(this,'icon')">Konum simgesi</button><button aria-pressed="false" onclick="mapViewTab(this,'map')">Harita</button></nav><div class="map-view-content"><div id="map-self-options"></div><div class="map-layer-choices" id="map-style-options" hidden>${Object.keys(mapStyleNames).map(mode=>`<button class="map-layer-option ${mode===mapStyleMode?'is-selected':''}" data-map-style="${mode}" aria-pressed="${mode===mapStyleMode}" onclick="chooseMapStyle('${mode}')"><span class="map-layer-preview">${miniature(mode)}</span><span>${mapStyleNames[mode]}</span></button>`).join('')}</div><p class="map-layer-status" id="maplayerstatus" role="status"></p></div><div class="map-source-credits">Harita: <a href="https://openfreemap.org/" target="_blank" rel="noopener noreferrer">OpenFreeMap</a> · <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener noreferrer">© OpenStreetMap katkıcıları</a></div></section></div>`);
 if(rasterBasemap){const credit=host.querySelector('.map-source-corner');if(credit)credit.innerHTML='<a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">© OpenStreetMap katkıcıları</a>'; }
}
function openMapLayers(){renderSelfOptions();$('#maplayers').hidden=false;document.querySelector('.map-layers-button').setAttribute('aria-expanded','true');document.querySelector('.map-layer-close').focus();}
function closeMapLayers(){stopPreviewMap();if($('#maplayers'))$('#maplayers').hidden=true;document.querySelector('.map-layers-button')?.setAttribute('aria-expanded','false');document.querySelector('.map-layers-button')?.focus()}
document.addEventListener('keydown',e=>{if($('#maplayers')?.hidden===false){if(e.key==='Escape'){e.preventDefault();closeMapLayers()}if(e.key==='Tab'){const a=[...$('#maplayers').querySelectorAll('button:not(:disabled)')];if(e.shiftKey&&document.activeElement===a[0]){e.preventDefault();a.at(-1).focus()}else if(!e.shiftKey&&document.activeElement===a.at(-1)){e.preventDefault();a[0].focus()}}}});
async function chooseMapStyle(mode){
 if(!mapStyleNames[mode]||!map)return;if(mode===mapStyleMode&&(vectorBasemap||nativeMap)){closeMapLayers();return}stopPreviewMap();
 const target=map,request=++styleRequest;const buttons=[...document.querySelectorAll('.map-layer-option')];buttons.forEach(b=>b.disabled=true);$('#maplayerstatus').textContent='Harita yükleniyor…';
 try{
  checkMapGraphics();
  if(mode==='3d'){await activateNative3D()}
  else{
   const style=await fetchMapStyle(mode);if(map!==target||request!==styleRequest)return;
   if(!vectorBasemap){vectorBasemap=L.maplibreGL({style,interactive:false,...mapRenderOptions()}).addTo(target)}else vectorBasemap.getMaplibreMap().setStyle(style,{diff:true});
   // Keep the last 3D camera position when returning to a flat map.
   const camera=nativeMap?{center:nativeMap.getCenter(),zoom:nativeMap.getZoom()+1}:null;
   cleanupNativeMap();if(camera)target.setView([camera.center.lat,camera.center.lng],camera.zoom,{animate:false});
  }
  if(map!==target||request!==styleRequest){cleanupNativeMap();return}
  mapStyleMode=mode;try{localStorage.setItem('kiyi-map-style',mode)}catch{}
  buttons.forEach(b=>{const selected=b.dataset.mapStyle===mode;b.classList.toggle('is-selected',selected);b.setAttribute('aria-pressed',String(selected))});
  $('#maplayerstatus').textContent='';if($('#maperror'))$('#maperror').hidden=true;const notice=document.querySelector('.map-notice');if(notice)notice.textContent=mapStyleLabel();closeMapLayers();
 }catch(error){if($('#maplayerstatus'))$('#maplayerstatus').textContent='Bu harita açılamadı. '+error.message;if(mode==='3d')cleanupNativeMap()}
 finally{buttons.forEach(b=>b.disabled=false)}
}
function cleanupNativeMap(){stopPreviewMap();nativePins.forEach(m=>m.remove());nativePins.clear();nativeSelf?.remove();nativeSelf=null;if(nativeMap){nativeMap.remove();nativeMap=null}$('#native-map')?.remove();document.querySelector('.map-experience')?.classList.remove('map-native-mode')}
function nativeAreaSource(){return {type:'FeatureCollection',features:[['konyaalti',RoadData.konyaaltiCoverageBoundary],['kultur',RoadData.kulturBoundary]].map(([name,points])=>({type:'Feature',properties:{region:name},geometry:{type:'Polygon',coordinates:[points.map(p=>[p[1],p[0]])]}})).concat(RoadData.laraCoverage.features,RoadData.stationAreas.features)}}
function updateNativeAreas(){if(nativeMap?.getLayer('kiyi-areas-fill'))nativeMap.setPaintProperty('kiyi-areas-fill','fill-opacity',['case',['==',['get','region'],region],.26,.16])}
async function activateNative3D(){
 if(nativeMap)return;
 const target=map;const style=await fetchMapStyle('3d');if(map!==target)return;
 const container=document.createElement('div');container.id='native-map';container.setAttribute('aria-label','Antalya 3D haritası');document.querySelector('.map-experience').prepend(container);
 const center=target.getCenter();let gl;
 try{gl=new maplibregl.Map({container,style,center:[center.lng,center.lat],zoom:Math.max(15.4,target.getZoom()-1),pitch:55,bearing:-20,attributionControl:false,...mapRenderOptions()});nativeMap=gl;
  await new Promise((resolve,reject)=>{const timeout=setTimeout(()=>reject(Error('3D harita bağlantısı zaman aşımına uğradı.')),18000);gl.once('load',()=>{clearTimeout(timeout);resolve()});gl.once('error',e=>{clearTimeout(timeout);reject(e.error||Error('3D harita yüklenemedi'))})});
  if(map!==target||nativeMap!==gl)return;
  // Liberty contains its official building-3d fill-extrusion layer.
  gl.addSource('kiyi-areas',{type:'geojson',data:nativeAreaSource()});
  const before=gl.getStyle().layers.find(l=>l.id==='building'||l.type==='fill-extrusion'||l.type==='symbol')?.id;
  gl.addLayer({id:'kiyi-areas-fill',type:'fill',source:'kiyi-areas',paint:{'fill-color':'#59AE73','fill-opacity':.26}},before);updateNativeAreas();if(region==='lara'||region==='kultur')gl.fitBounds([[RoadData.bounds[region][0][1],RoadData.bounds[region][0][0]],[RoadData.bounds[region][1][1],RoadData.bounds[region][1][0]]],{padding:70,pitch:45,bearing:0,maxZoom:14,duration:0});
  gl.addSource('kiyi-lara-endpoints',{type:'geojson',data:{type:'FeatureCollection',features:RoadData.laraEndpoints.concat(RoadData.stations||[]).map(e=>({type:'Feature',properties:{label:e.label},geometry:{type:'Point',coordinates:[e.pos[1],e.pos[0]]}}))}});gl.addLayer({id:'kiyi-lara-endpoints',type:'circle',source:'kiyi-lara-endpoints',paint:{'circle-radius':6,'circle-color':'#fff','circle-stroke-color':'#8b4cf6','circle-stroke-width':2}});gl.on('click',()=>clearSelectedCar());document.querySelector('.map-experience').classList.add('map-native-mode');refreshNativeCars();
 }catch(error){gl?.remove();nativeMap=null;container.remove();throw error}
}
function refreshNativeCars(){
 if(!nativeMap||!$('#native-map'))return;
 const visible=profiles.filter(p=>!state.blocked.includes(p.id)&&p.sharing&&(p.visibility==='all'||p.approved.includes('me')));const ids=new Set(visible.map(p=>p.id));
 nativePins.forEach((m,id)=>{if(!ids.has(id)){m.remove();nativePins.delete(id)}});
 visible.forEach(p=>{const v=routePosition(p.id);if(!Core.onRoad(v.pos))return;let m=nativePins.get(p.id);if(!m){const el=document.createElement('div');el.className='native-car-pin';el.innerHTML=carWithOwner(p,v.angle);el.tabIndex=0;el.setAttribute('role','button');el.setAttribute('aria-label',profileLocked(p)?'Hayalet araç profili':p.plate+' profili');el.onclick=e=>{e.stopPropagation();selectCar(p.id)};el.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();selectCar(p.id)}};m=new maplibregl.Marker({element:el,anchor:'bottom',offset:[0,19]}).setLngLat([v.pos[1],v.pos[0]]).addTo(nativeMap);nativePins.set(p.id,m)}else{m.setLngLat([v.pos[1],v.pos[0]]);const car=m.getElement().querySelector('.top-car');if(car)car.style.transform=`rotate(${v.angle-nativeMap.getBearing()}deg)`}m.getElement().classList.toggle('selected-vehicle',selectedCar===p.id)});
 const showSelf=state.premium&&tour.active&&tour.pos&&Date.now()<tour.until&&Date.now()-tour.last<120000&&Core.onRoad(tour.pos);
 if(showSelf){if(!nativeSelf){const el=document.createElement('div');el.className='native-car-pin';el.innerHTML=selfMapMarker(0);el.onclick=e=>{e.stopPropagation();openProfile('me')};nativeSelf=new maplibregl.Marker({element:el,anchor:'bottom',offset:[0,19]}).setLngLat([tour.pos[1],tour.pos[0]]).addTo(nativeMap)}else nativeSelf.setLngLat([tour.pos[1],tour.pos[0]])}else{nativeSelf?.remove();nativeSelf=null}
}
const layersOriginalRenderMap=renderMap;
renderMap=function(){layersOriginalRenderMap();mountMapLayerUI()};
const layersOriginalRefreshMarkers=refreshMarkers;
refreshMarkers=function(){if(nativeMap){refreshNativeCars();return}layersOriginalRefreshMarkers()};
const layersOriginalSelectRegion=selectRegion;
selectRegion=function(id,animate=true){layersOriginalSelectRegion(id,nativeMap?false:animate);if(nativeMap){if(id==='lara'||id==='kultur')nativeMap.fitBounds([[RoadData.bounds[id][0][1],RoadData.bounds[id][0][0]],[RoadData.bounds[id][1][1],RoadData.bounds[id][1][0]]],{padding:70,pitch:45,bearing:0,maxZoom:14,duration:animate?800:0});else nativeMap.flyTo({center:[RoadData.centers[id][1],RoadData.centers[id][0]],zoom:Math.max(15.4,RoadData.zooms[id]-1),pitch:55,bearing:-20,duration:animate?800:0});updateNativeAreas()}};

// Device-only display preference. Never included in profile, position or vehicle RPCs.
const selfMarkerColors=['#2563eb','#8b5cf6','#ec4899','#ef4444','#f59e0b','#22c55e','#06b6d4'];
let selfMarkerPreference={kind:'auto',color:'#8b5cf6'};
try{const p=JSON.parse(localStorage.getItem('kiyi-self-marker-v2')||'null');if(p&&['arrow','auto','motorcycle'].includes(p.kind)&&selfMarkerColors.includes(p.color))selfMarkerPreference=p}catch{}
function selfMapMarker(angle=0,profile=state.me){
 const p={...profile};
 if(selfMarkerPreference.kind==='auto')return carWithOwner(p,angle);
 if(selfMarkerPreference.kind==='motorcycle')return carWithOwner({...p,vehicleKind:'motorcycle'},angle);
 return `<div class="car-owner-marker"><svg class="top-car self-location-arrow" viewBox="0 0 64 90" width="48" height="74" style="transform:rotate(${Number(angle)||0}deg)" role="img" aria-label="Konum oku"><path d="M32 8 58 78 32 63 6 78Z" fill="${selfMarkerPreference.color}" stroke="#ffffff" stroke-width="2"/></svg></div>`;
}
function renderSelfOptions(){const host=document.getElementById('map-self-options');if(!host)return;host.innerHTML=`<div class="map-layer-choices self-marker-choices">${[['arrow','Ok'],['auto','Otomatik'],['motorcycle','Motosiklet']].map(([kind,label])=>`<button class="map-layer-option ${selfMarkerPreference.kind===kind?'is-selected':''}" aria-pressed="${selfMarkerPreference.kind===kind}" onclick="chooseSelfMarker('${kind}')"><span class="map-layer-preview self-marker-preview" style="color:${selfMarkerPreference.color}">${kind==='arrow'?'<svg viewBox="0 0 64 90"><path d="M32 8 58 78 32 63 6 78Z" fill="currentColor"/></svg>':carWithOwner({...state.me,vehicleKind:kind==='motorcycle'?'motorcycle':state.me.vehicleKind},0)}</span><span>${label}</span></button>`).join('')}</div>${selfMarkerPreference.kind==='arrow'?`<h3>Ok rengi</h3><div class="self-marker-colors">${selfMarkerColors.map((color,i)=>`<button style="--marker-color:${color}" aria-label="${['Mavi','Mor','Pembe','Kırmızı','Turuncu','Yeşil','Turkuaz'][i]}" aria-pressed="${selfMarkerPreference.color===color}" onclick="chooseSelfMarker(null,'${color}')">${selfMarkerPreference.color===color?'✓':''}</button>`).join('')}</div>`:''}`;}
function chooseSelfMarker(kind,color){if(kind&&!['arrow','auto','motorcycle'].includes(kind)||color&&!selfMarkerColors.includes(color))return;selfMarkerPreference={...selfMarkerPreference,kind:kind||selfMarkerPreference.kind,color:color||selfMarkerPreference.color};try{localStorage.setItem('kiyi-self-marker-v2',JSON.stringify(selfMarkerPreference))}catch{}renderSelfOptions();if(typeof myPin!=='undefined'&&myPin){myPin.getElement()?.replaceChildren();if(myPin.setIcon)myPin.setIcon(L.divIcon({className:'car-pin self-owner-pin',html:selfMapMarker(),iconSize:[64,100],iconAnchor:[32,81]}));else if(myPin.getElement())myPin.getElement().innerHTML=selfMapMarker();}if(nativeSelf)nativeSelf.getElement().innerHTML=selfMapMarker();window.dispatchEvent(new Event('kiyi:self-marker'));}
function mapViewTab(button,tab){const dialog=button.closest('.map-layer-dialog');dialog.querySelectorAll('.map-view-tabs button').forEach(b=>b.setAttribute('aria-pressed',String(b===button)));document.getElementById('map-self-options').hidden=tab!=='icon';document.getElementById('map-style-options').hidden=tab!=='map';if(tab==='map')loadRealMapPreviews();else stopPreviewMap();}
