import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/skin_scan_history_model.dart';
import '../widgets/skinova_theme.dart';

class SkinScanDetailsScreen extends StatefulWidget {
  final SkinScanModel scan;
  const SkinScanDetailsScreen({super.key, required this.scan});

  @override
  State<SkinScanDetailsScreen> createState() => _SkinScanDetailsScreenState();
}

class _SkinScanDetailsScreenState extends State<SkinScanDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}  •  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkiNova.offWhite,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildMeta(),
                const SizedBox(height: 24),
                _buildSectionTitle('Detected Concerns'),
                const SizedBox(height: 12),
                if (widget.scan.detectedConcerns.isEmpty)
                  _buildEmpty('No concerns detected.')
                else
                  ...widget.scan.detectedConcerns.map(_buildConcernRow),
                const SizedBox(height: 28),
                _buildSectionTitle('Recommended Routine'),
                const SizedBox(height: 12),
                _buildRoutineTabs(),
                const SizedBox(height: 12),
                _buildRoutineList(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
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
            _buildHeroImage(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    SkiNova.wine.withOpacity(0.75),
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
                  Text('Scan Result',
                      style: SkiNova.caption(color: Colors.white70)
                          .copyWith(letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(_formatDate(widget.scan.createdAt),
                      style: SkiNova.heading3(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    if (widget.scan.imageUrl.isEmpty) {
      return Container(
        color: SkiNova.wineMuted,
        child: const Icon(Icons.face_retouching_natural_rounded,
            size: 64, color: SkiNova.wine),
      );
    }
    const baseUrl = 'http://192.168.1.15:5000';
    final fullUrl = widget.scan.imageUrl.startsWith('http')
        ? widget.scan.imageUrl
        : '$baseUrl${widget.scan.imageUrl}';
    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: SkiNova.wineMuted,
        child: const Icon(Icons.face_retouching_natural_rounded,
            size: 64, color: SkiNova.wine),
      ),
    );
  }

  Widget _buildMeta() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: SkiNova.wineGradient,
        borderRadius: SkiNova.radiusLarge,
        boxShadow: SkiNova.wineShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Status',
                    style: SkiNova.caption(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  widget.scan.overallStatus.isEmpty
                      ? 'Unknown'
                      : widget.scan.overallStatus,
                  style: SkiNova.heading2(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.scan.concernCount} concern${widget.scan.concernCount == 1 ? '' : 's'}',
                  style: SkiNova.body(color: Colors.white70),
                ),
              ],
            ),
          ),
          if (widget.scan.skinScore != null)
            _RadialScore(score: widget.scan.skinScore! / 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
              color: SkiNova.wine, borderRadius: SkiNova.radiusCircle),
        ),
        const SizedBox(width: 10),
        Text(title, style: SkiNova.heading3()),
      ],
    );
  }

  Widget _buildEmpty(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(msg, style: SkiNova.body(color: SkiNova.textSecondary)),
    );
  }

  Widget _buildConcernRow(ScanConcern concern) {
    final pct = (concern.severityScore * 100).toInt();
    final color = _statusColor(concern.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(concern.name, style: SkiNova.heading3())),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: SkiNova.radiusCircle,
                ),
                child: Text(concern.status, style: SkiNova.label(color: color)),
              ),
              const SizedBox(width: 8),
              Text('$pct%',
                  style: SkiNova.body(color: color)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          if (concern.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(concern.description, style: SkiNova.caption()),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: SkiNova.radiusCircle,
            child: LinearProgressIndicator(
              value: concern.severityScore,
              minHeight: 4,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'good':
        return SkiNova.statusGood;
      case 'moderate':
        return SkiNova.statusModerate;
      default:
        return SkiNova.statusNeedsCare;
    }
  }

  Widget _buildRoutineTabs() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: SkiNova.surface,
        borderRadius: SkiNova.radiusMedium,
        boxShadow: SkiNova.softShadow,
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.wb_sunny_rounded, 'Morning'),
          _buildTab(1, Icons.nights_stay_rounded, 'Evening'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.index = index;
          setState(() {});
        },
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
              Icon(icon,
                  size: 16,
                  color: isActive ? Colors.white : SkiNova.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: SkiNova.body(
                        color: isActive ? Colors.white : SkiNova.textSecondary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutineList() {
    final steps = _tabController.index == 0
        ? widget.scan.morningRoutine
        : widget.scan.eveningRoutine;

    if (steps.isEmpty) {
      return _buildEmpty('No routine steps for this time of day.');
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        key: ValueKey(_tabController.index),
        children: steps.asMap().entries.map((e) {
          return _RoutineStepRow(
            stepNumber: e.key + 1,
            step: e.value,
            isLast: e.key == steps.length - 1,
          );
        }).toList(),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _RadialScore extends StatelessWidget {
  final double score; // 0–1
  const _RadialScore({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: _RadialPainter(score: score),
        child: Center(
          child: Text(
            '${(score * 100).toInt()}',
            style: SkiNova.caption(color: Colors.white)
                .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _RadialPainter extends CustomPainter {
  final double score;
  _RadialPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final bg = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fg = Paint()
      ..color = Colors.white
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

class _RoutineStepRow extends StatelessWidget {
  final int stepNumber;
  final ScanRoutineStep step;
  final bool isLast;

  const _RoutineStepRow({
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
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  gradient: SkiNova.wineGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$stepNumber',
                      style: SkiNova.label(color: Colors.white)),
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
                      if (step.keyIngredient.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: SkiNova.wineMuted,
                            borderRadius: SkiNova.radiusCircle,
                          ),
                          child: Text(
                            step.keyIngredient,
                            style: SkiNova.label(color: SkiNova.wine)
                                .copyWith(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  if (step.productCategory.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(step.productCategory,
                        style: SkiNova.caption(color: SkiNova.wine)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ],
                  if (step.why.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(step.why, style: SkiNova.caption()),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
