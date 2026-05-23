import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'gender_screen.dart';
import 'main_navigation_screen.dart';
import '../api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_home_screen.dart';
import 'seller_home_screen.dart';

class AuthPopup extends StatefulWidget {
  const AuthPopup({super.key});

  @override
  State<AuthPopup> createState() => _AuthPopupState();
}

class _AuthPopupState extends State<AuthPopup> {
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color wine = Color(0xFF5B2333);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final signupNameController = TextEditingController();
  final signupEmailController = TextEditingController();
  final signupPasswordController = TextEditingController();

  bool obscure = true;
  bool isLogin = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    signupNameController.dispose();
    signupEmailController.dispose();
    signupPasswordController.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: wine.withOpacity(0.42),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: wine.withOpacity(0.72), size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: wine.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: wine, width: 1.2),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.loginUser(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result["statusCode"] == 200) {
        final prefs = await SharedPreferences.getInstance();

        final userId = result["data"]["userId"];
        final role = result["data"]["role"] ?? "user";
        final userName = result["data"]["fullName"] ?? "Anonymous";

        await prefs.setString("userId", userId);
        await prefs.setString("role", role);
        await prefs.setString("userName", userName);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful")),
        );

        if (!mounted) return;

        if (role == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminHomeScreen(),
            ),
          );
        } else if (role == "saller") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SellerHomeScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainNavigationScreen(
                userId: userId,
                userName: userName,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["data"]["message"] ?? "Login failed"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleSignup(BuildContext context) async {
    final fullName = signupNameController.text.trim();
    final email = signupEmailController.text.trim();
    final password = signupPasswordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.registerUser(
        fullName: fullName,
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result["statusCode"] == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("userId", result["data"]["userId"]);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GenderScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["data"]["message"] ?? "Signup failed"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Container(
                width: size.width,
                constraints: const BoxConstraints(maxWidth: 430),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  color: whiteSmoke,
                  border: Border.all(
                    color: wine.withOpacity(0.10),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: wine.withOpacity(0.08),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: wine.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: wine.withOpacity(0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: wine.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: wine.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: wine.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isLogin = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOut,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isLogin ? wine : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Login',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: isLogin
                                        ? whiteSmoke
                                        : wine.withOpacity(0.72),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isLogin = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOut,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !isLogin ? wine : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Sign Up',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: !isLogin
                                        ? whiteSmoke
                                        : wine.withOpacity(0.72),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: isLogin
                          ? _LoginContent(
                              key: const ValueKey('login'),
                              wine: wine,
                              whiteSmoke: whiteSmoke,
                              emailController: emailController,
                              passwordController: passwordController,
                              obscure: obscure,
                              isLoading: isLoading,
                              onToggleObscure: () {
                                setState(() => obscure = !obscure);
                              },
                              onLoginPressed: () => _handleLogin(context),
                              fieldDecoration: fieldDecoration,
                            )
                          : _SignupContent(
                              key: const ValueKey('signup'),
                              wine: wine,
                              whiteSmoke: whiteSmoke,
                              nameController: signupNameController,
                              emailController: signupEmailController,
                              passwordController: signupPasswordController,
                              isLoading: isLoading,
                              onSignupPressed: () => _handleSignup(context),
                              fieldDecoration: fieldDecoration,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  final Color wine;
  final Color whiteSmoke;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscure;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onLoginPressed;
  final InputDecoration Function({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) fieldDecoration;

  const _LoginContent({
    super.key,
    required this.wine,
    required this.whiteSmoke,
    required this.emailController,
    required this.passwordController,
    required this.obscure,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onLoginPressed,
    required this.fieldDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: GoogleFonts.marcellus(
            fontSize: 31,
            color: wine,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Log in to continue your skincare journey',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            color: wine.withOpacity(0.9),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(
            color: wine,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: fieldDecoration(
            hint: 'Email',
            icon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: obscure,
          style: GoogleFonts.poppins(
            color: wine,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: fieldDecoration(
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscure
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: wine.withOpacity(0.72),
                size: 21,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen(),
                ),
              );
            },
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.poppins(
                color: wine,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: isLoading ? null : onLoginPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: wine,
              foregroundColor: whiteSmoke,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Login',
                    style: GoogleFonts.poppins(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: wine.withOpacity(0.12),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: GoogleFonts.poppins(
                  color: wine.withOpacity(0.42),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: wine.withOpacity(0.12),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(
                color: wine.withOpacity(0.12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: Text(
              'Continue with Google',
              style: GoogleFonts.poppins(
                color: wine,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignupContent extends StatelessWidget {
  final Color wine;
  final Color whiteSmoke;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSignupPressed;
  final InputDecoration Function({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) fieldDecoration;

  const _SignupContent({
    super.key,
    required this.wine,
    required this.whiteSmoke,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSignupPressed,
    required this.fieldDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Create Account',
          style: GoogleFonts.marcellus(
            fontSize: 31,
            color: wine,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join Skinova and start your personalized skincare journey',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            color: wine.withOpacity(0.62),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: nameController,
          style: GoogleFonts.poppins(
            color: wine,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: fieldDecoration(
            hint: 'Full Name',
            icon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(
            color: wine,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: fieldDecoration(
            hint: 'Email',
            icon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: true,
          style: GoogleFonts.poppins(
            color: wine,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: fieldDecoration(
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSignupPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: wine,
              foregroundColor: whiteSmoke,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Create Account',
                    style: GoogleFonts.poppins(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
