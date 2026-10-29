(function(root){
const sy=111320,sx=111320*Math.cos(36.86*Math.PI/180);
const meters=(a,b)=>Math.hypot((b[0]-a[0])*sy,(b[1]-a[1])*sx);
function prepare(points){if(!Array.isArray(points)||points.length<2)throw Error('Yol geometrisi eksik');const cumulative=[0];for(let i=1;i<points.length;i++)cumulative.push(cumulative[i-1]+meters(points[i-1],points[i]));return {points,cumulative,length:cumulative.at(-1)}}
function position(route,distance){const d=((distance%route.length)+route.length)%route.length;let lo=0,hi=route.points.length-1;while(lo+1<hi){const mid=(lo+hi)>>1;if(route.cumulative[mid]<=d)lo=mid;else hi=mid}const a=route.points[lo],b=route.points[hi],k=(d-route.cumulative[lo])/(route.cumulative[hi]-route.cumulative[lo]||1);return {pos:[a[0]+(b[0]-a[0])*k,a[1]+(b[1]-a[1])*k],angle:Math.atan2((b[1]-a[1])*sx,(b[0]-a[0])*sy)*180/Math.PI,segment:lo}}
function continuousAngle(previous,next){if(previous===undefined)return next;return previous+((next-previous+540)%360-180)}
const api={meters,prepare,position,continuousAngle};if(typeof module!=='undefined')module.exports=api;else root.RoadEngine=api;
})(globalThis);
