/* Independent local simulations: road-bound positions, smooth speed changes and pauses. */
(function(root){
const engine=typeof module!=='undefined'&&module.exports?require('./road-engine.js'):root.RoadEngine;
function travelled(t,m){const period=m.drive+m.wait,cycles=Math.floor(t/period),x=t-cycles*period,u=Math.min(x,m.drive),w=2*Math.PI/m.drive;return cycles*m.speed*m.drive+m.speed*(u+.18*(1-Math.cos(w*u))/w)}
function distance(m,elapsed){return m.offset+m.direction*(travelled(Math.max(0,elapsed)+m.phase,m)-travelled(m.phase,m))}
function position(route,m,elapsed){const p=engine.position(route,distance(m,elapsed));if(m.direction<0)p.angle+=180;return p}
function settings(index,length){return {offset:((.067+index*.61803398875)%1)*length,speed:3.4+(index*1.71%5.8),drive:75+(index*29%100),wait:6+(index*7%19),phase:index*37,direction:index%3===0?-1:1}}
const api={travelled,distance,position,settings};if(typeof module!=='undefined'&&module.exports)module.exports=api;else root.TrafficMotion=api;
})(globalThis);
