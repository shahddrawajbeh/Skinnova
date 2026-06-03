import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Hand-written localization class — mirrors the API that flutter gen-l10n would produce.
// No code generation step required. Add strings here directly and rerun.

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // ── Access from context ───────────────────────────────────────────────────
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static AppLocalizations? maybeOf(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Convenience: put all delegates together for MaterialApp
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    _AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  bool get isArabic => locale.languageCode == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  // ── Translation lookup ────────────────────────────────────────────────────
  String _t(String key) {
    return (_translations[locale.languageCode] ?? _translations['en']!)[key] ??
        _translations['en']![key] ??
        key;
  }

  // ── Common ────────────────────────────────────────────────────────────────
  String get appName => _t('appName');
  String get loading => _t('loading');
  String get error => _t('error');
  String get retry => _t('retry');
  String get tryAgain => _t('tryAgain');
  String get save => _t('save');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get confirm => _t('confirm');
  String get yes => _t('yes');
  String get no => _t('no');
  String get ok => _t('ok');
  String get done => _t('done');
  String get close => _t('close');
  String get back => _t('back');
  String get next => _t('next');
  String get submit => _t('submit');
  String get send => _t('send');
  String get edit => _t('edit');
  String get remove => _t('remove');
  String get search => _t('search');
  String get noResults => _t('noResults');

  // ── Navigation ────────────────────────────────────────────────────────────
  String get home => _t('home');
  String get shop => _t('shop');
  String get posts => _t('posts');
  String get profile => _t('profile');
  String get products => _t('products');
  String get scan => _t('scan');
  String get routine => _t('routine');

  // ── Settings sections ─────────────────────────────────────────────────────
  String get settings => _t('settings');
  String get account => _t('account');
  String get skinova => _t('skinova');
  String get support => _t('support');
  String get accountActions => _t('accountActions');
  String get appearance => _t('appearance');
  String get language => _t('language');

  // ── Account ───────────────────────────────────────────────────────────────
  String get editProfile => _t('editProfile');
  String get editProfileSubtitle => _t('editProfileSubtitle');
  String get changePassword => _t('changePassword');
  String get changePasswordSubtitle => _t('changePasswordSubtitle');
  String get notifications => _t('notifications');
  String get notificationsSubtitle => _t('notificationsSubtitle');
  String get privacyPolicy => _t('privacyPolicy');
  String get privacyPolicySubtitle => _t('privacyPolicySubtitle');
  String get scanPrivacy => _t('scanPrivacy');
  String get scanPrivacySubtitle => _t('scanPrivacySubtitle');
  String get savedPosts => _t('savedPosts');
  String get savedPostsSubtitle => _t('savedPostsSubtitle');
  String get helpFaq => _t('helpFaq');
  String get helpFaqSubtitle => _t('helpFaqSubtitle');
  String get contactUs => _t('contactUs');
  String get contactUsSubtitle => _t('contactUsSubtitle');
  String get reportBug => _t('reportBug');
  String get reportBugSubtitle => _t('reportBugSubtitle');
  String get termsConditions => _t('termsConditions');
  String get aboutSkinova => _t('aboutSkinova');
  String get logOut => _t('logOut');
  String get logOutConfirmTitle => _t('logOutConfirmTitle');
  String get logOutConfirmMessage => _t('logOutConfirmMessage');
  String get deleteAccount => _t('deleteAccount');
  String get deleteAccountSubtitle => _t('deleteAccountSubtitle');
  String get deleteAccountTitle => _t('deleteAccountTitle');
  String get deleteAccountMessage => _t('deleteAccountMessage');
  String get version => _t('version');

  // ── Appearance ────────────────────────────────────────────────────────────
  String get lightMode => _t('lightMode');
  String get darkMode => _t('darkMode');
  String get systemDefault => _t('systemDefault');
  String get lightModeSubtitle => _t('lightModeSubtitle');
  String get darkModeSubtitle => _t('darkModeSubtitle');
  String get systemDefaultSubtitle => _t('systemDefaultSubtitle');

  // ── Language ──────────────────────────────────────────────────────────────
  String get english => _t('english');
  String get arabic => _t('arabic');
  String get englishSubtitle => _t('englishSubtitle');
  String get arabicSubtitle => _t('arabicSubtitle');

  // ── Shop / AI ─────────────────────────────────────────────────────────────
  String get askAI => _t('askAI');
  String get askAISubtitle => _t('askAISubtitle');
  String get tryBeforeBuy => _t('tryBeforeBuy');
  String get tryBeforeBuySubtitle => _t('tryBeforeBuySubtitle');
  String get myPreviews => _t('myPreviews');
  String get generatePreview => _t('generatePreview');
  String get selectProduct => _t('selectProduct');
  String get selectProductSubtitle => _t('selectProductSubtitle');
  String get choosePhoto => _t('choosePhoto');
  String get choosePhotoSubtitle => _t('choosePhotoSubtitle');
  String get useScanPhoto => _t('useScanPhoto');
  String get useScanPhotoSubtitle => _t('useScanPhotoSubtitle');
  String get uploadNewPhoto => _t('uploadNewPhoto');
  String get uploadNewPhotoSubtitle => _t('uploadNewPhotoSubtitle');
  String get noPreviewsYet => _t('noPreviewsYet');
  String get noPreviewsTitle => _t('noPreviewsTitle');
  String get suitabilityScore => _t('suitabilityScore');
  String get expectedEffects => _t('expectedEffects');
  String get warnings => _t('warnings');
  String get aiDisclaimer => _t('aiDisclaimer');
  String get greatMatch => _t('greatMatch');
  String get moderateMatch => _t('moderateMatch');
  String get useWithCaution => _t('useWithCaution');

  String get skinCoach => _t('skinCoach');
  String get productDetective => _t('productDetective');
  String get smartShopper => _t('smartShopper');
  String get skinCoachSubtitle => _t('skinCoachSubtitle');
  String get productDetectiveSubtitle => _t('productDetectiveSubtitle');
  String get smartShopperSubtitle => _t('smartShopperSubtitle');

  // ─────────────────────────────────────────────────────────────────────────
  // STRING TABLES
  // ─────────────────────────────────────────────────────────────────────────

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'appName': 'Skinova',
      'loading': 'Loading...',
      'error': 'Something went wrong',
      'retry': 'Retry',
      'tryAgain': 'Try Again',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'done': 'Done',
      'close': 'Close',
      'back': 'Back',
      'next': 'Next',
      'submit': 'Submit',
      'send': 'Send',
      'edit': 'Edit',
      'remove': 'Remove',
      'search': 'Search',
      'noResults': 'No results found',
      'home': 'Home',
      'shop': 'Shop',
      'posts': 'Posts',
      'profile': 'Profile',
      'products': 'Products',
      'scan': 'Scan',
      'routine': 'Routine',
      'settings': 'Settings',
      'account': 'Account',
      'skinova': 'Skinova',
      'support': 'Support',
      'accountActions': 'Account Actions',
      'appearance': 'Appearance',
      'language': 'Language',
      'editProfile': 'Edit Profile',
      'editProfileSubtitle': 'Update your name, bio, and photo',
      'changePassword': 'Change Password',
      'changePasswordSubtitle': 'Update your account password',
      'notifications': 'Notifications',
      'notificationsSubtitle': 'Manage your notification preferences',
      'privacyPolicy': 'Privacy Policy',
      'privacyPolicySubtitle': 'How we handle your data',
      'scanPrivacy': 'Scan Privacy',
      'scanPrivacySubtitle': 'Control how scan data is stored',
      'savedPosts': 'Saved Posts',
      'savedPostsSubtitle': "View posts you've bookmarked",
      'helpFaq': 'Help & FAQ',
      'helpFaqSubtitle': 'Answers to common questions',
      'contactUs': 'Contact Us',
      'contactUsSubtitle': 'Send us a message',
      'reportBug': 'Report a Bug',
      'reportBugSubtitle': 'Help us improve Skinova',
      'termsConditions': 'Terms & Conditions',
      'aboutSkinova': 'About Skinova',
      'logOut': 'Log Out',
      'logOutConfirmTitle': 'Log Out?',
      'logOutConfirmMessage': 'You will be signed out of your account.',
      'deleteAccount': 'Delete Account',
      'deleteAccountSubtitle': 'Permanently remove all your data',
      'deleteAccountTitle': 'Delete Account?',
      'deleteAccountMessage':
          'This will permanently delete your account, profile, collections, and all data. This cannot be undone.',
      'version': 'Skinova · Version 1.0.0',
      'lightMode': 'Light Mode',
      'darkMode': 'Dark Mode',
      'systemDefault': 'System Default',
      'lightModeSubtitle': 'Always use light background',
      'darkModeSubtitle': 'Always use dark background',
      'systemDefaultSubtitle': 'Follow your device setting',
      'english': 'English',
      'arabic': 'العربية',
      'englishSubtitle': 'Switch to English',
      'arabicSubtitle': 'التبديل إلى العربية',
      'askAI': 'Ask AI',
      'askAISubtitle': 'Your personal skincare assistant',
      'tryBeforeBuy': 'Try Before You Buy',
      'tryBeforeBuySubtitle': 'See how a product may look on your skin',
      'myPreviews': 'My Previews',
      'generatePreview': 'Generate My Preview',
      'selectProduct': 'Select a Product',
      'selectProductSubtitle': 'Tap to choose a product to preview',
      'choosePhoto': 'Choose a Photo',
      'choosePhotoSubtitle': 'Use your skin scan or upload a new photo',
      'useScanPhoto': 'Use my Skin Scan photo',
      'useScanPhotoSubtitle': 'From your latest scan',
      'uploadNewPhoto': 'Upload a new photo',
      'uploadNewPhotoSubtitle': 'From gallery or camera',
      'noPreviewsYet': 'No previews yet.\nTry a product on your skin first.',
      'noPreviewsTitle': 'No Previews Yet',
      'suitabilityScore': 'Suitability Score',
      'expectedEffects': 'Expected Effects',
      'warnings': 'Things to Note',
      'aiDisclaimer':
          'AI-generated preview. Results are simulated and may vary in real life. This is not a medical assessment.',
      'greatMatch': 'Great Match',
      'moderateMatch': 'Moderate Match',
      'useWithCaution': 'Use with Caution',
      'skinCoach': 'Skin Coach',
      'productDetective': 'Product Detective',
      'smartShopper': 'Smart Shopper',
      'skinCoachSubtitle': 'Ask skincare questions',
      'productDetectiveSubtitle': 'Analyze ingredients & products',
      'smartShopperSubtitle': 'Find real products in the app',
    },
    'ar': {
      'appName': 'سكينوفا',
      'loading': 'جاري التحميل...',
      'error': 'حدث خطأ ما',
      'retry': 'إعادة المحاولة',
      'tryAgain': 'حاول مجدداً',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'confirm': 'تأكيد',
      'yes': 'نعم',
      'no': 'لا',
      'ok': 'موافق',
      'done': 'تم',
      'close': 'إغلاق',
      'back': 'رجوع',
      'next': 'التالي',
      'submit': 'إرسال',
      'send': 'إرسال',
      'edit': 'تعديل',
      'remove': 'إزالة',
      'search': 'بحث',
      'noResults': 'لا توجد نتائج',
      'home': 'الرئيسية',
      'shop': 'المتجر',
      'posts': 'المنشورات',
      'profile': 'الملف الشخصي',
      'products': 'المنتجات',
      'scan': 'الفحص',
      'routine': 'الروتين',
      'settings': 'الإعدادات',
      'account': 'الحساب',
      'skinova': 'سكينوفا',
      'support': 'الدعم',
      'accountActions': 'إجراءات الحساب',
      'appearance': 'المظهر',
      'language': 'اللغة',
      'editProfile': 'تعديل الملف الشخصي',
      'editProfileSubtitle': 'تحديث الاسم والسيرة الذاتية والصورة',
      'changePassword': 'تغيير كلمة المرور',
      'changePasswordSubtitle': 'تحديث كلمة مرور حسابك',
      'notifications': 'الإشعارات',
      'notificationsSubtitle': 'إدارة تفضيلات الإشعارات',
      'privacyPolicy': 'سياسة الخصوصية',
      'privacyPolicySubtitle': 'كيف نتعامل مع بياناتك',
      'scanPrivacy': 'خصوصية الفحص',
      'scanPrivacySubtitle': 'التحكم في كيفية تخزين بيانات الفحص',
      'savedPosts': 'المنشورات المحفوظة',
      'savedPostsSubtitle': 'عرض المنشورات التي حفظتها',
      'helpFaq': 'المساعدة والأسئلة الشائعة',
      'helpFaqSubtitle': 'إجابات على الأسئلة الشائعة',
      'contactUs': 'اتصل بنا',
      'contactUsSubtitle': 'أرسل لنا رسالة',
      'reportBug': 'الإبلاغ عن خطأ',
      'reportBugSubtitle': 'ساعدنا في تحسين سكينوفا',
      'termsConditions': 'الشروط والأحكام',
      'aboutSkinova': 'حول سكينوفا',
      'logOut': 'تسجيل الخروج',
      'logOutConfirmTitle': 'تسجيل الخروج؟',
      'logOutConfirmMessage': 'سيتم تسجيل خروجك من حسابك.',
      'deleteAccount': 'حذف الحساب',
      'deleteAccountSubtitle': 'إزالة جميع بياناتك نهائياً',
      'deleteAccountTitle': 'حذف الحساب؟',
      'deleteAccountMessage':
          'سيؤدي هذا إلى حذف حسابك وملفك الشخصي ومجموعاتك وجميع بياناتك بشكل دائم. لا يمكن التراجع عن هذا.',
      'version': 'سكينوفا · الإصدار 1.0.0',
      'lightMode': 'الوضع الفاتح',
      'darkMode': 'الوضع الداكن',
      'systemDefault': 'إعداد النظام',
      'lightModeSubtitle': 'استخدام الخلفية الفاتحة دائماً',
      'darkModeSubtitle': 'استخدام الخلفية الداكنة دائماً',
      'systemDefaultSubtitle': 'اتباع إعداد الجهاز',
      'english': 'English',
      'arabic': 'العربية',
      'englishSubtitle': 'Switch to English',
      'arabicSubtitle': 'التبديل إلى العربية',
      'askAI': 'اسأل الذكاء الاصطناعي',
      'askAISubtitle': 'مساعدك الشخصي للعناية بالبشرة',
      'tryBeforeBuy': 'جرّب قبل الشراء',
      'tryBeforeBuySubtitle': 'اكتشف كيف يبدو المنتج على بشرتك',
      'myPreviews': 'معاينات سابقة',
      'generatePreview': 'إنشاء معاينتي',
      'selectProduct': 'اختر منتجاً',
      'selectProductSubtitle': 'اضغط لاختيار منتج للمعاينة',
      'choosePhoto': 'اختر صورة',
      'choosePhotoSubtitle': 'استخدم صورة فحص بشرتك أو قم بتحميل صورة جديدة',
      'useScanPhoto': 'استخدام صورة فحص البشرة',
      'useScanPhotoSubtitle': 'من أحدث فحص لك',
      'uploadNewPhoto': 'رفع صورة جديدة',
      'uploadNewPhotoSubtitle': 'من المعرض أو الكاميرا',
      'noPreviewsYet': 'لا توجد معاينات بعد.\nجرّب منتجاً على بشرتك أولاً.',
      'noPreviewsTitle': 'لا توجد معاينات',
      'suitabilityScore': 'درجة الملاءمة',
      'expectedEffects': 'التأثيرات المتوقعة',
      'warnings': 'ملاحظات مهمة',
      'aiDisclaimer':
          'معاينة مُولَّدة بالذكاء الاصطناعي. النتائج محاكاة وقد تختلف في الواقع. هذا ليس تقييماً طبياً.',
      'greatMatch': 'ملاءمة ممتازة',
      'moderateMatch': 'ملاءمة معتدلة',
      'useWithCaution': 'استخدم بحذر',
      'skinCoach': 'مدرب البشرة',
      'productDetective': 'محقق المنتجات',
      'smartShopper': 'التسوق الذكي',
      'skinCoachSubtitle': 'أسئلة العناية بالبشرة',
      'productDetectiveSubtitle': 'تحليل المكونات والمنتجات',
      'smartShopperSubtitle': 'ابحث عن منتجات حقيقية في التطبيق',
    },
  };
}

// ── Delegate ──────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
