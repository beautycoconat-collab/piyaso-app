import {runDelivery,webhookTransport} from './runner.mjs';
const base=Deno.env.get('SUPABASE_URL')!,key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const reply=(value:unknown,status=200)=>new Response(JSON.stringify(value),{status,headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
Deno.serve(async(req:Request)=>{
 if(req.method!=='POST')return reply({error:'method_not_allowed'},405);
 if(!key||req.headers.get('Authorization')!=='Bearer '+key)return reply({error:'forbidden'},403);
 try{const body=await req.json();if(!body||typeof body!=='object'||!('channel' in body)||typeof body.channel!=='string'||!['email','push'].includes(body.channel))return reply({error:'invalid_channel'},400);
 const prefix=body.channel==='email'?'KIYI_EMAIL':'KIYI_PUSH';
 const transport=webhookTransport(Deno.env.get(prefix+'_DELIVERY_URL'),Deno.env.get(prefix+'_DELIVERY_TOKEN'),(Deno.env.get('KIYI_DELIVERY_ALLOWED_HOSTS')||'').split(',').map(s=>s.trim()).filter(Boolean));
 const backend=async(action:string,payload:unknown)=>{const r=await fetch(base+'/rest/v1/rpc/kiyi_delivery_worker',{method:'POST',headers:{apikey:key,Authorization:'Bearer '+key,'Content-Type':'application/json'},body:JSON.stringify({action,payload})});if(!r.ok)throw Error('Delivery database failed');return await r.json()};return reply(await runDelivery(body.channel,{backend,transport}));
 }catch{return reply({error:'delivery_worker_failed'},503)}
});
