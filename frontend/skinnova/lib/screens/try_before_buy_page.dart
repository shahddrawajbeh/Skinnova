import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';
import '../product_model.dart';
import 'try_before_buy_history_page.dart';

// ─── Result model ─────────────────────────────────────────────────────────────

class _TryResult {
  final int suitabilityScore;
  final List<String> expectedEffects;
  final List<String> warnings;
  final String generatedImageUrl;
  final String originalImageUrl;
  final String productName;

  _TryResult.fromJson(Map<String, dynamic> j)
      : suitabilityScore = (j['suitabilityScore'] as num?)?.toInt() ?? 0,
        expectedEffects = List<String>.from(
            (j['expectedEffects'] ?? []).map((e) => e.toString())),
        warnings =
            List<String>.from((j['warnings'] ?? []).map((e) => e.toString())),
        generatedImageUrl = j['generatedImageUrl']?.toString() ?? '',
        originalImageUrl = j['originalImageUrl']?.toString() ?? '',
        productName = j['productName']?.toString() ?? '';
}

// ─── Before / After slider widget ────────────────────────────────────────────

class _BeforeAfterSlider extends StatefulWidget {
  final Widget before;
  final Widget after;

  const _BeforeAfterSlider({required this.before, required this.after});

  @override
  State<_BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<_BeforeAfterSlider> {
  double _position = 0.5;

  static const Color wine = Color(0xFF5B2333);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxWidth; // square aspect ratio

        return GestureDetector(
          onHorizontalDragUpdate: (d) {
            setState(() {
              _position = (_position + d.delta.dx / w).clamp(0.04, 0.96);
            });
          },
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  // ── After (generated) — full width base layer ──
                  Positioned.fill(child: widget.after),

                  // ── Before (original) — clipped to left of handle ──
                  Positioned.fill(
                    child: ClipRect(
                      clipper: _LeftFractionClipper(_position),
                      child: widget.before,
                    ),
                  ),

                  // ── Divider line ──
                  Positioned(
                    left: w * _position - 1,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.22),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Drag handle ──
                  Positioned(
                    left: w * _position - 22,
                    top: h / 2 - 22,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.compare_arrows_rounded,
                        color: wine,
                        size: 20,
                      ),
                    ),
                  ),

                  // ── BEFORE label ──
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _sliderLabel("BEFORE"),
                  ),

                  // ── AFTER label ──
                  Positioned(
                    top: 12,
                    right: 12,
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _LeftFractionClipper extends CustomClipper<Rect> {
  final double fraction;
  const _LeftFractionClipper(this.fraction);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftFractionClipper old) => old.fraction != fraction;
}

// ─── Main page ────────────────────────────────────────────────────────────────

class TryBeforeBuyPage extends StatefulWidget {
  final String userId;
  final String userName;

  const TryBeforeBuyPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<TryBeforeBuyPage> createState() => _TryBeforeBuyPageState();
}

class _TryBeforeBuyPageState extends State<TryBeforeBuyPage>
    with SingleTickerProviderStateMixin {
  // ─── Palette ──────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color softPink = Color(0xFFF8E8EC);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color gold = Color(0xFFD4AF37);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color dustyRose = Color(0xFFE8AABA);

  // ─── State ────────────────────────────────────────────────────────────────
  List<ProductModel> _products = [];
  bool _loadingProducts = true;

  ProductModel? _selectedProduct;
  XFile? _pickedFile;
  Map<String, dynamic>? _latestScan;
  bool _useExistingScan = false;

  bool _isGenerating = false;
  _TryResult? _result;
  String? _errorMessage;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      ApiService.fetchProducts().catchError((_) => <ProductModel>[]),
      ApiService.fetchLatestSkinScan(widget.userId),
    ]);

    if (!mounted) return;
    setState(() {
      _products = results[0] as List<ProductModel>;
      _latestScan = results[1] as Map<String, dynamic>?;
      _loadingProducts = false;
      // Pre-select scan photo option if the scan has an image
      final scanImage = _latestScan?['imageUrl']?.toString() ?? '';
      _useExistingScan = scanImage.isNotEmpty;
    });
  }

  // ─── Photo helpers ────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1080,
    );
    if (file != null) {
      setState(() {
        _pickedFile = file;
        _useExistingScan = false;
        _result = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1080,
    );
    if (file != null) {
      setState(() {
        _pickedFile = file;
        _useExistingScan = false;
        _result = null;
        _errorMessage = null;
      });
    }
  }

  bool get _canGenerate {
    final hasProduct = _selectedProduct != null;
    final hasScanImage = _useExistingScan &&
        (_latestScan?['imageUrl']?.toString() ?? '').isNotEmpty;
    final hasPickedPhoto = _pickedFile != null;
    return hasProduct && (hasScanImage || hasPickedPhoto);
  }

  String get _scanImageUrl => _latestScan?['imageUrl']?.toString() ?? '';

  // ─── Generate ─────────────────────────────────────────────────────────────

  Future<void> _generate() async {
    if (!_canGenerate || _isGenerating) return;
    setState(() {
      _isGenerating = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> response;

      if (_pickedFile != null && !_useExistingScan) {
        response = await ApiService.tryBeforeBuyUpload(
          userId: widget.userId,
          productId: _selectedProduct!.id,
          imageFile: File(_pickedFile!.path),
        );
      } else {
        response = await ApiService.tryBeforeBuyWithUrl(
          userId: widget.userId,
          productId: _selectedProduct!.id,
          imageUrl: _scanImageUrl,
        );
      }

      if (!mounted) return;

      final data = response['data'] as Map<String, dynamic>;
      if (response['statusCode'] == 200 && data['success'] == true) {
        setState(() {
          _result = _TryResult.fromJson(data);
          _isGenerating = false;
        });
        // Scroll to results after generation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        setState(() {
          _errorMessage = data['message']?.toString() ??
              'Generation failed. Please try again.';
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isGenerating = false;
      });
    }
  }

  final ScrollController _scrollCtrl = ScrollController();

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warmCream,
      body: Stack(
        children: [
          _buildBody(),
          if (_isGenerating) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      controller: _scrollCtrl,
      slivers: [
        _buildAppBar(),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 4),
              _heroBanner(),
              const SizedBox(height: 24),
              _productSelectorCard(),
              const SizedBox(height: 16),
              _photoSelectorCard(),
              const SizedBox(height: 24),
              _generateButton(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _errorCard(),
              ],
              if (_result != null) ...[
                const SizedBox(height: 28),
                _resultSection(),
              ],
              const SizedBox(height: 20),
              _disclaimer(),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── App bar ──────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: warmCream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
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
            "Try Before You Buy",
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: deepPlum,
            ),
          ),
          Text(
            "AI Skin Preview",
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: wine.withOpacity(0.55),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        // History button — always visible
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TryBeforeBuyHistoryPage(userId: widget.userId),
            ),
          ),
          child: Container(
            margin: EdgeInsets.only(right: _result != null ? 6.0 : 14.0),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: wine.withOpacity(0.09),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.history_rounded, color: wine, size: 20),
          ),
        ),
        if (_result != null)
          GestureDetector(
            onTap: () => setState(() {
              _result = null;
              _errorMessage = null;
              _pickedFile = null;
              _selectedProduct = null;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: softPink,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "Reset",
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w500, color: wine),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Hero banner ──────────────────────────────────────────────────────────

  Widget _heroBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A10), deepPlum, wine],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.35, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: wine.withOpacity(0.35),
              blurRadius: 28,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          // Ambient glow
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [gold.withOpacity(0.10), Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: gold.withOpacity(0.32), width: 0.8),
                    ),
                    child: Text(
                      "AI-POWERED PREVIEW",
                      style: GoogleFonts.poppins(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.4,
                        color: gold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Try Before\nYou Buy",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "See how a product may look on your skin before purchasing.",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.68),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Product selector ─────────────────────────────────────────────────────

  Widget _productSelectorCard() {
    return GestureDetector(
      onTap: _loadingProducts ? null : _openProductPicker,
      child: _stepCard(
        step: "1",
        title: "Select a Product",
        subtitle: _selectedProduct == null
            ? "Tap to choose a product to preview"
            : null,
        child: _selectedProduct == null
            ? Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: softPink,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _loadingProducts
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: wine),
                            ),
                          )
                        : const Icon(Icons.add_rounded, color: wine, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _loadingProducts
                          ? "Loading products..."
                          : "${_products.length} products available",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.black26),
                ],
              )
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 52,
                      height: 52,
                      color: softPink,
                      child: _selectedProduct!.imageUrl.isNotEmpty
                          ? Image.network(
                              _selectedProduct!.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.spa_outlined,
                                  color: wine,
                                  size: 22),
                            )
                          : const Icon(Icons.spa_outlined,
                              color: wine, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedProduct!.brand.isNotEmpty)
                          Text(
                            _selectedProduct!.brand.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              color: wine.withOpacity(0.65),
                              letterSpacing: 0.7,
                            ),
                          ),
                        Text(
                          _selectedProduct!.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: softPink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "Change",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: wine,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Photo selector ───────────────────────────────────────────────────────

  Widget _photoSelectorCard() {
    final hasScan = _scanImageUrl.isNotEmpty;
    return _stepCard(
      step: "2",
      title: "Choose a Photo",
      subtitle: "Use your skin scan or upload a new photo",
      child: Column(
        children: [
          // Option 1 — use existing scan photo
          if (hasScan) ...[
            _photoOption(
              label: "Use my Skin Scan photo",
              sublabel: "From your latest scan",
              icon: Icons.face_retouching_natural_outlined,
              selected: _useExistingScan,
              onTap: () => setState(() {
                _useExistingScan = true;
                _result = null;
                _errorMessage = null;
              }),
              trailing: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  '${ApiService.baseUrl}$_scanImageUrl',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(width: 44, height: 44, color: softPink),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Option 2 — upload new photo
          _photoOption(
            label: "Upload a new photo",
            sublabel: "From gallery or camera",
            icon: Icons.add_photo_alternate_outlined,
            selected: !_useExistingScan,
            onTap: _showPhotoSourceSheet,
            trailing: _pickedFile != null && !_useExistingScan
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_pickedFile!.path),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _photoOption({
    required String label,
    required String sublabel,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? softPink : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? wine.withOpacity(0.22) : wine.withOpacity(0.07),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: wine.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? wine.withOpacity(0.12) : softPink,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: wine),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: darkText,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ] else if (selected)
              const Icon(Icons.check_circle_rounded, color: wine, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Generate button ──────────────────────────────────────────────────────

  Widget _generateButton() {
    final enabled = _canGenerate;
    return GestureDetector(
      onTap: enabled ? _generate : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [wine, Color(0xFF8E4B5D)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : Colors.black12,
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: wine.withOpacity(0.38),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: enabled ? Colors.white : Colors.black26,
              ),
              const SizedBox(width: 10),
              Text(
                "Generate My Preview",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: enabled ? Colors.white : Colors.black26,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Loading overlay ──────────────────────────────────────────────────────

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: warmCream,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: child,
                ),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [deepPlum, wine],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: wine.withOpacity(0.38),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      size: 32, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Generating Your\nSkin Preview",
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: deepPlum,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Skinova AI is analyzing the product\nand simulating its effects on your skin…",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black45,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                backgroundColor: softPink,
                color: wine,
                borderRadius: BorderRadius.circular(999),
                minHeight: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Result section ───────────────────────────────────────────────────────

  Widget _resultSection() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 3,
              height: 22,
              decoration: BoxDecoration(
                color: wine,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Your Skin Preview",
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Suitability score card
        _scoreCard(r.suitabilityScore),
        const SizedBox(height: 16),

        // Expected effects
        if (r.expectedEffects.isNotEmpty) ...[
          _infoCard(
            icon: Icons.trending_up_rounded,
            label: "Expected Effects",
            color: const Color(0xFF2E7D32),
            bgColor: const Color(0xFFE8F5E9),
            items: r.expectedEffects,
            bullet: "✓",
          ),
          const SizedBox(height: 12),
        ],

        // Warnings
        if (r.warnings.isNotEmpty) ...[
          _infoCard(
            icon: Icons.warning_amber_rounded,
            label: "Things to Note",
            color: Colors.orange.shade700,
            bgColor: Colors.orange.shade50,
            items: r.warnings,
            bullet: "!",
          ),
          const SizedBox(height: 12),
        ],

        // Before/After slider
        if (r.generatedImageUrl.isNotEmpty) ...[
          const SizedBox(height: 4),
          _sectionTitle("Before / After Preview"),
          const SizedBox(height: 12),
          _beforeAfterWidget(r),
          const SizedBox(height: 8),
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
        ] else ...[
          // No image generated — show friendly message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: softPink.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: wine.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: wine, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Image preview is temporarily unavailable. The analysis above is still accurate.",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: darkText.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _scoreCard(int score) {
    final Color scoreColor = score >= 80
        ? const Color(0xFF2E7D32)
        : score >= 55
            ? const Color(0xFFF57F17)
            : const Color(0xFFC62828);
    final String scoreLabel = score >= 80
        ? "Great Match"
        : score >= 55
            ? "Moderate Match"
            : "Use with Caution";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: dustyRose.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular score gauge
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 7,
                  backgroundColor: scoreColor.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$score",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: scoreColor,
                        height: 1,
                      ),
                    ),
                    Text(
                      "/ 100",
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Suitability Score",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black38,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  scoreLabel,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Based on your skin profile and product ingredients.",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black45,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required List<String> items,
    required String bullet,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$bullet ",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
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
          ),
        ],
      ),
    );
  }

  Widget _beforeAfterWidget(_TryResult r) {
    // Before image widget (local file or existing scan URL)
    Widget beforeWidget;
    if (_pickedFile != null && !_useExistingScan) {
      beforeWidget = Image.file(
        File(_pickedFile!.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      final fullUrl = r.originalImageUrl.startsWith('http')
          ? r.originalImageUrl
          : '${ApiService.baseUrl}${r.originalImageUrl}';
      beforeWidget = Image.network(
        fullUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(
            color: softPink,
            child: const Icon(Icons.person, size: 60, color: wine)),
      );
    }

    // After image widget (generated)
    final generatedFullUrl = r.generatedImageUrl.startsWith('http')
        ? r.generatedImageUrl
        : '${ApiService.baseUrl}${r.generatedImageUrl}';
    final afterWidget = Image.network(
      generatedFullUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
          color: softPink,
          child: const Icon(Icons.spa_outlined, size: 60, color: wine)),
    );

    return _BeforeAfterSlider(before: beforeWidget, after: afterWidget);
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: wine,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: darkText,
          ),
        ),
      ],
    );
  }

  // ─── Error card ───────────────────────────────────────────────────────────

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: wine.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: wine.withOpacity(0.7), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.black54,
                height: 1.45,
              ),
            ),
          ),
          GestureDetector(
            onTap: _generate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: wine,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "Retry",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Disclaimer ───────────────────────────────────────────────────────────

  Widget _disclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: softPink.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: wine.withOpacity(0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 15, color: wine.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "AI-generated preview. Results are simulated and may vary in real life. "
              "This is not a medical assessment.",
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: darkText.withOpacity(0.55),
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Reusable step card shell ─────────────────────────────────────────────

  Widget _stepCard({
    required String step,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: wine.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: dustyRose.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [wine, Color(0xFF8E4B5D)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: darkText,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ─── Product picker bottom sheet ──────────────────────────────────────────

  void _openProductPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProductPickerSheet(
        products: _products,
        selected: _selectedProduct,
        onSelect: (p) {
          setState(() {
            _selectedProduct = p;
            _result = null;
            _errorMessage = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  // ─── Photo source bottom sheet ────────────────────────────────────────────

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: warmCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Text(
              "Choose Photo Source",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: darkText,
              ),
            ),
            const SizedBox(height: 18),
            _sourceRow(
              icon: Icons.photo_library_outlined,
              label: "From Gallery",
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            const SizedBox(height: 12),
            _sourceRow(
              icon: Icons.camera_alt_outlined,
              label: "Take a Photo",
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: wine.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Icon(icon, color: wine, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkText,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

// ─── Product picker bottom sheet ──────────────────────────────────────────────

class _ProductPickerSheet extends StatefulWidget {
  final List<ProductModel> products;
  final ProductModel? selected;
  final ValueChanged<ProductModel> onSelect;

  const _ProductPickerSheet({
    required this.products,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  static const Color wine = Color(0xFF5B2333);
  static const Color softPink = Color(0xFFF8E8EC);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color dustyRose = Color(0xFFE8AABA);

  String _query = '';
  List<ProductModel> get _filtered => _query.isEmpty
      ? widget.products
      : widget.products.where((p) {
          final q = _query.toLowerCase();
          return p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q);
        }).toList();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
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
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select a Product",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: wine.withOpacity(0.09)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            color: Colors.black38, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: darkText),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: "Search by name or brand...",
                              hintStyle: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.black26),
                            ),
                            cursorColor: wine,
                            cursorWidth: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        "No products found",
                        style: GoogleFonts.poppins(color: Colors.black38),
                      ),
                    )
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = _filtered[i];
                        final isSelected = widget.selected?.id == p.id;
                        return GestureDetector(
                          onTap: () => widget.onSelect(p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? softPink : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? wine.withOpacity(0.22)
                                    : wine.withOpacity(0.06),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: wine.withOpacity(0.09),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : [
                                      BoxShadow(
                                        color: dustyRose.withOpacity(0.12),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      )
                                    ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    color: const Color(0xFFF8E8EC),
                                    child: p.imageUrl.isNotEmpty
                                        ? Image.network(
                                            p.imageUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.spa_outlined,
                                                    color: wine, size: 20),
                                          )
                                        : const Icon(Icons.spa_outlined,
                                            color: wine, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (p.brand.isNotEmpty)
                                        Text(
                                          p.brand.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w500,
                                            color: wine.withOpacity(0.6),
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      Text(
                                        p.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: darkText,
                                        ),
                                      ),
                                      if (p.category.isNotEmpty)
                                        Text(
                                          p.category,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: Colors.black38,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: wine, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
