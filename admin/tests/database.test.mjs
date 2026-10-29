import {PGlite} from '@electric-sql/pglite';
import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const db=new PGlite();
await db.exec(`create role anon;create role authenticated;create role service_role;create schema auth;create schema kiyi_private;grant usage on schema kiyi_private to authenticated;create table auth.users(id uuid primary key,email_confirmed_at timestamptz);create table auth.sessions(id uuid primary key,user_id uuid);create function auth.jwt() returns jsonb language sql stable as $$ select coalesce(nullif(current_setting('request.jwt.claims',true),''),'{}')::jsonb $$;create function auth.uid() returns uuid language sql stable as $$select (auth.jwt()->>'sub')::uuid$$;create table public.kiyi_profiles(user_id uuid primary key,username text,profile jsonb default '{}',created_at timestamptz default now(),searchable boolean default false);create table public.kiyi_regions(id text);create table public.kiyi_reports(status text);create table public.kiyi_entitlements(user_id uuid,premium_until timestamptz,verified boolean,suspended boolean);`);
await db.exec(await readFile(new URL('../supabase/admin-foundation.sql',import.meta.url),'utf8'));
const owner='10000000-0000-4000-8000-000000000001',normal='10000000-0000-4000-8000-000000000002',moderator='10000000-0000-4000-8000-000000000003',sid='20000000-0000-4000-8000-000000000001';
await db.exec(`insert into auth.users values('${owner}',now()),('${normal}',now()),('${moderator}',now());insert into auth.sessions values('${sid}','${owner}'),('20000000-0000-4000-8000-000000000003','${moderator}'),('20000000-0000-4000-8000-000000000002','${normal}');insert into public.kiyi_profiles(user_id,username,profile)values('${owner}','owner','{"plate":"07 ABC 001","bio":"SECRET"}'),('${normal}','normal','{"plate":"07 ABC 002"}'),('${moderator}','mod','{}');select kiyi_private.bootstrap_admin('${owner}','Approved owner test fixture');`);
async function jwt(user=owner,aal='aal2',session=sid,extra={}) {await db.query("select set_config('request.jwt.claims',$1,false)",[JSON.stringify({sub:user,aal,session_id:session,amr:[{method:'totp',timestamp:Math.floor(Date.now()/1000)}],...extra})]);}
async function call(action,payload={}) {return (await db.query('select public.kiyi_admin_command($1,$2::jsonb) data',[action,JSON.stringify(payload)])).rows[0].data;}
async function denied(fn,pattern){await assert.rejects(fn,pattern);}
await jwt(normal,'aal2','20000000-0000-4000-8000-000000000002');await denied(()=>call('summary'),/ADMIN_DENIED/);
await jwt(owner,'aal1');assert.equal((await call('probe')).role,'super_admin');await denied(()=>call('summary'),/ADMIN_MFA_REQUIRED/);
await jwt();await denied(()=>call('summary'),/ADMIN_REAUTH_REQUIRED/);await call('session');assert.equal((await call('summary')).profiles,3);
const users=await call('users',{query:'07abc001'});assert.equal(users.items.length,1);assert.equal(users.items[0].plate_masked,'07 •••');assert(!JSON.stringify(users).includes('SECRET'));
assert.equal((await call('users',{query:'%'})).items.length,0);
const grant={user_id:moderator,role:'moderator',expected_version:0,request_id:'30000000-0000-4000-8000-000000000001',reason:'Approved moderator fixture'};
await call('staff_grant',grant);await call('staff_grant',grant);await denied(()=>call('staff_grant',{...grant,role:'finance'}),/ADMIN_REQUEST_CONFLICT/);
assert.equal((await db.query("select count(*)::int n from kiyi_private.admin_audit where action='staff_grant'")).rows[0].n,1);
await denied(()=>call('staff_grant',{...grant,user_id:owner,request_id:'30000000-0000-4000-8000-000000000009'}),/ADMIN_INVALID_INPUT/);
await jwt(moderator,'aal2','20000000-0000-4000-8000-000000000003');await call('session');await call('users');await denied(()=>call('audit'),/ADMIN_DENIED/);await denied(()=>call('staff_grant',grant),/ADMIN_DENIED/);
await jwt();await call('staff_revoke',{user_id:moderator,expected_version:1,request_id:'30000000-0000-4000-8000-000000000002',reason:'Moderator access revoked fixture'});
await jwt(moderator,'aal2','20000000-0000-4000-8000-000000000003');await denied(()=>call('users'),/ADMIN_DENIED/);
await jwt();await db.exec("update kiyi_private.admin_leases set last_seen=now()-interval '16 minutes' where user_id='"+owner+"'");await denied(()=>call('summary'),/ADMIN_REAUTH_REQUIRED/);
await jwt(owner,'aal2',sid,{amr:[{method:'totp',timestamp:1}]});await denied(()=>call('session'),/ADMIN_REAUTH_REQUIRED/);
await jwt();await call('session');await call('logout');await denied(()=>call('session'),/ADMIN_DENIED/);
await db.exec('set role authenticated');await denied(()=>db.exec('select * from kiyi_private.admin_memberships'),/permission denied/);await denied(()=>db.exec("select kiyi_private.bootstrap_admin('"+normal+"','malicious bootstrap attempt')"),/permission denied/);await db.exec('reset role');
console.log('PASS: real Postgres permission, MFA, lease, role, masking, idempotency, audit, revocation, and bootstrap controls');await db.close();
