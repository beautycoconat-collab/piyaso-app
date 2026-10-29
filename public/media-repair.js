/* Assets are cacheable image files rather than 4.8 MB of eager base64 JavaScript. */
const EmbeddedMedia={"assets/gifts/gifts-transparent.png":"assets/optimized/gifts-transparent.webp","assets/gifts/lighter-transparent.png":"assets/optimized/lighter-transparent.webp","assets/music/693996352.jpg":"assets/optimized/693996352.webp","assets/music/693996306.jpg":"assets/optimized/693996306.webp","assets/music/499334149.jpg":"assets/optimized/499334149.webp","assets/music/499332705.jpg":"assets/optimized/499332705.webp","assets/music/696699513.jpg":"assets/optimized/696699513.webp","assets/fenomen-1786.jpeg":"assets/optimized/fenomen-1786.webp","assets/fenomen-1787.jpeg":"assets/optimized/fenomen-1787.webp","assets/fenomen-1783.jpeg":"assets/optimized/fenomen-1783.webp","assets/fenomen-1782.jpeg":"assets/optimized/fenomen-1782.webp","assets/fenomen-1784.jpeg":"assets/optimized/fenomen-1784.webp","assets/fenomen-1785.jpeg":"assets/optimized/fenomen-1785.webp"};
function reliableMedia(path){if(!path)return path;const key=String(path).replace(/^.*?\/assets\//,'assets/');return EmbeddedMedia[key]||path;}
document.documentElement.style.setProperty('--gift-sprite',`url("${EmbeddedMedia['assets/gifts/gifts-transparent.png']}")`);
flowers.forEach(f=>{const m=f.icon.match(/viewBox="([\d ]+)"/);if(m){const [x,y,w,h]=m[1].split(' ').map(Number);f.icon=`<span class="gift-art restored-gift-art" aria-hidden="true" style="background-image:var(--gift-sprite);background-size:${1254/w*100}% ${1254/h*100}%;background-position:${x/(1254-w)*100}% ${y/(1254-h)*100}%"></span>`}else if(f.id==='lighter')f.icon=`<img class="gift-art gift-lighter" src="${EmbeddedMedia['assets/gifts/lighter-transparent.png']}" alt="">`});
const originalMediaAvatar=ownerAvatar;
ownerAvatar=function(p,cls='owner-photo'){return originalMediaAvatar({...p,avatar:reliableMedia(p.avatar)},cls)};
const originalMediaCover=songCover;
songCover=function(s){return originalMediaCover({...s,artwork:reliableMedia(s.artwork)});};
function restoreVisibleMedia(root=document){
 const images=root.matches?.('img[src]')?[root]:root.querySelectorAll?.('img[src]')||[];
 for(const img of images){const src=img.getAttribute('src'),resolved=reliableMedia(src);img.decoding='async';if(resolved!==src){img.onerror=null;img.hidden=false;img.src=resolved;}}
}
restoreVisibleMedia();
// Inspect only newly inserted subtrees, never rescan the entire page for every SVG update.
const mediaObserver=new MutationObserver(records=>{for(const record of records)for(const node of record.addedNodes)if(node.nodeType===1)restoreVisibleMedia(node);});
mediaObserver.observe(document.body,{childList:true,subtree:true});
