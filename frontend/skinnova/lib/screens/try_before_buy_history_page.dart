import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class _HistoryRecord {
  final String id;
  final String productName;
  final String productBrand;
  final String productImageUrl;
  final String productCategory;
  final String originalImageUrl;
  final String generatedImageUrl;
  final int suitabilityScore;
  final List<String> expectedEffects;
  final List<String> warnings;
  final DateTime createdAt;

  _HistoryRecord.fromJson(Map<String, dynamic> j)
      : id = j['_id']?.toString() ?? '',
        productName = (j['productId'] is Map)
            ? (j['productId']['name']?.toString() ?? 'Unknown Product')
            : 'Unknown Product',
        productBrand = (j['productId'] is Map)
            ? (j['productId']['brand']?.toString() ?? '')
            : '',
        productImageUrl = (j['productId'] is Map)
            ? (j['productId']['imageUrl']?.toString() ?? '')
            : '',
        productCategory = (j['productId'] is Map)
            ? (j['productId']['category']?.toString() ?? '')
            : '',
        originalImageUrl = j['originalImageUrl']?.toString() ?? '',
        generatedImageUrl = j['generatedImageUrl']?.toString() ?? '',
        suitabilityScore = (j['suitabilityScore'] as num?)?.toInt() ?? 0,
        expectedEffects = List<String>.from(
            (j['expectedEffects'] ?? []).map((e) => e.toString())),
        warnings =
            List<String>.from((j['warnings'] ?? []).map((e) => e.toString())),
        createdAt = j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now();
}

// ─── History page ─────────────────────────────────────────────────────────────

class TryBeforeBuyHistoryPage extends StatefulWidget {
  final String userId;

  const TryBeforeBuyHistoryPage({super.key, required this.userId});

  @override
  State<TryBeforeBuyHistoryPage> createState() =>
      _TryBeforeBuyHistoryPageState();
}

class _TryBeforeBuyHistoryPageState extends State<TryBeforeBuyHistoryPage> {
  // ─── Palette ──────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color softPink = Color(0xFFF8E8EC);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color dustyRose = Color(0xFFE8AABA);

  // ─── State ────────────────────────────────────────────────────────────────
  List<_HistoryRecord> _records = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final raw = await ApiService.fetchTryBeforeBuyHistory(widget.userId);
      if (!mounted) return;
      setState(() {
        _records = raw
            .map((e) => _HistoryRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load previews. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    setState(() => _deletingIds.add(id));
    final ok = await ApiService.deleteTryBeforeBuyRecord(id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _records.removeWhere((r) => r.id == id);
        _deletingIds.remove(id);
      });
    } else {
      setState(() => _deletingIds.remove(id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete preview. Please try again.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: wine,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: warmCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete Preview?",
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: darkText),
        ),
        content: Text(
          "This preview will be permanently deleted.",
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style:
                    GoogleFonts.poppins(fontSize: 13, color: Colors.black45)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(id);
            },
            child: Text("Delete",
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: wine)),
          ),
        ],
      ),
    );
  }

  void _openDetail(_HistoryRecord r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailSheet(record: r),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warmCream,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: warmCream,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: wine.withOpacity(0.09),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: wine, size: 16),
        ),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            "My Skin Previews",
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: deepPlum,
            ),
          ),
          if (!_isLoading && _records.isNotEmpty)
            Text(
              "${_records.length} preview${_records.length == 1 ? '' : 's'}",
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: wine.withOpacity(0.55),
                letterSpacing: 0.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _loadingState();
    if (_errorMessage != null) return _errorState();
    if (_records.isEmpty) return _emptyState();
    return RefreshIndicator(
      onRefresh: _load,
      color: wine,
      backgroundColor: Colors.white,
      displacement: 30,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        itemCount: _records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _historyCard(_records[i]),
      ),
    );
  }

  // ─── Loading state ────────────────────────────────────────────────────────

  Widget _loadingState() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => _shimmerCard(),
    );
  }

  Widget _shimmerCard() {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: dustyRose.withOpacity(0.14),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: _ShimmerBox(
        child: Container(
          decoration: BoxDecoration(
            color: dustyRose.withOpacity(0.18),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [deepPlum, wine],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: wine.withOpacity(0.24),
                      blurRadius: 22,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.history_rounded,
                  size: 34, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              "No Previews Yet",
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: deepPlum,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "No previews yet.\nTry a product on your skin first.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black45,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error state ──────────────────────────────────────────────────────────

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 46, color: wine.withOpacity(0.5)),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.black54, height: 1.55),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: wine,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "Try Again",
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── History card ─────────────────────────────────────────────────────────

  Widget _historyCard(_HistoryRecord r) {
    final isDeleting = _deletingIds.contains(r.id);
    final Color scoreColor = r.suitabilityScore >= 80
        ? const Color(0xFF2E7D32)
        : r.suitabilityScore >= 55
            ? const Color(0xFFF57F17)
            : const Color(0xFFC62828);

    return GestureDetector(
      onTap: isDeleting ? null : () => _openDetail(r),
      onLongPress: isDeleting ? null : () => _confirmDelete(r.id),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDeleting ? 0.45 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: wine.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                  color: dustyRose.withOpacity(0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image pair (original + generated) ────────────────────────
              _imagePair(r),
              const SizedBox(width: 14),
              // ── Info ──────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product brand
                    if (r.productBrand.isNotEmpty)
                      Text(
                        r.productBrand.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: wine.withOpacity(0.60),
                          letterSpacing: 0.7,
                        ),
                      ),
                    // Product name
                    Text(
                      r.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: darkText,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Date + score row
                    Row(
                      children: [
                        Text(
                          _formatDate(r.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.black38,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 6, color: scoreColor),
                              const SizedBox(width: 4),
                              Text(
                                "${r.suitabilityScore}%",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: scoreColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    // First expected effect as a preview
                    if (r.expectedEffects.isNotEmpty)
                      Text(
                        r.expectedEffects.first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.black38,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              // ── Delete button ─────────────────────────────────────────────
              if (isDeleting)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 2),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: wine),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => _confirmDelete(r.id),
                  child: Container(
                    margin: const EdgeInsets.only(left: 6, top: 2),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: softPink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 15, color: wine.withOpacity(0.65)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePair(_HistoryRecord r) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Original (back, slightly offset)
          Positioned(
            left: 0,
            top: 0,
            child: _thumbImage(r.originalImageUrl, 72, label: "B"),
          ),
          // Generated (front, overlapping)
          Positioned(
            right: 0,
            bottom: 0,
            child: r.generatedImageUrl.isNotEmpty
                ? _thumbImage(r.generatedImageUrl, 72, label: "A", border: true)
                : _thumbPlaceholder(56),
          ),
        ],
      ),
    );
  }

  Widget _thumbImage(String url, double size,
      {String? label, bool border = false}) {
    final fullUrl = url.startsWith('http') ? url : '${ApiService.baseUrl}$url';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: border ? Border.all(color: Colors.white, width: 2.5) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(border ? 12 : 14),
            child: Image.network(
              fullUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                color: softPink,
                child: Icon(Icons.person_outline_rounded,
                    size: size * 0.4, color: wine.withOpacity(0.4)),
              ),
            ),
          ),
          if (label != null)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.48),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: softPink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Icon(Icons.auto_awesome_rounded,
          size: size * 0.4, color: wine.withOpacity(0.4)),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return "Today";
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return "${diff.inDays} days ago";
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}

// ─── Detail bottom sheet ──────────────────────────────────────────────────────

class _DetailSheet extends StatefulWidget {
  final _HistoryRecord record;
  const _DetailSheet({required this.record});

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  static const Color wine = Color(0xFF5B2333);
  static const Color softPink = Color(0xFFF8E8EC);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color dustyRose = Color(0xFFE8AABA);

  // Slider position (0.0 = all before, 1.0 = all after)
  double _sliderPos = 0.5;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final hasImages =
        r.originalImageUrl.isNotEmpty && r.generatedImageUrl.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: warmCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // Product name header
                  if (r.productBrand.isNotEmpty)
                    Text(
                      r.productBrand.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: wine.withOpacity(0.60),
                        letterSpacing: 1.0,
                      ),
                    ),
                  Text(
                    r.productName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: deepPlum,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Score card
                  _scoreRow(r.suitabilityScore),
                  const SizedBox(height: 16),

                  // Before / After comparison
                  if (hasImages) ...[
                    _detailSectionLabel("Before / After"),
                    const SizedBox(height: 10),
                    _comparisonSlider(r),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        "← Drag to compare →",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.black38,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Expected effects
                  if (r.expectedEffects.isNotEmpty) ...[
                    _detailSectionLabel("Expected Effects"),
                    const SizedBox(height: 10),
                    _effectsList(r.expectedEffects, Colors.green.shade700,
                        Colors.green.shade50),
                    const SizedBox(height: 14),
                  ],

                  // Warnings
                  if (r.warnings.isNotEmpty) ...[
                    _detailSectionLabel("Things to Note"),
                    const SizedBox(height: 10),
                    _effectsList(r.warnings, Colors.orange.shade700,
                        Colors.orange.shade50),
                    const SizedBox(height: 14),
                  ],

                  // Disclaimer
                  _disclaimer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreRow(int score) {
    final Color color = score >= 80
        ? const Color(0xFF2E7D32)
        : score >= 55
            ? const Color(0xFFF57F17)
            : const Color(0xFFC62828);
    final String label = score >= 80
        ? "Great Match"
        : score >= 55
            ? "Moderate Match"
            : "Use with Caution";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: dustyRose.withOpacity(0.14),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 5.5,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  "$score",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Suitability Score",
                style:
                    GoogleFonts.poppins(fontSize: 10.5, color: Colors.black38),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _comparisonSlider(_HistoryRecord r) {
    final origUrl = r.originalImageUrl.startsWith('http')
        ? r.originalImageUrl
        : '${ApiService.baseUrl}${r.originalImageUrl}';
    final genUrl = r.generatedImageUrl.startsWith('http')
        ? r.generatedImageUrl
        : '${ApiService.baseUrl}${r.generatedImageUrl}';

    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final h = w; // square

        return GestureDetector(
          onHorizontalDragUpdate: (d) {
            setState(() {
              _sliderPos = (_sliderPos + d.delta.dx / w).clamp(0.04, 0.96);
            });
          },
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  // After layer (full)
                  Positioned.fill(
                    child: Image.network(genUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: softPink)),
                  ),
                  // Before layer (left clip)
                  Positioned.fill(
                    child: ClipRect(
                      clipper: _LeftFractionClipper(_sliderPos),
                      child: Image.network(origUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFFECDDD8))),
                    ),
                  ),
                  // Divider
                  Positioned(
                    left: w * _sliderPos - 1,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: Container(
                      color: Colors.white.withOpacity(0.90),
                    ),
                  ),
                  // Handle
                  Positioned(
                    left: w * _sliderPos - 20,
                    top: h / 2 - 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.compare_arrows_rounded,
                          color: wine, size: 18),
                    ),
                  ),
                  // Labels
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _sliderLabel("BEFORE"),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _sliderLabel("AFTER"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sliderLabel(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.32),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _effectsList(List<String> items, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5, right: 8),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: darkText.withOpacity(0.78),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _detailSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: wine,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
      ],
    );
  }

  Widget _disclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: softPink.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: wine.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 13, color: wine.withOpacity(0.55)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              "AI-generated preview. Results are simulated and may vary in real life. This is not a medical assessment.",
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: darkText.withOpacity(0.50),
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clipper (reused from Try Before Buy page) ────────────────────────────────

class _LeftFractionClipper extends CustomClipper<Rect> {
  final double fraction;
  const _LeftFractionClipper(this.fraction);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftFractionClipper old) => old.fraction != fraction;
}

// ─── Shimmer widget ───────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final Widget child;
  const _ShimmerBox({required this.child});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.65).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(opacity: _anim.value, child: child),
      child: widget.child,
    );
  }
}
