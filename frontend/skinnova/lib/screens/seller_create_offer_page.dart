import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class SellerCreateOfferPage extends StatefulWidget {
  const SellerCreateOfferPage({super.key});

  @override
  State<SellerCreateOfferPage> createState() => _SellerCreateOfferPageState();
}

class _SellerCreateOfferPageState extends State<SellerCreateOfferPage> {
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);

  final titleController = TextEditingController();
  final subtitleController = TextEditingController();
  final buttonController = TextEditingController(text: "Shop now");
  final imageController = TextEditingController();

  bool isSaving = false;

  Future<void> _submitOffer() async {
    if (titleController.text.trim().isEmpty ||
        subtitleController.text.trim().isEmpty ||
        imageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isSaving = true);

    // هون بعدين بنربطها بالـ ApiService
    final result = await ApiService.createAdOffer(
      title: titleController.text.trim(),
      subtitle: subtitleController.text.trim(),
      imageUrl: imageController.text.trim(),
      buttonText: buttonController.text.trim(),
    );

    if (result["statusCode"] != 201) {
      throw Exception(result["data"]["message"] ?? "Failed to create offer");
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Offer sent for admin approval")),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: softBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: wine),
        centerTitle: true,
        title: Text(
          "New Offer",
          style: GoogleFonts.poppins(
            color: wine,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _field(titleController, "Offer title", Icons.local_offer_outlined),
            const SizedBox(height: 14),
            _field(
                subtitleController, "Short description", Icons.notes_rounded),
            const SizedBox(height: 14),
            _field(imageController, "Image URL", Icons.image_outlined),
            const SizedBox(height: 14),
            _field(buttonController, "Button text", Icons.smart_button_rounded),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isSaving ? null : _submitOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: wine,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Submit for Approval",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      maxLines: hint == "Short description" ? 3 : 1,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: wine),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
