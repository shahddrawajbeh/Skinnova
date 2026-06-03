// screens/skin_result_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/skin_analysis_model.dart';
import '../widgets/skinova_theme.dart';
import 'package:skinnova/screens/my_skin_routine_page.dart';
import 'package:skinnova/services/routine_api_service.dart';
import 'package:skinnova/features/skin_ai/services/skin_scan_api_service.dart';

class SkinResultScreen extends StatefulWidget {
  final File imageFile;
  final SkinAnalysisResult result;
  final String userId;

  const SkinResultScreen({
    super.key,
    required this.imageFile,
    required this.result,
    this.userId = '',
  });

  @override
  State<SkinResultScreen> createState() => _SkinResultScreenState();
}

class _SkinResultScreenState extends State<SkinResultScreen>
    with TickerProviderStateMixin {
  bool _showAllConcerns = false;
  RoutineTab _activeRoutineTab = RoutineTab.morning;
  bool _isSaving = false;

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    // Auto-save scan to backend (fire-and-forget)
    if (widget.userId.isNotEmpty) {
      _autoSaveScan();
    }
  }

  Future<void> _autoSaveScan() async {
    try {
      await SkinScanApiService.saveScan(
        userId: widget.userId,
        imageFile: widget.imageFile,
        result: widget.result,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: SkiNova.wine,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  List<SkinConcern> get _visibleConcerns =>
      _showAllConcerns ? widget.result.concerns : widget.result.topConcerns;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkiNova.offWhite,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    _buildOverallStatus(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Detected Concerns'),
                    const SizedBox(height: 14),
                    ..._visibleConcerns.map(_buildConcernCard),
                    if (widget.result.hasMoreConcerns && !_showAllConcerns)
                      _buildViewAllButton(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Your Skincare Routine'),
                    const SizedBox(height: 14),
                    _buildRoutineTabBar(),
                    const SizedBox(height: 14),
                    _buildRoutineSteps(),
                    const SizedBox(height: 16),
                    _buildDisclaimer(),
                    const SizedBox(height: 20),
                    _buildAddToRoutineButton(),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sliver App Bar (photo hero) ───────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: SkiNova.wine,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: SkiNova.radiusSmall,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: Colors.white),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(widget.imageFile, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    SkiNova.wine.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Skin Analysis Complete',
                      style: SkiNova.caption(color: Colors.white70)
                          .copyWith(letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('Your Results',
                      style: SkiNova.heading1(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overall status card ───────────────────────────────────────────────────

  Widget _buildOverallStatus() {
    final status = widget.result.overallStatus;
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SkiNova.surface,
        borderRadius: SkiNova.radiusLarge,
        boxShadow: SkiNova.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(status), color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Skin Status', style: SkiNova.caption()),
                const SizedBox(height: 2),
                Text(status.label, style: SkiNova.heading2(color: color)),
                Text(
                  '${widget.result.concerns.length} concern${widget.result.concerns.length == 1 ? '' : 's'} detected',
                  style: SkiNova.caption(),
                ),
              ],
            ),
          ),
          // Mini radial indicator
          _RadialScore(
            score: _overallScore(widget.result.concerns),
            color: color,
          ),
        ],
      ),
    );
  }

  double _overallScore(List<SkinConcern> concerns) {
    if (concerns.isEmpty) return 1.0;
    final avg = concerns.map((c) => c.severityScore).reduce((a, b) => a + b) /
        concerns.length;
    return 1.0 - avg; // higher = healthier
  }

  Color _statusColor(SkinConcernStatus status) {
    switch (status) {
      case SkinConcernStatus.good:
        return SkiNova.statusGood;
      case SkinConcernStatus.moderate:
        return SkiNova.statusModerate;
      case SkinConcernStatus.needsCare:
        return SkiNova.statusNeedsCare;
    }
  }

  IconData _statusIcon(SkinConcernStatus status) {
    switch (status) {
      case SkinConcernStatus.good:
        return Icons.check_circle_rounded;
      case SkinConcernStatus.moderate:
        return Icons.info_rounded;
      case SkinConcernStatus.needsCare:
        return Icons.warning_amber_rounded;
    }
  }

  // ── Section title ─────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
                color: SkiNova.wine, borderRadius: SkiNova.radiusCircle)),
        const SizedBox(width: 10),
        Text(title, style: SkiNova.heading3()),
      ],
    );
  }

  // ── Concern cards ─────────────────────────────────────────────────────────

  Widget _buildConcernCard(SkinConcern concern) {
    final color = _statusColor(concern.status);
    final pct = (concern.severityScore * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SkiNova.surface,
        borderRadius: SkiNova.radiusMedium,
        boxShadow: SkiNova.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status dot
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(concern.name, style: SkiNova.heading3())),
              // Status chip
              _StatusChip(status: concern.status, color: color),
              const SizedBox(width: 8),
              // Score text
              Text('$pct%',
                  style: SkiNova.body(color: color)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(concern.description, style: SkiNova.caption()),
          const SizedBox(height: 10),
          // Severity bar
          ClipRRect(
            borderRadius: SkiNova.radiusCircle,
            child: LinearProgressIndicator(
              value: concern.severityScore,
              minHeight: 5,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return GestureDetector(
      onTap: () => setState(() => _showAllConcerns = true),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: SkiNova.wineMuted,
          borderRadius: SkiNova.radiusMedium,
          border: Border.all(color: SkiNova.wine.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View full analysis (${widget.result.concerns.length - 3} more)',
              style: SkiNova.body(color: SkiNova.wine)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded,
                color: SkiNova.wine, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Routine tabs ──────────────────────────────────────────────────────────

  Widget _buildRoutineTabBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: SkiNova.surface,
        borderRadius: SkiNova.radiusMedium,
        boxShadow: SkiNova.softShadow,
      ),
      child: Row(
        children: RoutineTab.values.map((tab) {
          final isActive = _activeRoutineTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeRoutineTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: isActive ? SkiNova.wineGradient : null,
                  borderRadius: SkiNova.radiusSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab == RoutineTab.morning
                          ? Icons.wb_sunny_rounded
                          : Icons.nights_stay_rounded,
                      size: 16,
                      color: isActive ? Colors.white : SkiNova.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab == RoutineTab.morning ? 'Morning' : 'Evening',
                      style: SkiNova.body(
                        color: isActive ? Colors.white : SkiNova.textSecondary,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoutineSteps() {
    final steps = _activeRoutineTab == RoutineTab.morning
        ? widget.result.routine.morning
        : widget.result.routine.evening;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(_activeRoutineTab),
        children: steps.asMap().entries.map((e) {
          return _RoutineStepCard(
            stepNumber: e.key + 1,
            step: e.value,
            isLast: e.key == steps.length - 1,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddToRoutineButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isSaving ? null : _saveAndNavigateToRoutine,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: _isSaving ? null : SkiNova.wineGradient,
              color: _isSaving ? SkiNova.wine.withOpacity(0.5) : null,
              borderRadius: SkiNova.radiusMedium,
            ),
            child: _isSaving
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.spa_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Save to My Routine',
                        style: SkiNova.body(color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: SkiNova.surface,
              borderRadius: SkiNova.radiusMedium,
              border:
                  Border.all(color: SkiNova.wine.withOpacity(0.35), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined,
                    color: SkiNova.wine, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Scan Again',
                  style: SkiNova.body(color: SkiNova.wine)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAndNavigateToRoutine() async {
    setState(() => _isSaving = true);

    // Resolve userId: prefer passed param, fall back to SharedPreferences
    String userId = widget.userId;
    if (userId.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId') ?? '';
    }

    // 1. Try saving to backend
    bool savedToBackend = false;
    if (userId.isNotEmpty) {
      try {
        final result = await RoutineApiService.saveAiRoutine(
          userId: userId,
          routine: widget.result.routine,
          detectedConcerns: widget.result.concerns.map((c) => c.name).toList(),
        );
        savedToBackend = result != null;
      } catch (_) {}
    }

    // 2. Always persist to SharedPreferences as fallback
    // 2. Always persist to SharedPreferences too
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'skinova_ai_routine_$userId',
      jsonEncode(widget.result.routine.toJson()),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    Navigator.pop(context);
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SkiNova.divider.withOpacity(0.5),
        borderRadius: SkiNova.radiusMedium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: SkiNova.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This analysis is powered by AI and is for informational purposes only. Always consult a dermatologist for medical advice.',
              style: SkiNova.caption(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Enums & sub-widgets ───────────────────────────────────────────────────────

enum RoutineTab { morning, evening }

class _StatusChip extends StatelessWidget {
  final SkinConcernStatus status;
  final Color color;

  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: SkiNova.radiusCircle,
      ),
      child: Text(
        status.label,
        style: SkiNova.label(color: color),
      ),
    );
  }
}

class _RadialScore extends StatelessWidget {
  final double score; // 0–1 (higher = healthier)
  final Color color;

  const _RadialScore({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _RadialPainter(score: score, color: color),
        child: Center(
          child: Text(
            '${(score * 100).toInt()}',
            style: SkiNova.caption(color: color)
                .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _RadialPainter extends CustomPainter {
  final double score;
  final Color color;
  _RadialPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final bg = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * score,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _RoutineStepCard extends StatelessWidget {
  final int stepNumber;
  final RoutineStep step;
  final bool isLast;

  const _RoutineStepCard({
    required this.stepNumber,
    required this.step,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: SkiNova.wineGradient,
                  shape: BoxShape.circle,
                  boxShadow: SkiNova.wineShadow,
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: SkiNova.label(color: Colors.white),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: SkiNova.wine.withOpacity(0.2),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SkiNova.surface,
                borderRadius: SkiNova.radiusMedium,
                boxShadow: SkiNova.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child:
                              Text(step.stepName, style: SkiNova.heading3())),
                      _IngredientBadge(ingredient: step.keyIngredient),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(step.productCategory,
                      style: SkiNova.caption(color: SkiNova.wine)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(step.why, style: SkiNova.caption()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientBadge extends StatelessWidget {
  final String ingredient;
  const _IngredientBadge({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: SkiNova.wineMuted,
        borderRadius: SkiNova.radiusCircle,
      ),
      child: Text(
        ingredient,
        style: SkiNova.label(color: SkiNova.wine).copyWith(fontSize: 10),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
