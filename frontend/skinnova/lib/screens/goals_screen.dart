import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chronic_conditions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_widgets.dart';
import 'package:flutter/services.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final int currentStep = 7;
  final int totalSteps = 10;

  final Set<String> selectedGoals = {};
  final List<Map<String, dynamic>> goals = [
    {
      "title": "Scan and analyze my skin",
      "icon": Icons.document_scanner_outlined,
      "enabled": true
    },
    {
      "title": "Fix my skin concerns",
      "icon": Icons.healing_outlined,
      "enabled": true
    },
    {
      "title": "Get personalized product recommendations",
      "icon": Icons.recommend_outlined,
      "enabled": true
    },
    {
      "title": "Build a skincare routine for my skin",
      "icon": Icons.auto_fix_high_outlined,
      "enabled": true
    },
    {
      "title": "Track my skin progress over time",
      "icon": Icons.insights_outlined,
      "enabled": true
    },
    {
      "title": "Find safe products for my skin type",
      "icon": Icons.verified_user_outlined,
      "enabled": true
    },
    {
      "title": "Learn about ingredients and their effects",
      "icon": Icons.science_outlined,
      "enabled": true
    },
    {
      "title": "Avoid ingredients that may irritate my skin",
      "icon": Icons.block_outlined,
      "enabled": true
    },
    {
      "title": "Compare products and choose the best one",
      "icon": Icons.compare_arrows_outlined,
      "enabled": true
    },
  ];

  void toggleGoal(String title) {
    setState(() {
      if (selectedGoals.contains(title)) {
        selectedGoals.remove(title);
      } else {
        selectedGoals.add(title);
      }
    });
  }

  Future<void> saveGoalsAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId == null) {
      print("❌ No userId found");
      return;
    }
    final result = await ApiService.saveOnboarding(
        userId: userId, data: {"goals": selectedGoals.toList()});
    print("GOALS RESULT: $result");
    if (!mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ChronicConditionsScreen()));
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
                          currentStep: currentStep, totalSteps: totalSteps),
                      const SizedBox(height: 10),
                      OnboardingStepLabel(label: 'Step 8 of 10'),
                      const SizedBox(height: 28),
                      OnboardingHeading(
                        title: "What are your goals?",
                        subtitle:
                            "Choose all that match your skincare journey.\nThis helps us tailor the app to your needs.",
                      ),
                      const SizedBox(height: 28),
                      ...goals.map((item) {
                        final String title = item["title"]?.toString() ?? "";
                        final IconData icon =
                            item["icon"] as IconData? ?? Icons.circle_outlined;
                        final bool enabled = item["enabled"] == true;
                        final bool selected = selectedGoals.contains(title);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _GoalTile(
                            title: title,
                            icon: icon,
                            selected: selected,
                            enabled: enabled,
                            onTap: enabled ? () => toggleGoal(title) : null,
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      OnboardingContinueButton(
                        enabled: selectedGoals.isNotEmpty,
                        onPressed: saveGoalsAndContinue,
                        subLabel: "${selectedGoals.length} selected",
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

class _GoalTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _GoalTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.enabled,
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
          color: !enabled
              ? cs.surface.withOpacity(0.5)
              : selected
                  ? cs.primary
                  : cs.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: !enabled
                ? divider.withOpacity(0.5)
                : selected
                    ? cs.primary
                    : divider,
          ),
          boxShadow: [
            BoxShadow(
              color: selected && enabled
                  ? cs.primary.withOpacity(0.16)
                  : Colors.black.withOpacity(0.04),
              blurRadius: selected && enabled ? 22 : 12,
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
                color: !enabled
                    ? cs.surface
                    : selected
                        ? Colors.white.withOpacity(0.14)
                        : softPink,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: !enabled
                      ? divider.withOpacity(0.4)
                      : selected
                          ? Colors.white.withOpacity(0.10)
                          : divider,
                ),
              ),
              child: Icon(
                icon,
                size: 28,
                color: !enabled
                    ? cs.onSurface.withOpacity(0.28)
                    : selected
                        ? Colors.white
                        : cs.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15.6,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: !enabled
                      ? cs.onSurface.withOpacity(0.36)
                      : selected
                          ? Colors.white
                          : cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected && enabled ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: !enabled
                      ? divider.withOpacity(0.45)
                      : selected
                          ? Colors.white
                          : divider,
                  width: 1.4,
                ),
              ),
              child: selected && enabled
                  ? Icon(Icons.check_rounded, size: 14, color: cs.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
