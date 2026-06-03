import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

/// Shown when maintenanceMode == true for non-admin users.
class MaintenanceScreen extends StatefulWidget {
  final String message;
  final String contactEmail;
  final String contactPhone;

  const MaintenanceScreen({
    super.key,
    required this.message,
    this.contactEmail = '',
    this.contactPhone = '',
  });

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color bg = Color(0xFFF7F4F3);
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    try {
      final settings = await ApiService.getPublicSettings();
      if (!mounted) return;
      if (settings['maintenanceMode'] != true) {
        // Maintenance lifted — restart navigation
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      } else {
        setState(() => _checking = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Still under maintenance. Please check back soon.",
              style: GoogleFonts.poppins()),
          backgroundColor: wine,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2E8EA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.build_circle_outlined,
                    color: wine,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  "Under Maintenance",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.marcellus(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: wine,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.message.isNotEmpty
                      ? widget.message
                      : "We are currently performing maintenance.\nPlease try again later.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    color: const Color(0xFF7A7A7A),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),

                // Contact info
                if (widget.contactEmail.isNotEmpty ||
                    widget.contactPhone.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEECE9)),
                    ),
                    child: Column(
                      children: [
                        if (widget.contactEmail.isNotEmpty)
                          _contactRow(
                              Icons.email_outlined, widget.contactEmail),
                        if (widget.contactEmail.isNotEmpty &&
                            widget.contactPhone.isNotEmpty)
                          const SizedBox(height: 8),
                        if (widget.contactPhone.isNotEmpty)
                          _contactRow(
                              Icons.phone_outlined, widget.contactPhone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checking ? null : _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: wine,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                    ),
                    child: _checking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text("Check Again",
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 18, color: wine),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFF202124))),
          ),
        ],
      );
}
