import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'special_conditions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_widgets.dart';

class ChronicConditionsScreen extends StatefulWidget {
  const ChronicConditionsScreen({super.key});

  @override
  State<ChronicConditionsScreen> createState() =>
      _ChronicConditionsScreenState();
}

class _ChronicConditionsScreenState extends State<ChronicConditionsScreen> {
  final int currentStep = 8;
  final int totalSteps = 10;

  List<String> selectedConditions = [];
  final List<Map<String, dynamic>> options = [
    {"title": "Acne", "icon": Icons.bubble_chart_outlined},
    {"title": "Melasma", "icon": Icons.circle_outlined},
    {"title": "Rosacea", "icon": Icons.local_fire_department_outlined},
    {"title": "Eczema", "icon": Icons.healing_outlined},
    {"title": "Psoriasis", "icon": Icons.health_and_safety_outlined},
    {"title": "Contact dermatitis", "icon": Icons.warning_amber_rounded},
    {"title": "None of these", "icon": Icons.check_circle_outline_rounded},
  ];

  Future<void> saveConditionAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId == null) {
      print("❌ No userId found");
      return;
    }
    final result = await ApiService.saveOnboarding(
      userId: userId,
      data: {
        "chronicCondition": selectedConditions.join(", "),
        "specialConditions": selectedConditions,
      },
    );
    print("CHRONIC CONDITION RESULT: $result");
    if (!mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SpecialConditionsScreen()));
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId != null) {
      await ApiService.saveOnboarding(
          userId: userId, data: {"chronicCondition": null});
    }
    if (!context.mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SpecialConditionsScreen()));
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OnboardingHeader(
                        currentStep: currentStep,
                        totalSteps: totalSteps,
                        skipLabel: "Skip",
                        onSkip: _skip,
                      ),
                      const SizedBox(height: 10),
                      OnboardingStepLabel(label: 'Step 9 of 10'),
                      const SizedBox(height: 28),
                      OnboardingHeading(
                        title: "Do you have any chronic\nskin conditions?",
                        subtitle:
                            "This step is optional. It helps us avoid suggestions\nthat may not suit your skin needs.",
                      ),
                      const SizedBox(height: 28),
                      _ConditionsGrid(
                        options: options,
                        selectedConditions: selectedConditions,
                        onToggle: (title) {
                          setState(() {
                            if (title == "None of these") {
                              selectedConditions = ["None of these"];
                            } else {
                              selectedConditions.remove("None of these");
                              if (selectedConditions.contains(title)) {
                                selectedConditions.remove(title);
                              } else {
                                selectedConditions.add(title);
                              }
                            }
                          });
                        },
                        aspectRatio: 1.12,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 22),
                      OnboardingContinueButton(
                        enabled: true,
                        onPressed: saveConditionAndContinue,
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

/// Reusable 2-column grid for condition/special-condition screens.
class _ConditionsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final List<String> selectedConditions;
  final void Function(String) onToggle;
  final double aspectRatio;
  final int maxLines;

  const _ConditionsGrid({
    required this.options,
    required this.selectedConditions,
    required this.onToggle,
    required this.aspectRatio,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (context, index) {
        final item = options[index];
        final String title = item["title"]?.toString() ?? "";
        final IconData icon =
            item["icon"] as IconData? ?? Icons.circle_outlined;
        final bool isSelected = selectedConditions.contains(title);

        return _ConditionTile(
          title: title,
          icon: icon,
          selected: isSelected,
          maxLines: maxLines,
          onTap: () => onToggle(title),
        );
      },
    );
  }
}

class _ConditionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final int maxLines;
  final VoidCallback onTap;

  const _ConditionTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.maxLines,
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
        padding: const EdgeInsets.all(14),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.14) : softPink,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? Colors.white.withOpacity(0.10) : divider,
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? Colors.white : cs.primary,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Text(
                title,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: selected ? Colors.white : cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? Colors.white : Colors.transparent,
                  border: Border.all(
                    color: selected ? Colors.white : divider,
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 14, color: cs.primary)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
