import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import vm from 'node:vm';
import ts from 'typescript';
import sharp from 'sharp';
import {transformWithEsbuild} from 'vite';
await import('./configure-supabase.mjs');

const root=path.resolve(import.meta.dirname,'..'),pub=path.join(root,'public');
const read=file=>fs.readFile(path.join(pub,file),'utf8');
const html=await read('kiyi.html');
const scripts=[...html.matchAll(/<script\s+(?:defer\s+)?src="([^"?]+)(?:\?[^"]*)?"/g)].map(m=>m[1]);
const styles=[...html.matchAll(/<link rel="stylesheet" href="([^"?]+)(?:\?[^"]*)?"/g)].map(m=>m[1]);
const runtimeDir=path.join(pub,'assets/runtime');await fs.mkdir(runtimeDir,{recursive:true});
const hash=s=>crypto.createHash('sha256').update(s).digest('hex').slice(0,12);
const startupDir=path.join(pub,'assets/startup');await fs.mkdir(startupDir,{recursive:true});
const imageJobs=[
 ['assets/optimized/welcome-coastal-city-v5.webp','welcome.webp',864,78],
 ['assets/onboarding/piyaso-logo-v4.webp','logo.webp',720,84],
 ['assets/optimized/plate-coastal-map-v1.webp','map.webp',864,80],
 ['assets/onboarding/city-map-v2.webp','city.webp',864,80],
 ['assets/models/vw-golf-v1.webp','car.webp',1024,84],
 ['assets/onboarding/license-plate-v2.webp','plate.webp',820,84],
 ['assets/map-car.png','map-car.webp',256,84],
 ['assets/owner-33-ayc-048.jpeg','owner-one.webp',160,82],
 ['assets/owner-07-f-7755.jpeg','owner-two.webp',160,82],
 ['assets/optimized/fenomen-1782.webp','owner-three.webp',160,82],
 ['assets/optimized/fenomen-1783.webp','owner-four.webp',160,82]
];
const assetMap={};
for(const [src,name,width,quality] of imageJobs){const bytes=await sharp(path.join(pub,src)).resize({width,withoutEnlargement:true}).webp({quality,effort:5}).toBuffer();const file=name.replace('.webp','-'+hash(bytes)+'.webp');await fs.writeFile(path.join(startupDir,file),bytes);assetMap[src]='assets/startup/'+file;}
// Small, fixed car markup: the intro never needs the full garage/model catalog.
const ctx={esc:s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])),carColorName:()=> 'Mavi',state:{me:{plate:'07 PYS 01',paint:'#0764ff'},carColors:[]}};vm.createContext(ctx);
const functions=['kiyiVehicleLighting','kiyiRimArtwork','kiyiVehicleRims','kiyiVehicleAccessories','kiyiVehiclePlate','kiyiHoodArtwork','kiyiReferenceLivery','kiyiVehicleModel','kiyiVehicleName','kiyiModelShowcase','kiyiSedanShowcase','validCarColor'];
for(const file of ['vehicle-models.js','car-wraps.js','vehicle-showcase.js','car-colors.js','status-system.js']){
 const source=await read(file),tree=ts.createSourceFile(file,source,ts.ScriptTarget.Latest,true,ts.ScriptKind.JS);
 for(const node of tree.statements)if(ts.isFunctionDeclaration(node)&&functions.includes(node.name?.text)||ts.isVariableStatement(node)&&['vehicle-models.js','vehicle-showcase.js','car-wraps.js'].includes(file))vm.runInContext(node.getText(tree),ctx);
}
let carArt=ctx.kiyiSedanShowcase({vehicleModel:'vw-golf',plate:'07 PYS 01',plateStyle:'classic'},'#0764ff');
for(const [src,target] of Object.entries(assetMap))carArt=carArt.replaceAll(src,target);
let appJs='';
for(const file of scripts.filter(f=>!['first-run.js','ui-icons.js','welcome-story.js'].includes(f))){
 let source=await read(file);
 source=source.replace(/(?:document|window)\.addEventListener\(['"]DOMContentLoaded['"],/g,'window.PiyasoBoot.onReady(').replace(/\/\/# sourceMappingURL=.*$/gm,'');
 appJs+='\n;/* '+file+' */\n'+source+'\n;';
}
appJs=appJs.replaceAll('assets/map-car.png',assetMap['assets/map-car.png']);
appJs+='\nwindow.PiyasoBoot.didLoad();';
appJs=(await transformWithEsbuild(appJs,'app-runtime.js',{target:'es2020',minifyWhitespace:true,minifySyntax:true,minifyIdentifiers:false})).code;
const jsName='app-'+hash(appJs)+'.js';await fs.writeFile(path.join(runtimeDir,jsName),appJs);
const cssUrls=css=>css.replace(/@import\s+url\([^;]+;/g,'').replace(/url\((['"]?)(?!https?:|data:|\/|#)([^)'"\s]+)\1\)/g,(_,q,url)=>'url("/'+url+'")');
const entryStyles=['first-run.css','first-run-dream.css','welcome-story.css'];
let appCss='';for(const file of styles.filter(f=>!entryStyles.includes(f)))appCss+='\n/* '+file+' */\n'+cssUrls(await read(file));
appCss=(await transformWithEsbuild(appCss,'app-runtime.css',{loader:'css',minify:true})).code;
const cssName='app-'+hash(appCss)+'.css';await fs.writeFile(path.join(runtimeDir,cssName),appCss);
let entryCss='html,body{margin:0;min-height:100%;font-family:Arial,Helvetica,sans-serif}button,input{font:inherit}.sr-only{position:absolute!important;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}.vehicle-showcase{width:100%}.vehicle-showcase-art{width:100%;height:auto;display:block}.car-owner-marker{position:relative}.map-owner-bubble{position:absolute;border-radius:50%;isolation:isolate}.map-owner-bubble:after{content:"";position:absolute;border-radius:3px}.map-owner-photo{width:100%;height:100%;border-radius:50%;object-fit:cover;display:block}.top-car{object-fit:contain}.dark-car{filter:brightness(.3) saturate(.35)}';
for(const file of entryStyles)entryCss+='\n'+cssUrls(await read(file));
for(const [src,target] of Object.entries(assetMap))entryCss=entryCss.replaceAll(src,target);
entryCss=entryCss.replaceAll(assetMap['assets/optimized/welcome-coastal-city-v5.webp'],'assets/welcome-story/coastal-road-v1.webp');
entryCss+='\n#piyaso-entry:not([data-page]){background:#f4f7f2}#piyaso-entry[data-page=welcome] .entry-screen>section{animation:none}html.piyaso-boot-pending body>aside,html.piyaso-boot-pending body>main{visibility:hidden}#piyaso-startup{position:fixed;inset:0;z-index:30000;display:grid;place-items:center;background:#f4f7f2;color:#756285;font:14px Arial,sans-serif}#piyaso-startup span{display:grid;justify-items:center;gap:16px}#piyaso-startup span:before{content:"";width:24px;height:24px;border-radius:50%;border:2px solid #ddd5e8;border-top-color:#8b43f4;animation:piyasoLoading .7s linear infinite}#piyaso-entry[aria-busy=true]{pointer-events:none}html.piyaso-boot-pending #piyaso-entry{visibility:hidden}@keyframes piyasoLoading{to{transform:rotate(360deg)}}@media(prefers-reduced-motion:reduce){#piyaso-startup span:before{animation:none}}';
entryCss=(await transformWithEsbuild(entryCss,'entry.css',{loader:'css',minify:true})).code;
const sceneAssets={welcome:['assets/welcome-story/coastal-road-v1.webp',assetMap['assets/onboarding/piyaso-logo-v4.webp'],'assets/welcome-story/black-car-v1.webp','assets/welcome-story/white-car-v1.webp','assets/welcome-story/smile-v1.webp','assets/welcome-story/boy-smile-v1.webp','assets/welcome-story/tulip-v1.webp'],plate:[assetMap['assets/optimized/plate-coastal-map-v1.webp'],assetMap['assets/onboarding/license-plate-v2.webp'],'assets/onboarding/location-pin-3d.svg'],garage:[assetMap['assets/optimized/plate-coastal-map-v1.webp'],assetMap['assets/models/vw-golf-v1.webp'],'assets/onboarding/location-pin-3d.svg'],map:[assetMap['assets/onboarding/city-map-v2.webp'],assetMap['assets/owner-33-ayc-048.jpeg'],assetMap['assets/owner-07-f-7755.jpeg'],assetMap['assets/optimized/fenomen-1782.webp'],assetMap['assets/optimized/fenomen-1783.webp'],assetMap['assets/map-car.png']],email:[assetMap['assets/onboarding/piyaso-logo-v4.webp'],assetMap['assets/onboarding/city-map-v2.webp'],assetMap['assets/owner-33-ayc-048.jpeg'],assetMap['assets/owner-07-f-7755.jpeg'],assetMap['assets/optimized/fenomen-1782.webp'],assetMap['assets/optimized/fenomen-1783.webp'],assetMap['assets/map-car.png']]};
let boot=await fs.readFile(path.join(root,'scripts/startup-loader.js'),'utf8');
boot=boot.replace('__STARTUP_CONFIG__',JSON.stringify({js:'/assets/runtime/'+jsName,css:'/assets/runtime/'+cssName,scenes:sceneAssets,carArt}));
let entryJs=(await read('ui-icons.js'))+'\n;'+boot+'\n;'+await read('welcome-story.js')+'\n;'+await read('first-run.js');
entryJs=entryJs.replaceAll('assets/fenomen-1782.jpeg','assets/optimized/fenomen-1782.webp').replaceAll('assets/fenomen-1783.jpeg','assets/optimized/fenomen-1783.webp');
for(const [src,target] of Object.entries(assetMap))entryJs=entryJs.replaceAll(src,target);
entryJs=(await transformWithEsbuild(entryJs,'entry.js',{target:'es2020',minifyWhitespace:true,minifySyntax:true,minifyIdentifiers:false})).code;
// No application styles, map engines, catalogs or web fonts block the introduction.
let output=html.replace(/<link rel="stylesheet"[^>]*>/g,'').replace(/<link rel="preload"[^>]*>/g,'').replace(/<script defer src="[^"]+"><\/script>/g,'');
output=output.replace('<html lang="tr">','<html lang="tr" class="piyaso-boot-pending">');
output=output.replace('</head>',`<link rel="preload" as="image" href="/${sceneAssets.welcome[0]}" fetchpriority="high"><link rel="preload" as="image" href="/${sceneAssets.welcome[1]}" fetchpriority="high"><style>${entryCss}</style></head>`);
output=output.replace('<body>','<body><div id="piyaso-startup" role="status"><span>Hazırlanıyor…</span></div>');
output=output.replace('</body>',`<script>${entryJs.replaceAll('</script','<\\/script')}</script></body>`);
await fs.writeFile(path.join(pub,'startup.html'),output);
await fs.writeFile(path.join(runtimeDir,'manifest.json'),JSON.stringify({js:jsName,css:cssName,entryBytes:Buffer.byteLength(entryJs),appBytes:Buffer.byteLength(appJs),styles:styles.length,scripts:scripts.length,scenes:sceneAssets},null,2));
console.log(`Startup: ${styles.length} stylesheets + ${scripts.length} scripts removed from the intro critical path; ${Buffer.byteLength(entryJs)} bytes of self-contained entry JS.`);
