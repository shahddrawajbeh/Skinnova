import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skin_phototype_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class SkinConcernsScreen extends StatefulWidget {
  const SkinConcernsScreen({super.key});

  @override
  State<SkinConcernsScreen> createState() => _SkinConcernsScreenState();
}

class _SkinConcernsScreenState extends State<SkinConcernsScreen> {
  static const Color beetroot = Color(0xFF663F44);
  static const Color barelyMauve = Color(0xFFCCBDB9);
  static const Color softLight = Color(0xFFF6F1F0);
  static const Color softRose = Color(0xFFB08A90);

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
      userId: userId,
      data: {
        "skinConcerns": selectedConcerns.toList(),
      },
    );

    print("CONCERNS RESULT: $result");

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SkinPhototypeScreen(),
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
                  'Step 5 of 10',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: beetroot.withOpacity(0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 34),
              Center(
                child: Column(
                  children: [
                    Text(
                      "What are your concerns?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        color: beetroot,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Select all that apply so we can personalize your skincare routine more accurately.",
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
                    color: beetroot.withOpacity(0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: selectedConcerns.isEmpty
                      ? null
                      : () {
                          saveConcernsAndContinue();
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
                    "Continue",
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

class _ConcernChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ConcernChip({
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
                blurRadius: selected ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: softLight,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: selected ? softLight : beetroot,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
