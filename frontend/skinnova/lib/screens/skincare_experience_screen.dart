import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goals_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_widgets.dart';

class SkincareExperienceScreen extends StatefulWidget {
  const SkincareExperienceScreen({super.key});

  @override
  State<SkincareExperienceScreen> createState() => _SkincareExperienceScreenState();
}

class _SkincareExperienceScreenState extends State<SkincareExperienceScreen> {
  final int currentStep = 6;
  final int totalSteps = 10;
  String? selectedExperience;

  final List<Map<String, dynamic>> experienceOptions = [
    {
      "title": "I do it regularly",
      "subtitle": "I already follow skincare routines often",
      "icon": Icons.spa_rounded,
    },
    {
      "title": "I tried a few times",
      "subtitle": "I know a little, but I'm still exploring",
      "icon": Icons.self_improvement_rounded,
    },
    {
      "title": "I have no idea",
      "subtitle": "I'm a complete beginner and need simple guidance",
      "icon": Icons.lightbulb_outline_rounded,
    },
  ];

  Future<void> saveExperienceAndContinue() async {
    if (selectedExperience == null) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId == null) { print("❌ No userId found"); return; }
    final result = await ApiService.saveOnboarding(userId: userId, data: {"skincareExperience": selectedExperience});
    print("EXPERIENCE RESULT: $result");
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OnboardingHeader(currentStep: currentStep, totalSteps: totalSteps),
                      const SizedBox(height: 10),
                      OnboardingStepLabel(label: 'Step 7 of 10'),
                      const SizedBox(height: 28),
                      OnboardingHeading(
                        title: "How experienced are you\nwith skincare?",
                        subtitle:
                            "This helps us personalize your guidance,\nproduct suggestions, and routine complexity.",
                      ),
                      const SizedBox(height: 28),
                      ...experienceOptions.map((item) {
                        final String title = item["title"]?.toString() ?? "";
                        final String subtitle = item["subtitle"]?.toString() ?? "";
                        final IconData icon = item["icon"] as IconData? ?? Icons.circle_outlined;
                        final bool isSelected = selectedExperience == title;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ExperienceTile(
                            title: title,
                            subtitle: subtitle,
                            icon: icon,
                            selected: isSelected,
                            onTap: () => setState(() => selectedExperience = title),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      OnboardingContinueButton(
                        enabled: selectedExperience != null,
                        onPressed: saveExperienceAndContinue,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExperienceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ExperienceTile({
    required this.title,
    required this.subtitle,
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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.all(18),
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
                color: selected ? Colors.white.withOpacity(0.14) : softPink,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? Colors.white.withOpacity(0.10)
                      : divider,
                ),
              ),
              child: Icon(
                icon,
                size: 28,
                color: selected ? Colors.white : cs.primary,
              ),
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
    );
  }
}
