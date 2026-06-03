import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'forgot_password_screen.dart';
import 'gender_screen.dart';
import 'main_navigation_screen.dart';
import '../api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_home_screen.dart';
import 'seller_home_screen.dart';
import '../services/notification_service.dart';

// ── Google Sign-In configuration ──────────────────────────────────────────────
// Replace this with your Web Client ID from:
// Firebase Console → Authentication → Sign-in method → Google → Web SDK configuration
const String _kGoogleWebClientId =
    '33497603516-cfjh3vrnl1kb8uorpeb5p7l1025nbpp8.apps.googleusercontent.com';

// ─────────────────────────────────────────────────────────────────────────────
// AuthPopup — modern skincare-style login / sign-up modal
// ─────────────────────────────────────────────────────────────────────────────

class AuthPopup extends StatefulWidget {
  const AuthPopup({super.key});

  @override
  State<AuthPopup> createState() => _AuthPopupState();
}

class _AuthPopupState extends State<AuthPopup> {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color wineLight = Color(0xFF7A3346);
  static const Color cream = Color(0xFFF7F4F3);
  static const Color softBg = Color(0xFFFAF8F7);

  // ── Controllers ────────────────────────────────────────────────────────────
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  final _signupNameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _kGoogleWebClientId,
  );

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  bool _isValidEmail(String email) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(email);

  // ── Snackbar ───────────────────────────────────────────────────────────────

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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Shared navigation helper ───────────────────────────────────────────────

  void _navigateByRole(String role, String userId, String userName) {
    if (role == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    } else if (role == "saller") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellerHomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MainNavigationScreen(userId: userId, userName: userName),
        ),
      );
    }
  }

  // ── Google Sign-In handler ─────────────────────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) return; // User cancelled

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        _snack("Google sign-in failed. Please try again.", error: true);
        return;
      }

      final result = await ApiService.loginWithGoogle(idToken);
      if (!mounted) return;

      if (result["statusCode"] == 200) {
        final prefs = await SharedPreferences.getInstance();
        final userId = result["data"]["userId"].toString();
        final role = (result["data"]["role"] as String?) ?? "user";
        final userName = (result["data"]["fullName"] as String?) ?? "User";

        await prefs.setString("userId", userId);
        await prefs.setString("role", role);
        await prefs.setString("userName", userName);

        try {
          await NotificationService().saveTokenForUser(userId);
        } catch (_) {}

        if (!mounted) return;
        _navigateByRole(role, userId, userName);
      } else {
        final msg =
            (result["data"]?["message"] as String?) ?? "Google sign-in failed";
        _snack(msg, error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _snack("Google sign-in failed. Please try again.", error: true);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ── Login handler ──────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final password = _loginPasswordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _snack("Please enter your email and password", error: true);
      return;
    }
    if (!_isValidEmail(email)) {
      _snack("Please enter a valid email address", error: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result =
          await ApiService.loginUser(email: email, password: password);
      if (!mounted) return;

      if (result["statusCode"] == 200) {
        final prefs = await SharedPreferences.getInstance();
        final userId = result["data"]["userId"] as String;
        final role = (result["data"]["role"] as String?) ?? "user";
        final userName = (result["data"]["fullName"] as String?) ?? "User";

        await prefs.setString("userId", userId);
        await prefs.setString("role", role);
        await prefs.setString("userName", userName);

        try {
          await NotificationService().saveTokenForUser(userId);
        } catch (_) {}

        if (!mounted) return;
        _navigateByRole(role, userId, userName);
      } else {
        final msg = (result["data"]?["message"] as String?) ?? "Login failed";
        _snack(msg, error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _snack("Something went wrong. Please try again.", error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Signup handler ─────────────────────────────────────────────────────────

  Future<void> _handleSignup() async {
    final fullName = _signupNameCtrl.text.trim();
    final email = _signupEmailCtrl.text.trim();
    final password = _signupPasswordCtrl.text;

    if (fullName.isEmpty) {
      _snack("Please enter your full name", error: true);
      return;
    }
    if (email.isEmpty) {
      _snack("Please enter your email address", error: true);
      return;
    }
    if (!_isValidEmail(email)) {
      _snack("Please enter a valid email address", error: true);
      return;
    }
    if (password.length < 6) {
      _snack("Password must be at least 6 characters", error: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final appSettings = await ApiService.getPublicSettings();
      if (appSettings['allowNewRegistrations'] == false) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _snack("New registrations are currently disabled.", error: true);
        return;
      }

      final result = await ApiService.registerUser(
        fullName: fullName,
        email: email,
        password: password,
      );
      if (!mounted) return;

      if (result["statusCode"] == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("userId", result["data"]["userId"] as String);
        await prefs.setString("userName", fullName);
        await prefs.setString("role", "user");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GenderScreen()),
        );
      } else {
        final msg = (result["data"]?["message"] as String?) ?? "Signup failed";
        _snack(msg, error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _snack("Something went wrong. Please try again.", error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: _buildCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: wine.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: wine.withOpacity(0.12),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gradient header strip ──────────────────────────────────────
            Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5B2333), Color(0xFF9B4A60)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top row: drag handle + close ─────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: wine.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const Spacer(),
                      _closeButton(),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── Brand logo ────────────────────────────────────────────
                  _buildLogo(),
                  const SizedBox(height: 22),

                  // ── Segmented tab switch ──────────────────────────────────
                  _buildTabSwitch(),
                  const SizedBox(height: 26),

                  // ── Animated form content ─────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.03, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _isLogin
                        ? _LoginForm(
                            key: const ValueKey('login'),
                            wine: wine,
                            softBg: softBg,
                            emailCtrl: _loginEmailCtrl,
                            passwordCtrl: _loginPasswordCtrl,
                            isLoading: _isLoading,
                            onLogin: _handleLogin,
                            isGoogleLoading: _isGoogleLoading,
                            onGoogleSignIn: _handleGoogleSignIn,
                          )
                        : _SignupForm(
                            key: const ValueKey('signup'),
                            wine: wine,
                            softBg: softBg,
                            nameCtrl: _signupNameCtrl,
                            emailCtrl: _signupEmailCtrl,
                            passwordCtrl: _signupPasswordCtrl,
                            isLoading: _isLoading,
                            onSignup: _handleSignup,
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

  Widget _closeButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: wine.withOpacity(0.07),
          shape: BoxShape.circle,
          border: Border.all(color: wine.withOpacity(0.10)),
        ),
        child:
            Icon(Icons.close_rounded, size: 17, color: wine.withOpacity(0.80)),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5B2333), Color(0xFF8B3A52)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: wine.withOpacity(0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.spa_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          "Skinova",
          style: GoogleFonts.marcellus(
            fontSize: 22,
            color: wine,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Your personal skincare companion",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: wine.withOpacity(0.50),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: wine.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: wine.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          _tabItem("Login",
              isSelected: _isLogin,
              onTap: () => setState(() => _isLogin = true)),
          _tabItem("Sign Up",
              isSelected: !_isLogin,
              onTap: () => setState(() => _isLogin = false)),
        ],
      ),
    );
  }

  Widget _tabItem(String label,
      {required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? wine : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: wine.withOpacity(0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : wine.withOpacity(0.60),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration _fieldDec({
  required String hint,
  required IconData icon,
  required Color wine,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(color: wine.withOpacity(0.38), fontSize: 14),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(icon, color: wine.withOpacity(0.55), size: 20),
    ),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: wine.withOpacity(0.10), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: wine, width: 1.4),
    ),
  );
}

Widget _primaryButton({
  required String label,
  required bool isLoading,
  required VoidCallback onTap,
  required Color wine,
}) {
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: isLoading
            ? null
            : const LinearGradient(
                colors: [Color(0xFF5B2333), Color(0xFF7A3346)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isLoading ? const Color(0xFFCBB0B8) : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF5B2333).withOpacity(0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: Colors.white),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2),
              ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Login Form
// ─────────────────────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  final Color wine;
  final Color softBg;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool isLoading;
  final VoidCallback onLogin;
  final bool isGoogleLoading;
  final VoidCallback onGoogleSignIn;

  const _LoginForm({
    super.key,
    required this.wine,
    required this.softBg,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.isLoading,
    required this.onLogin,
    required this.isGoogleLoading,
    required this.onGoogleSignIn,
  });

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final wine = widget.wine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Heading ──────────────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              Text(
                "Welcome Back",
                style: GoogleFonts.marcellus(fontSize: 28, color: wine),
              ),
              const SizedBox(height: 6),
              Text(
                "Log in to continue your skincare journey",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: wine.withOpacity(0.55),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),

        // ── Email ─────────────────────────────────────────────────────────────
        TextField(
          controller: widget.emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.poppins(
              fontSize: 14.5, fontWeight: FontWeight.w500, color: wine),
          decoration: _fieldDec(
            hint: "Email address",
            icon: Icons.mail_outline_rounded,
            wine: wine,
          ),
        ),
        const SizedBox(height: 14),

        // ── Password ──────────────────────────────────────────────────────────
        TextField(
          controller: widget.passwordCtrl,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => widget.onLogin(),
          style: GoogleFonts.poppins(
              fontSize: 14.5, fontWeight: FontWeight.w500, color: wine),
          decoration: _fieldDec(
            hint: "Password",
            icon: Icons.lock_outline_rounded,
            wine: wine,
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: wine.withOpacity(0.50),
                size: 20,
              ),
            ),
          ),
        ),

        // ── Forgot password ───────────────────────────────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            ),
            style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6)),
            child: Text(
              "Forgot password?",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: wine,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // ── Login button ──────────────────────────────────────────────────────
        _primaryButton(
          label: "Login",
          isLoading: widget.isLoading,
          onTap: widget.onLogin,
          wine: wine,
        ),
        const SizedBox(height: 20),

        // ── Divider ───────────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
                child: Divider(color: wine.withOpacity(0.10), thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text("or",
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, color: wine.withOpacity(0.40))),
            ),
            Expanded(
                child: Divider(color: wine.withOpacity(0.10), thickness: 1)),
          ],
        ),
        const SizedBox(height: 20),

        // ── Google button ─────────────────────────────────────────────────────
        _googleButton(
          wine,
          isLoading: widget.isGoogleLoading,
          onTap: widget.onGoogleSignIn,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign-up Form
// ─────────────────────────────────────────────────────────────────────────────

class _SignupForm extends StatefulWidget {
  final Color wine;
  final Color softBg;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool isLoading;
  final VoidCallback onSignup;

  const _SignupForm({
    super.key,
    required this.wine,
    required this.softBg,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.isLoading,
    required this.onSignup,
  });

  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final wine = widget.wine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Heading ───────────────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              Text(
                "Create Account",
                style: GoogleFonts.marcellus(fontSize: 28, color: wine),
              ),
              const SizedBox(height: 6),
              Text(
                "Join Skinova and start your personalized skincare journey",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: wine.withOpacity(0.55),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),

        // ── Full name ─────────────────────────────────────────────────────────
        TextField(
          controller: widget.nameCtrl,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.poppins(
              fontSize: 14.5, fontWeight: FontWeight.w500, color: wine),
          decoration: _fieldDec(
            hint: "Full name",
            icon: Icons.person_outline_rounded,
            wine: wine,
          ),
        ),
        const SizedBox(height: 14),

        // ── Email ─────────────────────────────────────────────────────────────
        TextField(
          controller: widget.emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.poppins(
              fontSize: 14.5, fontWeight: FontWeight.w500, color: wine),
          decoration: _fieldDec(
            hint: "Email address",
            icon: Icons.mail_outline_rounded,
            wine: wine,
          ),
        ),
        const SizedBox(height: 14),

        // ── Password ──────────────────────────────────────────────────────────
        TextField(
          controller: widget.passwordCtrl,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => widget.onSignup(),
          style: GoogleFonts.poppins(
              fontSize: 14.5, fontWeight: FontWeight.w500, color: wine),
          decoration: _fieldDec(
            hint: "Password (min. 6 characters)",
            icon: Icons.lock_outline_rounded,
            wine: wine,
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: wine.withOpacity(0.50),
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // ── Sign up button ────────────────────────────────────────────────────
        _primaryButton(
          label: "Create Account",
          isLoading: widget.isLoading,
          onTap: widget.onSignup,
          wine: wine,
        ),
        const SizedBox(height: 18),

        // ── Terms note ────────────────────────────────────────────────────────
        Center(
          child: Text(
            "By signing up you agree to our Terms & Privacy Policy",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: wine.withOpacity(0.38),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google button (shared)
// ─────────────────────────────────────────────────────────────────────────────

Widget _googleButton(
  Color wine, {
  required bool isLoading,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: OutlinedButton(
      onPressed: isLoading ? null : onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        disabledBackgroundColor: Colors.white,
        side: BorderSide(color: wine.withOpacity(0.12), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: wine.withOpacity(0.60)),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google multicolour "G"
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CustomPaint(painter: _GoogleGPainter()),
                ),
                const SizedBox(width: 10),
                Text(
                  "Continue with Google",
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: wine.withOpacity(0.75),
                  ),
                ),
              ],
            ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Google multicolour "G" icon drawn with CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);

    // Four-quadrant Google colours as arcs
    const colors = [
      Color(0xFF4285F4), // blue — top-right
      Color(0xFF34A853), // green — bottom-right
      Color(0xFFFBBC05), // yellow — bottom-left
      Color(0xFFEA4335), // red — top-left
    ];

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.16
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius * 0.72);

    for (var i = 0; i < 4; i++) {
      arcPaint.color = colors[i];
      canvas.drawArc(
        rect,
        -3.14159 / 2 + i * 3.14159 / 2, // start
        3.14159 / 2 - 0.08, // sweep (slight gap)
        false,
        arcPaint,
      );
    }

    // White horizontal bar (the crossbar of "G")
    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.18, center.dy),
        width: radius * 0.78,
        height: size.height * 0.18,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
