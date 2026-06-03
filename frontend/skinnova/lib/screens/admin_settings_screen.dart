// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../api_service.dart';
// import 'admin_dashboard.dart';

// class AdminSettingsScreen extends StatefulWidget {
//   const AdminSettingsScreen({super.key});
//   @override
//   State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
// }

// class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
//   bool _loading = true;
//   bool _saving = false;
//   String _adminId = '';
//   final _appNameCtrl = TextEditingController();
//   final _mainMsgCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   final _phoneCtrl = TextEditingController();
//   final _termsCtrl = TextEditingController();
//   final _privacyCtrl = TextEditingController();
//   final _currencyCtrl = TextEditingController();
//   bool _maintenanceMode = false;
//   bool _allowRegistrations = true;
//   bool _allowSkinScans = true;
//   bool _allowProductScans = true;
//   bool _allowReviews = true;
//   bool _allowGroupPosts = true;

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   @override
//   void dispose() {
//     _appNameCtrl.dispose();
//     _mainMsgCtrl.dispose();
//     _emailCtrl.dispose();
//     _phoneCtrl.dispose();
//     _termsCtrl.dispose();
//     _privacyCtrl.dispose();
//     _currencyCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _init() async {
//     final prefs = await SharedPreferences.getInstance();
//     _adminId = prefs.getString('userId') ?? '';
//     await _load();
//   }

//   Future<void> _load() async {
//     setState(() => _loading = true);
//     try {
//       final data = await ApiService.adminGetSettings(_adminId);
//       if (!mounted) return;
//       setState(() {
//         _appNameCtrl.text = data['appName'] ?? 'Skinova';
//         _mainMsgCtrl.text = data['maintenanceMessage'] ?? '';
//         _emailCtrl.text = data['contactEmail'] ?? '';
//         _phoneCtrl.text = data['contactPhone'] ?? '';
//         _termsCtrl.text = data['termsUrl'] ?? '';
//         _privacyCtrl.text = data['privacyUrl'] ?? '';
//         _currencyCtrl.text = data['currency'] ?? 'ILS';
//         _maintenanceMode = data['maintenanceMode'] == true;
//         _allowRegistrations = data['allowNewRegistrations'] != false;
//         _allowSkinScans = data['allowSkinScans'] != false;
//         _allowProductScans = data['allowProductScans'] != false;
//         _allowReviews = data['allowReviews'] != false;
//         _allowGroupPosts = data['allowGroupPosts'] != false;
//         _loading = false;
//       });
//     } catch (_) {
//       if (!mounted) return;
//       setState(() => _loading = false);
//     }
//   }

//   Future<void> _save() async {
//     setState(() => _saving = true);
//     try {
//       await ApiService.adminUpdateSettings(_adminId, {
//         'appName': _appNameCtrl.text.trim(),
//         'maintenanceMode': _maintenanceMode,
//         'maintenanceMessage': _mainMsgCtrl.text.trim(),
//         'allowNewRegistrations': _allowRegistrations,
//         'allowSkinScans': _allowSkinScans,
//         'allowProductScans': _allowProductScans,
//         'allowReviews': _allowReviews,
//         'allowGroupPosts': _allowGroupPosts,
//         'contactEmail': _emailCtrl.text.trim(),
//         'contactPhone': _phoneCtrl.text.trim(),
//         'termsUrl': _termsCtrl.text.trim(),
//         'privacyUrl': _privacyCtrl.text.trim(),
//         'currency': _currencyCtrl.text.trim(),
//       });
//       if (!mounted) return;
//       _showSnack("Settings saved!");
//     } catch (e) {
//       if (!mounted) return;
//       _showSnack("Error: $e", error: true);
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading)
//       return const Center(
//           child: CircularProgressIndicator(color: AdminTheme.wine));
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text("App Settings", style: AdminTheme.title(20)),
//         const SizedBox(height: 4),
//         Text("Configure global app behaviour.", style: AdminTheme.sub(13)),
//         const SizedBox(height: 24),
//         _section("General", [
//           _f("App Name", _appNameCtrl),
//           const SizedBox(height: 12),
//           _f("Currency", _currencyCtrl),
//         ]),
//         const SizedBox(height: 16),
//         _section("Maintenance", [
//           _sw("Maintenance Mode", _maintenanceMode,
//               (v) => setState(() => _maintenanceMode = v),
//               danger: true),
//           if (_maintenanceMode) ...[
//             const SizedBox(height: 12),
//             _f("Maintenance Message", _mainMsgCtrl, maxLines: 3)
//           ],
//         ]),
//         const SizedBox(height: 16),
//         _section("Feature Flags", [
//           _sw("Allow New Registrations", _allowRegistrations,
//               (v) => setState(() => _allowRegistrations = v)),
//           _div(),
//           _sw("Allow Skin Scans", _allowSkinScans,
//               (v) => setState(() => _allowSkinScans = v)),
//           _div(),
//           _sw("Allow Product Scans", _allowProductScans,
//               (v) => setState(() => _allowProductScans = v)),
//           _div(),
//           _sw("Allow Reviews", _allowReviews,
//               (v) => setState(() => _allowReviews = v)),
//           _div(),
//           _sw("Allow Group Posts", _allowGroupPosts,
//               (v) => setState(() => _allowGroupPosts = v)),
//         ]),
//         const SizedBox(height: 16),
//         _section("Contact & Legal", [
//           _f("Contact Email", _emailCtrl),
//           const SizedBox(height: 12),
//           _f("Contact Phone", _phoneCtrl),
//           const SizedBox(height: 12),
//           _f("Terms URL", _termsCtrl),
//           const SizedBox(height: 12),
//           _f("Privacy URL", _privacyCtrl),
//         ]),
//         const SizedBox(height: 24),
//         SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _saving ? null : _save,
//               style: ElevatedButton.styleFrom(
//                   backgroundColor: AdminTheme.wine,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16))),
//               child: _saving
//                   ? const SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(
//                           color: Colors.white, strokeWidth: 2))
//                   : Text("Save Settings",
//                       style: GoogleFonts.poppins(
//                           color: Colors.white,
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600)),
//             )),
//       ]),
//     );
//   }

//   Widget _section(String title, List<Widget> children) => Container(
//         padding: const EdgeInsets.all(20),
//         decoration: AdminTheme.cardDec(),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(title, style: AdminTheme.title(14)),
//           const SizedBox(height: 14),
//           ...children,
//         ]),
//       );

//   Widget _sw(String label, bool value, ValueChanged<bool> onChanged,
//           {bool danger = false}) =>
//       Padding(
//         padding: const EdgeInsets.symmetric(vertical: 4),
//         child: Row(children: [
//           Text(label,
//               style: GoogleFonts.poppins(
//                   fontSize: 13.5,
//                   color: (danger && value)
//                       ? Colors.red.shade500
//                       : AdminTheme.black)),
//           const Spacer(),
//           Switch(
//               value: value,
//               activeColor: danger ? Colors.red.shade500 : AdminTheme.wine,
//               onChanged: onChanged),
//         ]),
//       );

//   Widget _div() => Container(
//       height: 1,
//       color: AdminTheme.line,
//       margin: const EdgeInsets.symmetric(vertical: 2));

//   Widget _f(String label, TextEditingController ctrl, {int maxLines = 1}) =>
//       TextField(
//           controller: ctrl,
//           maxLines: maxLines,
//           decoration: InputDecoration(
//               labelText: label,
//               labelStyle:
//                   GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey),
//               border:
//                   OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//               contentPadding:
//                   const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
//           style: GoogleFonts.poppins(fontSize: 13));

//   void _showSnack(String msg, {bool error = false}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(msg, style: GoogleFonts.poppins()),
//       backgroundColor: error ? Colors.red.shade400 : AdminTheme.wine,
//       behavior: SnackBarBehavior.floating,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//     ));
//   }
// }
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String _adminId = '';

  final _mainMsgCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _maintenanceMode = false;
  bool _allowRegistrations = true;
  bool _allowSkinScans = true;
  bool _allowProductScans = true;
  bool _allowReviews = true;
  bool _allowGroupPosts = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _mainMsgCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminId = prefs.getString('userId') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final data = await ApiService.adminGetSettings(_adminId);

      if (!mounted) return;

      setState(() {
        _mainMsgCtrl.text = data['maintenanceMessage'] ?? '';
        _emailCtrl.text = data['contactEmail'] ?? '';
        _phoneCtrl.text = data['contactPhone'] ?? '';

        _maintenanceMode = data['maintenanceMode'] == true;
        _allowRegistrations = data['allowNewRegistrations'] != false;
        _allowSkinScans = data['allowSkinScans'] != false;
        _allowProductScans = data['allowProductScans'] != false;
        _allowReviews = data['allowReviews'] != false;
        _allowGroupPosts = data['allowGroupPosts'] != false;

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await ApiService.adminUpdateSettings(_adminId, {
        'maintenanceMode': _maintenanceMode,
        'maintenanceMessage': _mainMsgCtrl.text.trim(),
        'allowNewRegistrations': _allowRegistrations,
        'allowSkinScans': _allowSkinScans,
        'allowProductScans': _allowProductScans,
        'allowReviews': _allowReviews,
        'allowGroupPosts': _allowGroupPosts,
        'contactEmail': _emailCtrl.text.trim(),
        'contactPhone': _phoneCtrl.text.trim(),
      });

      if (!mounted) return;
      _showSnack("Settings saved!");
    } catch (e) {
      if (!mounted) return;
      _showSnack("Error: $e", error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AdminTheme.wine),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("App Settings", style: AdminTheme.title(20)),
          const SizedBox(height: 4),
          Text(
            "Control app availability and main user features.",
            style: AdminTheme.sub(13),
          ),
          const SizedBox(height: 24),
          _section("App Status", [
            _sw(
              "Maintenance Mode",
              _maintenanceMode,
              (v) => setState(() => _maintenanceMode = v),
              danger: true,
            ),
            if (_maintenanceMode) ...[
              const SizedBox(height: 12),
              _f("Maintenance Message", _mainMsgCtrl, maxLines: 3),
            ],
          ]),
          const SizedBox(height: 16),
          _section("Features", [
            _sw(
              "Allow New Registrations",
              _allowRegistrations,
              (v) => setState(() => _allowRegistrations = v),
            ),
            _div(),
            _sw(
              "Allow Skin Scans",
              _allowSkinScans,
              (v) => setState(() => _allowSkinScans = v),
            ),
            _div(),
            _sw(
              "Allow Product Scans",
              _allowProductScans,
              (v) => setState(() => _allowProductScans = v),
            ),
            _div(),
            _sw(
              "Allow Reviews",
              _allowReviews,
              (v) => setState(() => _allowReviews = v),
            ),
            _div(),
            _sw(
              "Allow Group Posts",
              _allowGroupPosts,
              (v) => setState(() => _allowGroupPosts = v),
            ),
          ]),
          const SizedBox(height: 16),
          _section("Support", [
            _f("Contact Email", _emailCtrl),
            const SizedBox(height: 12),
            _f("Contact Phone", _phoneCtrl),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.wine,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Save Settings",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
        padding: const EdgeInsets.all(20),
        decoration: AdminTheme.cardDec(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AdminTheme.title(14)),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );

  Widget _sw(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    bool danger = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: (danger && value)
                      ? Colors.red.shade500
                      : AdminTheme.black,
                ),
              ),
            ),
            Switch(
              value: value,
              activeColor: danger ? Colors.red.shade500 : AdminTheme.wine,
              onChanged: onChanged,
            ),
          ],
        ),
      );

  Widget _div() => Container(
        height: 1,
        color: AdminTheme.line,
        margin: const EdgeInsets.symmetric(vertical: 2),
      );

  Widget _f(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: AdminTheme.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        style: GoogleFonts.poppins(fontSize: 13),
      );

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: error ? Colors.red.shade400 : AdminTheme.wine,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
