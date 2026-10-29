import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import zlib from 'node:zlib';
const html=fs.readFileSync('public/startup.html','utf8');
const manifest=JSON.parse(fs.readFileSync('public/assets/runtime/manifest.json','utf8'));
test('first response includes its intro code and CSS without external runtime or font dependencies',()=>{
 assert.doesNotMatch(html,/<script[^>]+src=/);
 assert.doesNotMatch(html,/<link rel="stylesheet"/);
 assert.doesNotMatch(html,/@import/);
 assert.doesNotMatch(html,/maplibre\.js|road-data\.js|plate-artwork\.js/);
 assert.match(html,/sceneReady/);assert.match(html,/piyaso-boot-pending/);
 assert.ok(zlib.gzipSync(html).length<35000,'compressed critical HTML remains below 35 KB');
 assert.ok(manifest.entryBytes<60000,'self-contained intro including sound and animation stays below 60 KB');
 for(const image of Object.values(manifest.scenes).flat())assert.ok(fs.statSync('public/'+image).size>0,image);
 const mapBytes=manifest.scenes.map.reduce((sum,file)=>sum+fs.statSync('public/'+file).size,0);
 assert.ok(mapBytes<250000,'the complete moving-map scene stays below 250 KB, including its car and portraits');
 assert.doesNotMatch(html,/assets\/map-car\.png|assets\/owner-07-f-7755\.jpeg/);
});
function loaderFixture(){
 const appended=[],events=[],images=[],callbacks=[];
 const c={Map,Promise,Event:class{constructor(type){this.type=type}},console,setTimeout:fn=>callbacks.push(fn),requestIdleCallback:fn=>callbacks.push(fn),Image:class{constructor(){images.push(this)}decode(){return Promise.resolve()}},document:{getElementById:()=>null,querySelector:()=>null,documentElement:{classList:{remove(){}}},createElement:tag=>({tag,dataset:{}}),head:{append:el=>appended.push(el)}},dispatchEvent:e=>events.push(e.type)};
 c.window=c;vm.createContext(c);vm.runInContext(fs.readFileSync('scripts/startup-loader.js','utf8').replace('__STARTUP_CONFIG__',JSON.stringify({js:'/app.js',css:'/app.css',scenes:{welcome:['hero','logo']},carArt:'<svg></svg>'})),c);
 return {c,appended,events,images};
}
test('an intro waits for both its image resources without loading the main application',async()=>{
 const f=loaderFixture();let revealed=false;const ready=f.c.PiyasoBoot.sceneReady('welcome').then(()=>revealed=true);
 assert.equal(f.images.length,2);assert.equal(f.appended.length,0);f.images[0].onload();await Promise.resolve();assert.equal(revealed,false);
 f.images[1].onload();await ready;assert.equal(revealed,true);assert.equal(f.appended.length,0);
});
test('main runtime is requested once and initialization runs only after both script and styles are ready',async()=>{
 const f=loaderFixture();let initialized=0;
 f.c.PiyasoBoot.onReady(()=>initialized++);
 const first=f.c.PiyasoBoot.loadApp(),second=f.c.PiyasoBoot.loadApp();assert.equal(first,second);assert.equal(f.appended.length,2);
 f.c.PiyasoBoot.didLoad();await Promise.resolve();assert.equal(initialized,0);assert.equal(f.c.PiyasoBoot.ready,false);
 f.appended.find(el=>el.tag==='link').onload();await first;
 assert.equal(initialized,1);assert.equal(f.c.PiyasoBoot.ready,true);assert.deepEqual(f.events,['piyaso:app-ready']);
});
