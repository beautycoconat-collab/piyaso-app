(function(root){
const zones=(typeof module!=='undefined'?require('./road-data.js'):root.RoadData).zones;
const normalize=s=>String(s).toLocaleUpperCase('tr-TR').replace(/\s/g,'');
function inside(point,poly){let c=false;const[x,y]=point;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const[a,b]=poly[i],[d,e]=poly[j];if((b>y)!=(e>y)&&x<(d-a)*(y-b)/(e-b)+a)c=!c}return c}
function insideZone(point,zone){return inside(point,zone.points)&&!(zone.holes||[]).some(hole=>inside(point,hole))}
function onRoad(point){return zones.some(z=>insideZone(point,z))}
function eligible(p,s,now=Date.now()){return s.premium&&!s.blocked.includes(p.id)&&p.sharing&&now-p.updated<120000&&onRoad(p.pos)&&(p.visibility==='all'||p.approved.includes('me'))}
function search(profiles,q,blocked){return profiles.filter(p=>p.searchable&&!blocked.includes(p.id)&&normalize(p.plate)===normalize(q))}
function approximate(p){return p.map(n=>Math.round(n*500)/500)}
const api={zones,normalize,inside,insideZone,onRoad,eligible,search,approximate};if(typeof module!=='undefined')module.exports=api;else root.Core=api;
})(globalThis);
