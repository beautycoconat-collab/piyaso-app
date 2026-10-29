// Runs the actual Edge handler with an isolated Auth transport and object store.
// This is not a hosted Supabase Auth or Storage service acceptance test.
import vm from 'node:vm';import fs from 'node:fs/promises';import ts from 'typescript';
import {randomUUID,randomBytes,createHmac,timingSafeEqual} from 'node:crypto';
export async function mediaHarness(db,user,session){
 const secret=randomBytes(32),objects=new Map();let handler;
 const claims={sub:user,role:'authenticated',session_id:session,exp:Math.floor(Date.now()/1000)+300};
 const header=Buffer.from(JSON.stringify({alg:'HS256',typ:'JWT'})).toString('base64url'),payload=Buffer.from(JSON.stringify(claims)).toString('base64url');
 const signature=s=>createHmac('sha256',secret).update(s).digest('base64url');
 const token=header+'.'+payload+'.'+signature(header+'.'+payload);
 const verify=auth=>{try{const parts=auth?.replace(/^Bearer /,'').split('.');if(parts?.length!==3)return false;const expected=Buffer.from(signature(parts[0]+'.'+parts[1])),actual=Buffer.from(parts[2]);return actual.length===expected.length&&timingSafeEqual(actual,expected)&&JSON.parse(Buffer.from(parts[1],'base64url')).exp>Date.now()/1000}catch{return false}};
 const actor=async(role,identity={})=>{await db.exec('reset role');await db.query("select set_config('request.jwt.claims',$1,false),set_config('request.jwt.claim.sub','',false)",[JSON.stringify(identity)]);await db.exec('set role '+role)};
 const fetcher=async(url,options={})=>{
  const path=new URL(url).pathname;let response;
  if(path==='/auth/v1/user')return Response.json(verify(options.headers.Authorization)?{id:user}:{error:'invalid token'},{status:verify(options.headers.Authorization)?200:401});
  try{
   if(path==='/rest/v1/rpc/kiyi_command'){
    if(!verify(options.headers.Authorization))return Response.json({error:'invalid token'},{status:401});
    await actor('authenticated',claims);const body=JSON.parse(options.body);response=(await db.query('select public.kiyi_command($1,$2::jsonb) as data',[body.action,JSON.stringify(body.payload)])).rows[0].data;
   }else if(path==='/rest/v1/rpc/kiyi_media_worker'){
    await actor('service_role',{role:'service_role'});const body=JSON.parse(options.body);response=(await db.query('select public.kiyi_media_worker($1,$2::jsonb) as data',[body.action,JSON.stringify(body.payload)])).rows[0].data;
   }else if(path.startsWith('/storage/v1/object/kiyi-media/')){
    const name=decodeURIComponent(path.slice('/storage/v1/object/kiyi-media/'.length)),bytes=Buffer.from(options.body);await db.exec('reset role');
    await db.query("insert into storage.objects(id,bucket_id,name,owner_id,metadata)values($1,'kiyi-media',$2,$3,$4::jsonb)",[randomUUID(),name,user,JSON.stringify({size:bytes.length,mimetype:options.headers['Content-Type']})]);objects.set(name,bytes);response={Key:name};
   }else throw Error('Unexpected isolated service route');
   return Response.json(response||{});
  }catch{return Response.json({error:'isolated service rejected request'},{status:403});}
 };
 const source=await fs.readFile(new URL('../../supabase/functions/kiyi-media/index.ts',import.meta.url),'utf8');
 const context={exports:{},Deno:{env:{get:k=>k==='SUPABASE_URL'?'https://isolated.invalid':'test-service-key'},serve:fn=>handler=fn},fetch:fetcher,Request,Response,Headers,Uint8Array,Array,JSON,Error};
 vm.createContext(context);vm.runInContext(ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,context);
 return {objects,token,upload:(body,mime='image/png',auth=token)=>handler(new Request('https://isolated.invalid/functions/v1/kiyi-media',{method:'POST',headers:{'Content-Type':mime,...(auth?{Authorization:'Bearer '+auth}:{})},body}))};
}
