import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';
import '../user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final UserModel user;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  File? selectedImage;
  bool isSaving = false;

  late List<String> selectedConcerns;
  late String selectedSkinType;
  late String selectedGender;
  late String selectedAgeRange;
  late String selectedSkinTone;

  // ── Lists ─────────────────────────────────────────────────────────────────
  static const _allConcerns = [
    'Acne & Blemishes',
    'Dark Circles',
    'Dryness',
    'Dark Spots',
    'Anti-Aging',
    'Hyperpigmentation',
    'Rosacea',
    'Enlarged pores',
    'Dullness',
    'Eczema',
    'Puffiness',
    'Melasma',
    'Sensitivity',
    'Uneven Texture',
    'Wrinkles',
    'Oiliness',
  ];

  static const _skinTypes = [
    'Normal',
    'Dry',
    'Oily',
    'Combination',
    'Sensitive',
  ];

  static const _genders = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];

  static const _ageRanges = [
    '13–18',
    '18–24',
    '25–34',
    '35–44',
    '45–54',
    '55+'
  ];

  static const _phototypes = [
    {
      'title': 'Pale white skin',
      'subtitle': 'Always burns, never tans',
      'color': Color(0xFFE7C9A8)
    },
    {
      'title': 'White skin',
      'subtitle': 'Burns easily, tans minimally',
      'color': Color(0xFFDDB48D)
    },
    {
      'title': 'Light brown skin',
      'subtitle': 'Sometimes burns, slowly tans',
      'color': Color(0xFFD0A47D)
    },
    {
      'title': 'Moderate brown skin',
      'subtitle': 'Burns minimally, tans easily',
      'color': Color(0xFFBF8457)
    },
    {
      'title': 'Dark brown skin',
      'subtitle': 'Rarely burns, tans well',
      'color': Color(0xFFAA6C2F)
    },
    {
      'title': 'Deep brown to black skin',
      'subtitle': 'Never burns, deeply pigmented',
      'color': Color(0xFF4B231B)
    },
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.user.fullName;
    _emailCtrl.text = widget.user.email;
    _bioCtrl.text = widget.user.bio;
    _cityCtrl.text = widget.user.city;

    selectedConcerns = List<String>.from(widget.user.onboarding.skinConcerns);
    selectedSkinType = widget.user.onboarding.skinType;
    selectedGender = widget.user.onboarding.gender;
    selectedAgeRange = widget.user.onboarding.ageRange;
    selectedSkinTone = widget.user.onboarding.skinPhototype;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => selectedImage = File(picked.path));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    setState(() => isSaving = true);

    String? imageUrl = widget.user.profileImage;
    if (selectedImage != null) {
      imageUrl = await ApiService.uploadProfileImage(
          userId: widget.userId, imageFile: selectedImage!);
    }

    final result = await ApiService.updateUserProfile(
      userId: widget.userId,
      data: {
        'fullName': name,
        'email': _emailCtrl.text.trim(),
        'profileImage': imageUrl ?? '',
        'bio': _bioCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'onboarding': {
          'skinConcerns': selectedConcerns,
          'skinType': selectedSkinType,
          'gender': selectedGender,
          'ageRange': selectedAgeRange,
          'skinPhototype': selectedSkinTone,
          'goals': widget.user.onboarding.goals,
          'skinSensitivity': widget.user.onboarding.skinSensitivity,
          'skincareExperience': widget.user.onboarding.skincareExperience,
          'chronicCondition': widget.user.onboarding.chronicCondition,
          'specialConditions': widget.user.onboarding.specialConditions,
        },
      },
    );

    if (!mounted) return;
    setState(() => isSaving = false);

    if (result['statusCode'] == 200) {
      Navigator.pop(context, true);
    } else {
      final msg = result['data']?['message'] ?? 'Failed to update profile';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: whiteSmoke,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: Colors.black54),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Edit Profile',
                          style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: darkText)),
                    ),
                  ),
                  GestureDetector(
                    onTap: isSaving ? null : _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                          color: isSaving ? grey.withOpacity(0.2) : wine,
                          borderRadius: BorderRadius.circular(12)),
                      child: isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Save',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: line),
            // ── Scrollable body ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + upload
                    _buildAvatarSection(),
                    const SizedBox(height: 28),

                    // Basic info
                    _buildGroupCard('Basic Information', [
                      _labeledField('Full Name', _nameCtrl, hint: 'Your name'),
                      const SizedBox(height: 14),
                      _labeledField('Email', _emailCtrl,
                          hint: 'your@email.com',
                          type: TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      _labeledField('Bio', _bioCtrl,
                          hint:
                              'Tell the community about your skincare journey…',
                          maxLines: 3),
                      const SizedBox(height: 14),
                      _labeledField('City', _cityCtrl,
                          hint: 'Your city', icon: Icons.location_on_outlined),
                    ]),
                    const SizedBox(height: 20),

                    // Skin type
                    _buildGroupCard('Skin Type', [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skinTypes.map((type) {
                          final selected = selectedSkinType == type;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => selectedSkinType = type),
                            child: _chip(type, selected),
                          );
                        }).toList(),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Skin concerns
                    _buildGroupCard('Skin Concerns', [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allConcerns.map((concern) {
                          final selected = selectedConcerns.contains(concern);
                          return GestureDetector(
                            onTap: () => setState(() {
                              selected
                                  ? selectedConcerns.remove(concern)
                                  : selectedConcerns.add(concern);
                            }),
                            child: _chip(concern, selected),
                          );
                        }).toList(),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Personal info
                    _buildGroupCard('Personal Info (private)', [
                      _buildLabel('Gender'),
                      const SizedBox(height: 10),
                      _buildDropdown(
                        value: selectedGender,
                        items: _genders,
                        onChanged: (v) => setState(
                            () => selectedGender = v ?? selectedGender),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Age Range'),
                      const SizedBox(height: 10),
                      _buildDropdown(
                        value: selectedAgeRange,
                        items: _ageRanges,
                        onChanged: (v) => setState(
                            () => selectedAgeRange = v ?? selectedAgeRange),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Skin tone
                    _buildGroupCard('Skin Tone / Phototype', [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ..._phototypes.map((p) {
                            final title = p['title'] as String;
                            final selected = selectedSkinTone == title;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => selectedSkinTone = title),
                              child: Tooltip(
                                message: '${p['title']}\n${p['subtitle']}',
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: p['color'] as Color,
                                    border: Border.all(
                                      color: selected ? wine : Colors.white,
                                      width: selected ? 3 : 2,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                                color: wine.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2))
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          GestureDetector(
                            onTap: () => setState(
                                () => selectedSkinTone = 'Prefer not to say'),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: whiteSmoke,
                                border: Border.all(
                                  color: selectedSkinTone == 'Prefer not to say'
                                      ? wine
                                      : line,
                                  width: selectedSkinTone == 'Prefer not to say'
                                      ? 3
                                      : 1.5,
                                ),
                              ),
                              child: const Icon(Icons.help_outline_rounded,
                                  color: Colors.grey, size: 22),
                            ),
                          ),
                        ],
                      ),
                      if (selectedSkinTone.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(selectedSkinTone,
                            style:
                                GoogleFonts.poppins(fontSize: 12, color: grey)),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar section ────────────────────────────────────────────────────────
  Widget _buildAvatarSection() {
    final hasImage =
        selectedImage != null || (widget.user.profileImage?.isNotEmpty == true);

    return Row(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFFE8E5E2)),
                child: ClipOval(
                  child: selectedImage != null
                      ? Image.file(selectedImage!, fit: BoxFit.cover)
                      : (widget.user.profileImage?.isNotEmpty == true)
                          ? Image.network(widget.user.profileImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _avatarInitial())
                          : _avatarInitial(),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      color: wine,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile Photo',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkText)),
            const SizedBox(height: 4),
            Text('Tap photo to change',
                style: GoogleFonts.poppins(fontSize: 12, color: grey)),
          ],
        ),
      ],
    );
  }

  Widget _avatarInitial() {
    return Center(
      child: Text(
        widget.user.fullName.isNotEmpty
            ? widget.user.fullName[0].toUpperCase()
            : '?',
        style: GoogleFonts.poppins(
            fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  // ── Shared form widgets ───────────────────────────────────────────────────
  Widget _buildGroupCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: grey,
                  letterSpacing: 0.3)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600, color: darkText));
  }

  Widget _labeledField(String label, TextEditingController ctrl,
      {String? hint, int maxLines = 1, TextInputType? type, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: type,
          style: GoogleFonts.poppins(fontSize: 14, color: darkText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
            prefixIcon: icon != null ? Icon(icon, size: 18, color: grey) : null,
            filled: true,
            fillColor: whiteSmoke,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Widget _chip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? wine : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? wine : line),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : darkText)),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: whiteSmoke, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: Colors.grey),
          hint: Text('Select',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade400)),
          style: GoogleFonts.poppins(fontSize: 14, color: darkText),
          items: items
              .map((i) => DropdownMenuItem(
                  value: i,
                  child: Text(i,
                      style:
                          GoogleFonts.poppins(fontSize: 14, color: darkText))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
