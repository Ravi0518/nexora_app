import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _key = 'user_lang';

  // ------------------------------------------------------------------
  // All translations for every screen in the app
  // Keys: English | සිංහල | தமிழ்
  // ------------------------------------------------------------------
  static Map<String, Map<String, String>> translations = {
    'English': {
      // ---- COMMON ----
      'app_name': 'Nexora',
      'continue_btn': 'Continue',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'loading': 'Loading...',
      'error_network': 'Network error. Please try again.',
      'error_server': 'Server error. Please try again.',

      // ---- LANGUAGE SCREEN ----
      'choose_lang': 'Choose Language',
      'choose_lang_sub': 'Select your preferred language to continue',
      'lang_change_hint': 'You can change this anytime in settings',

      // ---- LOGIN SCREEN ----
      'welcome_back': 'Welcome Back',
      'login_subtitle': 'Log in to continue your adventure.',
      'email': 'Email',
      'email_hint': 'Enter your email',
      'password': 'Password',
      'password_hint': 'Enter your password',
      'forgot_password': 'Forgot Password?',
      'login_btn': 'Login',
      'no_account': "Don't have an account? ",
      'sign_up': 'Sign Up',
      'fill_all_fields': 'Please fill in all fields',
      'login_failed': 'Login Failed',

      // ---- SIGNUP SCREEN ----
      'create_account': 'Create Account',
      'signup_subtitle': 'Verify your email to join Nexora.',
      'i_am_a': 'I am a...',
      'general_public': 'General Public',
      'snake_enthusiast': 'Snake Enthusiast',
      'full_name': 'Full Name',
      'name_hint': 'Enter your name',
      'name_required': 'Name is required',
      'email_invalid': 'Invalid email',
      'pass_min': 'Min. 8 characters',
      'pass_short': 'Password too short',
      'get_code': 'Get Verification Code',
      'already_account': 'Already have an account? ',
      'log_in': 'Log In',

      // ---- FORGOT PASSWORD SCREEN ----
      'reset_password': 'Reset Password',
      'reset_subtitle':
          "Enter your email and we'll send instructions to reset your password.",
      'email_address': 'Email Address',
      'send_instructions': 'Send Instructions',
      'reset_sent': 'Password reset link sent to your email!',
      'reset_not_found': 'Email address not found.',

      // ---- OTP SCREEN ----
      'verify_email': 'Verify Email',
      'otp_subtitle': 'Enter the 6-digit code sent to your email.',
      'enter_otp': 'Enter OTP',
      'verify_btn': 'Verify & Create Account',

      // ---- HOME SCREEN ----
      'welcome': 'Welcome back,',
      'quick_id': 'Quick Identify',
      'point_cam': 'Point camera at snake',
      'recent': 'Recent Activity',
      'emergency': 'EMERGENCY: Call Helpline',
      'request_help': 'Request Assistance',
      'no_recent': 'No recent sightings.',
      'home': 'Home',
      'identify': 'Identify',
      'collection': 'Collection',
      'profile': 'Profile',

      // ---- SCAN SCREEN ----
      'photo': 'PHOTO',
      'detecting': 'Detecting Species...',
      'api_error': 'API connection error. Try again.',

      // ---- COLLECTION SCREEN ----
      'my_collection': 'My Collection',
      'snakes_identified': 'snakes identified',
      'no_collection':
          'No snakes in your collection yet.\nUse the Identify tab to start!',
      'search_hint': 'Search collection...',
      'venomous': 'Venomous',
      'non_venomous': 'Non-Venomous',

      // ---- PROFILE SCREEN ----
      'my_profile': 'My Profile',
      'phone_number': 'Phone Number',
      'language_pref': 'Language',
      'logout': 'Logout',
      'delete_account': 'Delete Account',
      'profile_updated': 'Profile Updated',
      'are_you_sure': 'Are you sure?',
      'delete_confirm': 'This will permanently delete your account.',
      'name_empty': 'Name cannot be empty',
      'update_failed': 'Update failed. Please try again.',
    },
    'සිංහල': {
      // ---- COMMON ----
      'app_name': 'නෙක්සෝරා',
      'continue_btn': 'ඉදිරියට',
      'cancel': 'අවලංගු',
      'save': 'සුරකින්න',
      'delete': 'මකන්න',
      'loading': 'පූරණය වෙමින්...',
      'error_network': 'ජාල දෝෂය. නැවත උත්සාහ කරන්න.',
      'error_server': 'සේවාදායක දෝෂය. නැවත උත්සාහ කරන්න.',

      // ---- LANGUAGE SCREEN ----
      'choose_lang': 'භාෂාව තෝරන්න',
      'choose_lang_sub': 'ඔබේ කැමති භාෂාව තෝරන්න',
      'lang_change_hint': 'ඔබට ඕනෑම වේලාවක සැකසීම් වෙනස් කළ හැකිය',

      // ---- LOGIN SCREEN ----
      'welcome_back': 'ආයුබෝවන්',
      'login_subtitle': 'ඔබේ ගිණුමට පිවිසෙන්න.',
      'email': 'විද්‍යුත් තැපෑල',
      'email_hint': 'ඔබේ විද්‍යුත් තැපෑල ඇතුළු කරන්න',
      'password': 'මුරපදය',
      'password_hint': 'ඔබේ මුරපදය ඇතුළු කරන්න',
      'forgot_password': 'මුරපදය අමතකද?',
      'login_btn': 'පිවිසෙන්න',
      'no_account': 'ගිණුමක් නැද්ද? ',
      'sign_up': 'ලියාපදිංචි වන්න',
      'fill_all_fields': 'කරුණාකර සියලු ක්ෂේත්‍ර පුරවන්න',
      'login_failed': 'පිවිසීම අසාර්ථකයි',

      // ---- SIGNUP SCREEN ----
      'create_account': 'ගිණුම සාදන්න',
      'signup_subtitle':
          'නෙක්සෝරාවට සම්බන්ධ වීමට ඔබේ විද්‍යුත් තැපෑල තහවුරු කරන්න.',
      'i_am_a': 'මම...',
      'general_public': 'සාමාන්‍ය ජනතාව',
      'snake_enthusiast': 'සර්ප ශ්‍රේෂ්ඨ',
      'full_name': 'සම්පූර්ණ නම',
      'name_hint': 'ඔබේ නම ඇතුළු කරන්න',
      'name_required': 'නම අවශ්‍යයි',
      'email_invalid': 'වලංගු නොවන විද්‍යුත් තැපෑල',
      'pass_min': 'අවම. අකුරු 8ක්',
      'pass_short': 'මුරපදය ඉතා කෙටියි',
      'get_code': 'තහවුරු කේතය ලබාගන්න',
      'already_account': 'දැනටමත් ගිණුමක් තිබේද? ',
      'log_in': 'පිවිසෙන්න',

      // ---- FORGOT PASSWORD SCREEN ----
      'reset_password': 'මුරපදය යළි සකසන්න',
      'reset_subtitle': 'ඔබේ ගිණුමට සම්බන්ධ විද්‍යුත් තැපෑල ඇතුළු කරන්න.',
      'email_address': 'විද්‍යුත් තැපෑල ලිපිනය',
      'send_instructions': 'උපදෙස් යවන්න',
      'reset_sent': 'මුරපද යළි සැකසීමේ සබැඳිය ඔබේ විද්‍යුත් තැපෑලට යවන ලදී!',
      'reset_not_found': 'විද්‍යුත් තැපෑල ලිපිනය හමු නොවීය.',

      // ---- OTP SCREEN ----
      'verify_email': 'විද්‍යුත් තැපෑල තහවුරු කරන්න',
      'otp_subtitle': 'ඔබේ විද්‍යුත් තැපෑලට ලැබුණු ඉලක්කම් 6 කේතය ඇතුළු කරන්න.',
      'enter_otp': 'OTP ඇතුළු කරන්න',
      'verify_btn': 'තහවුරු කරන්න & ගිණුම සාදන්න',

      // ---- HOME SCREEN ----
      'welcome': 'ආයුබෝවන්,',
      'quick_id': 'සර්පයා හඳුනාගන්න',
      'point_cam': 'කැමරාව සර්පයා දෙසට යොමු කරන්න',
      'recent': 'මෑතකදී බැලූ සර්පයන්',
      'emergency': 'හදිසි ඇමතුම: 1990',
      'request_help': 'සහාය ලබාගන්න',
      'no_recent': 'මෑත දකිමි නැත.',
      'home': 'මුල් පිටුව',
      'identify': 'හඳුනාගන්න',
      'collection': 'එකතුව',
      'profile': 'පැතිකඩ',

      // ---- SCAN SCREEN ----
      'photo': 'ඡායාරූපය',
      'detecting': 'විශේෂය හඳුනාගනිමින්...',
      'api_error': 'සම්බන්ධතාවය අසාර්ථකයි. නැවත උත්සාහ කරන්න.',

      // ---- COLLECTION SCREEN ----
      'my_collection': 'මගේ එකතුව',
      'snakes_identified': 'සර්පයන් හඳුනාගත්',
      'no_collection':
          'ඔබේ එකතුවේ සර්පයන් නැත.\nහඳුනාගැනීමේ ටැබ් භාවිතා කරන්න!',
      'search_hint': 'එකතුව සොයන්න...',
      'venomous': 'විෂ සහිත',
      'non_venomous': 'විෂ රහිත',

      // ---- PROFILE SCREEN ----
      'my_profile': 'මගේ පැතිකඩ',
      'phone_number': 'දුරකථන අංකය',
      'language_pref': 'භාෂාව',
      'logout': 'පද්ධතියෙන් ඉවත් වන්න',
      'delete_account': 'ගිණුම මකා දමන්න',
      'profile_updated': 'පැතිකඩ යාවත්කාලීන කරන ලදී',
      'are_you_sure': 'ඔබට විශ්වාසද?',
      'delete_confirm': 'මෙයින් ඔබේ ගිණුම ස්ථිරවම මැකී යනු ඇත.',
      'name_empty': 'නම හිස් විය නොහැක',
      'update_failed': 'යාවත්කාලීන කිරීම අසාර්ථකයි. නැවත උත්සාහ කරන්න.',
    },
    'தமிழ்': {
      // ---- COMMON ----
      'app_name': 'நெக்ஸோரா',
      'continue_btn': 'தொடர்க',
      'cancel': 'ரத்து செய்',
      'save': 'சேமி',
      'delete': 'நீக்கு',
      'loading': 'ஏற்றுகிறது...',
      'error_network': 'நெட்வொர்க் பிழை. மீண்டும் முயற்சி செய்யுங்கள்.',
      'error_server': 'சர்வர் பிழை. மீண்டும் முயற்சி செய்யுங்கள்.',

      // ---- LANGUAGE SCREEN ----
      'choose_lang': 'மொழியை தேர்ந்தெடுங்கள்',
      'choose_lang_sub': 'தொடர உங்கள் விருப்பமான மொழியை தேர்ந்தெடுக்கவும்',
      'lang_change_hint': 'அமைப்புகளில் இதை எப்போது வேண்டுமானாலும் மாற்றலாம்',

      // ---- LOGIN SCREEN ----
      'welcome_back': 'மீண்டும் வரவேற்கிறோம்',
      'login_subtitle': 'உங்கள் கணக்கில் உள்நுழையவும்.',
      'email': 'மின்னஞ்சல்',
      'email_hint': 'உங்கள் மின்னஞ்சலை உள்ளிடுங்கள்',
      'password': 'கடவுச்சொல்',
      'password_hint': 'உங்கள் கடவுச்சொல்லை உள்ளிடுங்கள்',
      'forgot_password': 'கடவுச்சொல் மறந்துவிட்டீர்களா?',
      'login_btn': 'உள்நுழைக',
      'no_account': 'கணக்கு இல்லையா? ',
      'sign_up': 'பதிவு செய்யுங்கள்',
      'fill_all_fields': 'அனைத்து புலங்களையும் நிரப்பவும்',
      'login_failed': 'உள்நுழைவு தோல்வியடைந்தது',

      // ---- SIGNUP SCREEN ----
      'create_account': 'கணக்கை உருவாக்கு',
      'signup_subtitle': 'நெக்ஸோராவில் சேர உங்கள் மின்னஞ்சலை சரிபாருங்கள்.',
      'i_am_a': 'நான்...',
      'general_public': 'பொது மக்கள்',
      'snake_enthusiast': 'பாம்பு ஆர்வலர்',
      'full_name': 'முழு பெயர்',
      'name_hint': 'உங்கள் பெயரை உள்ளிடுங்கள்',
      'name_required': 'பெயர் தேவை',
      'email_invalid': 'தவறான மின்னஞ்சல்',
      'pass_min': 'குறைந்தது 8 எழுத்துக்கள்',
      'pass_short': 'கடவுச்சொல் மிகவும் குறைவாக உள்ளது',
      'get_code': 'சரிபார்ப்பு குறியீட்டைப் பெறுங்கள்',
      'already_account': 'ஏற்கனவே கணக்கு உள்ளதா? ',
      'log_in': 'உள்நுழைக',

      // ---- FORGOT PASSWORD SCREEN ----
      'reset_password': 'கடவுச்சொல்லை மீட்டமை',
      'reset_subtitle': 'உங்கள் கணக்குடன் தொடர்புடைய மின்னஞ்சலை உள்ளிடுங்கள்.',
      'email_address': 'மின்னஞ்சல் முகவரி',
      'send_instructions': 'வழிமுறைகளை அனுப்பு',
      'reset_sent':
          'கடவுச்சொல் மீட்டமைப்பு இணைப்பு உங்கள் மின்னஞ்சலுக்கு அனுப்பப்பட்டது!',
      'reset_not_found': 'மின்னஞ்சல் முகவரி கண்டுபிடிக்கப்படவில்லை.',

      // ---- OTP SCREEN ----
      'verify_email': 'மின்னஞ்சலை சரிபாருங்கள்',
      'otp_subtitle':
          'உங்கள் மின்னஞ்சலுக்கு அனுப்பப்பட்ட 6 இலக்க குறியீட்டை உள்ளிடுங்கள்.',
      'enter_otp': 'OTP உள்ளிடுங்கள்',
      'verify_btn': 'சரிபாரிக்கவும் & கணக்கை உருவாக்கவும்',

      // ---- HOME SCREEN ----
      'welcome': 'வரவேற்கிறோம்,',
      'quick_id': 'அடையாளம் காணுங்கள்',
      'point_cam': 'பாம்பின் மீது கேமராவைக் காட்டவும்',
      'recent': 'சமீபத்திய செயல்பாடு',
      'emergency': 'அவசரகாலம்: 1990',
      'request_help': 'உதவி கோருங்கள்',
      'no_recent': 'சமீபத்திய பார்வைகள் இல்லை.',
      'home': 'முகப்பு',
      'identify': 'அடையாளம் காண',
      'collection': 'தொகுப்பு',
      'profile': 'சுயவிவரம்',

      // ---- SCAN SCREEN ----
      'photo': 'படம்',
      'detecting': 'இனங்களைக் கண்டறிதல்...',
      'api_error': 'இணைப்பு தோல்வியடைந்தது. மீண்டும் முயற்சி செய்யுங்கள்.',

      // ---- COLLECTION SCREEN ----
      'my_collection': 'என் தொகுப்பு',
      'snakes_identified': 'பாம்புகள் அடையாளம் காணப்பட்டன',
      'no_collection':
          'உங்கள் தொகுப்பில் பாம்புகள் இல்லை.\nஅடையாளம் காண தாவலை பயன்படுத்துங்கள்!',
      'search_hint': 'தொகுப்பில் தேடுங்கள்...',
      'venomous': 'விஷமுள்ள',
      'non_venomous': 'விஷமில்லாத',

      // ---- PROFILE SCREEN ----
      'my_profile': 'எனது சுயவிவரம்',
      'phone_number': 'தொலைபேசி எண்',
      'language_pref': 'மொழி',
      'logout': 'வெளியேறு',
      'delete_account': 'கணக்கை நீக்கு',
      'profile_updated': 'சுயவிவரம் புதுப்பிக்கப்பட்டது',
      'are_you_sure': 'நிச்சயமாகவா?',
      'delete_confirm': 'இது உங்கள் கணக்கை நிரந்தரமாக நீக்கிவிடும்.',
      'name_empty': 'பெயர் காலியாக இருக்க முடியாது',
      'update_failed':
          'புதுப்பிப்பு தோல்வியடைந்தது. மீண்டும் முயற்சி செய்யுங்கள்.',
    },
  };

  // ------------------------------------------------------------------
  // Helper: get a translated string for the given language
  // ------------------------------------------------------------------
  static String t(String lang, String key) {
    return translations[lang]?[key] ?? translations['English']![key] ?? key;
  }

  static Future<void> setLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang);
  }

  static Future<String> getLang() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'English';
  }
}
