/* Conservative GPS sending policy. Never fabricates a cached-location heartbeat. */
(function(root){
'use strict';
function distance(a,b){const rad=Math.PI/180,dy=(b.lat-a.lat)*rad,dx=(b.lng-a.lng)*rad;const h=Math.sin(dy/2)**2+Math.cos(a.lat*rad)*Math.cos(b.lat*rad)*Math.sin(dx/2)**2;return 6371000*2*Math.atan2(Math.sqrt(h),Math.sqrt(Math.max(0,1-h)));}
function create(){let anchor=null,since=0,samples=0,still=false,lastAttempt=-Infinity,lastObserved=-Infinity;
 return {observe(pos,now=Date.now()){
 const c=pos?.coords,p={lat:c?.latitude,lng:c?.longitude,accuracy:c?.accuracy},observed=Number(pos?.timestamp);
 if(!Number.isFinite(p.lat)||!Number.isFinite(p.lng)||p.lat< -90||p.lat>90||p.lng< -180||p.lng>180||!Number.isFinite(p.accuracy)||p.accuracy<1||p.accuracy>100||!Number.isFinite(observed)||now-observed>30000||observed>now+5000||observed<=lastObserved)return false;
 lastObserved=observed;
 const uncertain=p.accuracy>25,moving=Number.isFinite(c.speed)&&c.speed>=1;
 if(!anchor||uncertain||moving||distance(anchor,p)>Math.max(12,Math.min(25,p.accuracy))){anchor=p;since=now;samples=1;still=false;}else{samples++;still=samples>=3&&now-since>=20000;}
 const interval=still?30000:5000;if(now-lastAttempt<interval)return false;lastAttempt=now;return true;
 },failed(){still=false;anchor=null;samples=0;},get stationary(){return still;}};
}
const api={create,distance};if(typeof module==='object'&&module.exports)module.exports=api;else root.KiyiLocationCadence=api;
})(typeof globalThis==='object'?globalThis:this);
