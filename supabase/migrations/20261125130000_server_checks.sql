-- One Scroll Gita: server-side purchase checks and Apple token revoke
-- (PRD_v9 section 5, owner decision 2026-11-25).
-- Run after 20261125120000_harden.sql. Safe to run again.
-- Deploy the Edge Functions in supabase/functions before running this:
-- from here on only they write purchase records.

-- Purchase records are now written by the verify-purchase function, which
-- checks each one with the App Store / Google Play. The app never unlocks
-- anything from this table: the store on the device stays the truth.
alter table public.purchases
  add column if not exists verified boolean not null default false,
  add column if not exists status text,
  add column if not exists expires_at timestamptz,
  add column if not exists environment text,
  add column if not exists original_transaction_id text,
  add column if not exists purchase_token text,
  add column if not exists updated_at timestamptz not null default now(),
  -- Whether a subscription will renew (null: one-time or not known).
  add column if not exists will_renew boolean,
  -- When and why the store refunded or revoked it.
  add column if not exists revoked_at timestamptz,
  add column if not exists revoke_reason text,
  -- sadhak or shravan, from the product ID, for support filters.
  add column if not exists package text generated always as (
    case
      when product_id like 'sadhak%' then 'sadhak'
      when product_id like 'shravan%' then 'shravan'
    end
  ) stored;

create index if not exists purchases_original_transaction_id_idx
  on public.purchases (original_transaction_id);
create index if not exists purchases_purchase_token_idx
  on public.purchases (purchase_token);

-- The app no longer writes rows itself; only the functions (service role).
drop policy if exists "Add own purchases" on public.purchases;
revoke insert, update, delete, truncate on table public.purchases
  from anon, authenticated;

comment on table public.purchases is
  'Support record written by the verify-purchase and store notification '
  'functions. verified = true: checked with the App Store / Google Play. '
  'The app never unlocks anything from this table.';

-- Apple refresh tokens, kept only so they can be revoked when the account
-- is deleted (Apple requires it). Only the Edge Functions can read them.
create table if not exists public.apple_tokens (
  user_id uuid primary key references auth.users (id) on delete cascade,
  -- Which Apple client issued the token: the app's bundle ID (iPhone) or
  -- the Services ID (web sign-in on Android). Revoke needs the same one.
  client_id text not null,
  refresh_token text not null,
  updated_at timestamptz not null default now()
);

alter table public.apple_tokens enable row level security;
-- No policies: nobody but the service role reaches this table.
revoke all on table public.apple_tokens from public, anon, authenticated;

-- One row per store notification: a short history for support ("renewed
-- on X, refunded on Y"). Written only by the notification functions; goes
-- with the account when it is deleted; pruned after a year.
create table if not exists public.purchase_events (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users (id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  event text not null check (char_length(event) <= 100),
  transaction_id text check (char_length(transaction_id) <= 200),
  original_transaction_id text,
  purchase_token text,
  received_at timestamptz not null default now()
);

create index if not exists purchase_events_user_id_idx
  on public.purchase_events (user_id);
create index if not exists purchase_events_received_at_idx
  on public.purchase_events (received_at);

alter table public.purchase_events enable row level security;
revoke all on table public.purchase_events from public, anon, authenticated;

-- Weekly clean-up of events older than a year (pg_cron, when available).
do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.schedule(
      'prune-purchase-events',
      '0 3 * * 0',
      $job$delete from public.purchase_events
           where received_at < now() - interval '1 year'$job$
    );
  end if;
end;
$$;

-- For the owner in the dashboard SQL editor: find a user's purchases and
-- history by email. The support schema is not exposed to the app's API,
-- and the app's roles cannot read it.
create schema if not exists support;
revoke all on schema support from public, anon, authenticated;

create or replace view support.purchases as
  select u.email, p.*
  from public.purchases p
  join auth.users u on u.id = p.user_id;

create or replace view support.purchase_events as
  select u.email, e.*
  from public.purchase_events e
  left join auth.users u on u.id = e.user_id;

revoke all on all tables in schema support from public, anon, authenticated;
