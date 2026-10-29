// Disposable embedded PostgreSQL + PostGIS. Never connects to an external database.
import {PGlite} from '@electric-sql/pglite';
import {postgis} from '@electric-sql/pglite-postgis';
import {pgcrypto} from '@electric-sql/pglite/contrib/pgcrypto';
import fs from 'node:fs/promises';
const q=s=>'"'+s.replaceAll('"','""')+'"';
const read=p=>fs.readFile(new URL('../../'+p,import.meta.url),'utf8');
export async function createMobileDB(){
 const snapshot=JSON.parse(await read('tests/fixtures/mobile-schema.json'));
 const access=JSON.parse(await read('tests/fixtures/mobile-access.json'));
 const db=new PGlite({extensions:{postgis,pgcrypto}});
 await db.exec(`create role anon;create role authenticated;create role service_role bypassrls;
 create schema extensions;create schema auth;create schema storage;create schema kiyi_private;
 create extension postgis with schema extensions;create extension pgcrypto with schema extensions;
 set search_path=public,extensions;set check_function_bodies=off;
 grant usage on schema auth,storage,kiyi_private,extensions to anon,authenticated,service_role;
 create type auth.aal_level as enum ('aal1','aal2','aal3');`);
 for(const name of ['users','sessions']){
  const cols=access.auth_columns.filter(c=>c.table===name).map(c=>`${q(c.name)} ${c.type==='USER-DEFINED'?'auth.'+q(c.udt):c.type}${c.name==='id'?' primary key':''}${c.name==='created_at'?' default now()':''}`);
  await db.exec(`create table auth.${q(name)}(${cols.join(',')});`);
 }
 await db.exec(`create function auth.jwt() returns jsonb language sql stable as $$select coalesce(nullif(current_setting('request.jwt.claims',true),''),'{}')::jsonb$$;
 create function auth.uid() returns uuid language sql stable as $$select coalesce(nullif(current_setting('request.jwt.claim.sub',true),''),auth.jwt()->>'sub')::uuid$$;
 create table storage.buckets(id text primary key,name text,public boolean default false,file_size_limit bigint,allowed_mime_types text[]);
 create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text references storage.buckets,name text,owner uuid,owner_id text,metadata jsonb default '{}',created_at timestamptz default now(),updated_at timestamptz default now());
 alter table storage.objects enable row level security;
 grant select,insert,update,delete on storage.objects to authenticated;
 create function storage.foldername(name text) returns text[] language sql immutable as $$select (string_to_array(name,'/'))[1:array_length(string_to_array(name,'/'),1)-1]$$;
 insert into storage.buckets(id,name)values('kiyi-media','kiyi-media');`);
 for(const seq of (access.sequences||[]).filter(seq=>!snapshot.schema.tables.some(t=>t.schema===seq.schema&&t.columns.some(c=>c.identity&&seq.name===t.name+'_'+c.name+'_seq'))))await db.exec(`create sequence ${q(seq.schema)}.${q(seq.name)};`);
 for(const table of snapshot.schema.tables){
  const cols=table.columns.map(c=>`${q(c.name)} ${c.type}${c.identity?' generated always as identity':c.generated?' generated always as ('+c.default+') stored':c.default?' default '+c.default:''}${c.notnull?' not null':''}`);
  await db.exec(`create table ${q(table.schema)}.${q(table.name)}(${cols.join(',')});${table.rls?`alter table ${q(table.schema)}.${q(table.name)} enable row level security;`:''}`);
 }
 for(const definition of snapshot.schema.functions)await db.exec(definition);
 for(const type of ['p','u','c','f'])for(const c of snapshot.schema.constraints.filter(c=>c.type===type))await db.exec(`alter table ${q(c.schema)}.${q(c.table)} add constraint ${q(c.name)} ${c.sql};`);
 for(const definition of snapshot.extras.indexes||[])await db.exec(definition);
 for(const definition of snapshot.extras.triggers||[])await db.exec(definition);
 for(const p of snapshot.extras.policies||[])await db.exec(`create policy ${q(p.policyname)} on ${q(p.schemaname)}.${q(p.tablename)} as ${p.permissive} for ${p.cmd} to ${p.roles.map(q).join(',')}${p.qual?' using ('+p.qual+')':''}${p.with_check?' with check ('+p.with_check+')':''};`);
 await db.exec('revoke all on all functions in schema kiyi_private from public,anon,authenticated,service_role;');
 for(const acl of access.function_acl){
  await db.exec(`revoke all on function ${acl.signature} from public,anon,authenticated,service_role;`);
  for(const role of ['anon','authenticated','service_role'])if(acl[role])await db.exec(`grant execute on function ${acl.signature} to ${role};`);
 }
 for(const g of snapshot.extras.grants||[])await db.exec(`grant ${g.privilege_type} on ${q(g.table_schema)}.${q(g.table_name)} to ${q(g.grantee)};`);
 for(const [name,rows] of Object.entries(snapshot.seed))if(rows?.length)await db.query(`insert into ${name} select * from jsonb_populate_recordset(null::${name},$1::jsonb)`,[JSON.stringify(rows)]);
 await db.exec(await read('supabase/kiyi-antalya-regions.sql'));
 // Candidate release patches are tested locally, never applied remotely here.
 await db.exec(await read('supabase/admin/release-audit-brand.sql'));
 await db.exec(await read('supabase/admin/release-audit-storage.sql'));
 await db.exec(await read('supabase/admin/apple-location-privacy.sql'));
 await db.exec(await read('supabase/admin/apple-account-erasure.sql'));
 await db.exec('set check_function_bodies=on;');
 return db;
}
