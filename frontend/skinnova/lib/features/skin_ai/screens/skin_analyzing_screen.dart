// screens/skin_analyzing_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';

import '../models/skin_analysis_model.dart';
import '../services/skin_analysis_service.dart';
import '../widgets/skinova_theme.dart';
import 'skin_result_screen.dart';

class SkinAnalyzingScreen extends StatefulWidget {
  final File imageFile;
  final String userId;
  const SkinAnalyzingScreen(
      {super.key, required this.imageFile, this.userId = ''});

  @override
  State<SkinAnalyzingScreen> createState() => _SkinAnalyzingScreenState();
}

class _SkinAnalyzingScreenState extends State<SkinAnalyzingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  int _stepIndex = 0;
  final _steps = [
    'Examining skin texture…',
    'Detecting concerns…',
    'Calculating severity scores…',
    'Building your routine…',
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _runAnalysis();
    _cycleSteps();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _cycleSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      setState(() => _stepIndex = i);
    }
  }

  Future<void> _runAnalysis() async {
    await Future.delayed(const Duration(milliseconds: 5600));
    if (!mounted) return;

    SkinAnalysisResult result;
    try {
      result = await SkinAnalysisService.analyze(widget.imageFile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
          backgroundColor: SkiNova.wine,
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SkinResultScreen(
          imageFile: widget.imageFile,
          result: result,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkiNova.offWhite,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),
                // Photo preview with scanning overlay
                _buildScanningPhoto(),
                const SizedBox(height: 48),
                // Spinner
                _buildSpinner(),
                const SizedBox(height: 28),
                // Step text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    _steps[_stepIndex],
                    key: ValueKey(_stepIndex),
                    style: SkiNova.heading3(color: SkiNova.wine),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Our AI is carefully reviewing your skin.\nThis takes just a moment.',
                  style: SkiNova.body(color: SkiNova.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                // Step dots
                _buildDots(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanningPhoto() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Photo
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: SkiNova.softShadow,
            border: Border.all(color: SkiNova.wine.withOpacity(0.2), width: 2),
          ),
          child: ClipOval(
            child: Image.file(widget.imageFile, fit: BoxFit.cover),
          ),
        ),
        // Scanning ring
        AnimatedBuilder(
          animation: _spinController,
          builder: (_, __) => Transform.rotate(
            angle: _spinController.value * 2 * 3.14159,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: SkiNova.wine.withOpacity(0.0), width: 0),
              ),
              child: CustomPaint(painter: _ScanRingPainter()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpinner() {
    return SizedBox(
      width: 36,
      height: 36,
      child: AnimatedBuilder(
        animation: _spinController,
        builder: (_, __) => CustomPaint(
          painter: _SpinnerPainter(_spinController.value),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps.length, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == _stepIndex ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color:
                i == _stepIndex ? SkiNova.wine : SkiNova.wine.withOpacity(0.2),
            borderRadius: SkiNova.radiusCircle,
          ),
        );
      }),
    );
  }
}

class _ScanRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          SkiNova.wine.withOpacity(0.0),
          SkiNova.wine.withOpacity(0.6),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      0,
      2 * 3.14159 * 0.75,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpinnerPainter extends CustomPainter {
  final double progress;
  _SpinnerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = SkiNova.wine.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fg = Paint()
      ..color = SkiNova.wine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      2 * 3.14159 * 0.7,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => old.progress != progress;
}
