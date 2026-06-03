import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color bg = Color(0xFFF7F4F3);

  // 6 individual OTP boxes
  final List<TextEditingController> _otpCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _resending = false;

  @override
  void dispose() {
    for (final c in _otpCtrl) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _otp => _otpCtrl.map((c) => c.text).join();

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

  Future<void> _resendCode() async {
    setState(() => _resending = true);
    try {
      await ApiService.forgotPassword(widget.email);
      if (!mounted) return;
      _snack("A new code has been sent to your email");
      for (final c in _otpCtrl) {
        c.clear();
      }
      _otpFocus[0].requestFocus();
    } catch (_) {
      if (!mounted) return;
      _snack("Failed to resend. Please try again.", error: true);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _submit() async {
    final otp = _otp;
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (otp.length < 6) {
      _snack("Please enter the 6-digit code", error: true);
      return;
    }
    if (password.length < 6) {
      _snack("Password must be at least 6 characters", error: true);
      return;
    }
    if (password != confirm) {
      _snack("Passwords do not match", error: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.resetPassword(
        email: widget.email,
        otp: otp,
        newPassword: password,
      );
      if (!mounted) return;

      if (result["statusCode"] == 200) {
        _snack("Password updated successfully! Please log in.");
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        _snack(
          (result["data"]?["message"] as String?) ?? "Failed to reset password",
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _snack("Network error. Please try again.", error: true);
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
                const SizedBox(height: 8),
                // ── Back ──────────────────────────────────────────────────────
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
                  child: const Icon(Icons.mark_email_read_outlined,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                Text(
                  "Check Your Email",
                  style: GoogleFonts.marcellus(fontSize: 28, color: wine),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: wine.withOpacity(0.55),
                        height: 1.55),
                    children: [
                      const TextSpan(text: "We sent a 6-digit code to\n"),
                      TextSpan(
                        text: widget.email,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: wine,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── OTP boxes ─────────────────────────────────────────────────
                Text("Reset Code",
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: wine.withOpacity(0.65))),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => _otpBox(i)),
                ),
                const SizedBox(height: 8),

                // ── Resend ────────────────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resending ? null : _resendCode,
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4)),
                    child: _resending
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: wine.withOpacity(0.6)),
                          )
                        : Text(
                            "Resend code",
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: wine),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── New password ──────────────────────────────────────────────
                Text("New Password",
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: wine.withOpacity(0.65))),
                const SizedBox(height: 8),
                _passField(
                  controller: _passwordCtrl,
                  hint: "Min. 6 characters",
                  obscure: _obscurePass,
                  onToggle: () => setState(() => _obscurePass = !_obscurePass),
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                Text("Confirm Password",
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: wine.withOpacity(0.65))),
                const SizedBox(height: 8),
                _passField(
                  controller: _confirmCtrl,
                  hint: "Re-enter password",
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  action: TextInputAction.done,
                  onSubmitted: _submit,
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
                              "Reset Password",
                              style: GoogleFonts.poppins(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── OTP single-digit box ───────────────────────────────────────────────────

  Widget _otpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _otpCtrl[index],
        focusNode: _otpFocus[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w700, color: wine),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: wine.withOpacity(0.14), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: wine, width: 1.6),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _otpFocus[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _otpFocus[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  // ── Password field ─────────────────────────────────────────────────────────

  Widget _passField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    TextInputAction action = TextInputAction.done,
    VoidCallback? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: action,
      onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
      style: GoogleFonts.poppins(
          fontSize: 14.5, fontWeight: FontWeight.w500, color: wine),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(color: wine.withOpacity(0.35), fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(Icons.lock_outline_rounded,
              color: wine.withOpacity(0.50), size: 20),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: wine.withOpacity(0.50),
            size: 20,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: wine.withOpacity(0.10), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: wine, width: 1.4),
        ),
      ),
    );
  }
}
