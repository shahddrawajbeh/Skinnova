import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skincare_experience_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class SkinPhototypeScreen extends StatefulWidget {
  const SkinPhototypeScreen({super.key});

  @override
  State<SkinPhototypeScreen> createState() => _SkinPhototypeScreenState();
}

class _SkinPhototypeScreenState extends State<SkinPhototypeScreen> {
  static const Color beetroot = Color(0xFF663F44);
  static const Color barelyMauve = Color(0xFFCCBDB9);
  static const Color softLight = Color(0xFFF6F1F0);
  static const Color softRose = Color(0xFFB08A90);

  final int currentStep = 5;
  final int totalSteps = 10;

  String? selectedType;

  final List<Map<String, dynamic>> phototypes = [
    {
      "title": "Pale white skin",
      "subtitle": "Always burns, never tans",
      "color": const Color(0xFFE7C9A8),
      "description":
          "Very fair skin with high sensitivity to UV exposure. Daily sunscreen and strong sun protection are especially important.",
    },
    {
      "title": "White skin",
      "subtitle": "Burns easily, tans minimally",
      "color": const Color(0xFFDDB48D),
      "description":
          "Fair skin that may tan slightly but still burns easily. Consistent SPF and protective habits are recommended.",
    },
    {
      "title": "Light brown skin",
      "subtitle": "Sometimes burns, slowly tans",
      "color": const Color(0xFFD0A47D),
      "description":
          "Skin that may burn moderately but gradually develops a light tan. Sun protection still matters for long-term skin health.",
    },
    {
      "title": "Moderate brown skin",
      "subtitle": "Burns minimally, tans easily",
      "color": const Color(0xFFBF8457),
      "description":
          "This skin type usually tans well and burns less often, but sunscreen is still important to prevent damage and discoloration.",
    },
    {
      "title": "Dark brown skin",
      "subtitle": "Rarely burns, tans well",
      "color": const Color(0xFFAA6C2F),
      "description":
          "Naturally more protected, but still vulnerable to pigmentation and sun damage. SPF remains important.",
    },
    {
      "title": "Deep brown to black skin",
      "subtitle": "Never burns, deeply pigmented",
      "color": const Color(0xFF4B231B),
      "description":
          "Deeply pigmented skin with stronger natural protection, though it can still be affected by hyperpigmentation and UV exposure.",
    },
    {
      "title": "Prefer not to say",
      "subtitle": "",
      "icon": Icons.help_outline_rounded,
      "description": null,
      "isPreferNot": true,
    },
  ];
  Future<void> savePhototypeAndContinue() async {
    if (selectedType == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");

    if (userId == null) {
      print("❌ No userId found");
      return;
    }

    final result = await ApiService.saveOnboarding(
      userId: userId,
      data: {
        "skinPhototype": selectedType,
      },
    );

    print("PHOTOTYPE RESULT: $result");

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SkincareExperienceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: barelyMauve.withOpacity(0.45),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: beetroot.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        totalSteps,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == currentStep ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: index <= currentStep
                                ? softRose
                                : barelyMauve.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Step 6 of 10',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: beetroot.withOpacity(0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    Text(
                      "What's your skin phototype?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        color: beetroot,
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Also known as the Fitzpatrick classification. This helps us offer more suitable guidance and protection tips.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        height: 1.6,
                        color: beetroot.withOpacity(0.58),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: phototypes.map((item) {
                      final String title = item["title"] as String;
                      final String subtitle =
                          item["subtitle"]?.toString() ?? "";
                      final String description =
                          item["description"]?.toString() ?? "";
                      final bool isSelected = selectedType == title;
                      final bool isPreferNot = item["isPreferNot"] == true;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          children: [
                            _PhototypeTile(
                              title: title,
                              subtitle: subtitle,
                              swatchColor: item["color"] as Color?,
                              isPreferNot: isPreferNot,
                              icon: item["icon"] as IconData?,
                              selected: isSelected,
                              onTap: () {
                                setState(() {
                                  selectedType = title;
                                });
                              },
                            ),
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 240),
                              crossFadeState: isSelected &&
                                      description.isNotEmpty &&
                                      !isPreferNot
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: const SizedBox.shrink(),
                              secondChild: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.66),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: barelyMauve.withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  description,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.4,
                                    height: 1.65,
                                    color: beetroot.withOpacity(0.76),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: selectedType == null
                      ? null
                      : () {
                          savePhototypeAndContinue();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: beetroot,
                    disabledBackgroundColor: beetroot.withOpacity(0.28),
                    foregroundColor: softLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    "Continue",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhototypeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? swatchColor;
  final bool isPreferNot;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _PhototypeTile({
    required this.title,
    required this.subtitle,
    required this.swatchColor,
    required this.isPreferNot,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  static const Color beetroot = Color(0xFF663F44);
  static const Color barelyMauve = Color(0xFFCCBDB9);
  static const Color softLight = Color(0xFFF6F1F0);
  static const Color softRose = Color(0xFFB08A90);

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      scale: selected ? 1.01 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? beetroot : Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected ? beetroot : barelyMauve.withOpacity(0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? beetroot.withOpacity(0.14)
                    : Colors.black.withOpacity(0.03),
                blurRadius: selected ? 22 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isPreferNot
                      ? (selected
                          ? Colors.white.withOpacity(0.16)
                          : softRose.withOpacity(0.14))
                      : swatchColor ?? softRose.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isPreferNot
                        ? (selected
                            ? Colors.white.withOpacity(0.10)
                            : barelyMauve.withOpacity(0.25))
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: isPreferNot
                    ? Icon(
                        icon ?? Icons.help_outline_rounded,
                        size: 28,
                        color: selected ? softLight : beetroot,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15.8,
                        fontWeight: FontWeight.w600,
                        color: selected ? softLight : beetroot,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13.2,
                          height: 1.45,
                          color: selected
                              ? softLight.withOpacity(0.86)
                              : beetroot.withOpacity(0.58),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? softLight : Colors.transparent,
                  border: Border.all(
                    color: selected ? softLight : barelyMauve.withOpacity(0.75),
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: beetroot,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
