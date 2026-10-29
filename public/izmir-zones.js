let referenceIconSequence=0;
/* İzmir discovery areas. Approximate surroundings, not surveyed road/geofence boundaries.
 * Coordinates: public map listings; branch choices confirmed by the project owner.
 * These overlays deliberately do not extend Core.onRoad or invent driving routes.
 */
const IzmirAreas=[
 {id:'iz-kucukpark',name:'Küçükpark',center:[38.460144,27.213274],radius:400,detail:'Bornova · Kazımdirik, Zafer Caddesi · Cochem Küçükpark'},
 {id:'iz-gul',name:'Gül Sokak',center:[38.4325,27.1401],radius:280,detail:'Alsancak · 1382 Sokak ve Dr. Mustafa Enver Bey Caddesi çevresi · Casual Alsancak · Rasa Alsancak'},
 {id:'iz-hasanaga',name:'Hasanağa',center:[38.382812,27.177658],radius:380,detail:'Buca · Adatepe, Hasanağa Bahçesi çevresi'},
 {id:'iz-myvia',name:'MyVia',center:[38.450766,27.200987],radius:280,detail:'Bornova · MyVia 414, Sanayi Caddesi No:31 · Cartel MyVia · Rasa MyVia'},
 {id:'iz-mojo',name:'Mojo',center:[38.407344,27.035751],radius:220,detail:'Balçova · İnciraltı Caddesi No:66 çevresi'},
 {id:'iz-mistral',name:'Mistral',center:[38.447842,27.178107],radius:300,detail:'Çınarlı · Ankara Asfaltı Caddesi No:15 çevresi'},
 {id:'iz-istinye',name:'İstinyePark',center:[38.3992,27.06788],radius:350,detail:'Balçova · Bahçelerarası, İstinyePark çevresi'},
 {id:'iz-guzelyali',name:'Güzelyalı',center:[38.398273,27.083021],radius:500,detail:'Konak · Mithatpaşa ve sahil çevresi'},
 {id:'iz-hatay',name:'Hatay',center:[38.4015,27.1063],radius:500,detail:'İzmir · İnönü Caddesi çevresi'}
];
function izmirRing(a){return Array.from({length:33},(_,i)=>{const t=i/32*Math.PI*2;return [a.center[0]+Math.sin(t)*a.radius/111320,a.center[1]+Math.cos(t)*a.radius/(111320*Math.cos(a.center[0]*Math.PI/180))]})}
const izmirGeoJSON={type:'FeatureCollection',features:IzmirAreas.map(a=>({type:'Feature',properties:{region:a.id,name:a.name},geometry:{type:'Polygon',coordinates:[izmirRing(a).map(p=>[p[1],p[0]])]}}))};
IzmirAreas.forEach(a=>{RoadData.centers[a.id]=a.center;RoadData.zooms[a.id]=15});
let mapCity='antalya',izmirLayer=null;
mapCity='antalya';
const cityNativeAreaSource=nativeAreaSource;
nativeAreaSource=function(){const data=cityNativeAreaSource();/* İzmir is inactive. */return data};
const cityRenderMap=renderMap;
renderMap=function(){
 if(mapCity==='izmir'&&!region.startsWith('iz-'))region=IzmirAreas[0].id;
 if(mapCity==='antalya'&&region.startsWith('iz-'))region='konyaalti';
 cityRenderMap();if(!map)return;
 izmirLayer=null;
 const host=document.querySelector('.region-chips');host.innerHTML='<div class="city-regions"></div>';
 document.querySelector('.map-experience').insertAdjacentHTML('beforeend','<div class="izmir-area-note" hidden><strong></strong><span>Yaklaşık çevre alanı</span></div>');
 mountCityRegions();
};
function mountCityRegions(){
 const iz=mapCity==='izmir';document.querySelectorAll('[data-city]').forEach(b=>{b.classList.toggle('active',b.dataset.city===mapCity);b.setAttribute('aria-pressed',String(b.dataset.city===mapCity))});
 const host=document.querySelector('.city-regions');if(!host)return;
 host.innerHTML=iz?'<label class="izmir-region-select"><span>Bölge</span><select aria-label="İzmir bölgesi" onchange="selectRegion(this.value)">'+IzmirAreas.map(a=>`<option value="${a.id}" ${a.id===region?'selected':''}>${a.name}</option>`).join('')+'</select></label>':[['konyaalti','Konyaaltı'],['lara','Lara'],['kultur','Kültür'],['bozkan','Bozkan']].map(([id,name])=>`<button class="region-chip ${id===region?'active':''}" id="region-${id}" onclick="selectRegion('${id}')">${pinIcon}${name}</button>`).join('');
 selectRegion(region,false);
 applyReferenceIconColors();
 document.querySelector('#map')?.setAttribute('aria-label',iz?'İzmir keşif haritası':'Antalya tur haritası');
}
function chooseMapCity(city){
 if(city!=='antalya')return;
 mapCity=city;region=city==='izmir'?IzmirAreas[0].id:'konyaalti';
 try{localStorage.setItem('kiyi-map-city',city)}catch{}
 if(document.querySelector('.map-experience')){clearSelectedCar();mountCityRegions()}
 updateDiscoveryCity();
}
function updateDiscoveryCity(){
 const select=document.querySelector('.discovery-city-picker select');if(select)select.value=mapCity;
}
function mountDiscoveryCity(){
 const hero=document.querySelector('.plate-search-card');if(!hero)return;
 if(!hero.querySelector('.discovery-city-picker'))hero.insertAdjacentHTML('afterbegin',`<label class="discovery-city-picker"><span class="discovery-city-location" aria-hidden="true">${pinIcon}</span><select aria-label="Şehir seçimi" onchange="chooseMapCity(this.value)"><option value="antalya">Antalya</option></select><svg class="discovery-city-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m6 9 6 6 6-6"/></svg></label>`);
 updateDiscoveryCity();
}

const cityDiscoveryRender=render;
window.render=function(){cityDiscoveryRender.apply(this,arguments);if(location.hash==='#search')mountDiscoveryCity();applyReferenceIconColors()};
const cityDiscoveryObserver=new MutationObserver(()=>{if(location.hash==='#search'&&!document.querySelector('.discovery-city-picker'))mountDiscoveryCity()});
cityDiscoveryObserver.observe(document.getElementById('app'),{childList:true,subtree:true});
if(location.hash==='#search')mountDiscoveryCity();

const citySelectRegion=selectRegion;
selectRegion=function(id,animate=true){
 if(id==='all'){region='all';document.querySelectorAll('.region-chip').forEach(x=>x.classList.toggle('active',x.id==='region-all'));const bs=Object.values(RoadData.bounds).flat();const south=Math.min(...bs.map(x=>x[0])),north=Math.max(...bs.map(x=>x[0])),west=Math.min(...bs.map(x=>x[1])),east=Math.max(...bs.map(x=>x[1]));if(nativeMap)nativeMap.fitBounds([[west,south],[east,north]],{padding:50,duration:animate?700:0});else if(map)map.fitBounds([[south,west],[north,east]],{animate});return;}
 citySelectRegion(id,animate);const area=IzmirAreas.find(a=>a.id===id);
 if(izmirLayer)izmirLayer.setStyle(f=>({fillOpacity:f.properties.region===id?.26:.16}));
 const note=document.querySelector('.izmir-area-note');if(note){note.hidden=!area;if(area)note.querySelector('strong').textContent=area.detail}
 const select=document.querySelector('.izmir-region-select select');if(select&&area)select.value=id;
 if(area&&nativeMap)nativeMap.flyTo({center:[area.center[1],area.center[0]],zoom:15,pitch:45,bearing:0,duration:animate?800:0});
};

// SVG-local gradients keep strokes reliable on Safari and after route changes.
function applyReferenceIconColors(){
 const targets=[...document.querySelectorAll('.region-chip svg,.discovery-city-location svg,#ghostbtn>svg,.map-layers-button>svg,.map-meetup-link>svg,.inbox-launch>svg,#nav .navicon svg')];
 targets.forEach((svg,index)=>{
  if(svg.querySelector('defs[data-reference-colors]'))return;
  const ghost=svg.parentElement.id==='ghostbtn',id='kiyi-reference-'+(++referenceIconSequence);
  const ns='http://www.w3.org/2000/svg',defs=document.createElementNS(ns,'defs'),gradient=document.createElementNS(ns,'linearGradient');
  defs.setAttribute('data-reference-colors','true');gradient.id=id;gradient.setAttribute('gradientUnits','userSpaceOnUse');
  for(const [key,value] of Object.entries({x1:'4',y1:'3',x2:'19',y2:'22'}))gradient.setAttribute(key,value);
  (ghost?['#687184','#191a35']:['#b754f6','#6200ce']).forEach((color,i)=>{const stop=document.createElementNS(ns,'stop');stop.setAttribute('offset',i?'100%':'0%');stop.setAttribute('stop-color',color);gradient.append(stop)});
  defs.append(gradient);svg.prepend(defs);svg.style.setProperty('--reference-stroke',`url(#${id})`);
  if(svg.parentElement.classList.contains('inbox-launch'))svg.querySelector('rect')?.setAttribute('fill',`url(#${id})`);else svg.setAttribute('stroke',`url(#${id})`);
 });
}

// Inbox refreshes its envelope when unread counts change.
const referenceLauncher=document.querySelector('.inbox-launch');
if(referenceLauncher)new MutationObserver(()=>applyReferenceIconColors()).observe(referenceLauncher,{childList:true});
