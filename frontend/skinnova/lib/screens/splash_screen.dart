import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Theme Colors
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color wine = Color(0xFF5B2333);

  late final AnimationController _mainController;
  late final AnimationController _textController;

  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  late final Animation<double> _textReveal;
  late final Animation<double> _textGlow;
  late final Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _fade = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _scale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    _textReveal = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    );

    _textGlow = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _subtitleFade = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _mainController.forward();

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        _textController.forward();
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => const WelcomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );

            final slide = Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(fade);

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteSmoke,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    whiteSmoke,
                    whiteSmoke,
                    wine.withOpacity(0.06),
                  ],
                ),
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: wine.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Brand Name Animation
                        AnimatedBuilder(
                          animation: _textController,
                          builder: (context, child) {
                            return ClipRect(
                              child: Align(
                                alignment: Alignment.center,
                                widthFactor: _textReveal.value,
                                child: child,
                              ),
                            );
                          },
                          child: AnimatedBuilder(
                            animation: _textGlow,
                            builder: (context, child) {
                              return Text(
                                "SKINOVA",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.marcellus(
                                  fontSize: 46,
                                  letterSpacing: 4,
                                  color: wine,
                                  shadows: [
                                    Shadow(
                                      blurRadius: _textGlow.value,
                                      color: wine.withOpacity(0.10),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        FadeTransition(
                          opacity: _subtitleFade,
                          child: Text(
                            "Know your skin like never before",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                              color: wine.withOpacity(0.70),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        const _ElegantDotsLoader(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElegantDotsLoader extends StatefulWidget {
  const _ElegantDotsLoader();

  @override
  State<_ElegantDotsLoader> createState() => _ElegantDotsLoaderState();
}

class _ElegantDotsLoaderState extends State<_ElegantDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Color dotColor = Color(0xFF5B2333);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _wave(double t, double shift) {
    final x = (t + shift) % 1.0;
    return 1 - (2 * (x - 0.5)).abs();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        final s1 = 0.85 + (_wave(t, 0.0) * 0.45);
        final s2 = 0.85 + (_wave(t, 0.2) * 0.45);
        final s3 = 0.85 + (_wave(t, 0.4) * 0.45);

        Widget dot(double scale) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: dotColor.withOpacity(0.88),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withOpacity(0.08),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(s1),
            dot(s2),
            dot(s3),
          ],
        );
      },
    );
  }
}
