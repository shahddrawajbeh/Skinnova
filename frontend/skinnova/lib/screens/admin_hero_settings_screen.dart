import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminHeroSettingsScreen extends StatefulWidget {
  const AdminHeroSettingsScreen({super.key});
  @override
  State<AdminHeroSettingsScreen> createState() =>
      _AdminHeroSettingsScreenState();
}

class _AdminHeroSettingsScreenState extends State<AdminHeroSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String _adminId = '';
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _btnTextCtrl = TextEditingController();
  final _btnTargetCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String _btnAction = 'scan';
  bool _heroActive = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _btnTextCtrl.dispose();
    _btnTargetCtrl.dispose();
    _imageCtrl.dispose();
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
      final data = await ApiService.adminGetHomeSettings(_adminId);
      if (!mounted) return;
      setState(() {
        _titleCtrl.text = data['heroTitle'] ?? '';
        _subtitleCtrl.text = data['heroSubtitle'] ?? '';
        _btnTextCtrl.text = data['heroButtonText'] ?? '';
        _btnTargetCtrl.text = data['heroButtonTarget'] ?? '';
        _imageCtrl.text = data['heroImageUrl'] ?? '';
        _btnAction = data['heroButtonAction'] ?? 'scan';
        _heroActive = data['heroIsActive'] != false;
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
      await ApiService.adminUpdateHomeSettings(_adminId, {
        'heroTitle': _titleCtrl.text.trim(),
        'heroSubtitle': _subtitleCtrl.text.trim(),
        'heroButtonText': _btnTextCtrl.text.trim(),
        'heroButtonTarget': _btnTargetCtrl.text.trim(),
        'heroImageUrl': _imageCtrl.text.trim(),
        'heroButtonAction': _btnAction,
        'heroIsActive': _heroActive,
      });
      if (!mounted) return;
      _showSnack("Hero settings saved!");
    } catch (e) {
      if (!mounted) return;
      _showSnack("Error: $e", error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: AdminTheme.wine));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Explore Store Section", style: AdminTheme.title(20)),
        const SizedBox(height: 4),
        Text("Control the Explore Store card shown on the home screen.",
            style: AdminTheme.sub(13)),
        const SizedBox(height: 24),

        // Live preview
        if (_imageCtrl.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: 180,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AdminTheme.line)),
            clipBehavior: Clip.hardEdge,
            child: Stack(fit: StackFit.expand, children: [
              Image.network(_imageCtrl.text,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: AdminTheme.wineMuted,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: AdminTheme.wine, size: 40))),
              Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                Colors.black.withOpacity(0.55),
                Colors.transparent
              ], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
              Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_titleCtrl.text,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text(_subtitleCtrl.text,
                            style: GoogleFonts.poppins(
                                color: Colors.white70, fontSize: 12)),
                      ])),
            ]),
          ),

        _card([
          _f("Explore Image URL", _imageCtrl, hint: "https://..."),
          const SizedBox(height: 14),
          _f("Title", _titleCtrl),
          const SizedBox(height: 14),
          _f("Subtitle", _subtitleCtrl),
          const SizedBox(height: 14),
          _f("Button Text", _btnTextCtrl),
          const SizedBox(height: 14),
          StatefulBuilder(
              builder: (_, setS) => DropdownButtonFormField<String>(
                    value: _btnAction,
                    decoration: _inputDec("Button Action"),
                    items: ['scan', 'shop', 'link', 'none']
                        .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(a, style: GoogleFonts.poppins())))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _btnAction = v!);
                      setS(() {});
                    },
                  )),
          if (_btnAction == 'link') ...[
            const SizedBox(height: 14),
            _f("Button Target URL", _btnTargetCtrl)
          ],
          const SizedBox(height: 14),
          Row(children: [
            Text("Explore Section Active",
                style:
                    GoogleFonts.poppins(fontSize: 14, color: AdminTheme.black)),
            const Spacer(),
            Switch(
                value: _heroActive,
                activeColor: AdminTheme.wine,
                onChanged: (v) => setState(() => _heroActive = v)),
          ]),
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
                      borderRadius: BorderRadius.circular(16))),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text("Save Changes",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
            )),
      ]),
    );
  }

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(20),
        decoration: AdminTheme.cardDec(),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  InputDecoration _inputDec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  TextField _f(String label, TextEditingController ctrl, {String? hint}) =>
      TextField(
        controller: ctrl,
        decoration: _inputDec(label, hint: hint),
        style: GoogleFonts.poppins(fontSize: 13),
        onChanged: (_) => setState(() {}),
      );

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? Colors.red.shade400 : AdminTheme.wine,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
