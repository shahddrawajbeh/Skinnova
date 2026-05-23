import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  static const bg = Color(0xFFF7F4F3);
  static const wine = Color(0xFF5B2333);
  static const cream = Color(0xFFFDF9F8);
  static const border = Color(0xFFE8E0DD);
  static const textPrimary = Color(0xFF1A0A0E);
  static const textSecondary = Color(0xFF8A6E74);
  static const success = Color(0xFF2D7D5A);
  static const successBg = Color(0xFFEAF5EF);
  static const amber = Color(0xFFB86A1A);
  static const amberBg = Color(0xFFFFF3E0);
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class RoutineStep {
  final int step;
  final String name;
  final String duration;
  final String instruction;
  final String category;

  RoutineStep({
    required this.step,
    required this.name,
    required this.duration,
    required this.instruction,
    required this.category,
  });

  factory RoutineStep.fromJson(Map<String, dynamic> json) => RoutineStep(
        step: json['step'] ?? 0,
        name: json['name'] ?? '',
        duration: json['duration'] ?? '',
        instruction: json['instruction'] ?? '',
        category: json['category'] ?? '',
      );
}

class SkinAnalysisResult {
  final int skinScore;
  final String skinType;
  final String severity;
  final List<String> conditions;
  final String expertAnalysis;
  final List<RoutineStep> morningRoutine;
  final List<RoutineStep> nightRoutine;

  SkinAnalysisResult({
    required this.skinScore,
    required this.skinType,
    required this.severity,
    required this.conditions,
    required this.expertAnalysis,
    required this.morningRoutine,
    required this.nightRoutine,
  });

  factory SkinAnalysisResult.fromJson(Map<String, dynamic> json) =>
      SkinAnalysisResult(
        skinScore: json['skinScore'] ?? 0,
        skinType: json['skinType'] ?? 'Unknown',
        severity: json['severity'] ?? 'Mild',
        conditions: List<String>.from(json['conditions'] ?? []),
        expertAnalysis: json['expertAnalysis'] ?? '',
        morningRoutine: (json['morningRoutine'] as List? ?? [])
            .map((e) => RoutineStep.fromJson(e))
            .toList(),
        nightRoutine: (json['nightRoutine'] as List? ?? [])
            .map((e) => RoutineStep.fromJson(e))
            .toList(),
      );

  static SkinAnalysisResult mock() => SkinAnalysisResult(
        skinScore: 72,
        skinType: 'Combination',
        severity: 'Moderate',
        conditions: [
          'Acne (T-zone)',
          'Mild Hyperpigmentation',
          'Enlarged Pores'
        ],
        expertAnalysis:
            'Your skin shows signs of a combination type with an oily T-zone and '
            'normal-to-dry cheeks. The acne clusters visible on your forehead and '
            'chin suggest excess sebum production possibly triggered by hormonal '
            'fluctuation or barrier disruption. The mild hyperpigmentation spots are '
            'post-inflammatory marks from previous breakouts. Enlarged pores on the '
            'nose indicate congestion that can be addressed with regular exfoliation. '
            'Your skin barrier appears slightly compromised — prioritize hydration '
            'and avoid harsh stripping cleansers.',
        morningRoutine: [
          RoutineStep(
              step: 1,
              name: 'Gentle Cleanser',
              duration: '60 sec',
              instruction:
                  'Use a pH-balanced, sulfate-free cleanser. Massage in circular motions, rinse with lukewarm water.',
              category: 'Cleanse'),
          RoutineStep(
              step: 2,
              name: 'Niacinamide Toner',
              duration: '30 sec',
              instruction:
                  'Apply with a cotton pad. Niacinamide (5–10%) reduces pore appearance and controls oil.',
              category: 'Tone'),
          RoutineStep(
              step: 3,
              name: 'Vitamin C Serum',
              duration: '1 min',
              instruction:
                  'Pat 3–4 drops onto skin. Targets hyperpigmentation and provides antioxidant protection.',
              category: 'Treat'),
          RoutineStep(
              step: 4,
              name: 'Oil-Free Moisturiser',
              duration: '30 sec',
              instruction:
                  'Light gel-cream texture. Focus on dry cheek areas, use sparingly on T-zone.',
              category: 'Moisturize'),
          RoutineStep(
              step: 5,
              name: 'SPF 50 Sunscreen',
              duration: '30 sec',
              instruction:
                  'Non-negotiable. Prevents worsening of hyperpigmentation. Reapply every 2 hours outdoors.',
              category: 'Protect'),
        ],
        nightRoutine: [
          RoutineStep(
              step: 1,
              name: 'Micellar Water / Oil Cleanser',
              duration: '90 sec',
              instruction:
                  'First cleanse — removes sunscreen, makeup and surface pollution thoroughly.',
              category: 'Cleanse'),
          RoutineStep(
              step: 2,
              name: 'Salicylic Acid Cleanser',
              duration: '60 sec',
              instruction:
                  'Second cleanse with BHA. Penetrates pores, dissolves excess sebum and prevents blackheads.',
              category: 'Cleanse'),
          RoutineStep(
              step: 3,
              name: 'AHA Exfoliant (2–3×/week)',
              duration: '10 min',
              instruction:
                  'Glycolic or lactic acid. Resurfaces skin and fades post-acne marks. Do not use daily.',
              category: 'Exfoliate'),
          RoutineStep(
              step: 4,
              name: 'Retinol 0.25%',
              duration: '1 min',
              instruction:
                  'Start low, go slow. Accelerates cell turnover and prevents clogged pores. Avoid eye area.',
              category: 'Treat'),
          RoutineStep(
              step: 5,
              name: 'Hyaluronic Acid Serum',
              duration: '30 sec',
              instruction:
                  'Apply to damp skin to lock in moisture before the barrier cream.',
              category: 'Hydrate'),
          RoutineStep(
              step: 6,
              name: 'Barrier Repair Cream',
              duration: '30 sec',
              instruction:
                  'Rich ceramide-based cream. Repairs and seals the skin barrier overnight.',
              category: 'Moisturize'),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCAN PAGE
// ─────────────────────────────────────────────────────────────────────────────

class AiSkinScanPage extends StatefulWidget {
  const AiSkinScanPage({super.key});

  @override
  State<AiSkinScanPage> createState() => _AiSkinScanPageState();
}

class _AiSkinScanPageState extends State<AiSkinScanPage>
    with TickerProviderStateMixin {
  static const String baseUrl = "http://192.168.1.17:5000/api";

  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0;
  final List<File?> _images = [null, null, null];
  bool _isAnalyzing = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  static const _stepLabels = ['Front', 'Left', 'Right'];
  static const _stepInstructions = [
    'Face the camera directly.\nKeep your face centred in the oval.',
    'Turn your face slightly to the LEFT.\nBoth eyes should be visible.',
    'Turn your face slightly to the RIGHT.\nKeep chin level.',
  ];
  static const _stepIcons = [
    Icons.face_outlined,
    Icons.turn_left_outlined,
    Icons.turn_right_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.97,
      upperBound: 1.03,
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  int get _completedCount => _images.where((f) => f != null).length;
  bool get _allDone => _completedCount == 3;

  void _goToStep(int index) {
    if (index == _currentStep) return;
    _fadeCtrl.reset();
    setState(() => _currentStep = index);
    _fadeCtrl.forward();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return;

    _fadeCtrl.reset();
    setState(() {
      _images[_currentStep] = File(picked.path);
      if (_currentStep < 2) _currentStep++;
    });
    _fadeCtrl.forward();
    HapticFeedback.lightImpact();
  }

  void _removeImage(int index) {
    setState(() => _images[index] = null);
    _goToStep(index);
    HapticFeedback.mediumImpact();
  }

  Future<void> _analyzeSkin() async {
    if (!_allDone) return;

    setState(() => _isAnalyzing = true);
    HapticFeedback.heavyImpact();

    try {
      final uri = Uri.parse("$baseUrl/skin-scan/analyze");

      final request = http.MultipartRequest("POST", uri);

      request.files.add(
        await http.MultipartFile.fromPath("frontImage", _images[0]!.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath("leftImage", _images[1]!.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath("rightImage", _images[2]!.path),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        throw Exception(
            "Server error: ${streamedResponse.statusCode}\n$responseBody");
      }

      final Map<String, dynamic> data = jsonDecode(responseBody);
      final result = SkinAnalysisResult.fromJson(data);

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => SkinScanResultPage(result: result),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not connect to AI analysis.\n$e"),
          backgroundColor: AppColors.wine,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _Header(completedCount: _completedCount),
          _StepIndicator(
            currentStep: _currentStep,
            images: _images,
            onTap: _goToStep,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _images[_currentStep] != null
                  ? _ImagePreview(
                      image: _images[_currentStep]!,
                      label: _stepLabels[_currentStep],
                      onRemove: () => _removeImage(_currentStep),
                    )
                  : _GuidedCapture(
                      pulseAnim: _pulseAnim,
                      label: _stepLabels[_currentStep],
                      instruction: _stepInstructions[_currentStep],
                      icon: _stepIcons[_currentStep],
                    ),
            ),
          ),
          _BottomActions(
            allDone: _allDone,
            isAnalyzing: _isAnalyzing,
            completedCount: _completedCount,
            onGallery: () => _pickImage(ImageSource.gallery),
            onCamera: () => _pickImage(ImageSource.camera),
            onAnalyze: _analyzeSkin,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCAN PAGE SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int completedCount;
  const _Header({required this.completedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.wine,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Skin Scan',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Capture 3 angles for accurate analysis',
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final done = i < completedCount;
                return Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? Colors.white : Colors.white.withOpacity(0.3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<File?> images;
  final ValueChanged<int> onTap;

  const _StepIndicator({
    required this.currentStep,
    required this.images,
    required this.onTap,
  });

  static const _labels = ['Front', 'Left Side', 'Right Side'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.wine,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == currentStep;
          final isDone = images[i] != null;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : isDone
                          ? Colors.white.withOpacity(0.18)
                          : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? Colors.white
                        : isDone
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isDone) ...[
                      Icon(Icons.check_circle,
                          size: 13,
                          color: isActive ? AppColors.wine : Colors.white),
                      const SizedBox(width: 5),
                    ] else ...[
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? AppColors.wine
                                : Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? AppColors.wine
                                  : Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                    Text(
                      _labels[i],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppColors.wine
                            : isDone
                                ? Colors.white
                                : Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GuidedCapture extends StatelessWidget {
  final Animation<double> pulseAnim;
  final String label;
  final String instruction;
  final IconData icon;

  const _GuidedCapture({
    required this.pulseAnim,
    required this.label,
    required this.instruction,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bg,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.amberBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.amber.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    color: AppColors.amber, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Good lighting + neutral expression = better results',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: AppColors.amber,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: ScaleTransition(
                scale: pulseAnim,
                child: CustomPaint(
                  size: const Size(200, 260),
                  painter: _FaceGuidePainter(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.wine, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.wine,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final File image;
  final String label;
  final VoidCallback onRemove;

  const _ImagePreview({
    required this.image,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(image, fit: BoxFit.cover),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _FaceOverlayPainter()),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 13, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Tap × to retake this photo',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  final bool allDone;
  final bool isAnalyzing;
  final int completedCount;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onAnalyze;

  const _BottomActions({
    required this.allDone,
    required this.isAnalyzing,
    required this.completedCount,
    required this.onGallery,
    required this.onCamera,
    required this.onAnalyze,
  });

  String get _analyzeLabel {
    if (allDone) return 'Analyze My Skin';
    final r = 3 - completedCount;
    return 'Add $r more photo${r == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _OutlineBtn(
                  icon: Icons.photo_library_outlined,
                  label: 'Upload Photo',
                  onTap: onGallery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OutlineBtn(
                  icon: Icons.camera_alt_outlined,
                  label: 'Take Photo',
                  onTap: onCamera,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (allDone && !isAnalyzing) ? onAnalyze : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wine,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.wine.withOpacity(0.3),
                disabledForegroundColor: Colors.white54,
                elevation: allDone ? 4 : 0,
                shadowColor: AppColors.wine.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isAnalyzing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Analysing your skin…',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  : Text(
                      _analyzeLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style:
                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.wine,
          side: BorderSide(color: AppColors.wine.withOpacity(0.3)),
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ovalPaint = Paint()
      ..color = AppColors.wine.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final cornerPaint = Paint()
      ..color = AppColors.wine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.03,
      size.width * 0.8,
      size.height * 0.94,
    );

    // Dashed oval
    final ovalPath = Path()..addOval(rect);
    final metrics = ovalPath.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      const dash = 10.0, gap = 6.0;
      while (dist < metric.length) {
        final end = (dist + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), ovalPaint);
        dist += dash + gap;
      }
    }

    // Corner brackets
    final cLen = size.width * 0.12;
    final bracketPath = Path();
    // top-left
    bracketPath.moveTo(rect.left, rect.top + cLen);
    bracketPath.lineTo(rect.left, rect.top);
    bracketPath.lineTo(rect.left + cLen, rect.top);
    // top-right
    bracketPath.moveTo(rect.right - cLen, rect.top);
    bracketPath.lineTo(rect.right, rect.top);
    bracketPath.lineTo(rect.right, rect.top + cLen);
    // bottom-left
    bracketPath.moveTo(rect.left, rect.bottom - cLen);
    bracketPath.lineTo(rect.left, rect.bottom);
    bracketPath.lineTo(rect.left + cLen, rect.bottom);
    // bottom-right
    bracketPath.moveTo(rect.right - cLen, rect.bottom);
    bracketPath.lineTo(rect.right, rect.bottom);
    bracketPath.lineTo(rect.right, rect.bottom - cLen);
    canvas.drawPath(bracketPath, cornerPaint);

    // Crosshair
    final crossPaint = Paint()
      ..color = AppColors.wine.withOpacity(0.3)
      ..strokeWidth = 1;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx - 12, cy), Offset(cx + 12, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - 12), Offset(cx, cy + 12), crossPaint);
    canvas.drawCircle(
        Offset(cx, cy), 2.5, Paint()..color = AppColors.wine.withOpacity(0.4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.06, size.width * 0.6,
          size.height * 0.76),
      Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULTS PAGE
// ─────────────────────────────────────────────────────────────────────────────

class SkinScanResultPage extends StatefulWidget {
  final SkinAnalysisResult result;
  const SkinScanResultPage({super.key, required this.result});

  @override
  State<SkinScanResultPage> createState() => _SkinScanResultPageState();
}

class _SkinScanResultPageState extends State<SkinScanResultPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Color get _severityColor {
    switch (widget.result.severity.toLowerCase()) {
      case 'mild':
        return AppColors.success;
      case 'moderate':
        return AppColors.amber;
      case 'severe':
        return const Color(0xFFC0392B);
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _severityBg {
    switch (widget.result.severity.toLowerCase()) {
      case 'mild':
        return AppColors.successBg;
      case 'moderate':
        return AppColors.amberBg;
      case 'severe':
        return const Color(0xFFFDECEA);
      default:
        return AppColors.bg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.wine,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: _ResultHero(result: r),
            ),
            title: Text(
              'Skin Analysis',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _ConditionChips(
              conditions: r.conditions,
              severity: r.severity,
              severityColor: _severityColor,
              severityBg: _severityBg,
            ),
          ),
          SliverToBoxAdapter(
            child: _ExpertAnalysisCard(analysis: r.expertAnalysis),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.wine,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.wine,
                indicatorWeight: 2.5,
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 13.5),
                unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500, fontSize: 13.5),
                tabs: const [
                  Tab(
                      icon: Icon(Icons.wb_sunny_outlined, size: 18),
                      text: 'Morning'),
                  Tab(
                      icon: Icon(Icons.bedtime_outlined, size: 18),
                      text: 'Night'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _RoutineList(steps: r.morningRoutine, isNight: false),
            _RoutineList(steps: r.nightRoutine, isNight: true),
          ],
        ),
      ),
    );
  }
}

class _ResultHero extends StatelessWidget {
  final SkinAnalysisResult result;
  const _ResultHero({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.wine,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 56, 20, 16),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${result.skinScore}',
                  style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1),
                ),
                Text('Score',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.white60)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${result.skinType} Skin',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.conditions.length} concerns detected',
                  style:
                      GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: result.skinScore / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionChips extends StatelessWidget {
  final List<String> conditions;
  final String severity;
  final Color severityColor;
  final Color severityBg;

  const _ConditionChips({
    required this.conditions,
    required this.severity,
    required this.severityColor,
    required this.severityBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Detected Conditions',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: severityBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  severity,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: severityColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: conditions.map((c) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppColors.wine),
                    ),
                    const SizedBox(width: 7),
                    Text(c,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ExpertAnalysisCard extends StatefulWidget {
  final String analysis;
  const _ExpertAnalysisCard({required this.analysis});

  @override
  State<_ExpertAnalysisCard> createState() => _ExpertAnalysisCardState();
}

class _ExpertAnalysisCardState extends State<_ExpertAnalysisCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.wine.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.biotech_outlined,
                      color: AppColors.wine, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expert Analysis',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('AI-powered skin assessment',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Text(
              widget.analysis,
              maxLines: _expanded ? 100 : 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textPrimary, height: 1.65),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Row(
                children: [
                  Text(
                    _expanded ? 'Show less' : 'Read full analysis',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.wine),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.wine,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineList extends StatelessWidget {
  final List<RoutineStep> steps;
  final bool isNight;
  const _RoutineList({required this.steps, required this.isNight});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      itemCount: steps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RoutineCard(step: steps[i], isNight: isNight),
    );
  }
}

class _RoutineCard extends StatefulWidget {
  final RoutineStep step;
  final bool isNight;
  const _RoutineCard({required this.step, required this.isNight});

  @override
  State<_RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<_RoutineCard> {
  bool _expanded = false;

  Color get _catColor {
    switch (widget.step.category.toLowerCase()) {
      case 'cleanse':
        return const Color(0xFF1A6BAE);
      case 'tone':
        return const Color(0xFF7B3FA0);
      case 'treat':
        return AppColors.wine;
      case 'exfoliate':
        return AppColors.amber;
      case 'moisturize':
        return AppColors.success;
      case 'protect':
        return const Color(0xFFB86A1A);
      case 'hydrate':
        return const Color(0xFF0E7C7B);
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _catBg {
    switch (widget.step.category.toLowerCase()) {
      case 'cleanse':
        return const Color(0xFFE8F3FC);
      case 'tone':
        return const Color(0xFFF5EAFA);
      case 'treat':
        return const Color(0xFFFAEEF0);
      case 'exfoliate':
        return AppColors.amberBg;
      case 'moisturize':
        return AppColors.successBg;
      case 'protect':
        return const Color(0xFFFFF3E0);
      case 'hydrate':
        return const Color(0xFFE6F7F7);
      default:
        return AppColors.bg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expanded ? _catColor.withOpacity(0.35) : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.isNight
                          ? AppColors.wine.withOpacity(0.08)
                          : AppColors.amberBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.step.step}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              widget.isNight ? AppColors.wine : AppColors.amber,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.step.name,
                            style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _catBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(widget.step.category,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _catColor)),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.timer_outlined,
                                size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(widget.step.duration,
                                style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (_expanded)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.step.instruction,
                  style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                      height: 1.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BAR DELEGATE
// ─────────────────────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: AppColors.bg, child: tabBar);

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => false;
}
