// Deterministic exports of the existing Piyaso vector sources; no new artwork.
import fs from 'node:fs/promises';import path from 'node:path';import sharp from 'sharp';
const root=new URL('../',import.meta.url);const res=new URL('android/app/src/main/res/',root);
// Reuse the approved in-app Piyaso logo; do not ship the old raster Kıyı splash.
const logo=await fs.readFile(new URL('../public/assets/onboarding/piyaso-logo-v4.webp',root));
const mark=await sharp(logo).trim().resize(870,600,{fit:'inside'}).png().toBuffer();
const icon=await sharp({create:{width:1024,height:1024,channels:3,background:'#8B4CF6'}}).composite([{input:mark,gravity:'centre'}]).removeAlpha().png().toBuffer();
const splashMark=await sharp(logo).trim().resize(1250,650,{fit:'inside'}).png().toBuffer();
const splash=await sharp({create:{width:2732,height:2732,channels:3,background:'#ffffff'}}).composite([{input:splashMark,gravity:'centre'}]).removeAlpha().png().toBuffer();
await fs.writeFile(new URL('ios/App/App/Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png',root),icon);
for(const name of ['splash-2732x2732.png','splash-2732x2732-1.png','splash-2732x2732-2.png'])await fs.writeFile(new URL('ios/App/App/Assets.xcassets/Splash.imageset/'+name,root),splash);
const sizes={'mipmap-mdpi':48,'mipmap-hdpi':72,'mipmap-xhdpi':96,'mipmap-xxhdpi':144,'mipmap-xxxhdpi':192};
for(const [dir,n]of Object.entries(sizes))for(const name of ['ic_launcher.png','ic_launcher_round.png','ic_launcher_foreground.png'])await sharp(icon).resize(n,n).png().toFile(path.join(res.pathname,dir,name));
for(const dir of await fs.readdir(res))if(dir.startsWith('drawable')){const p=path.join(res.pathname,dir,'splash.png');try{await fs.access(p);await sharp(splash).resize(960,960).png().toFile(p)}catch(e){if(e.code!=='ENOENT')throw e}}
console.log('Approved Piyaso logo exported to iOS and Android icon/splash resources.');
