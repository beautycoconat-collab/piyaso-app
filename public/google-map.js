/* Native Google Maps renderer. No unofficial Google tile URLs or proxy tiles. */
let googleMapInstance=null;
function mountGoogleMap(){
 const g=google.maps;
 googleMapInstance=new g.Map(document.getElementById('map'),{center:{lat:36.869,lng:30.649},zoom:14,mapTypeId:'roadmap',disableDefaultUI:true,gestureHandling:'greedy',clickableIcons:false});
 const native=googleMapInstance;
 map={__google:true,setView(pos,zoom){native.setCenter({lat:pos[0],lng:pos[1]});native.setZoom(zoom)},fitBounds(points){const b=new g.LatLngBounds();points.forEach(p=>b.extend({lat:p[0],lng:p[1]}));native.fitBounds(b,40)},removeLayer(m){m.setMap(null)},remove(){movingPins.forEach(m=>m.setMap(null));myPin?.setMap(null);googleMapInstance=null}};
 const wrap=shape=>({setStyle(o){const opts={};for(const [key,value] of Object.entries({strokeColor:o.color,strokeWeight:o.weight,strokeOpacity:o.opacity,fillOpacity:o.fillOpacity})){if(value!==undefined)opts[key]=value}shape.setOptions(opts)}});
 coverageLayer=wrap(new g.Polygon({map:native,paths:RoadData.selectionBoundary.map(p=>({lat:p[0],lng:p[1]})),strokeColor:'#81ad7b',strokeWeight:1,strokeOpacity:.5,fillColor:'#81b36b',fillOpacity:.10,clickable:false}));
 roadLayers=[];
 RoadData.secondaryRoads.forEach(r=>roadLayers.push({region:'konyaalti',secondary:true,layer:wrap(new g.Polyline({map:native,path:r.points.map(p=>({lat:p[0],lng:p[1]})),strokeColor:'#6baa83',strokeWeight:2,strokeOpacity:.45,clickable:false}))}));
 RoadData.displayRoutes.forEach(r=>roadLayers.push({region:r.region,secondary:false,layer:wrap(new g.Polyline({map:native,path:r.points.map(p=>({lat:p[0],lng:p[1]})),strokeColor:'#327c59',strokeWeight:3.5,strokeOpacity:.9,clickable:false}))}));
 native.addListener('click',clearSelectedCar);selectRegion(region,false);refreshGoogleCars();updateTourUI();
}
let GoogleCarOverlay;
function googleCar(pos,p,self=false){
 if(!GoogleCarOverlay){GoogleCarOverlay=class extends google.maps.OverlayView{
 constructor(point,profile,isSelf){super();this.point=point;this.profile=profile;this.self=isSelf;this.el=document.createElement('button');this.el.className=isSelf?'google-car self-pin':'google-car car-pin';this.el.setAttribute('aria-label',isSelf?'Sen · Yalnızca bu cihazda':profile.name+' · Demo');this.el.innerHTML=isSelf?selfMapMarker():carTop(profile.id==='d2'?'#3b4347':'#fff');this.el.onclick=e=>{e.stopPropagation();if(!this.self)selectCar(this.profile.id)}}
 onAdd(){this.getPanes().overlayMouseTarget.append(this.el)}
 draw(){const projection=this.getProjection();if(!projection)return;const pt=projection.fromLatLngToDivPixel(new google.maps.LatLng(this.point[0],this.point[1]));if(pt){this.el.style.left=(pt.x-10)+'px';this.el.style.top=(pt.y-(this.self?10:19))+'px'}}
 onRemove(){this.el.remove()}
 setLatLng(p){this.point=p;this.draw()}
 getElement(){return this.el}
 };}
 const pin=new GoogleCarOverlay(pos,p,self);pin.setMap(googleMapInstance);return pin;
}
function refreshGoogleCars(){
 if(!googleMapInstance)return;
 const visible=profiles.filter(p=>!state.blocked.includes(p.id)&&p.sharing&&(p.visibility==='all'||p.approved.includes('me')));
 const ids=new Set(visible.map(p=>p.id));
 movingPins.forEach((m,id)=>{if(!ids.has(id)){m.setMap(null);movingPins.delete(id);if(selectedCar===id)clearSelectedCar()}});
 visible.forEach(p=>{const v=routePosition(p.id);if(!Core.onRoad(v.pos)){const old=movingPins.get(p.id);old?.setMap(null);movingPins.delete(p.id);return}let pin=movingPins.get(p.id);if(!pin){pin=googleCar(v.pos,p);movingPins.set(p.id,pin)}else pin.setLatLng(v.pos);v.angle=RoadEngine.continuousAngle(markerAngles.get(p.id),v.angle);markerAngles.set(p.id,v.angle);const img=pin.getElement().querySelector('.top-car');if(img)img.style.transform=`rotate(${v.angle}deg)`});
 const showSelf=state.premium&&tour.active&&!tour.ghost&&tour.pos&&Date.now()<tour.until&&Date.now()-tour.last<120000&&Core.onRoad(tour.pos);
 if(showSelf){const pos=Core.approximate(tour.pos);if(!myPin)myPin=googleCar(pos,null,true);else myPin.setLatLng(pos)}else if(myPin){myPin.setMap(null);myPin=null}
}
(function loadGoogleMaps(){
 const key=window.KIYI_MAP_CONFIG?.googleMapsApiKey;if(!key)return;
 let failed=false;
 function showFailure(){failed=true;const el=document.getElementById('maperror');if(el){el.hidden=false;el.textContent='Google Maps açılamadı. API anahtarı, alan adı izni ve bağlantı kontrol edilmeli.'}}
 window.gm_authFailure=showFailure;
 window.kiyiGoogleReady=()=>{if(!failed&&(location.hash.slice(1)||'map')==='map'){if(map)map.remove();renderMap()}};
 const script=document.createElement('script');script.src='https://maps.googleapis.com/maps/api/js?key='+encodeURIComponent(key)+'&loading=async&callback=kiyiGoogleReady&language=tr&region=TR&v=quarterly';script.async=true;script.onerror=showFailure;document.head.append(script);
})();
