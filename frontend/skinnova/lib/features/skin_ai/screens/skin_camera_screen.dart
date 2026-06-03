// screens/skin_camera_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../helpers/feature_flags.dart';

import '../models/skin_scan_history_model.dart';
import '../services/skin_analysis_service.dart';
import '../services/skin_scan_api_service.dart';
import '../widgets/skinova_theme.dart';
import 'skin_analyzing_screen.dart';
import 'skin_scan_history_screen.dart';
import 'skin_scan_details_screen.dart';

class SkinCameraScreen extends StatefulWidget {
  final String userId;
  const SkinCameraScreen({super.key, this.userId = ''});

  @override
  State<SkinCameraScreen> createState() => _SkinCameraScreenState();
}

class _SkinCameraScreenState extends State<SkinCameraScreen>
    with TickerProviderStateMixin {
  final _picker = ImagePicker();
  bool _isValidating = false;
  String? _validationError;

  List<SkinScanModel> _recentScans = [];
  bool _scansLoaded = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadRecentScans();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentScans() async {
    if (widget.userId.isEmpty) return;
    try {
      final scans = await SkinScanApiService.getHistory(widget.userId);
      if (!mounted) return;
      setState(() {
        _recentScans = scans.take(3).toList();
        _scansLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _scansLoaded = true);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // Feature flag: allowSkinScans
    if (!await checkFeatureFlag(context, 'allowSkinScans',
        blockedMessage: 'Skin scans are currently disabled.')) return;

    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.front,
    );
    if (xFile == null) return;
    await _processImage(File(xFile.path));
  }

  Future<void> _processImage(File file) async {
    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    final result = await SkinAnalysisService.validateImage(file);

    if (!mounted) return;

    if (result.isValid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SkinAnalyzingScreen(imageFile: file, userId: widget.userId),
        ),
      );
    } else {
      setState(() {
        _validationError = _errorMessage(result.error);
        _isValidating = false;
      });
    }
  }

  String _errorMessage(ImageValidationError error) {
    switch (error) {
      case ImageValidationError.tooBlurry:
        return 'Image is too blurry. Please take a clearer photo in good lighting.';
      case ImageValidationError.tooSmall:
        return 'Image resolution is too low. Please use a higher quality photo.';
      case ImageValidationError.tooDark:
        return 'Image is too dark. Please take a photo in a well-lit area.';
      case ImageValidationError.noFaceDetected:
        return 'No face detected. Please ensure your face is clearly visible.';
      default:
        return 'Unable to process the image. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkiNova.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            //_buildHeader(context),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: SkiNova.surface,
                borderRadius: SkiNova.radiusSmall,
                boxShadow: SkiNova.softShadow,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: SkiNova.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Text('Skin Analysis', style: SkiNova.heading3()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Know your skin, ',
                style: SkiNova.heading1().copyWith(
                  fontSize: 20,
                ),
              ),
              Text(
                'inside and out.',
                style: SkiNova.heading1(
                  color: SkiNova.wine,
                ).copyWith(
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Take or upload a clear, well-lit photo of your face to receive a personalised skin analysis.',
            style: SkiNova.body(
              color: SkiNova.textSecondary,
            ).copyWith(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Camera frame illustration
          _buildCameraFrame(),

          const SizedBox(height: 32),

          // Tips
          _buildTips(),

          const SizedBox(height: 32),

          // Error message
          if (_validationError != null) ...[
            _buildErrorBanner(_validationError!),
            const SizedBox(height: 16),
          ],

          // Action buttons
          _buildActionButtons(),

          const SizedBox(height: 28),

          // Recent scans section
          if (_scansLoaded) _buildRecentScans(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRecentScans() {
    if (_recentScans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recent AI Scans', style: SkiNova.heading3()),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SkinScanHistoryScreen(userId: widget.userId),
                ),
              ).then((_) => _loadRecentScans()),
              child: Text(
                'View all',
                style: SkiNova.body(color: SkiNova.wine)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recentScans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _RecentScanCard(
              scan: _recentScans[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SkinScanDetailsScreen(scan: _recentScans[i]),
                ),
              ).then((_) => _loadRecentScans()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraFrame() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: _pulseAnim.value,
          child: child,
        ),
        child: Container(
          width: 220,
          height: 260,
          decoration: BoxDecoration(
            color: SkiNova.surface,
            borderRadius: SkiNova.radiusLarge,
            boxShadow: SkiNova.softShadow,
            border:
                Border.all(color: SkiNova.wine.withOpacity(0.15), width: 1.5),
          ),
          child: Stack(
            children: [
              // Corner accents
              ..._cornerAccents(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: SkiNova.wineGradient,
                        shape: BoxShape.circle,
                        boxShadow: SkiNova.wineShadow,
                      ),
                      child: const Icon(Icons.face_retouching_natural_rounded,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    Text('Face detection',
                        style: SkiNova.caption(color: SkiNova.textSecondary)),
                    const SizedBox(height: 4),
                    Text('AI-powered analysis',
                        style: SkiNova.label(color: SkiNova.wine)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _cornerAccents() {
    const size = 22.0;
    const width = 2.5;
    final color = SkiNova.wine;

    return [
      // Top-left
      Positioned(
        top: 14,
        left: 14,
        child: _cornerShape(color, size, width, top: true, left: true),
      ),
      // Top-right
      Positioned(
        top: 14,
        right: 14,
        child: _cornerShape(color, size, width, top: true, left: false),
      ),
      // Bottom-left
      Positioned(
        bottom: 14,
        left: 14,
        child: _cornerShape(color, size, width, top: false, left: true),
      ),
      // Bottom-right
      Positioned(
        bottom: 14,
        right: 14,
        child: _cornerShape(color, size, width, top: false, left: false),
      ),
    ];
  }

  Widget _cornerShape(Color color, double size, double width,
      {required bool top, required bool left}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerPainter(color: color, width: width, top: top, left: left),
    );
  }

  Widget _buildTips() {
    final tips = [
      (
        'wb_sunny',
        'Good lighting',
        'Natural or bright indoor light works best'
      ),
      (
        'center_focus_strong',
        'Face centered',
        'Keep your face in the center frame'
      ),
      ('no_makeup', 'Bare skin', 'Remove makeup for accurate results'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tips for best results', style: SkiNova.heading3()),
        const SizedBox(height: 12),
        ...tips.map((t) => _tipRow(t.$1, t.$2, t.$3)),
      ],
    );
  }

  Widget _tipRow(String iconName, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SkiNova.wineMuted,
              borderRadius: SkiNova.radiusSmall,
            ),
            child: Icon(
              _iconData(iconName),
              size: 18,
              color: SkiNova.wine,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SkiNova.body()),
                Text(subtitle, style: SkiNova.caption()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'wb_sunny':
        return Icons.wb_sunny_outlined;
      case 'center_focus_strong':
        return Icons.center_focus_strong_outlined;
      default:
        return Icons.face_outlined;
    }
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SkiNova.wineMuted,
        borderRadius: SkiNova.radiusMedium,
        border: Border.all(color: SkiNova.wine.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: SkiNova.wine),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message, style: SkiNova.body(color: SkiNova.wine))),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isValidating) {
      return const Center(
        child: CircularProgressIndicator(color: SkiNova.wine),
      );
    }

    return Column(
      children: [
        // Take Photo – primary
        _PrimaryButton(
          label: 'Take a Photo',
          icon: Icons.camera_alt_rounded,
          onTap: () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(height: 12),
        // Upload – secondary
        _SecondaryButton(
          label: 'Upload from Gallery',
          icon: Icons.photo_library_outlined,
          onTap: () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }
}

// ── Reusable button widgets ────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: SkiNova.wineGradient,
          borderRadius: SkiNova.radiusCircle,
          boxShadow: SkiNova.wineShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Text(label,
                style: SkiNova.heading3(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: SkiNova.surface,
          borderRadius: SkiNova.radiusCircle,
          border: Border.all(color: SkiNova.wine.withOpacity(0.4), width: 1.5),
          boxShadow: SkiNova.softShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: SkiNova.wine),
            const SizedBox(width: 10),
            Text(label,
                style: SkiNova.heading3(color: SkiNova.wine)
                    .copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Recent scan card ──────────────────────────────────────────────────────────

class _RecentScanCard extends StatelessWidget {
  final SkinScanModel scan;
  final VoidCallback onTap;

  const _RecentScanCard({required this.scan, required this.onTap});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  String get _date {
    final d = scan.createdAt;
    return '${d.day} ${_months[d.month - 1]}';
  }

  Color get _statusColor {
    switch (scan.overallStatus.toLowerCase()) {
      case 'good':
        return SkiNova.statusGood;
      case 'moderate':
        return SkiNova.statusModerate;
      default:
        return SkiNova.statusNeedsCare;
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseUrl = 'http://192.168.1.15:5000';
    final imageUrl = scan.imageUrl.isEmpty
        ? null
        : scan.imageUrl.startsWith('http')
            ? scan.imageUrl
            : '$baseUrl${scan.imageUrl}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: SkiNova.surface,
          borderRadius: SkiNova.radiusMedium,
          boxShadow: SkiNova.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 90,
                        color: SkiNova.wineMuted,
                        child: const Icon(Icons.face_retouching_natural_rounded,
                            color: SkiNova.wine, size: 32),
                      ),
                    )
                  : Container(
                      height: 90,
                      color: SkiNova.wineMuted,
                      child: const Icon(Icons.face_retouching_natural_rounded,
                          color: SkiNova.wine, size: 32),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
              child: Text(_date, style: SkiNova.caption()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      scan.overallStatus.isEmpty ? '—' : scan.overallStatus,
                      style: SkiNova.caption(color: _statusColor)
                          .copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Corner accent painter ──────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  final Color color;
  final double width;
  final bool top;
  final bool left;

  const _CornerPainter(
      {required this.color,
      required this.width,
      required this.top,
      required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
