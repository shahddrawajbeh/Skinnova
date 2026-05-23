import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'set_new_password_screen.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key, required this.email});

  final String email;
  static const primary = Color(0xFF663F44);

  @override
  Widget build(BuildContext context) {
    final codeCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter verification code",
                style: GoogleFonts.marcellus(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "We sent a code to:\n$email",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                  color: Colors.black.withOpacity(0.45),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                "Code",
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 6,
                  color: Colors.black.withOpacity(0.75),
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "••••••",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.black.withOpacity(0.30),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 6,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: Colors.black.withOpacity(0.06)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: Colors.black.withOpacity(0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: primary, width: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: لاحقاً نتحقق من الكود
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SetNewPasswordScreen(email: email),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Verify",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: لاحقاً resend code
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Resend code (later)")),
                    );
                  },
                  child: Text(
                    "Resend code",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
