// Backend acceptance fixtures; no real email, device, user or external account.
import {test,after} from 'node:test';import assert from 'node:assert/strict';import {randomUUID,randomBytes,createCipheriv,createDecipheriv,createHash} from 'node:crypto';
import fs from 'node:fs/promises';import os from 'node:os';import path from 'node:path';
import {PGlite} from '@electric-sql/pglite';import {postgis} from '@electric-sql/pglite-postgis';import {pgcrypto} from '@electric-sql/pglite/contrib/pgcrypto';
import {createMobileDB} from './testing/mobile-db.mjs';import {mediaHarness} from './testing/mobile-media.mjs';
const db=await createMobileDB();let closed=false;after(()=>closed?undefined:db.close());
const a=randomUUID(),b=randomUUID(),sa=randomUUID(),sb=randomUUID();let vehicle,post,expectedBalance,media;
const command=async(action,payload={})=>(await db.query('select public.kiyi_command($1,$2::jsonb) as result',[action,JSON.stringify(payload)])).rows[0].result;
async function actor(user,session){await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub','',false),set_config('request.jwt.claims',$1,false)",[JSON.stringify({sub:user,role:'authenticated',session_id:session})]);await db.exec('set role authenticated');}
test('A — isolated profile, garage, map, post and earned badge',async()=>{
 await db.query("insert into auth.users(id,email,email_confirmed_at,created_at)values($1,'mobile-a@example.invalid',now(),now()-interval '10 days'),($2,'mobile-b@example.invalid',now(),now()-interval '10 days')",[a,b]);
 await db.query('insert into auth.sessions(id,user_id)values($1,$2),($3,$4)',[sa,a,sb,b]);
 await actor(b,sb);await command('profile',{username:'mobile_b',searchable:true});
 await actor(a,sa);await command('profile',{username:'mobile_a',searchable:true,profile:{name:'Mobile A'}});
 vehicle=(await command('vehicle_create',{model:'peugeot-208',plate:'07 MOB 101'})).id;
 assert.equal((await command('garage_list')).count,1);
 await command('sharing',{enabled:true});const point=await command('position',{session:randomUUID(),seq:1,lat:36.86702735,lng:30.6417432365968,accuracy:10,observed_at:Date.now()});assert.equal(point.region,'konyaalti');
 post=(await command('post_create',{text:'İzole mobil senaryo paylaşımı',visibility:'public',request_id:randomUUID()})).post.id;
 await command('rewards');await command('badge_dashboard');await db.exec('reset role');
 assert((await db.query('select count(*)::int n from kiyi_private.badge_earned where owner=$1 and active',[a])).rows[0].n>=1);
 // An initial test-only balance supports gift assertions; this is not a purchase.
 await db.query('update public.kiyi_wallets set balance=100 where user_id=$1',[a]);
});
test('B — second isolated user follows, likes and comments; owner sees notification',async()=>{
 await actor(b,sb);await command('follow',{target:a,enabled:true});await command('like',{id:post,like:true});await command('comment',{id:post,text:'İzole senaryo yorumu',request_id:randomUUID()});
 await actor(a,sa);const bundle=await command('bundle');assert(bundle.followers.includes(b));assert(bundle.notifications.some(n=>n.sender===b));
 const current=(await command('post_get',{id:post})).post;assert.equal(current.likes,1);assert(current.comments.some(c=>c.text==='İzole senaryo yorumu'));
});
test('C — daily reward and burst duplicate gift requests settle only once',async()=>{
 await actor(a,sa);const earned=await command('reward_daily');assert.equal(earned.amount,5);const before=(await command('bundle')).balance;
 assert.equal((await command('reward_daily')).already_claimed,true);assert.equal((await command('bundle')).balance,before);
 const payload={target:b,product:'rose',request_id:randomUUID()};await Promise.all(Array.from({length:8},()=>command('gift',payload)));
 const afterGift=await command('bundle');expectedBalance=Number(before)-20;assert.equal(Number(afterGift.balance),expectedBalance);assert.equal(afterGift.gifts.filter(g=>g.id===payload.request_id).length,1);
 await actor(b,sb);assert((await command('bundle')).notifications.some(n=>n.sender===a&&n.gift_id===payload.request_id));
});
test('D — another account cannot edit a private vehicle, wallet or forge a purchase',async()=>{
 await actor(b,sb);await assert.rejects(()=>command('vehicle_update',{vehicle_id:vehicle,plate:'07 STOLEN'}));
 await assert.rejects(()=>db.query('update public.kiyi_wallets set balance=999999 where user_id=$1',[a]));
 for(const action of ['purchase','credit','order_settle'])await assert.rejects(()=>command(action,{amount:999999,verified:true,provider_transaction:'forged'}));
});
test('E — backend re-identification preserves profile, garage, wallet and badge',async()=>{
 await actor(a,sa);await command('sharing',{enabled:false});await db.exec("reset role;select set_config('request.jwt.claims','{}',false)");
 await actor(a,sa);const bundle=await command('bundle');assert.equal(bundle.me.username,'mobile_a');assert.equal(Number(bundle.balance),expectedBalance);assert.equal((await command('garage_list')).vehicles[0].id,vehicle);
 await db.exec('reset role');assert((await db.query('select count(*)::int n from kiyi_private.badge_earned where owner=$1 and active',[a])).rows[0].n>=1);
});
test('media Edge handler + actual registry accepts valid owned upload and rejects bypasses',async()=>{
 media=await mediaHarness(db,a,sa);const png=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==','base64');
 assert.equal((await media.upload(png,'image/png',null)).status,401);assert.equal((await media.upload(png,'image/png','forged')).status,401);assert.equal((await media.upload(Buffer.from('bad png'))).status,415);assert.equal((await media.upload(png,'image/svg+xml')).status,415);assert.equal((await media.upload(Buffer.alloc(5242881))).status,413);
 const response=await media.upload(png);assert.equal(response.status,200);const {path:uploaded}=await response.json();assert(uploaded.startsWith(a+'/social/'));assert(media.objects.get(uploaded).equals(png));
 await db.exec('reset role');assert.equal((await db.query('select state from kiyi_private.media_registry where path=$1',[uploaded])).rows[0].state,'ready');
 await actor(a,sa);await assert.rejects(()=>db.query("insert into storage.objects(bucket_id,name,owner_id)values('kiyi-media',$1,$2)",[a+'/bypass.png',a]));
});
test('encrypted isolated database and media backup restores data and detects tampering',async()=>{
 await db.exec('reset role');const vehicleRows=(await db.query('select count(*)::int n from public.kiyi_vehicles where owner=$1',[a])).rows[0].n;const dump=Buffer.from(await(await db.dumpDataDir('gzip')).arrayBuffer());const hash=data=>createHash('sha256').update(data).digest('hex');
 const files=[...media.objects].map(([name,bytes])=>({name,data:bytes.toString('base64'),sha256:hash(bytes)}));assert(files.length>0);
 const key=randomBytes(32),iv=randomBytes(12),cipher=createCipheriv('aes-256-gcm',key,iv),plain=Buffer.from(JSON.stringify({db:dump.toString('base64'),files})),encrypted=Buffer.concat([cipher.update(plain),cipher.final()]),tag=cipher.getAuthTag();
 const temp=await fs.mkdtemp(path.join(os.tmpdir(),'piyaso-isolated-restore-'));const file=path.join(temp,'backup.enc');await fs.writeFile(file,encrypted,{mode:0o600});
 const decrypt=bytes=>{const d=createDecipheriv('aes-256-gcm',key,iv);d.setAuthTag(tag);return Buffer.concat([d.update(bytes),d.final()])};
 try{
  const changed=Buffer.from(encrypted);changed[0]^=1;assert.throws(()=>decrypt(changed));
  await db.close();closed=true;media.objects.clear();const recovered=JSON.parse(decrypt(await fs.readFile(file)));
  const restored=new PGlite({loadDataDir:new Blob([Buffer.from(recovered.db,'base64')]),extensions:{postgis,pgcrypto}});
  try{assert.equal(Number((await restored.query('select balance from public.kiyi_wallets where user_id=$1',[a])).rows[0].balance),expectedBalance);assert.equal((await restored.query('select username from public.kiyi_profiles where user_id=$1',[a])).rows[0].username,'mobile_a');assert.equal((await restored.query('select count(*)::int n from public.kiyi_vehicles where owner=$1',[a])).rows[0].n,vehicleRows);for(const f of recovered.files){const bytes=Buffer.from(f.data,'base64');assert.equal(hash(bytes),f.sha256);media.objects.set(f.name,bytes);}assert.equal(media.objects.size,files.length);}
  finally{await restored.close();}
 }finally{key.fill(0);await fs.rm(temp,{recursive:true,force:true});}
});
