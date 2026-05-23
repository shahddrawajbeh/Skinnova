import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skin_type_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  static const Color beetroot = Color(0xFF663F44);
  static const Color barelyMauve = Color(0xFFCCBDB9);
  static const Color softLight = Color(0xFFF6F1F0);
  static const Color softRose = Color(0xFFB08A90);

  final int currentStep = 1;
  final int totalSteps = 10;

  final List<String> ageRanges = const [
    '13–18',
    '18–24',
    '25–34',
    '35–44',
    '45–54',
    '55+',
  ];

  String? selectedRange;
  Future<void> saveAgeAndContinue() async {
    if (selectedRange == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");

    if (userId == null) {
      print("❌ No userId found");
      return;
    }

    final result = await ApiService.saveOnboarding(
      userId: userId,
      data: {
        "ageRange": selectedRange,
      },
    );

    print("AGE ONBOARDING RESULT: $result");

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SkinTypeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: barelyMauve.withOpacity(0.45),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: beetroot.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                            color: index <= currentStep
                                ? softRose
                                : barelyMauve.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Step 2 of 10',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: beetroot.withOpacity(0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Choose your age range',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        color: beetroot,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This helps us tailor skincare recommendations to your stage and needs.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        height: 1.6,
                        color: beetroot.withOpacity(0.58),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              Expanded(
                child: ListView.separated(
                  itemCount: ageRanges.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final range = ageRanges[index];
                    final selected = selectedRange == range;

                    return _AgeRangeTile(
                      label: range,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          selectedRange = range;
                        });
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: selectedRange == null
                      ? null
                      : () {
                          saveAgeAndContinue();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: beetroot,
                    disabledBackgroundColor: beetroot.withOpacity(0.28),
                    foregroundColor: softLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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

  static const Color beetroot = Color(0xFF663F44);
  static const Color barelyMauve = Color(0xFFCCBDB9);
  static const Color softLight = Color(0xFFF6F1F0);
  static const Color softRose = Color(0xFFB08A90);

  @override
  Widget build(BuildContext context) {
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
            color: selected ? beetroot : Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? beetroot : barelyMauve.withOpacity(0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? beetroot.withOpacity(0.14)
                    : Colors.black.withOpacity(0.03),
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
              color: selected ? softLight : beetroot,
            ),
          ),
        ),
      ),
    );
  }
}
