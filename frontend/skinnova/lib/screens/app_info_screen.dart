import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppInfoType { faq, privacyPolicy, terms, about }

class AppInfoScreen extends StatelessWidget {
  final AppInfoType type;

  const AppInfoScreen({super.key, required this.type});

  static const Color wine = Color(0xFF5B2333);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color line = Color(0xFFEEECE9);

  String get _title {
    switch (type) {
      case AppInfoType.faq:
        return 'Help & FAQ';
      case AppInfoType.privacyPolicy:
        return 'Privacy Policy';
      case AppInfoType.terms:
        return 'Terms & Conditions';
      case AppInfoType.about:
        return 'About Skinova';
    }
  }

  List<_InfoSection> get _sections {
    switch (type) {
      case AppInfoType.faq:
        return _faqSections;
      case AppInfoType.privacyPolicy:
        return _privacySections;
      case AppInfoType.terms:
        return _termsSections;
      case AppInfoType.about:
        return _aboutSections;
    }
  }

  static final _faqSections = [
    _InfoSection('How do I scan a product?',
        'Go to the Discover tab, tap the Scan icon, and point your camera at the product label. Skinova will identify the product for you.'),
    _InfoSection('What is a skin scan?',
        'Skin scans use AI to analyse your skin condition from a photo. Navigate to the Skin AI section and follow the on-screen instructions.'),
    _InfoSection('How are collections used?',
        'Collections let you save and organise products you love, want to try, or want to remember. Tap the bookmark icon on any product to start saving.'),
    _InfoSection('Can I follow other users?',
        'Yes! Visit a user\'s profile and tap Follow. You\'ll see their posts and updates in your feed.'),
    _InfoSection('How do I contact support?',
        'Go to Settings → Contact Us and fill in the form. Our team responds within 24–48 hours.'),
  ];

  static final _privacySections = [
    _InfoSection('Data We Collect',
        'We collect information you provide when creating an account (name, email), skin profile data from onboarding, scan results, and product interactions such as favorites and reviews.'),
    _InfoSection('How We Use Your Data',
        'Your data is used to personalise your skincare experience, improve product recommendations, and operate the Skinova service. We never sell your personal data.'),
    _InfoSection('Scan Privacy',
        'Skin scan images and results are processed to provide analysis. You can control scan data retention in Settings → Scan Privacy.'),
    _InfoSection('Third-Party Services',
        'Skinova uses secure third-party services for image processing and AI analysis. These services are bound by confidentiality agreements.'),
    _InfoSection('Your Rights',
        'You can request deletion of your account and all associated data at any time via Settings → Delete Account.'),
    _InfoSection('Contact',
        'For privacy questions, contact us via Settings → Contact Us.'),
  ];

  static final _termsSections = [
    _InfoSection('Acceptance of Terms',
        'By using Skinova, you agree to these Terms and Conditions. If you do not agree, please stop using the application.'),
    _InfoSection('Use of the App',
        'Skinova is provided for personal, non-commercial use. You agree not to misuse the service, post harmful content, or attempt to access other users\' accounts.'),
    _InfoSection('User Content',
        'Posts, reviews, and other content you create remain your property. By posting, you grant Skinova a licence to display this content within the app.'),
    _InfoSection('Skin Analysis Disclaimer',
        'Skinova\'s AI-powered skin analysis is for informational purposes only and does not constitute medical advice. Always consult a qualified dermatologist for medical concerns.'),
    _InfoSection('Account Termination',
        'We reserve the right to suspend or terminate accounts that violate these terms. You may delete your account at any time from Settings.'),
    _InfoSection('Changes to Terms',
        'We may update these terms periodically. Continued use of the app after changes constitutes acceptance of the new terms.'),
  ];

  static final _aboutSections = [
    _InfoSection('What is Skinova?',
        'Skinova is a community-driven skincare app that helps you discover products, understand ingredients, track your skin journey, and connect with other skincare enthusiasts.'),
    _InfoSection('Our Mission',
        'We believe everyone deserves access to honest, science-backed skincare information. Skinova makes it easy to make informed decisions about the products you put on your skin.'),
    _InfoSection('Features',
        '• Product discovery and reviews\n• AI-powered skin analysis\n• Product barcode/label scanning\n• Ingredient education\n• Skincare community and posts\n• Personal collections and routines'),
    _InfoSection('Version', 'Skinova v1.0.0\nBuilt with Flutter & Node.js'),
    _InfoSection('Contact',
        'Have feedback or questions? Reach us via Settings → Contact Us. We read every message.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_title,
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700, color: darkText)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        itemCount: _sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildSection(_sections[i]),
      ),
    );
  }

  Widget _buildSection(_InfoSection section) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: whiteSmoke,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title,
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: darkText)),
          const SizedBox(height: 8),
          Text(section.body,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: grey, height: 1.6)),
        ],
      ),
    );
  }
}

class _InfoSection {
  final String title;
  final String body;
  const _InfoSection(this.title, this.body);
}
