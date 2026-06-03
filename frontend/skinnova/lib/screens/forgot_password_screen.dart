import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color bg = Color(0xFFF7F4F3);

  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String v) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(v);

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: error ? const Color(0xFFB91C1C) : wine,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _snack("Please enter your email address", error: true);
      return;
    }
    if (!_isValidEmail(email)) {
      _snack("Please enter a valid email address", error: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.forgotPassword(email);
      if (!mounted) return;

      if (result["statusCode"] == 200) {
        // Navigate to OTP screen regardless — never reveal if email exists
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
        );
      } else {
        _snack(
          (result["data"]?["message"] as String?) ?? "Something went wrong.",
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _snack("Network error. Please check your connection.", error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back button ───────────────────────────────────────────────
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: wine.withOpacity(0.12)),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 17, color: wine),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Icon + heading ────────────────────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B2333), Color(0xFF8B3A52)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: wine.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                Text(
                  "Forgot Password?",
                  style: GoogleFonts.marcellus(fontSize: 28, color: wine),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter the email linked to your Skinova account.\nWe'll send you a reset code.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: wine.withOpacity(0.55),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Email field ───────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: wine.withOpacity(0.10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: wine),
                    decoration: InputDecoration(
                      hintText: "name@email.com",
                      hintStyle: GoogleFonts.poppins(
                          color: wine.withOpacity(0.35), fontSize: 14),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.mail_outline_rounded,
                            color: wine.withOpacity(0.50), size: 20),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: wine.withOpacity(0.10), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: wine, width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Submit button ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF5B2333), Color(0xFF7A3346)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _isLoading ? const Color(0xFFCBB0B8) : null,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: _isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: wine.withOpacity(0.32),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2, color: Colors.white),
                            )
                          : Text(
                              "Send Reset Code",
                              style: GoogleFonts.poppins(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Security note ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: wine.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: wine.withOpacity(0.08)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: wine.withOpacity(0.55)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "For your security, we send the same response whether or not the email is registered.",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: wine.withOpacity(0.55),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
