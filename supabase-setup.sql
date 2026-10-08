-- 小小探險家：在 Supabase SQL Editor 執行一次
-- 先在 Authentication > Users 建立你的管理員帳號。
-- 把下方 admin email 換成你自己的電子郵件，再執行。
create table if not exists public.game_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.game_admins enable row level security;
-- 管理員只能讀取自己的資格；資格由 SQL Editor 授予。
drop policy if exists "read own admin" on public.game_admins;
create policy "read own admin" on public.game_admins for select to authenticated using (user_id = (select auth.uid()));
create table if not exists public.levels (
 id uuid primary key default gen_random_uuid(),
 title text not null check (char_length(title) between 1 and 60),
 description text not null default '',
 image_path text not null,
 image_url text not null,
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
alter table public.levels enable row level security;
drop policy if exists "public read levels" on public.levels;
create policy "public read levels" on public.levels for select to anon, authenticated using (true);
drop policy if exists "admins create levels" on public.levels;
create policy "admins create levels" on public.levels for insert to authenticated with check (
 created_by=(select auth.uid()) and exists(select 1 from public.game_admins where user_id=(select auth.uid()))
);
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('scenes','scenes',true,8388608,array['image/png','image/jpeg','image/webp'])
on conflict (id) do update set public=true,file_size_limit=8388608,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "admins upload scenes" on storage.objects;
create policy "admins upload scenes" on storage.objects for insert to authenticated with check (
 bucket_id='scenes' and (storage.foldername(name))[1]=(select auth.uid())::text
 and exists(select 1 from public.game_admins where user_id=(select auth.uid()))
);
drop policy if exists "admins delete scenes" on storage.objects;
create policy "admins delete scenes" on storage.objects for delete to authenticated using (
 bucket_id='scenes' and (storage.foldername(name))[1]=(select auth.uid())::text
 and exists(select 1 from public.game_admins where user_id=(select auth.uid()))
);
-- 建立管理員帳號後，另執行以下 SQL，將 EMAIL 改為你的實際信箱：
-- insert into public.game_admins(user_id)
-- select id from auth.users where email='YOUR_EMAIL@example.com'
-- on conflict do nothing;
