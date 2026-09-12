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
  priority    text not null default 'בינוני'
              check (priority in ('גבוה','בינוני','נמוך')),
  opened_at   date not null default current_date,
  note        text default '',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ---------- מיגרציה: הוספת עדיפות ותאריך פתיחה לטבלה קיימת ----------
-- (בטוח להריץ גם אם הטבלה כבר קיימת מריצה קודמת של הקובץ)
alter table public.gaps add column if not exists priority text not null default 'בינוני'
  check (priority in ('גבוה','בינוני','נמוך'));
alter table public.gaps add column if not exists opened_at date not null default current_date;

-- ---------- מיגרציה: פרטי מי שפתח את הפער ----------
-- (בטוח להריץ גם אם הטבלה כבר קיימת מריצה קודמת של הקובץ)
alter table public.gaps add column if not exists opened_by_name  text default '';
alter table public.gaps add column if not exists opened_by_phone text default '';

-- ---------- מיגרציה: מבנה ומספר חדר (למגורים/כיתות) ----------
-- (בטוח להריץ גם אם הטבלה כבר קיימת מריצה קודמת של הקובץ)
alter table public.gaps add column if not exists building     text default '';
alter table public.gaps add column if not exists room_number  text default '';

create index if not exists gaps_created_at_idx on public.gaps (created_at desc);
create index if not exists gaps_status_idx     on public.gaps (status);
create index if not exists gaps_priority_idx   on public.gaps (priority);
create index if not exists gaps_opened_at_idx  on public.gaps (opened_at desc);

-- ---------- טבלת Changelog לכל פער ----------
-- (טבלה חדשה: בטוח להריץ גם אם היא כבר קיימת מריצה קודמת של הקובץ)
create table if not exists public.gap_changes (
  id          uuid primary key default gen_random_uuid(),
  gap_id      uuid not null references public.gaps(id) on delete cascade,
  changed_at  timestamptz not null default now(),
  changed_by  text default '',
  change_type text not null default 'update' check (change_type in ('create','update')),
  field       text default '',
  old_value   text default '',
  new_value   text default ''
);

create index if not exists gap_changes_gap_id_idx     on public.gap_changes (gap_id);
create index if not exists gap_changes_changed_at_idx on public.gap_changes (changed_at desc);

-- ---------- טבלת עדכונים חופשיים לכל פער ----------
-- (בנפרד מ-gap_changes: כאן אנשי הצוות כותבים חופשי "הוזמן טכנאי, מגיע מחר" וכו')
-- (טבלה חדשה: בטוח להריץ גם אם היא כבר קיימת מריצה קודמת של הקובץ)
create table if not exists public.gap_updates (
  id          uuid primary key default gen_random_uuid(),
  gap_id      uuid not null references public.gaps(id) on delete cascade,
  message     text not null,
  created_at  timestamptz not null default now(),
  created_by  text default ''
);

create index if not exists gap_updates_gap_id_idx     on public.gap_updates (gap_id);
create index if not exists gap_updates_created_at_idx on public.gap_updates (created_at desc);

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
alter table public.gaps        enable row level security;
alter table public.settings    enable row level security;
alter table public.gap_changes enable row level security;
alter table public.gap_updates enable row level security;

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

-- ה-changelog הוא יומן ביקורת: מותר להוסיף ולקרוא, אין עדכון/מחיקה ידניים
-- (שורות נמחקות אוטומטית כשהפער עצמו נמחק, דרך ה-foreign key למעלה)
drop policy if exists gap_changes_select on public.gap_changes;
drop policy if exists gap_changes_insert on public.gap_changes;
drop policy if exists gap_changes_delete on public.gap_changes;

create policy gap_changes_select on public.gap_changes
  for select to authenticated using (true);
create policy gap_changes_insert on public.gap_changes
  for insert to authenticated with check (true);
create policy gap_changes_delete on public.gap_changes
  for delete to authenticated using (true);

-- עדכונים חופשיים: כל אחד יכול להוסיף, לקרוא ולמחוק (כמו בשאר הטבלאות באתר)
drop policy if exists gap_updates_select on public.gap_updates;
drop policy if exists gap_updates_insert on public.gap_updates;
drop policy if exists gap_updates_delete on public.gap_updates;

create policy gap_updates_select on public.gap_updates
  for select to authenticated using (true);
create policy gap_updates_insert on public.gap_updates
  for insert to authenticated with check (true);
create policy gap_updates_delete on public.gap_updates
  for delete to authenticated using (true);

-- ---------- עדכונים בזמן אמת ----------
alter publication supabase_realtime add table public.gaps;
alter publication supabase_realtime add table public.settings;

do $$
begin
  alter publication supabase_realtime add table public.gap_changes;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.gap_updates;
exception when duplicate_object then null;
end $$;
