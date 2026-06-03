import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SellerStoreProfileScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  final String storeId;
  const SellerStoreProfileScreen({
    super.key,
    required this.store,
    required this.storeId,
  });

  @override
  State<SellerStoreProfileScreen> createState() =>
      _SellerStoreProfileScreenState();
}

class _SellerStoreProfileScreenState extends State<SellerStoreProfileScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late String _logoUrl;
  late String _coverUrl;

  bool _isSaving = false;
  File? _pickedLogoFile;
  File? _pickedCoverFile;
  List<String> _galleryImages = [];
  bool _galleryUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _name = TextEditingController(text: s['storeName']?.toString() ?? '');
    _description =
        TextEditingController(text: s['description']?.toString() ?? '');
    _city = TextEditingController(text: s['city']?.toString() ?? '');
    _address = TextEditingController(text: s['address']?.toString() ?? '');
    _phone = TextEditingController(text: s['phone']?.toString() ?? '');
    _logoUrl = s['logoUrl']?.toString() ?? '';
    _coverUrl = s['coverImageUrl']?.toString() ?? '';

    final rawGallery = s['galleryImages'];
    if (rawGallery is List) {
      _galleryImages = rawGallery
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _city.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  // ── Image pickers ─────────────────────────────────────────────────────────

  Future<void> _pickLogoImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    setState(() => _pickedLogoFile = File(image.path));
  }

  Future<void> _pickCoverImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() => _pickedCoverFile = File(image.path));
  }

  Future<void> _pickGalleryImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    setState(() => _galleryUploading = true);
    try {
      final url = await ApiService.addStoreGalleryImage(
        storeId: widget.storeId,
        imageFile: File(image.path),
      );
      if (url != null && mounted) {
        setState(() => _galleryImages.add(url));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image.')),
        );
      }
    } finally {
      if (mounted) setState(() => _galleryUploading = false);
    }
  }

  Future<void> _deleteGalleryImage(String url) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove Image?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('This will remove the image from your gallery.',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: grey))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Remove',
                  style: GoogleFonts.poppins(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ApiService.deleteStoreGalleryImage(
        storeId: widget.storeId, imageUrl: url);
    if (ok && mounted) setState(() => _galleryImages.remove(url));
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String logoUrl = _logoUrl;
    String coverUrl = _coverUrl;

    if (_pickedLogoFile != null) {
      final uploaded = await ApiService.uploadStoreLogo(
          storeId: widget.storeId, imageFile: _pickedLogoFile!);
      if (uploaded != null) logoUrl = uploaded;
    }

    if (_pickedCoverFile != null) {
      final uploaded = await ApiService.uploadStoreCover(
          storeId: widget.storeId, imageFile: _pickedCoverFile!);
      if (uploaded != null) coverUrl = uploaded;
    }

    final ok = await ApiService.updateStoreProfile(
      storeId: widget.storeId,
      data: {
        'storeName': _name.text.trim(),
        'description': _description.text.trim(),
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'phone': _phone.text.trim(),
        'logoUrl': logoUrl,
        'coverImageUrl': coverUrl,
      },
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Store profile updated!'),
            backgroundColor: Color(0xFF4CAF50)),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update. Try again.')),
      );
    }
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
        title: Text('Store Profile',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700, color: deepPlum)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text('Save',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: wine)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            // FIX 1: stretch ensures every child fills the available width,
            // giving its children bounded horizontal constraints.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagesCard(),
              const SizedBox(height: 16),
              _buildSection('Basic Information', [
                _field(
                  ctrl: _name,
                  label: 'Store Name',
                  icon: Icons.storefront_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Store name is required'
                      : null,
                ),
                _field(
                    ctrl: _description,
                    label: 'Description',
                    icon: Icons.notes_rounded,
                    maxLines: 3),
              ]),
              const SizedBox(height: 16),
              _buildSection('Location & Contact', [
                _field(
                  ctrl: _city,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'City is required'
                      : null,
                ),
                _field(
                    ctrl: _address,
                    label: 'Street Address',
                    icon: Icons.pin_drop_outlined),
                _field(
                    ctrl: _phone,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
              ]),
              const SizedBox(height: 16),
              _buildGallerySection(),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Save Changes',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Images card (cover + logo) ─────────────────────────────────────────────

  Widget _buildImagesCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FIX 2: Container-first approach.
          // The Container (height: 130) provides TIGHT, BOUNDED constraints
          // to the Stack. StackFit.expand then safely fills those bounds.
          // No double.infinity on any Image — the parent sizes them.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                height: 130,
                // No width needed: CrossAxisAlignment.stretch fills parent.
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCoverContent(),
                    // Edit button overlay
                    Positioned(
                      right: 10,
                      top: 10,
                      child: _buildEditChip('Edit Cover'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Logo + info row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo circle with edit button
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: wine.withOpacity(0.06),
                        border: Border.all(color: line, width: 2),
                      ),
                      child: ClipOval(child: _buildLogoContent()),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickLogoImage,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: wine,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Store Logo',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkText)),
                      const SizedBox(height: 2),
                      Text('Tap the pencil icon to change',
                          style:
                              GoogleFonts.poppins(fontSize: 11, color: grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FIX 3: No explicit width/height on Image widgets — the parent Container
  // (tight 130px) or ClipOval (tight 72px) already constrains them.
  // Widget _buildCoverContent() {
  //   if (_pickedCoverFile != null) {
  //     return Image.file(_pickedCoverFile!, fit: BoxFit.cover);
  //   }
  //   if (_coverUrl.isNotEmpty && _coverUrl.startsWith('http')) {
  //     return Image.network(
  //       _coverUrl,
  //       fit: BoxFit.cover,
  //       errorBuilder: (_, __, ___) => _coverPlaceholder(),
  //     );
  //   }
  //   return _coverPlaceholder();
  // }
  Widget _buildCoverContent() {
    if (_pickedCoverFile != null) {
      return Image.file(
        _pickedCoverFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_coverUrl.isNotEmpty) {
      if (_coverUrl.startsWith('http')) {
        return Image.network(
          _coverUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _coverPlaceholder(),
        );
      }

      return Image.asset(
        _coverUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _coverPlaceholder(),
      );
    }

    return _coverPlaceholder();
  }

  // Widget _buildLogoContent() {
  //   if (_pickedLogoFile != null) {
  //     return Image.file(_pickedLogoFile!, fit: BoxFit.cover);
  //   }
  //   if (_logoUrl.isNotEmpty && _logoUrl.startsWith('http')) {
  //     return Image.network(
  //       _logoUrl,
  //       fit: BoxFit.cover,
  //       errorBuilder: (_, __, ___) => _logoInitial(),
  //     );
  //   }
  //   return _logoInitial();
  // }
  Widget _buildLogoContent() {
    if (_pickedLogoFile != null) {
      return Image.file(_pickedLogoFile!, fit: BoxFit.cover);
    }

    if (_logoUrl.isNotEmpty) {
      if (_logoUrl.startsWith('http')) {
        return Image.network(
          _logoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _logoInitial(),
        );
      }

      return Image.asset(
        _logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _logoInitial(),
      );
    }

    return _logoInitial();
  }

  Widget _coverPlaceholder() {
    return Container(
      color: wine.withOpacity(0.06),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.panorama_outlined,
                color: wine.withOpacity(0.3), size: 32),
            const SizedBox(height: 6),
            Text('Tap to add cover photo',
                style: GoogleFonts.poppins(fontSize: 11, color: grey)),
          ],
        ),
      ),
    );
  }

  Widget _logoInitial() {
    final letter = _name.text.isNotEmpty ? _name.text[0].toUpperCase() : 'S';
    return Container(
      color: wine.withOpacity(0.06),
      child: Center(
        child: Text(letter,
            style: GoogleFonts.poppins(
                fontSize: 26, fontWeight: FontWeight.w700, color: wine)),
      ),
    );
  }

  Widget _buildEditChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Gallery section ────────────────────────────────────────────────────────

  Widget _buildGallerySection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Store Gallery',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_galleryImages.length} photo${_galleryImages.length == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(fontSize: 11, color: grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // FIX 4: GridView is inside a Column with crossAxisAlignment.stretch,
          // ensuring bounded horizontal constraints propagate correctly.
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 16) / 3;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._galleryImages.map((url) {
                    return SizedBox(
                      width: itemWidth,
                      height: itemWidth,
                      child: _buildGalleryTile(url),
                    );
                  }),
                  SizedBox(
                    width: itemWidth,
                    height: itemWidth,
                    child: _buildAddTile(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _galleryUploading ? null : _pickGalleryImage,
      child: Container(
        decoration: BoxDecoration(
          color: softBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: wine.withOpacity(0.25)),
        ),
        child: _galleryUploading
            ? const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF5B2333))))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: wine.withOpacity(0.6), size: 26),
                  const SizedBox(height: 4),
                  Text('Add Photo',
                      style: GoogleFonts.poppins(
                          fontSize: 9.5, color: wine.withOpacity(0.7))),
                ],
              ),
      ),
    );
  }

  Widget _buildGalleryTile(String url) {
    // FIX 5: Container-first (explicit borderRadius clip + bounds),
    // then Stack with StackFit.expand fills those bounds cleanly.
    // No double.infinity on Image — it inherits the tight cell size.
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: softBg,
              child: const Icon(Icons.broken_image_outlined,
                  color: Colors.grey, size: 22),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _deleteGalleryImage(url),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _buildSection(String title, List<Widget> fields) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: grey)),
          const SizedBox(height: 12),
          ...fields,
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(fontSize: 14, color: darkText),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.poppins(fontSize: 13, color: grey),
          hintStyle:
              GoogleFonts.poppins(fontSize: 13, color: grey.withOpacity(0.6)),
          prefixIcon: Icon(icon, size: 18, color: grey),
          filled: true,
          fillColor: softBg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: wine, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF44336), width: 1)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFF44336), width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
