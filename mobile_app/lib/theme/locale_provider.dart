
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

/// Supported languages with their locale codes
const Map<String, Locale> kSupportedLocales = {
  'English':          Locale('en'),
  'हिंदी (Hindi)':   Locale('hi'),
  'தமிழ் (Tamil)':   Locale('ta'),
  'తెలుగు (Telugu)': Locale('te'),
  'मराठी (Marathi)': Locale('mr'),
  'ಕನ್ನಡ (Kannada)': Locale('kn'),
};

/// Translated strings for each locale
const Map<String, Map<String, String>> kAppStrings = {
  'en': {
    // Nav & Common
    'app_name': 'CropVision',
    'nav_home': 'Home',
    'nav_calendar': 'Calendar',
    'nav_capture': 'Scan',
    'nav_history': 'History',
    'nav_assistant': 'Assistant',
    'cancel': 'Cancel',
    'save': 'Save',
    'track': 'Track',
    'delete': 'Delete',
    'error': 'Error',
    'loading': 'Loading...',

    // Settings Screen
    'settings': 'Farm Settings & Profile',
    'farmer_profile': 'Farmer Profile',
    'farmer_account': 'Farmer Account',
    'sector_farmer': '🌱 Sector 4 Active Farmer',
    'language_region': 'LANGUAGE & REGION',
    'app_language': 'App Language',
    'preferences': 'PREFERENCES',
    'dark_mode': 'Dark Mode',
    'dark_mode_active': 'Dark theme active',
    'light_mode_active': 'Light theme active (Recommended for sunlight)',
    'farm_reminders': 'Farm Reminders',
    'farm_reminders_desc': 'Get alerts for scheduled spray & watering tasks',
    'about_tech': 'ABOUT CROPEYES AI TECHNOLOGY',
    'tech_title': 'MobileViT Deep Learning',
    'tech_subtitle': 'Hybrid Vision Transformer Architecture',
    'tech_desc': 'CropVision uses a lightweight MobileViT neural network trained on 38 botanical classes across Tomato, Potato, Corn, Apple, and Grape leaves. Severity estimation is calculated on-device via HSV color-space pixel segmentation.',
    'chip_classes': '38 Plant Classes',
    'chip_severity': 'HSV Severity Staging',
    'chip_remedies': 'ICAR Botanical Remedies',
    'app_version': 'App Version',
    'sign_out': 'Sign Out',
    'sign_out_btn': 'Sign Out of CropVision',
    'lang_switched': '🌐 Language switched to',

    // Home Screen
    'season_badge': '🌾 Rabi Season • Field 4 Active',
    'greeting_morning': 'Good Morning, Farmer 👋',
    'greeting_afternoon': 'Good Afternoon, Farmer 👋',
    'greeting_evening': 'Good Evening, Farmer 👋',
    'home_subtitle': "Check your crops and view today's field care",
    'scan_title': 'SCAN CROP LEAF',
    'scan_subtitle': 'Instant AI Disease Detection',
    'tap_to_open_camera': 'TAP TO OPEN CAMERA',
    'today_tasks': "Today's Farm Tasks",
    'view_calendar': 'View Calendar',
    'no_tasks_today': 'No pending tasks for today 🎉',
    'all_crops_healthy': 'All scheduled field treatments are up to date.',
    'track_crop_see_tasks': 'Track a crop to see tasks',
    'my_crops': 'My Monitored Crops',
    'track_crop': 'Track Crop',
    'no_crops_title': 'No Crops Monitored Yet',
    'no_crops_subtitle': 'Track your planted crops to receive stage-by-stage spray schedules.',
    'track_first_crop': 'Track First Crop',
    'recent_scans': 'Recent Leaf Scans',
    'view_all': 'View All',
    'no_scans': 'No Leaf Scans Yet',
    'no_scans_desc': 'Notice any yellow spots or curled leaves? Scan a leaf now.',
    'scan_first': 'Scan Your First Leaf',
    'ask_ai_doctor': 'Ask AI Doctor',
    'plant_date': 'Plant Date',
    'stage': 'Stage',
    'days_old': 'days old',

    // Calendar Screen
    'calendar': 'Crop Calendar & Stages',
    'reminders': 'Reminders',
    'tracked_crops': 'Tracked Crops',
    'track_a_crop': 'Track a crop',
    'no_reminders': 'No reminders for this day',
    'no_crops': 'No crops tracked yet',
    'add_reminder': 'Add Reminder',

    // Assistant & History
    'assistant': 'AI Farm Assistant',
    'history': 'Scan History',
    'history_title': 'Farm Diagnosis History',
    'no_diagnoses_title': 'No Leaf Diagnoses Saved Yet',
    'no_diagnoses_desc': 'Take a photo of any diseased leaf to save diagnosis and get ICAR treatments.',
    'healthy': 'Healthy',
    'diseased': 'Diseased',
    'severity': 'Severity',
    'treatment': 'Treatment',
    'capture': 'Capture Leaf',
    'retake': 'Retake',
    'analyze': 'Analyze Leaf',
  },
  'ta': {
    // Nav & Common
    'app_name': 'பயிர் பார்வை',
    'nav_home': 'முகப்பு',
    'nav_calendar': 'நாட்காட்டி',
    'nav_capture': 'ஸ்கேன்',
    'nav_history': 'வரலாறு',
    'nav_assistant': 'உதவியாளர்',
    'cancel': 'ரத்து செய்',
    'save': 'சேமி',
    'track': 'கண்காணி',
    'delete': 'நீக்கு',
    'error': 'பிழை',
    'loading': 'ஏற்றுகிறது...',

    // Settings Screen
    'settings': 'பண்ணை அமைப்புகள் & சுயவிவரம்',
    'farmer_profile': 'விவசாயி சுயவிவரம்',
    'farmer_account': 'விவசாயி கணக்கு',
    'sector_farmer': '🌱 பிரிவு 4 செயலில் உள்ள விவசாயி',
    'language_region': 'மொழி மற்றும் பகுதி',
    'app_language': 'பயன்பாட்டு மொழி',
    'preferences': 'விருப்பத்தேர்வுகள்',
    'dark_mode': 'இருண்ட பயன்முறை',
    'dark_mode_active': 'இருண்ட பயன்முறை செயலில் உள்ளது',
    'light_mode_active': 'வெளிச்ச பயன்முறை (சூரிய ஒளிக்கு ஏற்றது)',
    'farm_reminders': 'பண்ணை நினைவூட்டல்கள்',
    'farm_reminders_desc': 'தெளித்தல் & நீர்ப்பாசன பணிகளுக்கான அறிவிப்புகள்',
    'about_tech': 'பயிர் பார்வை AI தொழில்நுட்பம் பற்றி',
    'tech_title': 'மொபைல்விட் ஆழமான கற்றல்',
    'tech_subtitle': 'ஹைப்ரிட் விஷன் டிரான்ஸ்ஃபார்மர் கட்டமைப்பு',
    'tech_desc': 'பயிர் பார்வை தக்காளி, உருளைக்கிழங்கு, சோளம், ஆப்பிள் மற்றும் திராட்சை இலைகளில் 38 தாவர வகைகளில் பயிற்றுவிக்கப்பட்ட மொபைல்விட் நியூரல் நெட்வொர்க்கைப் பயன்படுத்துகிறது.',
    'chip_classes': '38 தாவர வகுப்புகள்',
    'chip_severity': 'HSV தீவிர நிலை கணக்கீடு',
    'chip_remedies': 'ICAR தாவர மருத்துவ வழிகாட்டல்',
    'app_version': 'பயன்பாட்டு பதிப்பு',
    'sign_out': 'வெளியேறு',
    'sign_out_btn': 'பயிர் பார்வையிலிருந்து வெளியேறு',
    'lang_switched': '🌐 மொழி மாற்றப்பட்டது:',

    // Home Screen
    'season_badge': '🌾 ரபி பருவம் • களம் 4 செயலில்',
    'greeting_morning': 'காலை வணக்கம், விவசாயி 👋',
    'greeting_afternoon': 'மதிய வணக்கம், விவசாயி 👋',
    'greeting_evening': 'மாலை வணக்கம், விவசாயி 👋',
    'home_subtitle': 'உங்கள் பயிர்களை சரிபார்த்து இன்றைய பராமரிப்பை கவனியுங்கள்',
    'scan_title': 'இலையை ஸ்கேன் செய்யுங்கள்',
    'scan_subtitle': 'உடனடி AI நோய் கண்டறிதல்',
    'tap_to_open_camera': 'கேமராவை திறக்க தொடவும்',
    'today_tasks': 'இன்றைய பண்ணை பணிகள்',
    'view_calendar': 'நாட்காட்டி காண்க',
    'no_tasks_today': 'இன்றைய பணிகள் எதுவும் நிலுவையில் இல்லை 🎉',
    'all_crops_healthy': 'அனைத்து திட்டமிடப்பட்ட சிகிச்சைகளும் புதுப்பிக்கப்பட்டுள்ளன.',
    'track_crop_see_tasks': 'பணிகளைக் காண ஒரு பயிரை சேர்க்கவும்',
    'my_crops': 'என் கண்காணிக்கப்படும் பயிர்கள்',
    'track_crop': 'பயிர் சேர்க்கவும்',
    'no_crops_title': 'பயிர்கள் எதுவும் கண்காணிக்கப்படவில்லை',
    'no_crops_subtitle': 'படிப்படியான தெளிப்பு அட்டவணையைப் பெற பயிர்களை கண்காணிக்கவும்.',
    'track_first_crop': 'முதல் பயிரை சேர்க்கவும்',
    'recent_scans': 'சமீபத்திய இலை ஸ்கேன்கள்',
    'view_all': 'அனைத்தும் காண்க',
    'no_scans': 'இதுவரை ஸ்கேன் இல்லை',
    'no_scans_desc': 'இலைகளில் புள்ளிகள் தெரிகிறதா? இப்போதே ஸ்கேன் செய்யுங்கள்.',
    'scan_first': 'முதல் இலையை ஸ்கேன் செய்யுங்கள்',
    'ask_ai_doctor': 'AI மருத்துவரிடம் கேளுங்கள்',
    'plant_date': 'நட்ட தேதி',
    'stage': 'நிலை',
    'days_old': 'நாட்கள் ஆனது',

    // Calendar Screen
    'calendar': 'பயிர் நாட்காட்டி & நிலைகள்',
    'reminders': 'நினைவூட்டல்கள்',
    'tracked_crops': 'கண்காணிக்கப்படும் பயிர்கள்',
    'track_a_crop': 'பயிரை சேர்',
    'no_reminders': 'இந்த நாளில் நினைவூட்டல் இல்லை',
    'no_crops': 'இதுவரை பயிர் இல்லை',
    'add_reminder': 'நினைவூட்டல் சேர்க்க',

    // Assistant & History
    'assistant': 'AI விவசாய உதவியாளர்',
    'history': 'ஸ்கேன் வரலாறு',
    'history_title': 'பண்ணை நோய் கண்டறிதல் வரலாறு',
    'no_diagnoses_title': 'நோய் கண்டறிதல்கள் எதுவும் இல்லை',
    'no_diagnoses_desc': 'பாதிக்கப்பட்ட இலையைப் படம் பிடித்து ICAR சிகிச்சைகளைப் பெறுங்கள்.',
    'healthy': 'ஆரோக்கியமான',
    'diseased': 'நோயுள்ள',
    'severity': 'தீவிரம்',
    'treatment': 'சிகிச்சை',
    'capture': 'இலையை படம் எடு',
    'retake': 'மீண்டும் எடு',
    'analyze': 'இலை பகுப்பாய்வு',
  },
  'hi': {
    // Nav & Common
    'app_name': 'क्रॉपविज़न',
    'nav_home': 'होम',
    'nav_calendar': 'कैलेंडर',
    'nav_capture': 'स्कैन',
    'nav_history': 'इतिहास',
    'nav_assistant': 'सहायक',
    'cancel': 'रद्द करें',
    'save': 'सहेजें',
    'track': 'ट्रैक करें',
    'delete': 'हटाएं',
    'error': 'त्रुटि',
    'loading': 'लोड हो रहा है...',

    // Settings Screen
    'settings': 'खेत सेटिंग्स और प्रोफ़ाइल',
    'farmer_profile': 'किसान प्रोफ़ाइल',
    'farmer_account': 'किसान खाता',
    'sector_farmer': '🌱 सेक्टर 4 सक्रिय किसान',
    'language_region': 'भाषा और क्षेत्र',
    'app_language': 'ऐप भाषा',
    'preferences': 'प्राथमिकताएं',
    'dark_mode': 'डार्क मोड',
    'dark_mode_active': 'डार्क थीम सक्रिय',
    'light_mode_active': 'लाइट थीम (धूप के लिए अनुशंसित)',
    'farm_reminders': 'खेत अनुस्मारक',
    'farm_reminders_desc': 'छिड़काव और सिंचाई कार्यों के लिए अलर्ट प्राप्त करें',
    'about_tech': 'क्रॉपविज़न AI तकनीक के बारे में',
    'tech_title': 'मोबाइलविट डीप लर्निंग',
    'tech_subtitle': 'हाइब्रिड विज़न ट्रांसफार्मर आर्किटेक्चर',
    'tech_desc': 'क्रॉपविज़न 38 वनस्पति वर्गों पर प्रशिक्षित एक हल्के मोबाइलविट न्यूरल नेटवर्क का उपयोग करता है।',
    'chip_classes': '38 पौधे वर्ग',
    'chip_severity': 'HSV गंभीरता गणना',
    'chip_remedies': 'ICAR वनस्पति उपचार',
    'app_version': 'ऐप संस्करण',
    'sign_out': 'साइन आउट',
    'sign_out_btn': 'क्रॉपविज़न से साइन आउट करें',
    'lang_switched': '🌐 भाषा बदली गई:',

    // Home Screen
    'season_badge': '🌾 रबी मौसम • खेत 4 सक्रिय',
    'greeting_morning': 'सुप्रभात, किसान 👋',
    'greeting_afternoon': 'नमस्ते, किसान 👋',
    'greeting_evening': 'शुभ संध्या, किसान 👋',
    'home_subtitle': 'अपनी फसलें जांचें और आज की खेत देखभाल देखें',
    'scan_title': 'फसल की पत्ती स्कैन करें',
    'scan_subtitle': 'तुरंत AI रोग पहचान',
    'tap_to_open_camera': 'कैमरा खोलने के लिए टैप करें',
    'today_tasks': 'आज के खेत के काम',
    'view_calendar': 'कैलेंडर देखें',
    'no_tasks_today': 'आज के लिए कोई लंबित कार्य नहीं 🎉',
    'all_crops_healthy': 'सभी निर्धारित उपचार अद्यतित हैं।',
    'track_crop_see_tasks': 'कार्य देखने के लिए फसल जोड़ें',
    'my_crops': 'मेरी निगरानी की फसलें',
    'track_crop': 'फसल जोड़ें',
    'no_crops_title': 'कोई फसल अभी तक ट्रैक नहीं की गई',
    'no_crops_subtitle': 'चरण-दर-चरण छिड़काव कार्यक्रम के लिए फसलें ट्रैक करें।',
    'track_first_crop': 'पहली फसल जोड़ें',
    'recent_scans': 'हाल के पत्ती स्कैन',
    'view_all': 'सभी देखें',
    'no_scans': 'अभी तक कोई स्कैन नहीं',
    'no_scans_desc': 'पत्तियों पर कोई धब्बा दिखे? अभी स्कैन करें।',
    'scan_first': 'पहली पत्ती स्कैन करें',
    'ask_ai_doctor': 'AI डॉक्टर से पूछें',
    'plant_date': 'रोपण तिथि',
    'stage': 'चरण',
    'days_old': 'दिन हुए',

    // Calendar Screen
    'calendar': 'फसल कैलेंडर और चरण',
    'reminders': 'अनुस्मारक',
    'tracked_crops': 'ट्रैक की गई फसलें',
    'track_a_crop': 'फसल ट्रैक करें',
    'no_reminders': 'इस दिन कोई अनुस्मारक नहीं',
    'no_crops': 'अभी कोई फसल नहीं',
    'add_reminder': 'अनुस्मारक जोड़ें',

    // Assistant & History
    'assistant': 'AI कृषि सहायक',
    'history': 'स्कैन इतिहास',
    'history_title': 'रोग निदान इतिहास',
    'no_diagnoses_title': 'अभी तक कोई निदान सहेजा नहीं गया',
    'no_diagnoses_desc': 'रोगग्रस्त पत्ती की फोटो लें और ICAR उपचार प्राप्त करें।',
    'healthy': 'स्वस्थ',
    'diseased': 'रोगग्रस्त',
    'severity': 'गंभीरता',
    'treatment': 'उपचार',
    'capture': 'पत्ती कैप्चर करें',
    'retake': 'दोबारा लें',
    'analyze': 'पत्ती विश्लेषण करें',
  },
  'te': {
    // Nav & Common
    'app_name': 'క్రాప్ విజన్',
    'nav_home': 'హోమ్',
    'nav_calendar': 'క్యాలెండర్',
    'nav_capture': 'స్కాన్',
    'nav_history': 'చరిత్ర',
    'nav_assistant': 'సహాయకుడు',
    'cancel': 'రద్దు',
    'save': 'భద్రపరచు',
    'track': 'ట్రాక్ చేయండి',
    'delete': 'తొలగించు',
    'error': 'లోపం',
    'loading': 'లోడ్ అవుతోంది...',

    // Settings Screen
    'settings': 'పొలం సెట్టింగ్‌లు & ప్రొఫైల్',
    'farmer_profile': 'రైతు ప్రొఫైల్',
    'farmer_account': 'రైతు ఖాతా',
    'sector_farmer': '🌱 సెక్టార్ 4 క్రియాశీల రైతు',
    'language_region': 'భాష మరియు ప్రాంతం',
    'app_language': 'యాప్ భాష',
    'preferences': 'ప్రాధాన్యతలు',
    'dark_mode': 'డార్క్ మోడ్',
    'dark_mode_active': 'డార్క్ మోడ్ సక్రియంగా ఉంది',
    'light_mode_active': 'లైట్ మోడ్ (ఎండకు అనుకూలం)',
    'farm_reminders': 'పొలం రిమైండర్లు',
    'farm_reminders_desc': 'స్ప్రే మరియు నీటిపారుదల పనుల కోసం హెచ్చరికలు',
    'about_tech': 'క్రాప్‌విజన్ AI సాంకేతికత గురించి',
    'tech_title': 'మొబైల్ విట్ డీప్ లెర్నింగ్',
    'tech_subtitle': 'హైబ్రిడ్ విజన్ ట్రాన్స్‌ఫార్మర్ ఆర్కిటెక్చర్',
    'tech_desc': 'క్రాప్‌విజన్ 38 రకాల మొక్కల వ్యాధులను గుర్తించడానికి మొబైల్ విట్ నెట్‌వర్క్‌ను ఉపయోగిస్తుంది.',
    'chip_classes': '38 మొక్కల రకాలు',
    'chip_severity': 'HSV తీవ్రత లెక్కింపు',
    'chip_remedies': 'ICAR నివారణలు',
    'app_version': 'యాప్ వెర్షన్',
    'sign_out': 'సైన్ అవుట్',
    'sign_out_btn': 'క్రాప్‌విజన్ నుండి సైన్ అవుట్ చేయండి',
    'lang_switched': '🌐 భాష మార్చబడింది:',

    // Home Screen
    'season_badge': '🌾 రబీ సీజన్ • ఫీల్డ్ 4 క్రియాశీలం',
    'greeting_morning': 'శుభోదయం, రైతు 👋',
    'greeting_afternoon': 'శుభ మధ్యాహ్నం, రైతు 👋',
    'greeting_evening': 'శుభ సాయంత్రం, రైతు 👋',
    'home_subtitle': 'మీ పంటలను తనిఖీ చేసి నేటి సంరక్షణను చూడండి',
    'scan_title': 'ఆకును స్కాన్ చేయండి',
    'scan_subtitle': 'తక్షణ AI వ్యాధి గుర్తింపు',
    'tap_to_open_camera': 'కెమెరా తెరవడానికి తాకండి',
    'today_tasks': 'నేటి పొలం పనులు',
    'view_calendar': 'క్యాలెండర్ చూడండి',
    'no_tasks_today': 'నేటికి పనులేమీ లేవు 🎉',
    'all_crops_healthy': 'అన్ని పనులు పూర్తయ్యాయి.',
    'track_crop_see_tasks': 'పనులను చూడటానికి పంటను జోడించండి',
    'my_crops': 'నా పర్యవేక్షించే పంటలు',
    'track_crop': 'పంట జోడించండి',
    'no_crops_title': 'ఇంకా పంటలేమీ జోడించలేదు',
    'no_crops_subtitle': 'దశలవారీ స్ప్రే షెడ్యూల్ కోసం పంటలను ట్రాక్ చేయండి.',
    'track_first_crop': 'మొదటి పంటను జోడించండి',
    'recent_scans': 'ఇటీవలి ఆకు స్కాన్లు',
    'view_all': 'అన్నీ చూడండి',
    'no_scans': 'ఇంకా స్కాన్లు లేవు',
    'no_scans_desc': 'ఆకులపై మచ్చలు కనిపిస్తున్నాయా? ఇప్పుడే స్కాన్ చేయండి.',
    'scan_first': 'మొదటి ఆకు స్కాన్ చేయండి',
    'ask_ai_doctor': 'AI డాక్టర్‌ని అడగండి',
    'plant_date': 'నాటిన తేదీ',
    'stage': 'దశ',
    'days_old': 'రోజులు అయ్యాయి',

    // Calendar Screen
    'calendar': 'పంట క్యాలెండర్ & దశలు',
    'reminders': 'రిమైండర్లు',
    'tracked_crops': 'ట్రాక్ చేసిన పంటలు',
    'track_a_crop': 'పంటను ట్రాక్ చేయండి',
    'no_reminders': 'ఈ రోజు రిమైండర్లు లేవు',
    'no_crops': 'ఇంకా పంటలు లేవు',
    'add_reminder': 'రిమైండర్ జోడించండి',

    // Assistant & History
    'assistant': 'AI వ్యవసాయ సహాయకుడు',
    'history': 'స్కాన్ చరిత్ర',
    'history_title': 'రోగ నిర్ధారణ చరిత్ర',
    'no_diagnoses_title': 'ఇంకా నిర్ధారణలు లేవు',
    'no_diagnoses_desc': 'వ్యాధిగ్రస్త ఆకును ఫోటో తీసి ICAR చికిత్సలను పొందండి.',
    'healthy': 'ఆరోగ్యకరమైన',
    'diseased': 'వ్యాధిగ్రస్తమైన',
    'severity': 'తీవ్రత',
    'treatment': 'చికిత్స',
    'capture': 'ఆకు తీయండి',
    'retake': 'మళ్ళీ తీయండి',
    'analyze': 'ఆకు విశ్లేషించండి',
  },
  'mr': {
    // Nav & Common
    'app_name': 'क्रॉपव्हिजन',
    'nav_home': 'होम',
    'nav_calendar': 'दिनदर्शिका',
    'nav_capture': 'स्कॅन',
    'nav_history': 'इतिहास',
    'nav_assistant': 'सहाय्यक',
    'cancel': 'रद्द करा',
    'save': 'जतन करा',
    'track': 'ट्रॅक करा',
    'delete': 'हटवा',
    'error': 'त्रुटी',
    'loading': 'लोड होत आहे...',

    // Settings Screen
    'settings': 'शेत सेटिंग्ज आणि प्रोफाइल',
    'farmer_profile': 'शेतकरी प्रोफाइल',
    'farmer_account': 'शेतकरी खाते',
    'sector_farmer': '🌱 सेक्टर 4 सक्रिय शेतकरी',
    'language_region': 'भाषा आणि प्रदेश',
    'app_language': 'अ‍ॅप भाषा',
    'preferences': 'प्राधान्ये',
    'dark_mode': 'गडद मोड',
    'dark_mode_active': 'गडद थीम सक्रिय',
    'light_mode_active': 'हलकी थीम (उन्हासाठी शिफारस केलेली)',
    'farm_reminders': 'शेत स्मरणपत्रे',
    'farm_reminders_desc': 'फवारणी व पाणी देण्याच्या कामांसाठी सूचना मिळवा',
    'about_tech': 'क्रॉपव्हिजन AI तंत्रज्ञानाबद्दल',
    'tech_title': 'मोबाइलविट डीप लर्निंग',
    'tech_subtitle': 'हायब्रिड व्हिजन ट्रान्सफॉर्मर आर्किटेक्चर',
    'tech_desc': 'क्रॉपव्हिजन 38 वनस्पती वर्गांवर प्रशिक्षित मोबाइलविट न्यूरल नेटवर्क वापरते.',
    'chip_classes': '38 वनस्पती वर्ग',
    'chip_severity': 'HSV तीव्रता मोजणी',
    'chip_remedies': 'ICAR वनस्पती उपाय',
    'app_version': 'अ‍ॅप आवृत्ती',
    'sign_out': 'साइन आउट',
    'sign_out_btn': 'क्रॉपव्हिजनमधून बाहेर पडा',
    'lang_switched': '🌐 भाषा बदलली:',

    // Home Screen
    'season_badge': '🌾 रब्बी हंगाम • शेत 4 सक्रिय',
    'greeting_morning': 'सुप्रभात, शेतकरी 👋',
    'greeting_afternoon': 'नमस्कार, शेतकरी 👋',
    'greeting_evening': 'शुभ संध्या, शेतकरी 👋',
    'home_subtitle': 'तुमची पिके तपासा आणि आजची शेत काळजी पहा',
    'scan_title': 'पान स्कॅन करा',
    'scan_subtitle': 'तात्काळ AI रोग ओळख',
    'tap_to_open_camera': 'कॅमेरा उघडण्यासाठी टॅप करा',
    'today_tasks': 'आजचे शेत कार्य',
    'view_calendar': 'दिनदर्शिका पहा',
    'no_tasks_today': 'आज कोणतेही प्रलंबित काम नाही 🎉',
    'all_crops_healthy': 'सर्व नियोजित उपचार पूर्ण झाले आहेत.',
    'track_crop_see_tasks': 'कामे पाहण्यासाठी पीक जोडा',
    'my_crops': 'माझी पिके',
    'track_crop': 'पीक जोडा',
    'no_crops_title': 'अद्याप पिके ट्रॅक केलेली नाहीत',
    'no_crops_subtitle': 'टप्प्याटप्प्याने फवारणी वेळापत्रक मिळवण्यासाठी पिके जोडा.',
    'track_first_crop': 'पहिले पीक जोडा',
    'recent_scans': 'अलीकडील पान स्कॅन',
    'view_all': 'सर्व पहा',
    'no_scans': 'अद्याप स्कॅन नाही',
    'no_scans_desc': 'पानांवर डाग दिसतात? आत्ताच स्कॅन करा.',
    'scan_first': 'पहिले पान स्कॅन करा',
    'ask_ai_doctor': 'AI डॉक्टरांना विचारा',
    'plant_date': 'लागवड तारीख',
    'stage': 'टप्पा',
    'days_old': 'दिवस झाले',

    // Calendar Screen
    'calendar': 'पीक दिनदर्शिका आणि टप्पे',
    'reminders': 'स्मरणपत्रे',
    'tracked_crops': 'ट्रॅक केलेली पिके',
    'track_a_crop': 'पीक ट्रॅक करा',
    'no_reminders': 'या दिवशी स्मरणपत्रे नाहीत',
    'no_crops': 'अद्याप पिके नाहीत',
    'add_reminder': 'स्मरणपत्र जोडा',

    // Assistant & History
    'assistant': 'AI कृषी सहाय्यक',
    'history': 'स्कॅन इतिहास',
    'history_title': 'रोग निदान इतिहास',
    'no_diagnoses_title': 'अद्याप कोणतेही निदान जतन केलेले नाही',
    'no_diagnoses_desc': 'रोगग्रस्त पानाचा फोटो घ्या आणि ICAR उपचार मिळवा.',
    'healthy': 'निरोगी',
    'diseased': 'रोगग्रस्त',
    'severity': 'तीव्रता',
    'treatment': 'उपचार',
    'capture': 'पान कॅप्चर करा',
    'retake': 'पुन्हा घ्या',
    'analyze': 'पान विश्लेषण करा',
  },
  'kn': {
    // Nav & Common
    'app_name': 'ಕ್ರಾಪ್ ವಿಷನ್',
    'nav_home': 'ಮುಖಪುಟ',
    'nav_calendar': 'ಕ್ಯಾಲೆಂಡರ್',
    'nav_capture': 'ಸ್ಕ್ಯಾನ್',
    'nav_history': 'ಇತಿಹಾಸ',
    'nav_assistant': 'ಸಹಾಯಕ',
    'cancel': 'ರದ್ದುಮಾಡಿ',
    'save': 'ಉಳಿಸಿ',
    'track': 'ಟ್ರ್ಯಾಕ್ ಮಾಡಿ',
    'delete': 'ಅಳಿಸಿ',
    'error': 'ದೋಷ',
    'loading': 'ಲೋಡ್ ಆಗುತ್ತಿದೆ...',

    // Settings Screen
    'settings': 'ಹೊಲದ ಸೆಟ್ಟಿಂಗ್ ಮತ್ತು ಪ್ರೊಫೈಲ್',
    'farmer_profile': 'ರೈತ ಪ್ರೊಫೈಲ್',
    'farmer_account': 'ರೈತ ಖಾತೆ',
    'sector_farmer': '🌱 ಸೆಕ್ಟರ್ 4 ಸಕ್ರಿಯ ರೈತ',
    'language_region': 'ಭಾಷೆ ಮತ್ತು ಪ್ರದೇಶ',
    'app_language': 'ಅಪ್ಲಿಕೇಶನ್ ಭಾಷೆ',
    'preferences': 'ಆದ್ಯತೆಗಳು',
    'dark_mode': 'ಡಾರ್ಕ್ ಮೋಡ್',
    'dark_mode_active': 'ಡಾರ್ಕ್ ಮೋಡ್ ಸಕ್ರಿಯವಾಗಿದೆ',
    'light_mode_active': 'ಲೈಟ್ ಮೋಡ್ (ಬಿಸಿಲಿಗೆ ಸೂಕ್ತ)',
    'farm_reminders': 'ಹೊಲದ ಜ್ಞಾಪನೆಗಳು',
    'farm_reminders_desc': 'ಸಿಂಪರಣೆ ಮತ್ತು ನೀರಾವರಿ ಕೆಲಸಗಳಿಗೆ ಎಚ್ಚರಿಕೆಗಳನ್ನು ಪಡೆಯಿರಿ',
    'about_tech': 'ಕ್ರಾಪ್ ವಿಷನ್ AI ತಂತ್ರಜ್ಞಾನದ ಬಗ್ಗೆ',
    'tech_title': 'ಮೊಬೈಲ್ ವಿಟ್ ಡೀಪ್ ಲರ್ನಿಂಗ್',
    'tech_subtitle': 'ಹೈಬ್ರಿಡ್ ವಿಷನ್ ಟ್ರಾನ್ಸ್‌ಫಾರ್ಮರ್ ವಾಸ್ತುಶಿಲ್ಪ',
    'tech_desc': 'ಕ್ರಾಪ್ ವಿಷನ್ 38 ಸಸ್ಯ ವರ್ಗಗಳಲ್ಲಿ ರೋಗ ಪತ್ತೆಹಚ್ಚಲು ಮೊಬೈಲ್ ವಿಟ್ ನೆಟ್‌ವರ್ಕ್ ಬಳಸುತ್ತದೆ.',
    'chip_classes': '38 ಸಸ್ಯ ವರ್ಗಗಳು',
    'chip_severity': 'HSV ತೀವ್ರತೆ ಹಂತ',
    'chip_remedies': 'ICAR ಸಸ್ಯ ಪರಿಹಾರಗಳು',
    'app_version': 'ಅಪ್ ಆವೃತ್ತಿ',
    'sign_out': 'ಸೈನ್ ಔಟ್',
    'sign_out_btn': 'ಕ್ರಾಪ್ ವಿಷನ್‌ನಿಂದ ನಿರ್ಗಮಿಸಿ',
    'lang_switched': '🌐 ಭಾಷೆ ಬದಲಾಯಿಸಲಾಗಿದೆ:',

    // Home Screen
    'season_badge': '🌾 ರಬಿ ಋತು • ಕ್ಷೇತ್ರ 4 ಸಕ್ರಿಯ',
    'greeting_morning': 'ಶುಭೋದಯ, ರೈತ 👋',
    'greeting_afternoon': 'ಶುಭ ಮಧ್ಯಾಹ್ನ, ರೈತ 👋',
    'greeting_evening': 'ಶುಭ ಸಂಜೆ, ರೈತ 👋',
    'home_subtitle': 'ನಿಮ್ಮ ಬೆಳೆಗಳನ್ನು ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಇಂದಿನ ಆರೈಕೆ ನೋಡಿ',
    'scan_title': 'ಎಲೆ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
    'scan_subtitle': 'ತಕ್ಷಣ AI ರೋಗ ಪತ್ತೆ',
    'tap_to_open_camera': 'ಕ್ಯಾಮೆರಾ ತೆರೆಯಲು ಸ್ಪರ್ಶಿಸಿ',
    'today_tasks': 'ಇಂದಿನ ಹೊಲದ ಕೆಲಸ',
    'view_calendar': 'ಕ್ಯಾಲೆಂಡರ್ ನೋಡಿ',
    'no_tasks_today': 'ಇಂದು ಯಾವುದೇ ಬಾಕಿ ಕೆಲಸಗಳಿಲ್ಲ 🎉',
    'all_crops_healthy': 'ಎಲ್ಲಾ ನಿಗದಿತ ಚಿಕಿತ್ಸೆಗಳು ಪೂರ್ಣಗೊಂಡಿವೆ.',
    'track_crop_see_tasks': 'ಕೆಲಸಗಳನ್ನು ನೋಡಲು ಬೆಳೆ ಸೇರಿಸಿ',
    'my_crops': 'ನನ್ನ ಬೆಳೆಗಳು',
    'track_crop': 'ಬೆಳೆ ಸೇರಿಸಿ',
    'no_crops_title': 'ಇನ್ನೂ ಯಾವುದೇ ಬೆಳೆಗಳಿಲ್ಲ',
    'no_crops_subtitle': 'ಹಂತ ಹಂತದ ಸಿಂಪರಣೆ ವೇಳಾಪಟ್ಟಿಗಾಗಿ ಬೆಳೆಗಳನ್ನು ಟ್ರ್ಯಾಕ್ ಮಾಡಿ.',
    'track_first_crop': 'ಮೊದಲ ಬೆಳೆಯನ್ನು ಸೇರಿಸಿ',
    'recent_scans': 'ಇತ್ತೀಚಿನ ಎಲೆ ಸ್ಕ್ಯಾನ್',
    'view_all': 'ಎಲ್ಲ ನೋಡಿ',
    'no_scans': 'ಇನ್ನೂ ಸ್ಕ್ಯಾನ್ ಇಲ್ಲ',
    'no_scans_desc': 'ಎಲೆಗಳ ಮೇಲೆ ಚುಕ್ಕೆ ಕಂಡರೆ? ಈಗಲೇ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ.',
    'scan_first': 'ಮೊದಲ ಎಲೆ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
    'ask_ai_doctor': 'AI ವೈದ್ಯರನ್ನು ಕೇಳಿ',
    'plant_date': 'ನಾಟಿ ದಿನಾಂಕ',
    'stage': 'ಹಂತ',
    'days_old': 'ದಿನಗಳು ಕಳೆದಿವೆ',

    // Calendar Screen
    'calendar': 'ಬೆಳೆ ಕ್ಯಾಲೆಂಡರ್ ಮತ್ತು ಹಂತಗಳು',
    'reminders': 'ಜ್ಞಾಪಕ ಪತ್ರಗಳು',
    'tracked_crops': 'ಟ್ರ್ಯಾಕ್ ಮಾಡಿದ ಬೆಳೆಗಳು',
    'track_a_crop': 'ಬೆಳೆ ಟ್ರ್ಯಾಕ್ ಮಾಡಿ',
    'no_reminders': 'ಈ ದಿನ ಜ್ಞಾಪಕ ಇಲ್ಲ',
    'no_crops': 'ಇನ್ನೂ ಬೆಳೆಗಳಿಲ್ಲ',
    'add_reminder': 'ಜ್ಞಾಪನೆ ಸೇರಿಸಿ',

    // Assistant & History
    'assistant': 'AI ಕೃಷಿ ಸಹಾಯಕ',
    'history': 'ಸ್ಕ್ಯಾನ್ ಇತಿಹಾಸ',
    'history_title': 'ರೋಗ ಪತ್ತೆ ಇತಿಹಾಸ',
    'no_diagnoses_title': 'ಇನ್ನೂ ಯಾವುದೇ ರೋಗ ಪತ್ತೆಗಳಿಲ್ಲ',
    'no_diagnoses_desc': 'ರೋಗಪೀಡಿತ ಎಲೆಯ ಫೋಟೋ ತೆಗೆದು ICAR ಚಿಕಿತ್ಸೆಗಳನ್ನು ಪಡೆಯಿರಿ.',
    'healthy': 'ಆರೋಗ್ಯಕರ',
    'diseased': 'ರೋಗಪೀಡಿತ',
    'severity': 'ತೀವ್ರತೆ',
    'treatment': 'ಚಿಕಿತ್ಸೆ',
    'capture': 'ಎಲೆ ತೆಗೆಯಿರಿ',
    'retake': 'ಮತ್ತೆ ತೆಗೆಯಿರಿ',
    'analyze': 'ಎಲೆ ವಿಶ್ಲೇಷಿಸಿ',
  },
};

/// Gets a translated string for the given key and locale code.
/// Falls back to English if key not found.
String t(String langCode, String key) {
  return kAppStrings[langCode]?[key] ?? kAppStrings['en']![key] ?? key;
}

class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'app_language_name';
  Locale _locale = const Locale('en');
  String _languageName = 'English';

  LocaleProvider() {
    _loadSavedLocale();
  }

  Locale get locale => _locale;
  String get languageName => _languageName;
  String get langCode => _locale.languageCode;

  /// Returns a translated string using this provider's current locale
  String tr(String key) => t(langCode, key);

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_prefKey);
      if (savedLang != null && kSupportedLocales.containsKey(savedLang)) {
        _languageName = savedLang;
        _locale = kSupportedLocales[savedLang]!;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String languageName) async {
    final locale = kSupportedLocales[languageName];
    if (locale != null && locale != _locale) {
      _locale = locale;
      _languageName = languageName;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, languageName);
      } catch (_) {}
    }
  }
}

/// Handy extension so any widget can do `context.tr('key')`
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    try {
      final provider = Provider.of<LocaleProvider>(this, listen: true);
      return provider.tr(key);
    } catch (_) {
      return kAppStrings['en']?[key] ?? key;
    }
  }
}
