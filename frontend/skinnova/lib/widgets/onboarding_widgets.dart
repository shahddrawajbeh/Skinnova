import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ── Onboarding shared widgets ──────────────────────────────────────────────────
// All widgets adapt to the current theme (light / dark) via Theme.of(context).

/// Progress dots + back button row that appears at the top of every onboarding screen.
class OnboardingHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String? skipLabel;
  final VoidCallback? onSkip;

  const OnboardingHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.skipLabel,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;

    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.surface,
              shape: BoxShape.circle,
              border: Border.all(color: divider),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: cs.onSurface.withOpacity(0.75),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Progress dots
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalSteps,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == currentStep ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: index <= currentStep ? AppColors.dustyRose : divider,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),

        // Optional skip button (same width as back button to keep dots centered)
        if (skipLabel != null && onSkip != null) ...[
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onSkip,
            child: Text(
              skipLabel!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dustyRose,
              ),
            ),
          ),
        ] else
          const SizedBox(width: 42),
      ],
    );
  }
}

/// Small "Step N of 10" label displayed below the header.
class OnboardingStepLabel extends StatelessWidget {
  final String label;
  const OnboardingStepLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Centred question heading + subtitle used on all onboarding screens.
class OnboardingHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const OnboardingHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 30,
              color: cs.primary,
              height: 1.18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              height: 1.6,
              color: cs.onSurface.withOpacity(0.58),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width pill Continue button used on all onboarding screens.
class OnboardingContinueButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  final String label;
  final String? subLabel;

  const OnboardingContinueButton({
    super.key,
    required this.enabled,
    required this.onPressed,
    this.label = 'Continue',
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          disabledBackgroundColor: cs.primary.withOpacity(0.28),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: subLabel != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subLabel!,
                      style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.82),
                          fontWeight: FontWeight.w400)),
                ],
              )
            : Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Small animated check circle used on the right edge of selection tiles.
class OnboardingCheckCircle extends StatelessWidget {
  final bool selected;
  const OnboardingCheckCircle({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;
    return AnimatedContainer(
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
    );
  }
}
