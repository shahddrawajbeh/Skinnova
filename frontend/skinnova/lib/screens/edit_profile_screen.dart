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
  static const Color textDark = Color(0xFF202124);
  static const Color lightBorder = Color(0xFFEAEAEA);
  static const Color softBlue = Color(0xFFF7F4F3);
  static const Color accentBlue = Color(0xFF5B2333);

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  File? selectedImage;
  bool isSaving = false;

  late List<String> selectedConcerns;
  late String selectedGender;
  late String selectedAgeRange;
  late String selectedSkinTone;
  late String selectedSkinType;

  final List<String> allConcerns = [
    "Acne & Blemishes",
    "Dark Circles",
    "Dryness",
    "Dark Spots",
    "Anti-Aging",
    "Hyperpigmentation",
    "Rosacea",
    "Enlarged pores",
    "Dullness",
    "Eczema",
    "Puffiness",
    "Melasma",
  ];
  final List<String> skinTypes = [
    "Normal Skin",
    "Dry Skin",
    "Oily Skin",
    "Combination Skin",
  ];
  final List<String> genders = ["Female", "Male"];
  final List<String> ageRanges = [
    "13–18",
    "18–24",
    "25–34",
    "35–44",
    "45–54",
    "55+"
  ];

  final List<Map<String, dynamic>> phototypes = [
    {
      "title": "Pale white skin",
      "subtitle": "Always burns, never tans",
      "color": const Color(0xFFE7C9A8),
    },
    {
      "title": "White skin",
      "subtitle": "Burns easily, tans minimally",
      "color": const Color(0xFFDDB48D),
    },
    {
      "title": "Light brown skin",
      "subtitle": "Sometimes burns, slowly tans",
      "color": const Color(0xFFD0A47D),
    },
    {
      "title": "Moderate brown skin",
      "subtitle": "Burns minimally, tans easily",
      "color": const Color(0xFFBF8457),
    },
    {
      "title": "Dark brown skin",
      "subtitle": "Rarely burns, tans well",
      "color": const Color(0xFFAA6C2F),
    },
    {
      "title": "Deep brown to black skin",
      "subtitle": "Never burns, deeply pigmented",
      "color": const Color(0xFF4B231B),
    },
    {
      "title": "Prefer not to say",
      "subtitle": "",
      "icon": Icons.help_outline_rounded,
      "isPreferNot": true,
    },
  ];

  @override
  void initState() {
    super.initState();

    fullNameController.text = widget.user.fullName;
    emailController.text = widget.user.email;

    selectedConcerns = List<String>.from(widget.user.onboarding.skinConcerns);
    selectedGender = widget.user.onboarding.gender;
    selectedAgeRange = widget.user.onboarding.ageRange;
    selectedSkinTone = widget.user.onboarding.skinPhototype;
    selectedSkinType = widget.user.onboarding.skinType;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> saveProfile() async {
    setState(() {
      isSaving = true;
    });

    String? uploadedImageUrl = widget.user.profileImage;

    if (selectedImage != null) {
      uploadedImageUrl = await ApiService.uploadProfileImage(
        userId: widget.userId,
        imageFile: selectedImage!,
      );
    }

    final result = await ApiService.updateUserProfile(
      userId: widget.userId,
      data: {
        "fullName": fullNameController.text.trim(),
        "email": emailController.text.trim(),
        "profileImage": uploadedImageUrl ?? "",
        "onboarding": {
          "skinConcerns": selectedConcerns,
          "goals": widget.user.onboarding.goals,
          "specialConditions": widget.user.onboarding.specialConditions,
          "gender": selectedGender,
          "ageRange": selectedAgeRange,
          "skinType": selectedSkinType,
          "skinSensitivity": widget.user.onboarding.skinSensitivity,
          "skinPhototype": selectedSkinTone,
          "skincareExperience": widget.user.onboarding.skincareExperience,
          "chronicCondition": widget.user.onboarding.chronicCondition,
        }
      },
    );

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    if (result["statusCode"] == 200) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile")),
      );
    }
  }

  Widget buildTag(String label) {
    final selected = selectedConcerns.contains(label);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            selectedConcerns.remove(label);
          } else {
            selectedConcerns.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: lightBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: textDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF2F2F2F),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInput({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textDark,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget buildTextField(TextEditingController controller, {String? hint}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lightBorder),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(fontSize: 16, color: textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
      ),
    );
  }

  Widget buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lightBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          isExpanded: true,
          hint: Text(
            "Select",
            style: GoogleFonts.poppins(color: Colors.grey.shade400),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: GoogleFonts.poppins()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Color getSkinToneColor(String tone) {
    switch (tone) {
      case "White skin":
        return const Color(0xFFE9C9A5);
      case "Fair skin":
        return const Color(0xFFE2B48C);
      case "Light brown skin":
        return const Color(0xFFD19A6E);
      case "Medium brown skin":
        return const Color(0xFFC17E4C);
      case "Brown skin":
        return const Color(0xFFB56A25);
      case "Dark brown skin":
        return const Color(0xFF5A251C);
      default:
        return const Color(0xFFE9C9A5);
    }
  }

  Widget buildSkinToneCircle(Map<String, dynamic> phototype) {
    final String title = phototype["title"];
    final bool selected = selectedSkinTone == title;
    final bool isPreferNot = phototype["isPreferNot"] == true;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSkinTone = title;
        });
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPreferNot ? Colors.white : phototype["color"],
          border: Border.all(
            color: selected ? accentBlue : const Color(0xFFE5E5E5),
            width: selected ? 3 : 1.5,
          ),
        ),
        child: isPreferNot
            ? const Icon(
                Icons.help_outline_rounded,
                color: Colors.grey,
                size: 24,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = selectedImage != null
        ? Image.file(selectedImage!, fit: BoxFit.cover)
        : (widget.user.profileImage != null &&
                widget.user.profileImage!.isNotEmpty)
            ? Image.network(widget.user.profileImage!, fit: BoxFit.cover)
            : Container(
                color: const Color(0xFFF7F4F3),
                child: Center(
                  child: Text(
                    widget.user.fullName.isNotEmpty
                        ? widget.user.fullName[0].toUpperCase()
                        : "?",
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.chevron_left,
                        size: 28, color: Colors.grey),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Edit profile",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: isSaving ? null : saveProfile,
                    child: Icon(
                      Icons.check,
                      size: 30,
                      color: isSaving ? Colors.grey : accentBlue,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: currentImage,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                width: 150,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: softBlue,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "+ Upload",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: accentBlue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 26),
                    buildInput(
                      label: "Name",
                      child: buildTextField(fullNameController),
                    ),
                    const SizedBox(height: 18),
                    buildInput(
                      label: "Email",
                      child: buildTextField(emailController),
                    ),
                    const SizedBox(height: 18),
                    buildInput(
                      label: "Tags (we recommend at least 2)",
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        children: selectedConcerns.map(buildTag).toList(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    buildInput(
                      label: "Gender (only visible to you)",
                      child: buildDropdown(
                        value: selectedGender,
                        items: genders,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedGender = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    buildInput(
                      label: "Age range (only visible to you)",
                      child: buildDropdown(
                        value: selectedAgeRange,
                        items: ageRanges,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedAgeRange = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    buildInput(
                      label: "Skin type",
                      child: buildDropdown(
                        value: selectedSkinType,
                        items: skinTypes,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedSkinType = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      "Skin tone",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: phototypes.map(buildSkinToneCircle).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
