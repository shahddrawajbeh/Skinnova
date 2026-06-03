import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skincare_experience_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_widgets.dart';

class SkinPhototypeScreen extends StatefulWidget {
  const SkinPhototypeScreen({super.key});

  @override
  State<SkinPhototypeScreen> createState() => _SkinPhototypeScreenState();
}

class _SkinPhototypeScreenState extends State<SkinPhototypeScreen> {
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
        userId: userId, data: {"skinPhototype": selectedType});
    print("PHOTOTYPE RESULT: $result");
    if (!mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SkincareExperienceScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingHeader(
                  currentStep: currentStep, totalSteps: totalSteps),
              const SizedBox(height: 10),
              OnboardingStepLabel(label: 'Step 6 of 10'),
              const SizedBox(height: 28),
              OnboardingHeading(
                title: "What's your skin phototype?",
                subtitle:
                    "Also known as the Fitzpatrick classification. This helps us offer more suitable guidance and protection tips.",
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
                              onTap: () => setState(() => selectedType = title),
                            ),
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 240),
                              crossFadeState: isSelected &&
                                      description.isNotEmpty &&
                                      !isPreferNot
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: const SizedBox.shrink(),
                              secondChild: _DescriptionBox(text: description),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OnboardingContinueButton(
                enabled: selectedType != null,
                onPressed: savePhototypeAndContinue,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = Theme.of(context).dividerColor;
    final softPink = isDark ? AppColors.darkSoftPink : AppColors.lightSoftPink;

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
            color: selected ? cs.primary : cs.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: selected ? cs.primary : divider),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? cs.primary.withOpacity(0.16)
                    : Colors.black.withOpacity(0.04),
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
                      ? (selected ? Colors.white.withOpacity(0.16) : softPink)
                      : swatchColor ?? softPink,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isPreferNot
                        ? (selected ? Colors.white.withOpacity(0.10) : divider)
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: isPreferNot
                    ? Icon(
                        icon ?? Icons.help_outline_rounded,
                        size: 28,
                        color: selected ? Colors.white : cs.primary,
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
                        color: selected ? Colors.white : cs.onSurface,
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
                              ? Colors.white.withOpacity(0.86)
                              : cs.onSurface.withOpacity(0.58),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OnboardingCheckCircle(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionBox extends StatelessWidget {
  final String text;
  const _DescriptionBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: divider),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13.4,
          height: 1.65,
          color: cs.onSurface.withOpacity(0.76),
        ),
      ),
    );
  }
}
