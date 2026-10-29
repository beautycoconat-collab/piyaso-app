/* Piyaso v17 — official OpenFreeMap Bright map: pale built-up areas, green countryside.
 * This module fetches the official Bright style from OpenFreeMap, then only
 * alters paint colors. No Liberty, Esri, or Google basemap is used.
 * Vector tiles, fonts, sprites remain served by OpenFreeMap.
 */
(function(root){
 'use strict';
 const brightStyleUrl='https://tiles.openfreemap.org/styles/bright';
 // Built-up city areas remain cream, while unbuilt countryside becomes green.
 // NOTE: Bright draws city polygons using the OpenMapTiles landuse source.
 // Areas lacking urban landuse data will show the countryside color.
 const colors=Object.freeze({
   background:'#D5EFA8',       // light green countryside (not cities)
   residential:'#FAFAF7',      // cream/near-white settlement polygons,
   commercial:'#FAFAF7',
   industrial:'#F7F7F3',
   park:'#C3E6A0',
   wood:'#A9D88D',
   grass:'#D0EBAA',
   beach:'#F3E8C8',
   water:'#9EDAF4',            // reference turquoise, not old Liberty lilac-blue
   waterway:'#9EDAF4',
   road:'#DEE0E4',             // gray main roads (no yellow)
   roadCasing:'#B8BDC4',
   roadMinor:'#FFFFFF',       // narrow streets like reference
   roadMinorCasing:'#D6D9DD',
   roadPath:'#E7E1D5'
 });
 const replace={
   'background':['background-color','background'],
   'landuse-residential':['fill-color','residential'],
   'landuse-suburb':['fill-color','residential'],
   'landuse-commercial':['fill-color','commercial'],
   'landuse-industrial':['fill-color','industrial'],
   'park':['fill-color','park'],
   'landcover-wood':['fill-color','wood'],
   'landcover-grass':['fill-color','grass'],
   'landcover-grass-park':['fill-color','park'],
   'landcover-sand':['fill-color','beach'],
   'water':['fill-color','water'],
   'water-intermittent':['fill-color','water']
 };
 function customize(style){
   if(!style || style.version!==8 || !Array.isArray(style.layers) ||
      !style.layers.some(l=>l.id==='highway-primary') ||
      !style.layers.some(l=>l.id==='water')){
      throw Error('OpenFreeMap Bright harita biçimi beklenenden farklı.');
   }
   // The official Bright style defines casing and all named street layers.
   const result={...style, layers:style.layers.map(layer=>{
      const id=layer.id||'';
      const r=replace[id];
      if(r) {
        const paint={...layer.paint,[r[0]]:colors[r[1]]};
        // Bright fades forest/park polygons nearly away by default. Our reference
        // map needs visible darker green vegetation while cities stay cream.
        if(id==='landcover-wood') paint['fill-opacity']=0.82;
        if(id==='park') paint['fill-opacity']=0.80;
        if(id==='landcover-grass-park') paint['fill-opacity']=0.9;
        return {...layer,paint};
      }
      if(/^waterway[-_]/.test(id) && layer.type==='line')
         return {...layer,paint:{...layer.paint,'line-color':colors.waterway}};
      if(/^(highway-|bridge-|tunnel-)/.test(id) && layer.type==='line' && !/railway|rail|road_oneway/.test(id)){
        let newColor;
        if(/-casing$/.test(id)) newColor=/-minor-casing$|-service-track-casing$|-path-casing$/.test(id)?colors.roadMinorCasing:colors.roadCasing;
        else if(/-minor$|-service-track$/.test(id)) newColor=colors.roadMinor;
        else if(/-path$/.test(id)) newColor=colors.roadPath;
        else newColor=colors.road;
        return {...layer,paint:{...layer.paint,'line-color':newColor}};
      }
      if(id==='highway-area' && layer.type==='fill')
        return {...layer,paint:{...layer.paint,'fill-color':'#E3E4E6', 'fill-outline-color':colors.roadMinorCasing}};
      return layer;
   })};
   // Urban backdrop below parks, roads and water: protects white city blocks
   // where the upstream residential landuse polygons are incomplete.
   const cities=[[[30.566,36.827],[30.585,36.865],[30.615,36.898],[30.642,36.932],[30.658,36.971],[30.705,36.988],[30.742,36.966],[30.766,36.935],[30.794,36.901],[30.821,36.87],[30.848,36.847],[30.84,36.82],[30.78,36.837],[30.742,36.853],[30.708,36.876],[30.682,36.883],[30.653,36.87],[30.616,36.845],[30.566,36.827]],[[30.566,37.001],[30.585,37.047],[30.628,37.056],[30.65,37.024],[30.628,36.999],[30.588,36.986],[30.566,37.001]]];
   result.sources={...result.sources,'kiyi-city-areas':{type:'geojson',data:{type:'FeatureCollection',features:cities.map(points=>({type:'Feature',properties:{},geometry:{type:'Polygon',coordinates:[points]}}))}}};
   const first=result.layers.findIndex(l=>l.type!=='background'&&l.type!=='raster');
   result.layers.splice(Math.max(1,first),0,{id:'kiyi-white-city-areas',type:'fill',source:'kiyi-city-areas',paint:{'fill-color':colors.residential,'fill-opacity':1}});
   return result;
 }
 async function load(){
   const controller=typeof AbortController!=='undefined'?new AbortController():null;
   const t=controller?setTimeout(()=>controller.abort(),12000):null;
   try {
     const response=await fetch(brightStyleUrl,controller?{signal:controller.signal,cache:'default'}:{cache:'default'});
     if(!response.ok) throw Error('HTTP '+response.status);
     return customize(await response.json());
   } finally {if(t)clearTimeout(t)}
 }
 root.KIYI_CUSTOM_MAP_STYLE={brightStyleUrl,colors,customize,load};
 if(typeof module!=='undefined'&&module.exports)module.exports=root.KIYI_CUSTOM_MAP_STYLE;
})(typeof window!=='undefined'?window:globalThis);
