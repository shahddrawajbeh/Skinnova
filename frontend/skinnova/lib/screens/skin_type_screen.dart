import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skin_sensitivity_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class SkinTypeScreen extends StatefulWidget {
  const SkinTypeScreen({super.key});

  @override
  State<SkinTypeScreen> createState() => _SkinTypeScreenState();
}

class _SkinTypeScreenState extends State<SkinTypeScreen> {
  static const Color beetroot = Color(0xFF663F44);
  static const Color barelyMauve = Color(0xFFCCBDB9);
  static const Color softLight = Color(0xFFF6F1F0);
  static const Color softRose = Color(0xFFB08A90);

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
      userId: userId,
      data: {
        "skinType": selected,
      },
    );

    print("SKIN TYPE RESULT: $result");

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SkinSensitivityScreen(),
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
                  'Step 3 of 10',
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
                      "What's your skin type?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        color: beetroot,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Identifying your skin type helps us build more accurate routines and recommendations.",
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
                      onTap: () {
                        setState(() {
                          selected = item["title"] as String;
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
                  onPressed: selected == null
                      ? null
                      : () {
                          saveSkinTypeAndContinue();
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
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: selected ? beetroot : Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(28),
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
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white.withOpacity(0.16)
                      : softRose.withOpacity(0.14),
                ),
                child: Icon(
                  icon,
                  color: selected ? softLight : beetroot,
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
                    color: selected ? softLight : beetroot,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? softLight : Colors.transparent,
                  border: Border.all(
                    color: selected ? softLight : barelyMauve.withOpacity(0.75),
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: beetroot,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
