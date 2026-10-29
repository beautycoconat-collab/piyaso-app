// Real embedded SQL, simulated Auth/storage adapters. NOT hosted Supabase Auth.
import {test,after} from 'node:test';import assert from 'node:assert/strict';import {randomUUID,createHash} from 'node:crypto';
import {createMobileDB} from './testing/mobile-db.mjs';import {eraseAccount} from '../lib/account-erasure.mjs';
const db=await createMobileDB();after(()=>db.close());
const a=randomUUID(),b=randomUUID(),sa=randomUUID(),sb=randomUUID();
async function role(name,claims={}){await db.exec('reset role');await db.query("select set_config('request.jwt.claims',$1,false),set_config('request.jwt.claim.sub','',false)",[JSON.stringify(claims)]);await db.exec('set role '+name)}
const actor=(u,s)=>role('authenticated',{role:'authenticated',sub:u,session_id:s});
const command=async(action,payload={})=>(await db.query('select public.kiyi_command($1,$2::jsonb) result',[action,JSON.stringify(payload)])).rows[0].result;
const worker=async(action,owner=a)=>{await role('service_role',{role:'service_role'});return(await db.query('select public.piyaso_erasure_worker($1,$2::jsonb) result',[action,JSON.stringify({owner})])).rows[0].result};
const map={west:30.5,east:30.8,south:36.7,north:37,zoom:18,region:'all'};
let post,vehicle;
test('setup two isolated review identities with garage, post and map data',async()=>{
 await db.query("insert into auth.users(id,email,email_confirmed_at,created_at)values($1,'apple-a@example.invalid',now(),now()-interval '10 days'),($2,'apple-b@example.invalid',now(),now()-interval '10 days')",[a,b]);await db.query('insert into auth.sessions(id,user_id)values($1,$2),($3,$4)',[sa,a,sb,b]);
 await actor(a,sa);await command('profile',{username:'apple_test_a',searchable:true});vehicle=(await command('vehicle_create',{model:'peugeot-208',plate:'07 APL 101'})).id;post=(await command('post_create',{text:'İzole Apple kabul verisi',visibility:'public',request_id:randomUUID()})).post.id;
 await command('sharing',{enabled:true,ghost:true});await command('position',{session:randomUUID(),seq:1,lat:36.86702735,lng:30.6417432365968,accuracy:10,observed_at:Date.now()});
 await actor(b,sb);await command('profile',{username:'apple_test_b'});
 await db.exec('reset role');await db.query("update public.kiyi_entitlements set premium_until=now()+interval '1 day' where user_id=$1",[b]);
});
test('Premium cannot unmask ghost identity or reveal exact location',async()=>{await actor(b,sb);const m=await command('map',map);assert.equal(m.people.length,1);assert.equal(m.people[0].username,'hayalet');assert.notEqual(m.people[0].id,a);assert.deepEqual(m.people[0].pos,[36.87,30.64]);assert.equal(m.people[0].heading,null)});
test('blocking removes ghost location for both users',async()=>{await actor(b,sb);await command('block',{target:a,enabled:true});assert.equal((await command('map',map)).people.length,0);await command('block',{target:a,enabled:false})});
test('normal authenticated/anonymous roles cannot invoke erasure worker',async()=>{await actor(b,sb);await assert.rejects(()=>db.query("select public.piyaso_erasure_worker('prepare',$1)",[JSON.stringify({owner:a})]));await role('anon');await assert.rejects(()=>db.query("select public.piyaso_erasure_worker('prepare',$1)",[JSON.stringify({owner:a})]))});
test('cross-app references reject deletion before changing visibility',async()=>{await db.exec('reset role');await db.exec('create table public.other_application(owner uuid references auth.users)');await db.query('insert into public.other_application values($1)',[a]);await assert.rejects(()=>worker('prepare'),/SHARED_OR_ADMIN_IDENTITY/);await db.exec('reset role');assert.equal((await db.query('select deleted_at from public.kiyi_profiles where user_id=$1',[a])).rows[0].deleted_at,null);await db.exec('drop table public.other_application')});
test('legal hold prevents erasure',async()=>{await db.exec('reset role');await db.query("insert into kiyi_private.erasure_holds values($1,'isolated test hold')",[a]);await assert.rejects(()=>worker('prepare'),/RETENTION_REVIEW_REQUIRED/);await db.exec('reset role');await db.query('delete from kiyi_private.erasure_holds where owner=$1',[a])});
test('pending upload prevents deletion racing a media upload',async()=>{await db.exec('reset role');await db.query("insert into kiyi_private.media_registry values($1,$2,'image/png',12,'pending',now())",[a+'/pending',a]);await assert.rejects(()=>worker('prepare'),/UPLOAD_IN_PROGRESS/);await db.exec('reset role');await db.query('delete from kiyi_private.media_registry where owner=$1',[a])});
test('paid-order retention blocks deletion before hiding the profile',async()=>{await db.exec('reset role');const id=randomUUID();await db.query("insert into public.kiyi_orders(id,owner,provider,status,amount_kurus)values($1,$2,'apple','verified',100)",[id,a]);await assert.rejects(()=>worker('prepare'),/PAID_RETENTION_NOT_CONFIGURED/);await db.exec('reset role');assert.equal((await db.query('select deleted_at from public.kiyi_profiles where user_id=$1',[a])).rows[0].deleted_at,null);await db.query('delete from public.kiyi_orders where id=$1',[id])});
test('map pagination hides real user UUIDs and returns every ghost once',async()=>{
 await db.exec('reset role; begin');
 try{
  const template=(await db.query('select to_jsonb(p) p from public.kiyi_positions p where user_id=$1',[a])).rows[0].p;
  await db.exec("create temporary table apple_page_ids as select gen_random_uuid() id from generate_series(1,201);insert into auth.users(id,email_confirmed_at)select id,now()from apple_page_ids;insert into public.kiyi_profiles(user_id,username)select id,'page_'||left(replace(id::text,'-',''),22)from apple_page_ids;insert into public.kiyi_privacy(user_id,sharing,ghost)select id,true,true from apple_page_ids;");
  await db.query("insert into public.kiyi_positions select (jsonb_populate_record(null::public.kiyi_positions,$1::jsonb||jsonb_build_object('user_id',id))).* from apple_page_ids",[JSON.stringify(template)]);
  await actor(b,sb);const first=await command('map',map);assert.equal(first.people.length,200);assert.match(first.next,/^[a-f0-9]{32}$/);const second=await command('map',{...map,after:first.next});assert.equal(second.people.length,2);assert.equal(second.next,null);const ids=[...first.people,...second.people].map(x=>x.id);assert.equal(new Set(ids).size,202);assert(!ids.includes(a));
  const unkeyed=createHash('md5').update(b+a+new Date().toISOString().slice(0,10)).digest('hex');assert(!ids.includes(unkeyed));
 }finally{await db.exec('rollback; reset role')}
});
test('isolated full erasure removes Auth row, media, profile, garage, posts and wallet; peer remains',async()=>{
 await db.exec('reset role');await db.query('update public.kiyi_privacy set approved=array[$1::uuid] where user_id=$2',[a,b]);const path=a+'/photo.png';await db.query("insert into storage.objects(bucket_id,name,owner_id)values('kiyi-media',$1,$2)",[path,a]);
 const result=await eraseAccount({token:'Bearer isolated',password:'test-password',confirmation:'SİL'},{
 currentUser:async()=>({id:a,email:'apple-a@example.invalid'}),reauthenticate:async()=>({user:{id:a},access_token:'isolated'}),prepare:id=>worker('prepare',id),
 signOutAll:async()=>{await db.exec('reset role');await db.query('delete from auth.sessions where user_id=$1',[a])},
 removeObjects:async paths=>{await db.exec('reset role');for(const p of paths)await db.query('delete from storage.objects where name=$1',[p])},
 purgePersonalData:id=>worker('purge',id),deleteAuthUser:async id=>{await db.exec('reset role');await db.query('delete from auth.users where id=$1',[id])},authUserExists:async id=>(await db.query('select id from auth.users where id=$1',[id])).rows.length>0
 },{enabled:true,authScope:'exclusive',policy:'free-account-erasure-v1'});
 assert.equal(result.status,'deleted');await db.exec('reset role');
 for(const [table,col] of [['auth.users','id'],['public.kiyi_profiles','user_id'],['public.kiyi_vehicles','owner'],['public.kiyi_posts','author'],['public.kiyi_wallets','user_id'],['public.kiyi_positions','user_id'],['auth.sessions','user_id']])assert.equal((await db.query(`select count(*)::int n from ${table} where ${col}=$1`,[a])).rows[0].n,0,table);
 assert.deepEqual((await db.query('select approved from public.kiyi_privacy where user_id=$1',[b])).rows[0].approved,[]);await actor(a,sa);await assert.rejects(()=>command('bundle'));await db.exec('reset role');assert.equal((await db.query('select count(*)::int n from auth.users where id=$1',[b])).rows[0].n,1);await actor(b,sb);assert.equal((await command('bundle')).me.username,'apple_test_b');
});
