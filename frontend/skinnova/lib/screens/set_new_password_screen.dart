import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key, required this.email});
  final String email;

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  static const primary = Color(0xFF81A6C6);

  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;

  @override
  void dispose() {
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                "Set new password",
                style: GoogleFonts.marcellus(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Create strong and secured\nnew password.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                  color: Colors.black.withOpacity(0.45),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                "Password",
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 8),
              _Field(
                controller: passCtrl,
                hint: "••••••••",
                obscureText: obscure1,
                onToggle: () => setState(() => obscure1 = !obscure1),
              ),
              const SizedBox(height: 14),
              Text(
                "Confirm Password",
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 8),
              _Field(
                controller: confirmCtrl,
                hint: "••••••••",
                obscureText: obscure2,
                onToggle: () => setState(() => obscure2 = !obscure2),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (passCtrl.text != confirmCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Passwords do not match")),
                      );
                      return;
                    }
                    // TODO: لاحقاً نحفظ الباسورد بالباكند
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password saved (later)")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF663F44), // زي الصورة disabled
                    foregroundColor: Colors.black.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Save Password",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                      color:
                          Color.fromARGB(255, 241, 233, 233).withOpacity(0.55),
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final VoidCallback onToggle;

  static const primary = Color(0xFF663F44);

  const _Field({
    required this.controller,
    required this.hint,
    required this.obscureText,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.poppins(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: Colors.black.withOpacity(0.78),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.black.withOpacity(0.35),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.black.withOpacity(0.45),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withOpacity(0.35), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withOpacity(0.35), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),
    );
  }
}
