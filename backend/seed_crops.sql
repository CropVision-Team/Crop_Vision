-- ============================================================
-- Seed: crops
-- ============================================================
-- Auto-generated from model/supported_crops.py to keep the DB's crop
-- registry in sync with what the model actually supports. Run
-- this AFTER supabase_schema.sql and BEFORE seed_treatment_guidelines.sql.

insert into public.crops (name, supported_diseases) values
('Apple', '{"Apple___Apple_scab","Apple___Black_rot","Apple___Cedar_apple_rust","Apple___healthy"}'),
('Corn (Maize)', '{"Corn___Cercospora_leaf_spot Gray_leaf_spot","Corn___Common_rust","Corn___Northern_Leaf_Blight","Corn___healthy"}'),
('Grape', '{"Grape___Black_rot","Grape___Esca_(Black_Measles)","Grape___Leaf_blight_(Isariopsis_Leaf_Spot)","Grape___healthy"}'),
('Potato', '{"Potato___Early_blight","Potato___Late_blight","Potato___healthy"}'),
('Tomato', '{"Tomato___Bacterial_spot","Tomato___Early_blight","Tomato___Late_blight","Tomato___Leaf_Mold","Tomato___Septoria_leaf_spot","Tomato___Spider_mites Two-spotted_spider_mite","Tomato___Target_Spot","Tomato___Tomato_Yellow_Leaf_Curl_Virus","Tomato___Tomato_mosaic_virus","Tomato___healthy"}')
on conflict (name) do nothing;
