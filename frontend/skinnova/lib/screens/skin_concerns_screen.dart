import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skin_phototype_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onboarding_widgets.dart';

class SkinConcernsScreen extends StatefulWidget {
  const SkinConcernsScreen({super.key});

  @override
  State<SkinConcernsScreen> createState() => _SkinConcernsScreenState();
}

class _SkinConcernsScreenState extends State<SkinConcernsScreen> {
  final int currentStep = 4;
  final int totalSteps = 10;

  final List<String> concerns = [
    "Acne & Blemishes",
    "Blackheads",
    "Dark Spots",
    "Dryness",
    "Oiliness",
    "Redness",
    "Dullness",
    "Uneven Texture",
    "Visible Pores",
    "Dark Circles",
    "Puffiness",
    "Fine Lines & Wrinkles",
    "Loss of Firmness",
    "Sensitive Skin",
    "Dehydration",
  ];

  final Set<String> selectedConcerns = {};

  Future<void> saveConcernsAndContinue() async {
    if (selectedConcerns.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    if (userId == null) {
      print("❌ No userId found");
      return;
    }
    final result = await ApiService.saveOnboarding(
        userId: userId, data: {"skinConcerns": selectedConcerns.toList()});
    print("CONCERNS RESULT: $result");
    if (!mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SkinPhototypeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              OnboardingStepLabel(label: 'Step 5 of 10'),
              const SizedBox(height: 34),
              OnboardingHeading(
                title: "What are your concerns?",
                subtitle:
                    "Select all that apply so we can personalize your skincare routine more accurately.",
              ),
              const SizedBox(height: 26),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: concerns.map((concern) {
                      final bool isSelected =
                          selectedConcerns.contains(concern);
                      return _ConcernChip(
                        label: concern,
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedConcerns.remove(concern);
                            } else {
                              selectedConcerns.add(concern);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  selectedConcerns.isEmpty
                      ? 'Select at least one concern'
                      : '${selectedConcerns.length} selected',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: cs.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OnboardingContinueButton(
                enabled: selectedConcerns.isNotEmpty,
                onPressed: saveConcernsAndContinue,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConcernChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ConcernChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;

    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: selected ? 1.02 : 1.0,
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? cs.primary : cs.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? cs.primary : divider),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? cs.primary.withOpacity(0.16)
                    : Colors.black.withOpacity(0.04),
                blurRadius: selected ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
