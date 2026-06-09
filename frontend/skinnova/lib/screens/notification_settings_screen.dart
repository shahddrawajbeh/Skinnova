import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final String userId;

  const NotificationSettingsScreen({super.key, required this.userId});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // ── Palette (matches Skinova design system) ───────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  // ── State ─────────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _saving = false;
  bool _inApp = true;
  bool _push = true;
  bool _email = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings =
        await ApiService.getNotificationSettings(widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (settings != null) {
        _inApp = settings['inApp'] ?? true;
        _push = settings['push'] ?? true;
        _email = settings['email'] ?? true;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final ok = await ApiService.updateNotificationSettings(
      widget.userId,
      inApp: _inApp,
      push: _push,
      email: _email,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Notification settings updated'
              : 'Failed to update notification settings',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: ok ? wine : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Toggle a channel and immediately persist
  void _toggle(String channel, bool value) {
    setState(() {
      if (channel == 'inApp') _inApp = value;
      if (channel == 'push') _push = value;
      if (channel == 'email') _email = value;
    });
    _save();
  }

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
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w700, color: darkText),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                // ── Info card ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: wine.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: wine.withOpacity(0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: wine),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Choose how you want to receive notifications from Skinova.',
                          style: GoogleFonts.poppins(
                              fontSize: 12.5, color: wine, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Section label ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'CHANNELS',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: grey,
                        letterSpacing: 0.5),
                  ),
                ),

                // ── Toggle group ───────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: line),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _toggleTile(
                        icon: Icons.notifications_active_outlined,
                        iconColor: wine,
                        title: 'In-App Notifications',
                        subtitle: 'Receive alerts inside the Skinova app',
                        value: _inApp,
                        onChanged: (v) => _toggle('inApp', v),
                      ),
                      Divider(height: 1, color: line, indent: 58),
                      _toggleTile(
                        icon: Icons.phone_android_rounded,
                        iconColor: const Color(0xFF1565C0),
                        title: 'Push Notifications',
                        subtitle:
                            'Receive notifications on your device lock screen',
                        value: _push,
                        onChanged: (v) => _toggle('push', v),
                      ),
                      Divider(height: 1, color: line, indent: 58),
                      _toggleTile(
                        icon: Icons.email_outlined,
                        iconColor: const Color(0xFF00838F),
                        title: 'Email Notifications',
                        subtitle:
                            'Receive important updates to your email address',
                        value: _email,
                        onChanged: (v) => _toggle('email', v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Description cards ──────────────────────────────────────
                _infoCard(
                  icon: Icons.email_outlined,
                  iconColor: const Color(0xFF00838F),
                  title: 'What emails will I receive?',
                  body:
                      'Order confirmations, store approvals, ad decisions, new followers, and important account updates.',
                ),
              ],
            ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _toggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: darkText),
                ),
                Text(
                  subtitle,
                  style:
                      GoogleFonts.poppins(fontSize: 11.5, color: grey),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: _saving ? null : onChanged,
            activeColor: wine,
            activeTrackColor: wine.withOpacity(0.25),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: darkText),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: grey, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
