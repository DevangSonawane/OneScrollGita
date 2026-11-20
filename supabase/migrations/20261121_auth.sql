-- One Scroll Gita: optional account (docs/PRD_v9.md section 5).
-- Run once in the Supabase SQL editor (or `supabase db push`).

-- A row per account, made automatically on sign-up.
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Read own profile" on public.profiles
  for select using (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id) on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Store purchases, for support only. The app never unlocks anything from
-- this table: the App Store / Google Play stay the source of truth.
create table if not exists public.purchases (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  product_id text not null,
  platform text not null check (platform in ('ios', 'android')),
  transaction_id text,
  created_at timestamptz not null default now(),
  unique (user_id, transaction_id)
);

alter table public.purchases enable row level security;

create policy "Read own purchases" on public.purchases
  for select using (auth.uid() = user_id);

create policy "Add own purchases" on public.purchases
  for insert with check (auth.uid() = user_id);

-- In-app account deletion (required by Apple and Google Play). Deleting the
-- auth user cascades to profiles and purchases.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not signed in';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
