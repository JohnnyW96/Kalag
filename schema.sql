-- ============================================================
--  פועלי בניין — סכמת מסד הנתונים ל‑Supabase
--  הריצו את כל הקובץ ב‑SQL Editor של הפרויקט, פעם אחת.
-- ============================================================

-- ---------- טבלת הפערים ----------
create table if not exists public.gaps (
  id          uuid primary key default gen_random_uuid(),
  company     text not null,
  gap         text not null,
  location    text default '',
  status      text not null default 'טרם הועלה'
              check (status in ('טרם הועלה','בטיפול','טופל')),
  note        text default '',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists gaps_created_at_idx on public.gaps (created_at desc);
create index if not exists gaps_status_idx     on public.gaps (status);

-- ---------- טבלת הגדרות (שורה אחת) ----------
create table if not exists public.settings (
  id          int primary key default 1 check (id = 1),
  course_name text default '',
  updated_at  timestamptz not null default now()
);

insert into public.settings (id, course_name)
values (1, '')
on conflict (id) do nothing;

-- ---------- עדכון אוטומטי של updated_at ----------
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists gaps_touch on public.gaps;
create trigger gaps_touch before update on public.gaps
  for each row execute function public.touch_updated_at();

drop trigger if exists settings_touch on public.settings;
create trigger settings_touch before update on public.settings
  for each row execute function public.touch_updated_at();

-- ---------- אבטחה: רק משתמש מחובר רואה ומשנה ----------
alter table public.gaps     enable row level security;
alter table public.settings enable row level security;

drop policy if exists gaps_select on public.gaps;
drop policy if exists gaps_insert on public.gaps;
drop policy if exists gaps_update on public.gaps;
drop policy if exists gaps_delete on public.gaps;

create policy gaps_select on public.gaps
  for select to authenticated using (true);
create policy gaps_insert on public.gaps
  for insert to authenticated with check (true);
create policy gaps_update on public.gaps
  for update to authenticated using (true) with check (true);
create policy gaps_delete on public.gaps
  for delete to authenticated using (true);

drop policy if exists settings_select on public.settings;
drop policy if exists settings_update on public.settings;

create policy settings_select on public.settings
  for select to authenticated using (true);
create policy settings_update on public.settings
  for update to authenticated using (true) with check (true);

-- ---------- עדכונים בזמן אמת ----------
alter publication supabase_realtime add table public.gaps;
alter publication supabase_realtime add table public.settings;
