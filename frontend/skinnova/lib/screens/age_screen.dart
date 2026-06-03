import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skin_type_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_widgets.dart';

class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  final int currentStep = 1;
  final int totalSteps = 10;

  final List<String> ageRanges = const [
    '13–18', '18–24', '25–34', '35–44', '45–54', '55+',
  ];

  String? selectedRange;

  Future<void> saveAgeAndContinue() async {
    if (selectedRange == null) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId == null) { print("❌ No userId found"); return; }
    final result = await ApiService.saveOnboarding(userId: userId, data: {"ageRange": selectedRange});
    print("AGE ONBOARDING RESULT: $result");
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SkinTypeScreen()));
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
              OnboardingHeader(currentStep: currentStep, totalSteps: totalSteps),
              const SizedBox(height: 10),
              OnboardingStepLabel(label: 'Step 2 of 10'),
              const SizedBox(height: 36),
              OnboardingHeading(
                title: 'Choose your age range',
                subtitle: 'This helps us tailor skincare recommendations to your stage and needs.',
              ),
              const SizedBox(height: 34),
              Expanded(
                child: ListView.separated(
                  itemCount: ageRanges.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final range = ageRanges[index];
                    return _AgeRangeTile(
                      label: range,
                      selected: selectedRange == range,
                      onTap: () => setState(() => selectedRange = range),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                ),
              ),
              const SizedBox(height: 18),
              OnboardingContinueButton(
                enabled: selectedRange != null,
                onPressed: saveAgeAndContinue,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeRangeTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AgeRangeTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;

    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      scale: selected ? 1.01 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          height: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? cs.primary : cs.surface,
            borderRadius: BorderRadius.circular(999),
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
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
