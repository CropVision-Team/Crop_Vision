-- ============================================================
-- CropVision Complete Database Setup (Schema + Crops + Treatments)
-- Run this once in the Supabase SQL Editor.
-- ============================================================

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

-- ---------- 2. Crop registry ----------
create table if not exists public.crops (
  id serial primary key,
  name text not null unique,
  scientific_name text,
  supported_diseases text[]
);

alter table public.crops enable row level security;

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
  image_url text not null,
  is_valid_leaf boolean not null,
  rejection_reason text,
  predicted_disease text,
  confidence numeric(5,2),
  severity_stage text check (severity_stage in ('G0','G1','G2','G3')),
  severity_percent numeric(5,2),
  treatment_recommendation text,
  prevention_tips text,
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
  recurrence_interval text,
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

-- ---------- 8. Crop Growth Tracking ----------
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

-- ---------- 9. Seed Crops ----------
insert into public.crops (name, supported_diseases) values
('Apple', '{"Apple___Apple_scab","Apple___Black_rot","Apple___Cedar_apple_rust","Apple___healthy"}'),
('Corn (Maize)', '{"Corn___Cercospora_leaf_spot Gray_leaf_spot","Corn___Common_rust","Corn___Northern_Leaf_Blight","Corn___healthy"}'),
('Grape', '{"Grape___Black_rot","Grape___Esca_(Black_Measles)","Grape___Leaf_blight_(Isariopsis_Leaf_Spot)","Grape___healthy"}'),
('Potato', '{"Potato___Early_blight","Potato___Late_blight","Potato___healthy"}'),
('Tomato', '{"Tomato___Bacterial_spot","Tomato___Early_blight","Tomato___Late_blight","Tomato___Leaf_Mold","Tomato___Septoria_leaf_spot","Tomato___Spider_mites Two-spotted_spider_mite","Tomato___Target_Spot","Tomato___Tomato_Yellow_Leaf_Curl_Virus","Tomato___Tomato_mosaic_virus","Tomato___healthy"}')
on conflict (name) do nothing;

-- ---------- 10. Seed Treatment Guidelines ----------
insert into public.treatment_guidelines (disease_name, severity_stage, recommendation, prevention_tips) values
('Tomato___healthy', 'G0', 'No treatment needed. Plant is healthy.', 'Continue regular monitoring, proper spacing, and balanced fertilization.'),
('Tomato___Early_blight', 'G1', 'Remove affected lower leaves. Apply a preventive copper-based fungicide.', 'Mulch soil to prevent spore splash-back onto leaves.'),
('Tomato___Early_blight', 'G2', 'Apply copper-based or chlorothalonil fungicide every 7-10 days. Remove and destroy affected leaves.', 'Rotate crops annually; avoid planting tomatoes/potatoes in the same soil consecutively.'),
('Tomato___Early_blight', 'G3', 'Apply systemic fungicide immediately. Remove severely affected plants to prevent spread. Consult local agricultural extension officer.', 'Consider resistant tomato varieties for the next planting cycle.'),
('Tomato___Late_blight', 'G1', 'Apply preventive fungicide (mancozeb or copper-based).', 'Improve field drainage and airflow between plants.'),
('Tomato___Late_blight', 'G2', 'Apply systemic fungicide (metalaxyl-based). Remove infected foliage immediately.', 'Avoid working in fields when foliage is wet to reduce spread.'),
('Tomato___Late_blight', 'G3', 'Urgent: remove and destroy infected plants entirely. Apply fungicide to remaining healthy plants as a barrier.', 'Late blight can destroy a field within days - report to local agri-extension for regional alerts.'),
('Tomato___Bacterial_spot', 'G1', 'Apply copper-based bactericide. Avoid handling wet plants.', 'Use certified disease-free seeds/transplants.'),
('Tomato___Bacterial_spot', 'G2', 'Increase copper spray frequency to every 5-7 days. Remove severely spotted leaves.', 'Avoid overhead irrigation; water at the base of plants.'),
('Tomato___Bacterial_spot', 'G3', 'Remove and destroy heavily infected plants. Apply bactericide to remaining crop.', 'Rotate with non-solanaceous crops for at least 2 years.'),
('Tomato___Leaf_Mold', 'G1', 'Improve greenhouse/field ventilation. Apply fungicide if humidity remains high.', 'Reduce humidity around plants; increase plant spacing.'),
('Tomato___Leaf_Mold', 'G2', 'Apply fungicide (chlorothalonil or copper-based). Remove affected leaves.', 'Avoid leaf wetness overnight - water early in the day.'),
('Tomato___Leaf_Mold', 'G3', 'Apply systemic fungicide immediately; heavy leaf mold can severely reduce yield.', 'Use resistant tomato varieties in humid climates.'),
('Tomato___Septoria_leaf_spot', 'G1', 'Remove lower affected leaves. Apply preventive fungicide.', 'Mulch to prevent soil splash onto lower leaves.'),
('Tomato___Septoria_leaf_spot', 'G2', 'Apply fungicide every 7-10 days. Remove and destroy infected debris.', 'Avoid working among wet plants to prevent spread.'),
('Tomato___Septoria_leaf_spot', 'G3', 'Apply fungicide immediately; consider removing severely defoliated plants.', 'Practice 2-3 year crop rotation away from tomato/potato.'),
('Tomato___Spider_mites Two-spotted_spider_mite', 'G1', 'Spray with insecticidal soap or neem oil.', 'Keep plants well-watered - mites thrive in drought-stressed plants.'),
('Tomato___Spider_mites Two-spotted_spider_mite', 'G2', 'Apply miticide. Introduce predatory mites if using biological control.', 'Avoid excessive nitrogen fertilization, which favors mite reproduction.'),
('Tomato___Spider_mites Two-spotted_spider_mite', 'G3', 'Apply targeted miticide immediately; heavy infestation can defoliate plants rapidly.', 'Regularly inspect undersides of leaves for early detection.'),
('Tomato___Target_Spot', 'G1', 'Apply preventive fungicide; remove affected leaves.', 'Ensure good air circulation between plants.'),
('Tomato___Target_Spot', 'G2', 'Apply fungicide (azoxystrobin or chlorothalonil-based) every 7-10 days.', 'Avoid overhead watering; remove crop debris after harvest.'),
('Tomato___Target_Spot', 'G3', 'Apply fungicide immediately and remove severely infected plant material.', 'Rotate crops and avoid dense planting in future seasons.'),
('Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'G1', 'Control whitefly vectors with insecticidal soap; remove affected leaves.', 'Use whitefly-proof netting/screens in nursery stage.'),
('Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'G2', 'Apply systemic insecticide to control whitefly population. Remove heavily symptomatic plants.', 'Use reflective mulches to repel whiteflies.'),
('Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'G3', 'Remove and destroy severely infected plants immediately - no cure exists once systemic. Focus on protecting remaining crop from whiteflies.', 'Plant virus-resistant tomato varieties in future seasons.'),
('Tomato___Tomato_mosaic_virus', 'G1', 'Remove affected leaves; disinfect tools between plants (virus spreads via contact).', 'Wash hands and tools with soap before handling plants.'),
('Tomato___Tomato_mosaic_virus', 'G2', 'Remove moderately affected plants if spread is increasing. No chemical cure exists.', 'Avoid tobacco product use near plants (a known transmission source).'),
('Tomato___Tomato_mosaic_virus', 'G3', 'Remove and destroy severely infected plants to protect the rest of the field.', 'Use certified virus-free seed for future planting.'),
('Potato___healthy', 'G0', 'No treatment needed. Plant is healthy.', 'Continue regular monitoring and good field hygiene.'),
('Potato___Early_blight', 'G1', 'Apply preventive fungicide. Remove lower affected leaves.', 'Ensure balanced fertilization - avoid nitrogen deficiency, which increases susceptibility.'),
('Potato___Early_blight', 'G2', 'Apply fungicide (chlorothalonil or mancozeb) every 7-10 days.', 'Rotate with non-host crops for at least 2 years.'),
('Potato___Early_blight', 'G3', 'Apply fungicide immediately; consider early harvest if tuber bulking is complete.', 'Use certified disease-free seed potatoes.'),
('Potato___Late_blight', 'G1', 'Apply preventive fungicide immediately - late blight spreads extremely fast.', 'Monitor weather forecasts; blight thrives in cool, wet conditions.'),
('Potato___Late_blight', 'G2', 'Apply systemic fungicide. Remove and destroy infected foliage.', 'Improve field drainage and plant spacing for airflow.'),
('Potato___Late_blight', 'G3', 'Urgent: destroy infected plants to prevent field-wide loss. This disease caused historic famines - treat as emergency.', 'Report outbreaks to local agricultural extension for regional monitoring.'),
('Apple___healthy', 'G0', 'No treatment needed.', 'Prune trees to improve air circulation.'),
('Apple___Black_rot', 'G1', 'Remove mummified fruit and cankers from tree.', 'Sanitize pruning tools between cuts.'),
('Apple___Black_rot', 'G2', 'Apply fungicide spray program (captan or myclobutanil-based) during growing season.', 'Remove nearby wild/abandoned apple trees that can host the fungus.'),
('Apple___Black_rot', 'G3', 'Aggressive pruning of infected branches. Apply fungicide immediately.', 'Consider resistant apple cultivars for future plantings.'),
('Apple___Apple_scab', 'G1', 'Apply preventive fungicide at green-tip stage.', 'Rake and destroy fallen leaves in autumn (fungus overwinters there).'),
('Apple___Apple_scab', 'G2', 'Apply fungicide (myclobutanil or captan) every 7-14 days through the season.', 'Prune for better air circulation and sunlight penetration.'),
('Apple___Apple_scab', 'G3', 'Apply fungicide immediately; heavy defoliation risk affects fruit yield next season too.', 'Plant scab-resistant apple varieties.'),
('Apple___Cedar_apple_rust', 'G1', 'Apply preventive fungicide in spring when orange gall spores are active nearby.', 'Remove nearby juniper/cedar trees within 2 miles if feasible (alternate host).'),
('Apple___Cedar_apple_rust', 'G2', 'Apply fungicide (myclobutanil-based) every 10-14 days during spring.', 'Choose rust-resistant apple varieties for new plantings.'),
('Apple___Cedar_apple_rust', 'G3', 'Apply fungicide immediately and remove heavily infected leaves.', 'Coordinate with neighbors to remove alternate juniper hosts in the area.'),
('Corn___healthy', 'G0', 'No treatment needed.', 'Practice crop rotation with non-host crops.'),
('Corn___Northern_Leaf_Blight', 'G1', 'Monitor closely; apply fungicide if weather remains humid.', 'Use resistant hybrid seed varieties where available.'),
('Corn___Northern_Leaf_Blight', 'G2', 'Apply foliar fungicide (strobilurin or triazole-based).', 'Till under crop residue after harvest to reduce fungal spores.'),
('Corn___Northern_Leaf_Blight', 'G3', 'Apply fungicide immediately; yield loss risk is high at this stage.', 'Rotate to soybean or other non-host crop next season.'),
('Corn___Common_rust', 'G1', 'Monitor; fungicide rarely needed at this stage for resistant hybrids.', 'Plant rust-resistant hybrids where common rust pressure is high.'),
('Corn___Common_rust', 'G2', 'Apply fungicide if susceptible hybrid and conditions favor spread.', 'Avoid late planting that exposes young plants to peak rust season.'),
('Corn___Common_rust', 'G3', 'Apply fungicide immediately to protect remaining green leaf area for grain fill.', 'Select resistant hybrids for future seasons in high-pressure areas.'),
('Corn___Cercospora_leaf_spot Gray_leaf_spot', 'G1', 'Monitor; consider fungicide if continuous corn planting history.', 'Rotate crops; avoid continuous corn-on-corn planting.'),
('Corn___Cercospora_leaf_spot Gray_leaf_spot', 'G2', 'Apply foliar fungicide, especially before tasseling.', 'Till crop residue to reduce overwintering fungal spores.'),
('Corn___Cercospora_leaf_spot Gray_leaf_spot', 'G3', 'Apply fungicide immediately; significant yield loss risk from leaf area loss.', 'Select resistant hybrids and rotate away from corn for a season.'),
('Grape___healthy', 'G0', 'No treatment needed.', 'Maintain good canopy management for airflow.'),
('Grape___Black_rot', 'G1', 'Remove mummified berries and infected leaves.', 'Prune for open canopy to reduce humidity around clusters.'),
('Grape___Black_rot', 'G2', 'Apply fungicide (myclobutanil or captan) starting at bloom.', 'Remove wild grape vines nearby that can harbor the fungus.'),
('Grape___Black_rot', 'G3', 'Apply fungicide immediately and remove severely infected clusters.', 'Consider resistant grape varieties for new plantings.'),
('Grape___Esca_(Black_Measles)', 'G1', 'Prune out affected wood during dry weather; disinfect tools.', 'Avoid pruning wounds during wet weather when fungal spores are active.'),
('Grape___Esca_(Black_Measles)', 'G2', 'Remove and destroy affected canes/spurs. No effective fungicide cure exists.', 'Protect large pruning wounds with wound sealant.'),
('Grape___Esca_(Black_Measles)', 'G3', 'Remove severely affected vines to prevent spread to healthy vines.', 'Replant with certified disease-free nursery stock.'),
('Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 'G1', 'Apply preventive fungicide; remove affected leaves.', 'Improve canopy airflow through leaf pulling.'),
('Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 'G2', 'Apply fungicide (copper-based) every 10-14 days.', 'Avoid overhead irrigation.'),
('Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 'G3', 'Apply fungicide immediately; heavy defoliation affects fruit ripening.', 'Rotate fungicide classes to avoid resistance buildup.')
on conflict (disease_name, severity_stage) do nothing;
