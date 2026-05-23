import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_ready_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class SpecialConditionsScreen extends StatefulWidget {
  const SpecialConditionsScreen({super.key});

  @override
  State<SpecialConditionsScreen> createState() =>
      _SpecialConditionsScreenState();
}

class _SpecialConditionsScreenState extends State<SpecialConditionsScreen> {
  static const Color beetroot = Color(0xFF663F44);
  static const Color barelyMauve = Color(0xFFCCBDB9);
  static const Color softLight = Color(0xFFF6F1F0);
  static const Color softRose = Color(0xFFB08A90);

  final int currentStep = 9;
  final int totalSteps = 10;

  final Set<String> selectedConditions = {};
  final List<Map<String, dynamic>> options = [
    {
      "title": "Pregnancy or breastfeeding",
      "icon": Icons.pregnant_woman_outlined,
    },
    {
      "title": "Hormonal changes",
      "icon": Icons.balance_rounded,
    },
    {
      "title": "Menopause or perimenopause",
      "icon": Icons.self_improvement_outlined,
    },
    {
      "title": "Autoimmune condition",
      "icon": Icons.health_and_safety_outlined,
    },
    {
      "title": "Stress or lack of sleep",
      "icon": Icons.bedtime_outlined,
    },
    {
      "title": "None of these",
      "icon": Icons.check_circle_outline_rounded,
    },
  ];
  void toggleCondition(String item) {
    setState(() {
      if (item == "None of these") {
        if (selectedConditions.contains(item)) {
          selectedConditions.remove(item);
        } else {
          selectedConditions
            ..clear()
            ..add(item);
        }
      } else {
        if (selectedConditions.contains(item)) {
          selectedConditions.remove(item);
        } else {
          selectedConditions.remove("None of these");
          selectedConditions.add(item);
        }
      }
    });
  }

  Future<void> goNext(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");

    if (userId != null) {
      final result = await ApiService.saveOnboarding(
        userId: userId,
        data: {
          "specialConditions": selectedConditions.toList(),
        },
      );

      print("SPECIAL CONDITIONS RESULT: $result");

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WelcomeReadyScreen(
              userId: userId, userName: prefs.getString("userName") ?? "User"),
        ),
      );
    } else {
      print("❌ No userId found");
    }
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
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => goNext(context),
                            child: Text(
                              "Skip",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: softRose,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Step 10 of 10',
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
                              "Do you have any special\nconditions that might\naffect your skin?",
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
                              "This step is optional. It helps us personalize\nrecommendations more carefully.",
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
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: options.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.02,
                        ),
                        itemBuilder: (context, index) {
                          final item = options[index];
                          final String title = item["title"]?.toString() ?? "";
                          final IconData icon = item["icon"] as IconData? ??
                              Icons.circle_outlined;
                          final bool isSelected =
                              selectedConditions.contains(title);

                          return GestureDetector(
                            onTap: () => toggleCondition(title),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.all(14),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.14)
                                          : softRose.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.10)
                                            : barelyMauve.withOpacity(0.25),
                                      ),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 24,
                                      color: isSelected ? softLight : beetroot,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                        color:
                                            isSelected ? softLight : beetroot,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 240),
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
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: () => goNext(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: beetroot,
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
