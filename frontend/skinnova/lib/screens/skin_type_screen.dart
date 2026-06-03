import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skin_sensitivity_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_widgets.dart';

class SkinTypeScreen extends StatefulWidget {
  const SkinTypeScreen({super.key});

  @override
  State<SkinTypeScreen> createState() => _SkinTypeScreenState();
}

class _SkinTypeScreenState extends State<SkinTypeScreen> {
  final int currentStep = 2;
  final int totalSteps = 10;
  String? selected;

  final List<Map<String, dynamic>> options = const [
    {"title": "Normal Skin", "icon": Icons.spa_outlined},
    {"title": "Combination Skin", "icon": Icons.blur_circular_rounded},
    {"title": "Dry Skin", "icon": Icons.wb_sunny_outlined},
    {"title": "Oily Skin", "icon": Icons.water_drop_outlined},
    {"title": "I don't know", "icon": Icons.help_outline_rounded},
  ];

  Future<void> saveSkinTypeAndContinue() async {
    if (selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId == null) {
      print("❌ No userId found");
      return;
    }
    final result = await ApiService.saveOnboarding(
        userId: userId, data: {"skinType": selected});
    print("SKIN TYPE RESULT: $result");
    if (!mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SkinSensitivityScreen()));
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
              OnboardingStepLabel(label: 'Step 3 of 10'),
              const SizedBox(height: 36),
              OnboardingHeading(
                title: "What's your skin type?",
                subtitle:
                    "Identifying your skin type helps us build more accurate routines and recommendations.",
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final item = options[index];
                    final bool active = selected == item["title"];
                    return _SkinTypeTile(
                      label: item["title"] as String,
                      icon: item["icon"] as IconData,
                      selected: active,
                      onTap: () =>
                          setState(() => selected = item["title"] as String),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                ),
              ),
              const SizedBox(height: 18),
              OnboardingContinueButton(
                enabled: selected != null,
                onPressed: saveSkinTypeAndContinue,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkinTypeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SkinTypeTile({
    required this.label,
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
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? Colors.white.withOpacity(0.16) : softPink,
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
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15.8,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : cs.onSurface,
                  ),
                ),
              ),
              OnboardingCheckCircle(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}
