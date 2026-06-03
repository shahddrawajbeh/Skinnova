import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class ScanPrivacyScreen extends StatefulWidget {
  final String userId;
  const ScanPrivacyScreen({super.key, required this.userId});

  @override
  State<ScanPrivacyScreen> createState() => _ScanPrivacyScreenState();
}

class _ScanPrivacyScreenState extends State<ScanPrivacyScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  bool _allowScanHistory = true;
  bool _allowImageStorage = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiService.fetchScanPrivacy(widget.userId);
    if (!mounted) return;
    setState(() {
      _allowScanHistory = data['allowScanHistory'] ?? true;

      _allowImageStorage = data['allowImageStorage'] ?? true;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final ok = await ApiService.updateScanPrivacy(
      userId: widget.userId,
      allowScanHistory: _allowScanHistory,
      allowImageStorage: _allowImageStorage,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          ok ? 'Privacy settings saved!' : 'Failed to save. Try again.',
          style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: ok ? const Color(0xFF4CAF50) : const Color(0xFFD32F2F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(14),
    ));
  }

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
        title: Text('Scan Privacy',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700, color: darkText)),
        actions: [
          TextButton(
            onPressed: (_isSaving || _isLoading) ? null : _save,
            child: Text('Save',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700, color: wine)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: wine.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: wine.withOpacity(0.15))),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: wine.withOpacity(0.7), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Control how Skinova stores and uses your skin scan data. Changes take effect immediately.',
                            style: GoogleFonts.poppins(
                                fontSize: 12.5, color: grey, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggles in a card
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: line),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3))
                        ]),
                    child: Column(
                      children: [
                        _toggleTile(
                          icon: Icons.history_rounded,
                          title: 'Scan History',
                          subtitle: 'Keep a record of your product scans',
                          value: _allowScanHistory,
                          onChanged: (v) =>
                              setState(() => _allowScanHistory = v),
                          isFirst: true,
                        ),
                        Divider(
                            height: 1, color: line, indent: 60, endIndent: 16),
                        _toggleTile(
                          icon: Icons.image_outlined,
                          title: 'Image Storage',
                          subtitle: 'Store scan images on Skinova servers',
                          value: _allowImageStorage,
                          onChanged: (v) =>
                              setState(() => _allowImageStorage = v),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: wine,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Save Settings',
                              style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 14, 16, isLast ? 16 : 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: (value ? wine : grey).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: value ? wine : grey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: darkText)),
                Text(subtitle,
                    style: GoogleFonts.poppins(fontSize: 11.5, color: grey)),
              ],
            ),
          ),
          Switch.adaptive(
              value: value, onChanged: onChanged, activeColor: wine),
        ],
      ),
    );
  }
}
