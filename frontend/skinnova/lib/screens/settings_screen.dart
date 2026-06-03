import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../user_model.dart';
import '../app_settings.dart';
import '../l10n/app_localizations.dart';
import 'saved_posts_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'scan_privacy_screen.dart';
import 'contact_form_screen.dart';
import 'app_info_screen.dart';
import 'store_request_screen.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const SettingsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);
  static const Color danger = Color(0xFFD32F2F);

  // ── State ─────────────────────────────────────────────────────────────────
  UserModel? _user;
  bool _loadingUser = false;

  // ── Load user (lazy) ──────────────────────────────────────────────────────
  Future<UserModel?> _fetchUser() async {
    if (_user != null) return _user;
    setState(() => _loadingUser = true);
    final result = await ApiService.fetchUserProfile(widget.userId);
    if (mounted)
      setState(() {
        _user = result;
        _loadingUser = false;
      });
    return result;
  }

  // ── Navigation helpers ────────────────────────────────────────────────────
  Future<void> _openEditProfile() async {
    final user = await _fetchUser();
    if (!mounted || user == null) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfileScreen(userId: widget.userId, user: user),
        ));
    _user = null; // clear cache so next open re-fetches
  }

  Future<void> _openSkinProfile() async {
    final user = await _fetchUser();
    if (!mounted || user == null) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfileScreen(userId: widget.userId, user: user),
        ));
    _user = null;
  }

  // ── Logout dialog ─────────────────────────────────────────────────────────
  void _confirmLogout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: danger.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, size: 24, color: danger),
            ),
            const SizedBox(height: 14),
            Text('Log Out?',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: darkText)),
            const SizedBox(height: 6),
            Text('You will be signed out of your account.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await NotificationService().removeTokenOnLogout();

                  final prefs = await SharedPreferences.getInstance();
                  if (!mounted) return;
                  // Pop all routes back to root
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Log Out',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: line),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: darkText)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete account dialog ─────────────────────────────────────────────────
  void _confirmDeleteAccount() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: danger.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.delete_forever_outlined,
                  size: 26, color: danger),
            ),
            const SizedBox(height: 14),
            Text('Delete Account?',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: darkText)),
            const SizedBox(height: 8),
            Text(
              'This will permanently delete your account, profile, collections, and all data. This cannot be undone.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: grey, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(sheetCtx);
                  final ok = await ApiService.deleteAccount(widget.userId);
                  if (!mounted) return;
                  if (ok) {
                    await NotificationService().removeTokenOnLogout();

                    final prefs = await SharedPreferences.getInstance();
                    if (!mounted) return;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Failed to delete account. Please try again.',
                            style: GoogleFonts.poppins(fontSize: 13)),
                        backgroundColor: danger,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(14),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Delete My Account',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(sheetCtx),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: line),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: darkText)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteSmoke,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.maybeOf(context)?.settings ?? 'Settings',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700, color: darkText)),
      ),
      body: Builder(builder: (ctx) {
        final l = AppLocalizations.maybeOf(ctx);
        final settings = AppSettings.of(ctx);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── Sell on Skinova ─────────────────────────────────────────────
            _sectionLabel('Sell on Skinova'),
            _settingsGroup([
              _tile(
                icon: Icons.storefront_rounded,
                iconColor: wine,
                title: 'Open a Store',
                subtitle:
                    'Apply to become a store owner and sell your products',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StoreRequestScreen()),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Account ─────────────────────────────────────────────────────
            _sectionLabel(l?.account ?? 'Account'),
            _settingsGroup([
              _tile(
                icon: Icons.person_outline_rounded,
                iconColor: wine,
                title: l?.editProfile ?? 'Edit Profile',
                subtitle: l?.editProfileSubtitle ??
                    'Update your name, bio, and photo',
                onTap: _loadingUser ? null : _openEditProfile,
                trailing: _loadingUser
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: wine))
                    : null,
              ),
              _divider(),
              _tile(
                icon: Icons.lock_outline_rounded,
                iconColor: wine,
                title: l?.changePassword ?? 'Change Password',
                subtitle:
                    l?.changePasswordSubtitle ?? 'Update your account password',
                onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChangePasswordScreen(userId: widget.userId),
                    )),
              ),
              _divider(),
              _tile(
                icon: Icons.notifications_none_rounded,
                iconColor: wine,
                title: l?.notifications ?? 'Notifications',
                subtitle: l?.notificationsSubtitle ??
                    'Manage your notification preferences',
                badge: 'Soon',
              ),
              _divider(),
              _tile(
                icon: Icons.shield_outlined,
                iconColor: wine,
                title: l?.privacyPolicy ?? 'Privacy Policy',
                subtitle: l?.privacyPolicySubtitle ?? 'How we handle your data',
                onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AppInfoScreen(type: AppInfoType.privacyPolicy),
                    )),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Skinova ──────────────────────────────────────────────────────
            _sectionLabel(l?.skinova ?? 'Skinova'),
            _settingsGroup([
              _tile(
                icon: Icons.document_scanner_outlined,
                iconColor: const Color(0xFF1565C0),
                title: l?.scanPrivacy ?? 'Scan Privacy',
                subtitle:
                    l?.scanPrivacySubtitle ?? 'Control how scan data is stored',
                onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ScanPrivacyScreen(userId: widget.userId),
                    )),
              ),
              _divider(),
              _tile(
                icon: Icons.bookmark_outline_rounded,
                iconColor: const Color(0xFF7B1FA2),
                title: l?.savedPosts ?? 'Saved Posts',
                subtitle:
                    l?.savedPostsSubtitle ?? "View posts you've bookmarked",
                onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => SavedPostsScreen(
                        userId: widget.userId,
                        userName: widget.userName,
                      ),
                    )),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Support ──────────────────────────────────────────────────────
            _sectionLabel(l?.support ?? 'Support'),
            _settingsGroup([
              _tile(
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFFE65100),
                title: l?.helpFaq ?? 'Help & FAQ',
                subtitle: l?.helpFaqSubtitle ?? 'Answers to common questions',
                onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AppInfoScreen(type: AppInfoType.faq),
                    )),
              ),
              _divider(),
              _tile(
                icon: Icons.mail_outline_rounded,
                iconColor: const Color(0xFF00838F),
                title: l?.contactUs ?? 'Contact Us',
                subtitle: l?.contactUsSubtitle ?? 'Send us a message',
                onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ContactFormScreen(
                        userId: widget.userId,
                        userName: widget.userName,
                        type: 'contact',
                      ),
                    )),
              ),
              _divider(),
              _tile(
                icon: Icons.bug_report_outlined,
                iconColor: const Color(0xFFF57C00),
                title: l?.reportBug ?? 'Report a Bug',
                subtitle: l?.reportBugSubtitle ?? 'Help us improve Skinova',
                onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ContactFormScreen(
                        userId: widget.userId,
                        userName: widget.userName,
                        type: 'bug',
                      ),
                    )),
              ),
              _divider(),
              _tile(
                icon: Icons.menu_book_outlined,
                iconColor: grey,
                title: l?.termsConditions ?? 'Terms & Conditions',
                onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AppInfoScreen(type: AppInfoType.terms),
                    )),
              ),
              _divider(),
              _tile(
                icon: Icons.info_outline_rounded,
                iconColor: grey,
                title: l?.aboutSkinova ?? 'About Skinova',
                onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AppInfoScreen(type: AppInfoType.about),
                    )),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Appearance ───────────────────────────────────────────────────
            _sectionLabel(l?.appearance ?? 'Appearance'),
            _settingsGroup([
              _selectTile(
                icon: Icons.wb_sunny_outlined,
                iconColor: const Color(0xFFE65100),
                title: l?.lightMode ?? 'Light Mode',
                subtitle: l?.lightModeSubtitle ?? 'Always use light background',
                selected: settings.themeMode == ThemeMode.light,
                onTap: () => settings.setThemeMode(ThemeMode.light),
              ),
              _divider(),
              _selectTile(
                icon: Icons.dark_mode_outlined,
                iconColor: const Color(0xFF5C6BC0),
                title: l?.darkMode ?? 'Dark Mode',
                subtitle: l?.darkModeSubtitle ?? 'Always use dark background',
                selected: settings.themeMode == ThemeMode.dark,
                onTap: () => settings.setThemeMode(ThemeMode.dark),
              ),
              _divider(),
              _selectTile(
                icon: Icons.phone_android_outlined,
                iconColor: grey,
                title: l?.systemDefault ?? 'System Default',
                subtitle:
                    l?.systemDefaultSubtitle ?? 'Follow your device setting',
                selected: settings.themeMode == ThemeMode.system,
                onTap: () => settings.setThemeMode(ThemeMode.system),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Language ─────────────────────────────────────────────────────
            _sectionLabel(l?.language ?? 'Language'),
            _settingsGroup([
              _selectTile(
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF00897B),
                title: l?.english ?? 'English',
                subtitle: 'English',
                selected: settings.locale.languageCode == 'en',
                onTap: () => settings.setLocale(const Locale('en')),
              ),
              _divider(),
              _selectTile(
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF00897B),
                title: l?.arabic ?? 'العربية',
                subtitle: 'Arabic / العربية',
                selected: settings.locale.languageCode == 'ar',
                onTap: () => settings.setLocale(const Locale('ar')),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Danger zone ──────────────────────────────────────────────────
            _sectionLabel(l?.accountActions ?? 'Account Actions',
                color: danger),
            _settingsGroup([
              _tile(
                icon: Icons.logout_rounded,
                iconColor: danger,
                title: l?.logOut ?? 'Log Out',
                titleColor: danger,
                onTap: _confirmLogout,
                showArrow: false,
              ),
              _divider(),
              _tile(
                icon: Icons.delete_forever_outlined,
                iconColor: danger,
                title: l?.deleteAccount ?? 'Delete Account',
                subtitle: l?.deleteAccountSubtitle ??
                    'Permanently remove all your data',
                titleColor: danger,
                onTap: _confirmDeleteAccount,
                showArrow: false,
              ),
            ]),
            const SizedBox(height: 28),

            // ── Version ──────────────────────────────────────────────────────
            Center(
              child: Text(l?.version ?? 'Skinova · Version 1.0.0',
                  style: GoogleFonts.poppins(fontSize: 12, color: grey)),
            ),
          ],
        );
      }),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? grey,
              letterSpacing: 0.3)),
    );
  }

  Widget _settingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: line, indent: 58, endIndent: 0);

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? titleColor,
    bool showArrow = true,
    String? badge,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? darkText)),
                  if (subtitle != null)
                    Text(subtitle,
                        style:
                            GoogleFonts.poppins(fontSize: 11.5, color: grey)),
                ],
              ),
            ),
            // Trailing: badge / custom widget / arrow
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: grey.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(badge,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: grey)),
              )
            else if (trailing != null)
              trailing
            else if (showArrow && onTap != null)
              Icon(Icons.arrow_forward_ios_rounded, size: 13, color: grey),
          ],
        ),
      ),
    );
  }

  // Radio-style tile: shows a wine checkmark when [selected] is true.
  Widget _selectTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? wine.withOpacity(0.09)
                    : iconColor.withOpacity(0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: selected ? wine : iconColor),
            ),
            const SizedBox(width: 14),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? wine : darkText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 11.5, color: grey),
                  ),
                ],
              ),
            ),
            // Checkmark
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Container(
                      key: const ValueKey(true),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: wine.withOpacity(0.09),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 14, color: wine),
                    )
                  : const SizedBox(key: ValueKey(false), width: 24),
            ),
          ],
        ),
      ),
    );
  }
}
