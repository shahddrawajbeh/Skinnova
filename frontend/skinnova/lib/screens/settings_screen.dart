import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'saved_posts_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const SettingsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  static const Color bg = Colors.white;
  static const Color cardColor = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF202124);
  static const Color textMuted = Color(0xFFBDBDBD);
  static const Color borderColor = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.chevron_left,
                      size: 30,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: borderColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
                children: [
                  _sectionTitle("General"),
                  const SizedBox(height: 10),
                  _settingsTile(
                    icon: Icons.person_add_alt_1_outlined,
                    title: "Invite friends",
                  ),
                  _settingsTile(
                    icon: Icons.star_border_rounded,
                    title: "Saved posts",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SavedPostsScreen(
                            userId: userId,
                            userName: userName,
                          ),
                        ),
                      );
                    },
                  ),
                  _settingsTile(
                    icon: Icons.notifications_none_rounded,
                    title: "Notifications",
                  ),
                  _settingsTile(
                    icon: Icons.menu_book_outlined,
                    title: "Terms and conditions",
                  ),
                  _settingsTile(
                    icon: Icons.update_rounded,
                    title: "App updates",
                  ),
                  _settingsTile(
                    icon: Icons.verified_user_outlined,
                    title: "Photo sharing consent",
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle("App support"),
                  const SizedBox(height: 14),
                  _settingsTile(
                    icon: Icons.lightbulb_outline_rounded,
                    title: "Suggest a new feature",
                  ),
                  _settingsTile(
                    icon: Icons.warning_amber_rounded,
                    title: "Report a bug",
                  ),
                  _settingsTile(
                    icon: Icons.check_circle_outline_rounded,
                    title: "Request verification",
                  ),
                  _settingsTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: "Contact us",
                  ),
                  _settingsTile(
                    icon: Icons.rate_review_outlined,
                    title: "Leave an app store review",
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle("Account"),
                  const SizedBox(height: 14),
                  _settingsTile(
                    icon: Icons.workspace_premium_outlined,
                    title: "Premium subscription",
                  ),
                  _settingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: "Change password",
                    enabled: false,
                  ),
                  _settingsTile(
                    icon: Icons.bookmark_border_rounded,
                    title: "Request full routine pdf",
                  ),
                  _settingsTile(
                    icon: Icons.person_remove_alt_1_outlined,
                    title: "Delete account",
                  ),
                  _settingsTile(
                    icon: Icons.logout_rounded,
                    title: "Logout",
                  ),
                  const SizedBox(height: 26),
                  Center(
                    child: Text(
                      "Skinova App version 2.15.13",
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textDark,
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    final iconColor = enabled ? textDark : const Color(0xFFD2D2D2);
    final textColor = enabled ? textDark : const Color(0xFFC7C7C7);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: iconColor,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
