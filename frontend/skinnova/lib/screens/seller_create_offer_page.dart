import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

class SellerCreateOfferPage extends StatefulWidget {
  const SellerCreateOfferPage({super.key});

  @override
  State<SellerCreateOfferPage> createState() => _SellerCreateOfferPageState();
}

class _SellerCreateOfferPageState extends State<SellerCreateOfferPage> {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  // ── Controllers ───────────────────────────────────────────────────────────
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _buttonText = TextEditingController(text: 'Shop Now');

  // ── State ─────────────────────────────────────────────────────────────────
  File? _pickedImage;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Rebuild preview whenever text changes
    _title.addListener(_rebuild);
    _subtitle.addListener(_rebuild);
    _buttonText.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _title.removeListener(_rebuild);
    _subtitle.removeListener(_rebuild);
    _buttonText.removeListener(_rebuild);
    _title.dispose();
    _subtitle.dispose();
    _buttonText.dispose();
    super.dispose();
  }

  // ── Image picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() => _pickedImage = File(image.path));
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final title = _title.text.trim();
    final sub = _subtitle.text.trim();
    final btn = _buttonText.text.trim();

    if (title.isEmpty || sub.isEmpty || btn.isEmpty) {
      _snack('Please fill in all fields.', isError: true);
      return;
    }
    if (_pickedImage == null) {
      _snack('Please select a banner image.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    // 1. Upload image
    final imageUrl = await ApiService.uploadAdImage(_pickedImage!);
    if (!mounted) return;

    if (imageUrl == null) {
      setState(() => _isSaving = false);
      _snack('Image upload failed. Please try again.', isError: true);
      return;
    }

    // 2. Create offer
    final result = await ApiService.createAdOffer(
      title: title,
      subtitle: sub,
      imageUrl: imageUrl,
      buttonText: btn,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['statusCode'] == 201) {
      _snack('Offer submitted! Awaiting admin approval.');
      Navigator.pop(context, true);
    } else {
      final msg = result['data']?['message'] ?? 'Failed to submit offer.';
      _snack(msg, isError: true);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: warmCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: deepPlum, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create Offer',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700, color: deepPlum)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Live preview ───────────────────────────────────────────────
            _buildSectionLabel('Offer Preview'),
            const SizedBox(height: 10),
            _buildPreviewCard(),
            const SizedBox(height: 22),

            // ── Banner image ───────────────────────────────────────────────
            _buildSectionLabel('Banner Image'),
            const SizedBox(height: 10),
            _buildImagePicker(),
            const SizedBox(height: 22),

            // ── Offer details ──────────────────────────────────────────────
            _buildSectionLabel('Offer Details'),
            const SizedBox(height: 10),
            _buildDetailsCard(),
            const SizedBox(height: 22),

            // ── Approval notice ────────────────────────────────────────────
            _buildApprovalNotice(),
            const SizedBox(height: 24),

            // ── Submit button ──────────────────────────────────────────────
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600, color: grey));
  }

  // ── Live preview card ──────────────────────────────────────────────────────

  Widget _buildPreviewCard() {
    final title = _title.text.trim();
    final sub = _subtitle.text.trim();
    final btn = _buttonText.text.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 2.2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: picked image or gradient placeholder
            _pickedImage != null
                ? Image.file(_pickedImage!, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [deepPlum, wine, Color(0xFF8B3A50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.72),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.3, 1.0],
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.isEmpty ? 'Your Offer Title' : title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(sub,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Text(
                        btn.isEmpty ? 'Shop Now' : btn,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: wine,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Preview badge
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('PREVIEW',
                    style: GoogleFonts.poppins(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image picker section ───────────────────────────────────────────────────

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _isSaving ? null : _pickImage,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _pickedImage != null
            ? _buildPickedImageView()
            : _buildEmptyImageView(),
      ),
    );
  }

  Widget _buildPickedImageView() {
    return Stack(
      key: const ValueKey('picked'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 2.2,
            child: Image.file(_pickedImage!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text('Change Image',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyImageView() {
    return Container(
      key: const ValueKey('empty'),
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: wine.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: wine.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_photo_alternate_outlined,
                color: wine.withOpacity(0.7), size: 26),
          ),
          const SizedBox(height: 12),
          Text('Tap to add banner image',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: darkText)),
          const SizedBox(height: 3),
          Text('Recommended ratio: 2.2:1 (wide banner)',
              style: GoogleFonts.poppins(fontSize: 10.5, color: grey)),
        ],
      ),
    );
  }

  // ── Details card ───────────────────────────────────────────────────────────

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          _field(
            ctrl: _title,
            label: 'Offer Title',
            hint: 'e.g. Summer Glow Sale',
            icon: Icons.local_offer_outlined,
          ),
          const SizedBox(height: 12),
          _field(
            ctrl: _subtitle,
            label: 'Short Description',
            hint: 'e.g. Up to 30% off on all serums',
            icon: Icons.notes_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _field(
            ctrl: _buttonText,
            label: 'Button Text',
            hint: 'e.g. Shop Now, Discover More',
            icon: Icons.smart_button_outlined,
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14, color: darkText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: grey),
        hintStyle:
            GoogleFonts.poppins(fontSize: 12.5, color: grey.withOpacity(0.6)),
        prefixIcon: Icon(icon, size: 18, color: grey),
        filled: true,
        fillColor: softBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: wine, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  // ── Approval notice ────────────────────────────────────────────────────────

  Widget _buildApprovalNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: wine.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: wine.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: wine.withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pending Admin Approval',
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: wine)),
                const SizedBox(height: 3),
                Text(
                  'Your offer will be reviewed before it appears in the app. This usually takes up to 24 hours.',
                  style: GoogleFonts.poppins(fontSize: 11, color: grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit button ──────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: wine,
          foregroundColor: Colors.white,
          disabledBackgroundColor: wine.withOpacity(0.5),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: wine.withOpacity(0.4),
        ),
        child: _isSaving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                  const SizedBox(width: 12),
                  Text('Submitting…',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Submit for Approval',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
