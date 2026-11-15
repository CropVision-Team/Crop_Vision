-- ============================================================
-- Mobile-Based Crop Disease Detection - Supabase Schema
-- ============================================================
-- Auth is handled natively by Supabase (auth.users table).
-- This schema adds the app-specific tables + RLS policies.
--
-- IDEMPOTENT: every statement here is safe to re-run, even if some or
-- all of it already ran before (e.g. if a previous run got partway
-- through and errored out). Tables/indexes use "if not exists";
-- policies (which Postgres doesn't support "if not exists" for) are
-- dropped first if they already exist, then recreated.

-- ---------- 1. Farmer profile ----------
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  full_name text,
  phone_number text,
  location text,
  preferred_language text default 'en',
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Function & trigger to automatically create a public.profiles row when a user registers in auth.users
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------- 2. Crop registry (static reference data) ----------
create table if not exists public.crops (
  id serial primary key,
  name text not null unique,          -- e.g. 'Tomato'
  scientific_name text,
  supported_diseases text[]           -- e.g. {'Early Blight','Late Blight','Healthy'}
);

alter table public.crops enable row level security;

-- Reference data: anyone signed in can read it, nobody can write to it
-- via the app (only via service role / SQL editor / migrations).
drop policy if exists "Anyone can read crops" on public.crops;
create policy "Anyone can read crops"
  on public.crops for select
  to authenticated
  using (true);

-- ---------- 3. Diagnosis records ----------
create table if not exists public.diagnoses (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  crop_id int references public.crops(id),
  image_url text not null,                 -- Supabase Storage path
  is_valid_leaf boolean not null,          -- result of Image Verification stage
  rejection_reason text,                   -- populated only if is_valid_leaf = false
  predicted_disease text,
  confidence numeric(5,2),
  severity_stage text check (severity_stage in ('G0','G1','G2','G3')),
  severity_percent numeric(5,2),           -- diseased-area % from CV estimator
  treatment_recommendation text,
  prevention_tips text,                    -- stored per-diagnosis so history stays
                                            -- accurate even if guidelines change later
  created_at timestamptz default now()
);

alter table public.diagnoses enable row level security;

drop policy if exists "Users can view own diagnoses" on public.diagnoses;
create policy "Users can view own diagnoses"
  on public.diagnoses for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own diagnoses" on public.diagnoses;
create policy "Users can insert own diagnoses"
  on public.diagnoses for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own diagnoses" on public.diagnoses;
create policy "Users can delete own diagnoses"
  on public.diagnoses for delete
  using (auth.uid() = user_id);

-- ---------- 4. Treatment knowledge base ----------
create table if not exists public.treatment_guidelines (
  id serial primary key,
  disease_name text not null,
  severity_stage text check (severity_stage in ('G0','G1','G2','G3')) not null,
  recommendation text not null,
  prevention_tips text,
  unique(disease_name, severity_stage)
);

alter table public.treatment_guidelines enable row level security;

drop policy if exists "Anyone can read treatment guidelines" on public.treatment_guidelines;
create policy "Anyone can read treatment guidelines"
  on public.treatment_guidelines for select
  to authenticated
  using (true);

-- ---------- 5. Crop calendar / reminders ----------
create table if not exists public.reminders (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  description text,
  reminder_date timestamptz not null,
  is_recurring boolean default false,
  recurrence_interval text,       -- e.g. 'weekly', 'monthly'
  is_completed boolean default false,
  created_at timestamptz default now()
);

alter table public.reminders enable row level security;

drop policy if exists "Users manage own reminders" on public.reminders;
create policy "Users manage own reminders"
  on public.reminders for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------- 6. AI assistant chat history ----------
create table if not exists public.chat_messages (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  role text check (role in ('user','assistant')) not null,
  content text not null,
  related_diagnosis_id uuid references public.diagnoses(id),
  created_at timestamptz default now()
);

alter table public.chat_messages enable row level security;

drop policy if exists "Users manage own chat history" on public.chat_messages;
create policy "Users manage own chat history"
  on public.chat_messages for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------- 7. Storage bucket for leaf images ----------
insert into storage.buckets (id, name, public)
values ('leaf-images', 'leaf-images', false)
on conflict (id) do nothing;

drop policy if exists "Users upload own images" on storage.objects;
create policy "Users upload own images"
  on storage.objects for insert
  with check (bucket_id = 'leaf-images' and auth.uid()::text = (storage.foldername(name))[1]);

drop policy if exists "Users view own images" on storage.objects;
create policy "Users view own images"
  on storage.objects for select
  using (bucket_id = 'leaf-images' and auth.uid()::text = (storage.foldername(name))[1]);

drop policy if exists "Users delete own images" on storage.objects;
create policy "Users delete own images"
  on storage.objects for delete
  using (bucket_id = 'leaf-images' and auth.uid()::text = (storage.foldername(name))[1]);

-- ---------- 8. Indexes ----------
-- Matches the actual query patterns in SupabaseService: history/reminders/
-- chat are always filtered by user_id and ordered by a timestamp column.
create index if not exists idx_diagnoses_user_created on public.diagnoses (user_id, created_at desc);
create index if not exists idx_reminders_user_date on public.reminders (user_id, reminder_date);
create index if not exists idx_chat_messages_user_created on public.chat_messages (user_id, created_at);

-- ---------- 9. Column documentation ----------
comment on column public.diagnoses.severity_stage is
  'G0=Healthy, G1=Mild, G2=Moderate, G3=Critical';

-- ---------- 10. Crop Growth Tracking ----------
-- One row per crop a farmer is tracking a growth cycle for. The
-- growth-stage calendar itself (which day ranges map to which of the
-- 5 stages, per crop) is static reference data that lives in the app
-- code (model/crop_growth_calendar.py, mirrored in Dart) rather than a
-- database table - only the farmer-specific planting date needs to be
-- stored and queried per user.
create table if not exists public.crop_growth_tracking (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  crop_name text not null,
  planting_date date not null,
  created_at timestamptz default now()
);

alter table public.crop_growth_tracking enable row level security;

drop policy if exists "Users view own tracked crops" on public.crop_growth_tracking;
create policy "Users view own tracked crops"
  on public.crop_growth_tracking for select
  using (auth.uid() = user_id);

drop policy if exists "Users insert own tracked crops" on public.crop_growth_tracking;
create policy "Users insert own tracked crops"
  on public.crop_growth_tracking for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users update own tracked crops" on public.crop_growth_tracking;
create policy "Users update own tracked crops"
  on public.crop_growth_tracking for update
  using (auth.uid() = user_id);

drop policy if exists "Users delete own tracked crops" on public.crop_growth_tracking;
create policy "Users delete own tracked crops"
  on public.crop_growth_tracking for delete
  using (auth.uid() = user_id);

create index if not exists idx_crop_growth_tracking_user on public.crop_growth_tracking (user_id);
