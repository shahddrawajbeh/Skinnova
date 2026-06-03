import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class ContactFormScreen extends StatefulWidget {
  final String userId;
  final String userName;

  /// 'contact' or 'bug'
  final String type;

  const ContactFormScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.type,
  });

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isSending = false;

  bool get _isBug => widget.type == 'bug';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      _snack('Please fill in all required fields.', isError: true);
      return;
    }

    setState(() => _isSending = true);
    final ok = await ApiService.submitSupportMessage(
      type: widget.type,
      subject: subject,
      message: message,
      userId: widget.userId,
      userName: widget.userName,
      email: email,
    );
    if (!mounted) return;
    setState(() => _isSending = false);

    if (ok) {
      _snack(_isBug
          ? 'Bug report submitted. Thank you!'
          : 'Message sent! We\'ll get back to you soon.');
      Navigator.pop(context);
    } else {
      _snack('Failed to send. Please try again.', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor:
          isError ? const Color(0xFFD32F2F) : const Color(0xFF4CAF50),
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
        title: Text(_isBug ? 'Report a Bug' : 'Contact Us',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700, color: darkText)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: wine.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: wine.withOpacity(0.15))),
              child: Row(
                children: [
                  Icon(
                    _isBug
                        ? Icons.bug_report_outlined
                        : Icons.mail_outline_rounded,
                    color: wine.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isBug
                          ? 'Describe the bug clearly so we can fix it as soon as possible.'
                          : 'Send us a message and we\'ll get back to you within 24–48 hours.',
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, color: grey, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _labeledField(
              label: 'Your Email (optional)',
              ctrl: _emailCtrl,
              hint: 'your@email.com',
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _labeledField(
              label: _isBug ? 'Bug Summary *' : 'Subject *',
              ctrl: _subjectCtrl,
              hint: _isBug
                  ? 'e.g. App crashes on scan page'
                  : 'What can we help with?',
            ),
            const SizedBox(height: 16),
            _labeledField(
              label: _isBug ? 'Steps to Reproduce *' : 'Message *',
              ctrl: _messageCtrl,
              hint: _isBug
                  ? '1. Open the app\n2. Go to...\n3. Tap...'
                  : 'Tell us more about your question or concern…',
              maxLines: 6,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: wine,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isBug ? 'Submit Report' : 'Send Message',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    int maxLines = 1,
    TextInputType? type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600, color: darkText)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: type,
          style: GoogleFonts.poppins(fontSize: 14, color: darkText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
                fontSize: 13, color: Colors.grey.shade400, height: 1.5),
            filled: true,
            fillColor: whiteSmoke,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: wine, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
