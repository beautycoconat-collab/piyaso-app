import {eraseAccount} from './coordinator.mjs';
const base=Deno.env.get('SUPABASE_URL')||'';
const key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')||'';
const headers={'Content-Type':'application/json','Cache-Control':'no-store','Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS'};
async function api(path:string,body?:unknown,method='POST',token='Bearer '+key){
 const r=await fetch(base+path,{method,headers:{apikey:key,Authorization:token,'Content-Type':'application/json'},...(body===undefined?{}:{body:JSON.stringify(body)})});
 if(!r.ok)throw Object.assign(new Error('DELETION_SERVICE_FAILED'),{status:r.status===401?401:502});
 const text=await r.text();return text?JSON.parse(text):{};
}
const worker=(action:string,owner:string)=>api('/rest/v1/rpc/piyaso_erasure_worker',{action,payload:{owner}});
Deno.serve(async req=>{
 if(req.method==='OPTIONS')return new Response(null,{headers});
 if(req.method!=='POST')return new Response(JSON.stringify({error:'METHOD_NOT_ALLOWED'}),{status:405,headers});
 try{
  if(!req.headers.get('Content-Type')?.startsWith('application/json'))return new Response(JSON.stringify({error:'JSON_REQUIRED'}),{status:415,headers});
  const reader=req.body?.getReader();if(!reader)throw Object.assign(new Error('EMPTY_INPUT'),{status:400});
  const chunks:Uint8Array[]=[];let size=0;
  while(true){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>2048){await reader.cancel();return new Response(JSON.stringify({error:'INPUT_TOO_LARGE'}),{status:413,headers});}chunks.push(value);}
  const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
  let input;try{input=JSON.parse(new TextDecoder().decode(bytes))}catch{throw Object.assign(new Error('INVALID_JSON'),{status:400})}
  if(!input||typeof input!=='object'||Array.isArray(input))throw Object.assign(new Error('INVALID_INPUT'),{status:400});
  const result=await eraseAccount({token:req.headers.get('Authorization'),password:input.password,confirmation:input.confirmation},{
   currentUser:(token:string)=>api('/auth/v1/user',undefined,'GET',token),
   reauthenticate:(email:string,password:string)=>api('/auth/v1/token?grant_type=password',{email,password}),
   prepare:(id:string)=>worker('prepare',id),
   signOutAll:(token:string)=>api('/auth/v1/logout?scope=global',undefined,'POST',token),
   removeObjects:(paths:string[])=>api('/storage/v1/object/kiyi-media',{prefixes:paths},'DELETE'),
   purgePersonalData:(id:string)=>worker('purge',id),
   deleteAuthUser:(id:string)=>api('/auth/v1/admin/users/'+encodeURIComponent(id),{should_soft_delete:false},'DELETE'),
   authUserExists:async(id:string)=>{const r=await fetch(base+'/auth/v1/admin/users/'+encodeURIComponent(id),{headers:{apikey:key,Authorization:'Bearer '+key}});if(r.status===404)return false;if(!r.ok)throw Error('AUTH_CHECK_FAILED');return true;}
  },{enabled:Deno.env.get('PIYASO_ACCOUNT_DELETION_ENABLED')==='true',authScope:Deno.env.get('PIYASO_AUTH_SCOPE'),policy:Deno.env.get('PIYASO_ERASURE_POLICY')});
  return new Response(JSON.stringify(result),{headers});
 }catch(error){const e=error as {status?:number;code?:string};return new Response(JSON.stringify({error:e.code||'DELETION_NOT_COMPLETED'}),{status:e.status||502,headers});}
});
