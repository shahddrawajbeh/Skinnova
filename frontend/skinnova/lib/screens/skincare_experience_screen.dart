import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goals_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class SkincareExperienceScreen extends StatefulWidget {
  const SkincareExperienceScreen({super.key});

  @override
  State<SkincareExperienceScreen> createState() =>
      _SkincareExperienceScreenState();
}

class _SkincareExperienceScreenState extends State<SkincareExperienceScreen> {
  static const Color beetroot = Color(0xFF663F44);
  static const Color barelyMauve = Color(0xFFCCBDB9);
  static const Color softLight = Color(0xFFF6F1F0);
  static const Color softRose = Color(0xFFB08A90);

  final int currentStep = 6;
  final int totalSteps = 10;

  String? selectedExperience;

  final List<Map<String, dynamic>> experienceOptions = [
    {
      "title": "I do it regularly",
      "subtitle": "I already follow skincare routines often",
      "icon": Icons.spa_rounded,
    },
    {
      "title": "I tried a few times",
      "subtitle": "I know a little, but I’m still exploring",
      "icon": Icons.self_improvement_rounded,
    },
    {
      "title": "I have no idea",
      "subtitle": "I’m a complete beginner and need simple guidance",
      "icon": Icons.lightbulb_outline_rounded,
    },
  ];
  Future<void> saveExperienceAndContinue() async {
    if (selectedExperience == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");

    if (userId == null) {
      print("❌ No userId found");
      return;
    }

    final result = await ApiService.saveOnboarding(
      userId: userId,
      data: {
        "skincareExperience": selectedExperience,
      },
    );

    print("EXPERIENCE RESULT: $result");

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GoalsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softLight,
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
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
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
                          'Step 7 of 10',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: beetroot.withOpacity(0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              "How experienced are you\nwith skincare?",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                color: beetroot,
                                height: 1.18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "This helps us personalize your guidance,\nproduct suggestions, and routine complexity.",
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
                      const SizedBox(height: 28),
                      ...experienceOptions.map((item) {
                        final String title = item["title"]?.toString() ?? "";
                        final String subtitle =
                            item["subtitle"]?.toString() ?? "";
                        final IconData icon =
                            item["icon"] as IconData? ?? Icons.circle_outlined;
                        final bool isSelected = selectedExperience == title;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedExperience = title;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? beetroot
                                    : Colors.white.withOpacity(0.72),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: isSelected
                                      ? beetroot
                                      : barelyMauve.withOpacity(0.45),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? beetroot.withOpacity(0.14)
                                        : Colors.black.withOpacity(0.03),
                                    blurRadius: isSelected ? 22 : 12,
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
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.14)
                                          : softRose.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.10)
                                            : barelyMauve.withOpacity(0.25),
                                      ),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 28,
                                      color: isSelected ? softLight : beetroot,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15.8,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? softLight
                                                : beetroot,
                                          ),
                                        ),
                                        if (subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            subtitle,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13.2,
                                              height: 1.45,
                                              color: isSelected
                                                  ? softLight.withOpacity(0.86)
                                                  : beetroot.withOpacity(0.58),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 240),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? softLight
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? softLight
                                            : barelyMauve.withOpacity(0.75),
                                        width: 1.4,
                                      ),
                                    ),
                                    child: isSelected
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
                      }),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: selectedExperience == null
                              ? null
                              : () {
                                  saveExperienceAndContinue();
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
          },
        ),
      ),
    );
  }
}
