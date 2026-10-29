import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import fs from 'node:fs';
function fixture(expires=0){
 const old={user:{id:'old'},expires_at:expires,refresh_token:'refresh'};let finish;const calls=[];
 const c={sessionStorage:{getItem:()=>JSON.stringify(old),setItem(){},removeItem(){}},fetch:async(url)=>{calls.push(url);return new Promise(r=>{finish=r})},window:{},AbortSignal,console};
 vm.createContext(c);const source=fs.readFileSync('public/supabase-account.js','utf8');
 vm.runInContext(source.slice(source.indexOf("'use strict';"),source.indexOf('async function mediaURL('))+source.slice(source.indexOf('function assertAccount('),source.indexOf('async function applyBundle('))+';globalThis.api={db,command,request,getSession:()=>session,setSession:s=>session=s};',c);
 return {c,calls,finish:r=>finish(r)};
}
test('a failed old refresh cannot sign out the newly selected account',async()=>{
 const {c,finish,calls}=fixture();const work=c.api.db('rpc/kiyi_command','POST',{action:'profile'});
 c.api.setSession({user:{id:'new'},access_token:'new-token'});
 finish({ok:false,status:401,text:async()=>JSON.stringify({code:'invalid_credentials'})});
 await assert.rejects(work,/Oturum değişti/);assert.equal(c.api.getSession().user.id,'new');assert.equal(calls.length,1);
});
test('an old successful refresh cannot send the prior account payload with a new token',async()=>{
 const {c,finish,calls}=fixture();const work=c.api.db('rpc/kiyi_command','POST',{action:'profile',payload:{name:'Old'}});
 c.api.setSession({user:{id:'new'},access_token:'new-token'});
 finish({ok:true,status:200,text:async()=>JSON.stringify({user:{id:'old'},access_token:'old-new',expires_in:3600})});
 await assert.rejects(work,/Oturum değişti/);assert.equal(c.api.getSession().user.id,'new');assert.equal(calls.length,1);
});

test('an expired response from the previous user cannot clear the current session',async()=>{
 const {c,finish}=fixture(Math.floor(Date.now()/1000)+3600);const work=c.api.command('bundle');
 await new Promise(setImmediate);c.api.setSession({user:{id:'new'},access_token:'new-token'});
 finish({ok:false,status:401,text:async()=>JSON.stringify({message:'Oturum geçersiz. Yeniden giriş yap.'})});
 await assert.rejects(work);assert.equal(c.api.getSession().user.id,'new');
});
test('legacy server restriction text remains recognized during brand rollout',async()=>{
 const {c,finish}=fixture();const work=c.api.request('/auth/v1/user');
 finish({ok:false,status:403,text:async()=>JSON.stringify({message:'Kıyı hesabın silinmiş.'})});
 await assert.rejects(work,e=>e.restricted===true&&e.message==='Piyaso hesabın silinmiş.');
});

function bundleFixture(){
 let finish,first=true;const c={session:{user:{id:'old'}},epoch:0,state:{me:{username:'old-visible'}},defaults:{me:{}},profiles:[],flowers:[],tour:{},window:{dispatchEvent(){}},updateCreditDisplays(){},structuredClone,CustomEvent,Date,mediaURL:()=>first?(first=false,new Promise(r=>finish=r)):Promise.resolve(''),command:async()=>({profiles:[{id:'old',avatar:'private',supabaseProfile:true}]})};
 vm.createContext(c);const source=fs.readFileSync('public/supabase-account.js','utf8');vm.runInContext(source.slice(source.indexOf('function assertAccount('),source.indexOf('async function hydrate(')),c);return {c,finish:()=>finish('signed-old')};
}
test('late private profile media cannot overwrite another account bundle',async()=>{
 const {c,finish}=bundleFixture();const work=c.applyBundle({me:{username:'old-private',avatar:'private'},privacy:{}});
 assert.equal(c.state.me.username,'old-visible');c.session={user:{id:'new'}};c.state={me:{username:'new'}};finish();
 await assert.rejects(work,/Oturum değişti/);assert.equal(c.state.me.username,'new');
});
test('late directory media cannot append the previous account profiles',async()=>{
 const {c,finish}=bundleFixture();const work=c.loadDirectory();await new Promise(setImmediate);
 c.session={user:{id:'new'}};c.profiles=[{id:'new-only'}];finish();await assert.rejects(work,/Oturum değişti/);assert.equal(c.profiles.length,1);assert.equal(c.profiles[0].id,'new-only');
});
