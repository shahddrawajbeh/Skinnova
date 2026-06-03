import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_ready_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_widgets.dart';
// _ConditionTile and _ConditionsGrid are defined in chronic_conditions_screen.dart
// but since they're private (_), we duplicate the grid inline here.

class SpecialConditionsScreen extends StatefulWidget {
  const SpecialConditionsScreen({super.key});

  @override
  State<SpecialConditionsScreen> createState() =>
      _SpecialConditionsScreenState();
}

class _SpecialConditionsScreenState extends State<SpecialConditionsScreen> {
  final int currentStep = 9;
  final int totalSteps = 10;

  final Set<String> selectedConditions = {};
  final List<Map<String, dynamic>> options = [
    {
      "title": "Pregnancy or breastfeeding",
      "icon": Icons.pregnant_woman_outlined
    },
    {"title": "Hormonal changes", "icon": Icons.balance_rounded},
    {
      "title": "Menopause or perimenopause",
      "icon": Icons.self_improvement_outlined
    },
    {"title": "Autoimmune condition", "icon": Icons.health_and_safety_outlined},
    {"title": "Stress or lack of sleep", "icon": Icons.bedtime_outlined},
    {"title": "None of these", "icon": Icons.check_circle_outline_rounded},
  ];

  void toggleCondition(String item) {
    setState(() {
      if (item == "None of these") {
        if (selectedConditions.contains(item)) {
          selectedConditions.remove(item);
        } else {
          selectedConditions
            ..clear()
            ..add(item);
        }
      } else {
        if (selectedConditions.contains(item)) {
          selectedConditions.remove(item);
        } else {
          selectedConditions.remove("None of these");
          selectedConditions.add(item);
        }
      }
    });
  }

  Future<void> goNext(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId != null) {
      final result = await ApiService.saveOnboarding(
        userId: userId,
        data: {"specialConditions": selectedConditions.toList()},
      );
      print("SPECIAL CONDITIONS RESULT: $result");
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WelcomeReadyScreen(
            userId: userId,
            userName: prefs.getString("userName") ?? "User",
          ),
        ),
      );
    } else {
      print("❌ No userId found");
    }
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
                        onSkip: () => goNext(context),
                      ),
                      const SizedBox(height: 10),
                      OnboardingStepLabel(label: 'Step 10 of 10'),
                      const SizedBox(height: 28),
                      OnboardingHeading(
                        title:
                            "Do you have any special\nconditions that might\naffect your skin?",
                        subtitle:
                            "This step is optional. It helps us personalize\nrecommendations more carefully.",
                      ),
                      const SizedBox(height: 28),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: options.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.02,
                        ),
                        itemBuilder: (context, index) {
                          final item = options[index];
                          final String title = item["title"]?.toString() ?? "";
                          final IconData icon = item["icon"] as IconData? ??
                              Icons.circle_outlined;
                          final bool isSelected =
                              selectedConditions.contains(title);

                          return _SpecialConditionTile(
                            title: title,
                            icon: icon,
                            selected: isSelected,
                            onTap: () => toggleCondition(title),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      OnboardingContinueButton(
                        enabled: true,
                        onPressed: () => goNext(context),
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

class _SpecialConditionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SpecialConditionTile({
    required this.title,
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
                maxLines: 3,
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
