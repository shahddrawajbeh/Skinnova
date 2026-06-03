import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skin_concerns_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_widgets.dart';

class SkinSensitivityScreen extends StatefulWidget {
  const SkinSensitivityScreen({super.key});

  @override
  State<SkinSensitivityScreen> createState() => _SkinSensitivityScreenState();
}

class _SkinSensitivityScreenState extends State<SkinSensitivityScreen> {
  final int currentStep = 3;
  final int totalSteps = 10;
  String? selected;

  final List<Map<String, dynamic>> options = const [
    {
      "title": "Not sensitive",
      "icon": Icons.sentiment_very_satisfied_rounded,
      "description":
          "Your skin usually tolerates most products well and rarely reacts to weather or new ingredients.",
    },
    {
      "title": "Somewhat sensitive",
      "icon": Icons.sentiment_neutral_rounded,
      "description":
          "Your skin may occasionally react to certain products or environmental changes with mild irritation or dryness.",
    },
    {
      "title": "Very sensitive",
      "icon": Icons.sentiment_dissatisfied_rounded,
      "description":
          "Your skin reacts easily to fragrance, strong ingredients, or weather changes and needs extra gentle care.",
    },
  ];

  Future<void> saveSensitivityAndContinue() async {
    if (selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId == null) {
      print("❌ No userId found");
      return;
    }
    final result = await ApiService.saveOnboarding(
        userId: userId, data: {"skinSensitivity": selected});
    print("SENSITIVITY RESULT: $result");
    if (!mounted) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const SkinConcernsScreen()));
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
              OnboardingStepLabel(label: 'Step 4 of 10'),
              const SizedBox(height: 36),
              OnboardingHeading(
                title: 'How sensitive is your skin?',
                subtitle:
                    'This helps us choose gentler, more suitable recommendations for your skin.',
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = options[index];
                    final bool active = selected == item["title"];
                    return _SensitivityTile(
                      title: item["title"] as String,
                      description: item["description"] as String,
                      icon: item["icon"] as IconData,
                      selected: active,
                      onTap: () =>
                          setState(() => selected = item["title"] as String),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              OnboardingContinueButton(
                enabled: selected != null,
                onPressed: saveSensitivityAndContinue,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensitivityTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SensitivityTile({
    required this.title,
    required this.description,
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          selected ? Colors.white.withOpacity(0.16) : softPink,
                    ),
                    child: Icon(
                      icon,
                      color: selected ? Colors.white : cs.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : cs.onSurface,
                      ),
                    ),
                  ),
                  OnboardingCheckCircle(selected: selected),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 240),
                crossFadeState: selected
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        height: 1.6,
                        color: Colors.white.withOpacity(0.86),
                        fontWeight: FontWeight.w400,
                      ),
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
