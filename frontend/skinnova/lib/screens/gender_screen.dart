import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'age_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_widgets.dart';

class GenderScreen extends StatefulWidget {
  const GenderScreen({super.key});

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  final int currentStep = 0;
  final int totalSteps = 10;
  String? selectedGender;

  Future<void> saveGenderAndContinue() async {
    if (selectedGender == null) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId == null) {
      print("❌ No userId found");
      return;
    }
    final result = await ApiService.saveOnboarding(
        userId: userId, data: {"gender": selectedGender});
    print("ONBOARDING RESULT: $result");
    if (!mounted) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AgeScreen()));
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
              OnboardingStepLabel(label: 'Step 1 of 10'),
              const Spacer(),
              OnboardingHeading(
                title: 'Select your gender',
                subtitle: 'This helps us personalize your skincare experience.',
              ),
              const SizedBox(height: 40),
              _GenderTile(
                label: 'Female',
                icon: Icons.female_rounded,
                selected: selectedGender == 'Female',
                onTap: () => setState(() => selectedGender = 'Female'),
              ),
              const SizedBox(height: 16),
              _GenderTile(
                label: 'Male',
                icon: Icons.male_rounded,
                selected: selectedGender == 'Male',
                onTap: () => setState(() => selectedGender = 'Male'),
              ),
              const Spacer(),
              OnboardingContinueButton(
                enabled: selectedGender != null,
                onPressed: saveGenderAndContinue,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderTile({
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
      scale: selected ? 1.01 : 1.0,
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 22),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? Colors.white.withOpacity(0.16) : softPink,
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : cs.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16.5,
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
