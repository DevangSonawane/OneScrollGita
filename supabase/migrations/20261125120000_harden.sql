-- One Scroll Gita: tighten the account backend (PRD_v9 section 5).
-- Run once after 20261121_auth.sql (SQL editor, or `supabase db push`).
-- Safe to run again.

-- Nobody signed out needs these tables. Row level security already hides
-- the rows; this removes the access altogether.
revoke all on table public.profiles from anon;
revoke all on table public.purchases from anon;

-- Profiles are made only by the sign-up trigger: the app reads, never writes.
revoke insert, update, delete, truncate on table public.profiles
  from authenticated;

-- The app writes only these four columns of a purchase record. It cannot
-- set created_at or id, and it never updates or deletes a record.
revoke insert, update, delete, truncate on table public.purchases
  from authenticated;
grant insert (user_id, product_id, platform, transaction_id)
  on table public.purchases to authenticated;

-- The sign-up trigger function is not something to call directly.
revoke all on function public.handle_new_user()
  from public, anon, authenticated;

-- Sane values only. NOT VALID: rows already stored are left as they are.
alter table public.purchases
  drop constraint if exists purchases_product_id_check,
  drop constraint if exists purchases_transaction_id_check;
alter table public.purchases
  add constraint purchases_product_id_check
    check (product_id ~ '^[a-z0-9_.]{1,100}$') not valid,
  add constraint purchases_transaction_id_check
    check (transaction_id is null or char_length(transaction_id) between 1 and 200)
    not valid;

-- One record per store transaction, whichever account sent it first, so
-- two accounts cannot both claim the same purchase. Rows without a
-- transaction ID are not affected (nulls never clash).
-- If this fails, the table already holds a transaction under two accounts:
-- remove the extra row by hand and run the file again.
alter table public.purchases
  drop constraint if exists purchases_platform_transaction_id_key;
alter table public.purchases
  add constraint purchases_platform_transaction_id_key
    unique (platform, transaction_id);

-- At most 200 records per account, so nobody can fill the table.
create or replace function public.limit_purchase_rows()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if (select count(*) from public.purchases where user_id = new.user_id)
      >= 200 then
    raise exception 'too many purchase records';
  end if;
  return new;
end;
$$;

revoke all on function public.limit_purchase_rows()
  from public, anon, authenticated;

drop trigger if exists limit_purchase_rows on public.purchases;
create trigger limit_purchase_rows
  before insert on public.purchases
  for each row execute function public.limit_purchase_rows();

comment on table public.purchases is
  'Support record written by the app. Not verified with the stores: '
  'check the App Store / Play Console before acting on a row. '
  'The app never unlocks anything from this table.';
