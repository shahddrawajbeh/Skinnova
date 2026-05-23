import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'main_navigation_screen.dart';

class WelcomeReadyScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const WelcomeReadyScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<WelcomeReadyScreen> createState() => _WelcomeReadyScreenState();
}

class _WelcomeReadyScreenState extends State<WelcomeReadyScreen> {
  static const Color softLight = Color(0xFFF6F1F0);
  static const Color barelyMauve = Color(0xFFCCBDB9);
  static const Color lavender = Color(0xFF663F44);

  double progress = 0.0;
  int currentStep = 0;
  Timer? _timer;

  final List<String> steps = [
    "Analyzing your data",
    "Crafting your personalized plan",
    "Setting up your daily routines",
    "Creating your recommendations",
    "Ready!",
  ];

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() {
    const totalDuration = Duration(seconds: 5);
    const tick = Duration(milliseconds: 100);

    final int totalTicks = totalDuration.inMilliseconds ~/ tick.inMilliseconds;
    int tickCount = 0;

    _timer = Timer.periodic(tick, (timer) {
      tickCount++;
      final double newProgress = tickCount / totalTicks;

      int stepIndex = 0;
      if (newProgress >= 0.20) stepIndex = 1;
      if (newProgress >= 0.45) stepIndex = 2;
      if (newProgress >= 0.70) stepIndex = 3;
      if (newProgress >= 0.95) stepIndex = 4;

      if (mounted) {
        setState(() {
          progress = newProgress.clamp(0.0, 1.0);
          currentStep = stepIndex;
        });
      }

      if (tickCount >= totalTicks) {
        timer.cancel();

        Future.delayed(const Duration(milliseconds: 450), () {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainNavigationScreen(
                  userId: widget.userId, userName: widget.userName),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildStepItem(int index) {
    final bool isActive = index == currentStep;
    final bool isDone = index < currentStep;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isActive || isDone ? 1 : 0.28,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? lavender
                    : isActive
                        ? lavender.withOpacity(0.10)
                        : Colors.transparent,
                border: Border.all(
                  color: isDone || isActive
                      ? lavender.withOpacity(0.75)
                      : barelyMauve.withOpacity(0.45),
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : isActive
                      ? Padding(
                          padding: const EdgeInsets.all(4),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(lavender),
                          ),
                        )
                      : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                steps[index],
                style: GoogleFonts.poppins(
                  fontSize: 13.4,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                  color: isActive
                      ? Colors.black.withOpacity(0.88)
                      : isDone
                          ? Colors.black.withOpacity(0.78)
                          : Colors.black.withOpacity(0.28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softLight,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 280,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/profile.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.02),
                          Colors.white.withOpacity(0.06),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: softLight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
                child: Column(
                  children: [
                    Text(
                      "We are setting everything\nup for you...",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 29,
                        height: 1.22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.86),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        backgroundColor: const Color(0xFFE7E2F3),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(lavender),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: List.generate(
                        steps.length,
                        (index) => _buildStepItem(index),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
