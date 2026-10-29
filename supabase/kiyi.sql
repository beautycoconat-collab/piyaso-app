-- Kıyı application boundary: no changes to other applications or auth settings.
create table public.kiyi_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 username text not null unique check (username ~ '^[a-z0-9_\.]{3,30}$'),
 searchable boolean not null default false,
 profile jsonb not null default '{}' check (jsonb_typeof(profile)='object' and octet_length(profile::text)<9000000),
 created_at timestamptz not null default now()
);
create table public.kiyi_preferences (
 user_id uuid primary key references auth.users(id) on delete cascade,
 preferences jsonb not null default '{}' check (jsonb_typeof(preferences)='object' and octet_length(preferences::text)<50000)
);
create table public.kiyi_wallets (
 user_id uuid primary key references auth.users(id) on delete cascade,
 balance bigint not null default 0 check (balance>=0)
);
create table public.kiyi_credit_packs (
 id text primary key, base integer not null check(base>0), bonus integer not null check(bonus>=0), price_kurus integer not null check(price_kurus>0)
);
insert into public.kiyi_credit_packs values
 ('small',50,5,4999),('medium',150,40,14999),('large',400,200,39999),('plus',1000,600,99999),('max',2200,1800,219999);
create table public.kiyi_products (
 id text primary key, kind text not null check(kind in ('gift','song','car_color','plate')), credits integer not null check(credits>0)
);
insert into public.kiyi_products values
 ('rose','gift',20),('tulip','gift',20),('evil-eye','gift',20),('bouquet','gift',40),('friendship','gift',10),('coffee','gift',40),('tea','gift',50),('ring','gift',300),('cat','gift',222),('lemon','gift',40),('lighter','gift',50),('song','song',60),('car_color','car_color',500),('plate','plate',100);
-- Wallets are deliberately read-only to clients. No demo-credit import or payment crediting endpoint.
alter table public.kiyi_profiles enable row level security;
alter table public.kiyi_preferences enable row level security;
alter table public.kiyi_wallets enable row level security;
alter table public.kiyi_credit_packs enable row level security;
alter table public.kiyi_products enable row level security;
revoke all on public.kiyi_profiles,public.kiyi_preferences,public.kiyi_wallets,public.kiyi_credit_packs,public.kiyi_products from anon,authenticated;
grant select,insert,update,delete on public.kiyi_profiles,public.kiyi_preferences to authenticated;
grant select on public.kiyi_profiles,public.kiyi_credit_packs,public.kiyi_products to anon;
grant select on public.kiyi_wallets,public.kiyi_credit_packs,public.kiyi_products to authenticated;
create policy kiyi_profile_read on public.kiyi_profiles for select to anon,authenticated using (searchable or user_id=(select auth.uid()));
create policy kiyi_profile_insert on public.kiyi_profiles for insert to authenticated with check(user_id=(select auth.uid()));
create policy kiyi_profile_update on public.kiyi_profiles for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy kiyi_profile_delete on public.kiyi_profiles for delete to authenticated using(user_id=(select auth.uid()));
create policy kiyi_preferences_owner on public.kiyi_preferences for all to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy kiyi_wallet_owner on public.kiyi_wallets for select to authenticated using(user_id=(select auth.uid()));
create policy kiyi_packs_read on public.kiyi_credit_packs for select to anon,authenticated using(true);
create policy kiyi_products_read on public.kiyi_products for select to anon,authenticated using(true);
notify pgrst,'reload schema';
