import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../product_model.dart';
import 'product_details_screen.dart';
import 'chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreProfileScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  final String userId;
  final String userName;

  const StoreProfileScreen({
    super.key,
    required this.store,
    required this.userId,
    required this.userName,
  });

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen>
    with TickerProviderStateMixin {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color gold = Color(0xFFD4AF37);
  static const Color softPink = Color(0xFFF8E8EC);
  // ignore: unused_field
  static const Color dustyRose = Color(0xFFE8AABA);
  static const Color deepPlum = Color(0xFF2E1520);

  // ── State ──────────────────────────────────────────────────────────────────
  List<dynamic> storeProducts = [];
  bool isLoading = true;
  bool isFollowing = false;
  bool _isFollowLoading = false;
  int _followersCount = 0;
  bool _showFollowCheck = false;
  String selectedCategory = "All";
  final ScrollController _scrollController = ScrollController();
  bool _stickyCategories = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
  final Set<String> _wishlist = {};
  final GlobalKey _categoryKey = GlobalKey();
  Map<String, dynamic>? userProfile;
  static const List<String> _categories = [
    "All",
    "After sun care",
    "Blemish treatment",
    "Body lotion",
    "Body wash",
    "Cleanser",
    "Complexion",
    "Exfoliator",
    "Eye treatment",
    "Face mask",
    "Face mist",
    "Face oil",
    "Foot treatment",
    "Fragrance",
    "Gel",
    "Hair conditioner",
    "Hair shampoo",
    "Hand treatment",
    "Injectable",
    "Lip treatment",
    "Moisturizer",
    "Scrub",
    "Serum",
    "Sunscreen",
    "Toner",
    "Tools",
  ];
  static const List<Map<String, dynamic>> _policies = [
    {
      "icon": Icons.local_shipping_outlined,
      "title": "Free Shipping",
      "subtitle": "On orders above 150 ILS",
    },
    {
      "icon": Icons.replay_outlined,
      "title": "Easy Returns",
      "subtitle": "Within 14 days of purchase",
    },
    {
      "icon": Icons.payment_outlined,
      "title": "Secure Payment",
      "subtitle": "Cash, card & online payment",
    },
    {
      "icon": Icons.location_city_outlined,
      "title": "Delivery Areas",
      "subtitle": "West Bank & Jerusalem",
    },
  ];

  @override
  void initState() {
    super.initState();
    _followersCount = (widget.store["followersCount"] as num?)?.toInt() ?? 0;
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(_scaleCtrl);
    _scrollController.addListener(_onScroll);
    _loadStoreProducts();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Sticky category bar triggers around 420px scroll
    final sticky = _scrollController.offset > 420;
    if (sticky != _stickyCategories) {
      setState(() => _stickyCategories = sticky);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final result = await ApiService.getUserProfile(userId: widget.userId);

      if (!mounted) return;

      if (result["statusCode"] == 200) {
        final profile = Map<String, dynamic>.from(result["data"]);
        final storeId = (widget.store["_id"] ?? "").toString();
        final followed = (profile["followedStores"] as List<dynamic>? ?? []);
        final alreadyFollowing = followed.any((id) => id.toString() == storeId);
        setState(() {
          userProfile = profile;
          isFollowing = alreadyFollowing;
        });
      }
    } catch (e) {
      debugPrint("User profile load error: $e");
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _isFollowLoading = true);

    final storeId = (widget.store["_id"] ?? "").toString();
    final Map<String, dynamic> result;
    if (isFollowing) {
      result = await ApiService.unfollowStore(
          userId: widget.userId, storeId: storeId);
    } else {
      result =
          await ApiService.followStore(userId: widget.userId, storeId: storeId);
    }

    if (!mounted) return;
    if (result["statusCode"] == 200) {
      final newCount = (result["data"]["followersCount"] as num?)?.toInt() ??
          _followersCount;
      final nowFollowing = !isFollowing;
      setState(() {
        isFollowing = nowFollowing;
        _followersCount = newCount;
        _isFollowLoading = false;
        if (nowFollowing) _showFollowCheck = true;
      });
      if (nowFollowing) {
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) setState(() => _showFollowCheck = false);
        });
      }
    } else {
      setState(() => _isFollowLoading = false);
    }
  }

  String _formatFollowersCount(int count) {
    if (count >= 1000000)
      return "${(count / 1000000).toStringAsFixed(1)}M followers";
    if (count >= 1000) return "${(count / 1000).toStringAsFixed(1)}k followers";
    return "$count followers";
  }

  Future<void> _openGoogleMaps() async {
    final city = widget.store["city"] ?? "";
    final address = widget.store["address"] ?? "";
    final storeName = widget.store["storeName"] ?? "";

    final query = Uri.encodeComponent("$storeName $address $city");
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$query",
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _loadStoreProducts() async {
    try {
      final storeId = widget.store["_id"];
      final result = await ApiService.fetchProductsByStore(storeId);
      if (!mounted) return;
      setState(() {
        storeProducts = result;
        isLoading = false;
      });
      _fadeCtrl.forward();
      _scaleCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<dynamic> get _filteredProducts {
    final currentStoreId = _getId(widget.store["_id"]);

    return storeProducts.where((item) {
      final itemStoreId = _getId(item["storeId"]);

      if (itemStoreId != currentStoreId) return false;

      if (selectedCategory == "All") return true;

      final product = item["productId"] ?? {};
      final cat = (product["category"] ?? "").toString().toLowerCase().trim();
      final selected = selectedCategory.toLowerCase().trim();

      return cat == selected;
    }).toList();
  }

  String _getId(dynamic value) {
    if (value == null) return "";

    if (value is Map) {
      return (value["_id"] ?? value[r"$oid"] ?? "").toString();
    }

    return value.toString();
  }

  List<dynamic> get _bestSellers {
    final sorted = [...storeProducts];

    sorted.sort((a, b) {
      final sA = (a["soldCount"] ?? 0) as num;
      final sB = (b["soldCount"] ?? 0) as num;
      return sB.compareTo(sA);
    });

    return sorted
        .where((item) {
          final sold = (item["soldCount"] ?? 0) as num;
          return sold > 0;
        })
        .take(6)
        .toList();
  }

  List<dynamic> get _allReviews {
    final reviews = (widget.store["reviews"] as List<dynamic>? ?? []);
    return reviews
        .where((r) => (r["status"] ?? "approved") == "approved")
        .toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _netImage(String url,
      {double? width,
      double? height,
      BoxFit fit = BoxFit.cover,
      Widget? placeholder}) {
    if (url.isEmpty) return placeholder ?? const SizedBox.shrink();

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            placeholder ?? const Icon(Icons.image_outlined),
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          placeholder ?? const Icon(Icons.image_outlined),
    );
  }

  void _addToCart(dynamic item, ProductModel product) async {
    final stockCount = (item["stockCount"] ?? 0) as num;

    if (stockCount <= 0) {
      if (!mounted) return;
      _showStockSnackBar("This product is currently out of stock.");
      return;
    }

    try {
      final storeId = (item["storeId"] is Map)
          ? (item["storeId"]["_id"] ?? "").toString()
          : (item["storeId"] ?? widget.store["_id"] ?? "").toString();
      final result = await ApiService.addToCart(
        userId: widget.userId,
        productId: product.id,
        quantity: 1,
        storeId: storeId,
        price: item["price"] ?? product.price,
        currency: item["currency"] ?? product.currency,
      );
      if (!mounted) return;

      if (result["statusCode"] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${product.name} added to cart",
                style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: wine,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        final msg =
            result["data"]["message"] ?? "Could not add product to cart.";
        _showStockSnackBar(msg);
      }
    } catch (_) {}
  }

  void _showStockSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final storeName = widget.store["storeName"] ?? "Store";
    final logoUrl = widget.store["logoUrl"] ?? "";
    final coverUrl = widget.store["coverImageUrl"] ?? "";
    final city = widget.store["city"] ?? "";
    final address = widget.store["address"] ?? "";
    final description = widget.store["description"] ?? "";
    final phone = widget.store["phone"] ?? "";
    final rating = (widget.store["rating"] ?? 4.8).toDouble();
    final responseTime = widget.store["responseTime"] ?? "< 1h";
    final shippingTime = widget.store["shippingTime"] ?? "1–2d";
    final reviewsCount =
        (widget.store["reviews"] as List<dynamic>? ?? []).length;

    return Scaffold(
      backgroundColor: softBg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(storeName, logoUrl, coverUrl, city, address,
                  rating, reviewsCount),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildVerifiedBadge(storeName),
                    _buildStatsRow(responseTime, shippingTime),
                    _buildActionButtons(phone),
                    _buildQuickActions(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              // ── Category bar (non-sticky position) ──────────────────────────
              SliverToBoxAdapter(
                key: _categoryKey,
                child: _buildCategoryBar(),
              ),
              // ── Featured products ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: isLoading
                    ? _buildSkeletonGrid()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: ScaleTransition(
                          scale: _scaleAnim,
                          child: _buildFeaturedSection(),
                        ),
                      ),
              ),
              // ── Best sellers ─────────────────────────────────────────────────
              if (!isLoading && _bestSellers.isNotEmpty)
                SliverToBoxAdapter(child: _buildBestSellersSection()),
              // ── Reviews ──────────────────────────────────────────────────────
              if (!isLoading) SliverToBoxAdapter(child: _buildReviewsSection()),
              // ── About ────────────────────────────────────────────────────────

              // ── Policies ─────────────────────────────────────────────────────
              // ── Gallery ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                  child:
                      _buildGallerySection()), // ── Recommended ──────────────────────────────────────────────────
              if (!isLoading && storeProducts.length > 4)
                SliverToBoxAdapter(child: _buildRecommendedSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
          // ── Sticky category bar overlay ──────────────────────────────────────
          if (_stickyCategories)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color: softBg.withOpacity(0.92),
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 4, bottom: 8),
                    child: _buildCategoryBar(compact: true),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────────────────────────
  Widget _buildSliverHeader(String storeName, String logoUrl, String coverUrl,
      String city, String address, double rating, int reviewsCount) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: wine,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Link copied to clipboard",
                    style: GoogleFonts.poppins(fontSize: 13)),
                backgroundColor: wine,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.share_outlined, color: Colors.white, size: 18),
          ),
        ),
        GestureDetector(
          onTap: _showStoreMoreOptions,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            coverUrl.isNotEmpty
                ? _netImage(coverUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(color: const Color(0xFF3D1625)))
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5B2333), Color(0xFF2E1520)],
                      ),
                    ),
                  ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            // Store logo + name at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: logoUrl.isNotEmpty
                            ? _netImage(logoUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                placeholder: _logoFallback(storeName))
                            : _logoFallback(storeName),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  storeName,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // const SizedBox(width: 6),
                              // const Icon(Icons.verified_rounded,
                              //     color: Color(0xFF4FC3F7), size: 18),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white70, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                "$city${address.isNotEmpty ? " · $address" : ""}",
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _ratingStars(rating, size: 13),
                              const SizedBox(width: 6),
                              Text(
                                rating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: gold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "($reviewsCount reviews)",
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.white60),
                              ),
                            ],
                          ),
                        ],
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

  void _showStoreMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        decoration: const BoxDecoration(
          color: warmCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _moreOption(
              Icons.flag_outlined,
              "Report store",
              () {
                Navigator.pop(context);
                _showReportStoreSheet();
              },
            ),
            _moreOption(
              Icons.visibility_off_outlined,
              "Hide this store",
              () {
                Navigator.pop(context);
                _confirmHideStore();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportStoreSheet() {
    final reasons = [
      "Fake store",
      "Wrong product info",
      "Suspicious prices",
      "Bad customer experience",
      "Other",
    ];
    String? selectedReason;
    final otherController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDDDDD),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Report Store",
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Why are you reporting this store?",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: reasons.map((reason) {
                        final isSelected = selectedReason == reason;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedReason = reason),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? wine : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isSelected ? wine : const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Text(
                              reason,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : darkText,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (selectedReason == "Other") ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: otherController,
                        maxLines: 3,
                        style:
                            GoogleFonts.poppins(fontSize: 13, color: darkText),
                        decoration: InputDecoration(
                          hintText: "Please describe the issue...",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFFAAAAAA),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (selectedReason == null || isSubmitting)
                            ? null
                            : () async {
                                setSheetState(() => isSubmitting = true);
                                final storeId =
                                    (widget.store["_id"] ?? "").toString();
                                final details = selectedReason == "Other"
                                    ? otherController.text.trim()
                                    : "";
                                final result = await ApiService.reportStore(
                                  storeId: storeId,
                                  userId: widget.userId,
                                  reason: selectedReason!,
                                  details: details,
                                );
                                if (!mounted) return;
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                final code = result["statusCode"] as int;
                                final msg = code == 201
                                    ? "Store reported. Our admin team will review it shortly."
                                    : code == 409
                                        ? "You've already reported this store. It's under review."
                                        : "Failed to submit report. Try again.";
                                _showActionSnackBar(msg);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: wine,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFDDDDDD),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "Submit Report",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmHideStore() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          "Hide this store?",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: darkText,
          ),
        ),
        content: Text(
          "This store won't appear in your shop feed anymore. You can always find it by searching.",
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF777777),
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: OutlinedButton.styleFrom(
              foregroundColor: darkText,
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final storeId = (widget.store["_id"] ?? "").toString();
              final success = await ApiService.hideStore(
                userId: widget.userId,
                storeId: storeId,
              );
              if (!mounted) return;
              if (success) {
                _showActionSnackBar("Store hidden from your feed.");
                Navigator.pop(context, {
                  'hidden': true,
                  'storeId': (widget.store["_id"] ?? "").toString()
                });
              } else {
                _showActionSnackBar("Could not hide store. Try again.");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: wine,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Hide Store",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: wine,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _moreOption(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: wine),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
      ),
    );
  }

  Widget _logoFallback(String storeName) {
    final letter = storeName.isNotEmpty ? storeName[0].toUpperCase() : "S";
    return Container(
      color: wine,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.playfairDisplay(
            fontSize: 28, fontWeight: FontWeight.w500, color: Colors.white),
      ),
    );
  }

  // ── Verified Badge + Follow/Share ──────────────────────────────────────────
  Widget _buildVerifiedBadge(String storeName) {
    final isVerified = widget.store["isVerified"] == true;
    final verificationLevel =
        widget.store["verificationLevel"]?.toString() ?? "standard";

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          if (isVerified)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      verificationLevel == "trusted"
                          ? "Trusted Store"
                          : verificationLevel == "premium"
                              ? "Premium Store"
                              : "Verified Store",
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store_outlined, color: Colors.black38, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    "New Store",
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Follow button with animated check overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: _toggleFollow,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isFollowing ? Colors.white : wine,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: wine, width: 1.5),
                        boxShadow: isFollowing
                            ? []
                            : [
                                BoxShadow(
                                  color: wine.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: _isFollowLoading
                          ? SizedBox(
                              width: 50,
                              height: 17,
                              child: Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    color: isFollowing ? wine : Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              isFollowing ? "Following ✓" : "Follow",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isFollowing ? wine : Colors.white,
                              ),
                            ),
                    ),
                  ),
                  // Floating check animation on follow
                  AnimatedOpacity(
                    opacity: _showFollowCheck ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedScale(
                      scale: _showFollowCheck ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: wine,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: wine.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Followers count
              Text(
                _formatFollowersCount(_followersCount),
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: const Color(0xFF888888),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow(String responseTime, String shippingTime) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          _statCard(
            value: "${storeProducts.length}",
            label: "Products",
            icon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(width: 10),
          _statCard(
            value: responseTime,
            label: "Response",
            icon: Icons.timer_outlined,
          ),
          const SizedBox(width: 10),
          _statCard(
            value: shippingTime,
            label: "Shipping",
            icon: Icons.local_shipping_outlined,
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      {required String value, required String label, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: wine.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: wine, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: darkText)),
            Text(label,
                style:
                    GoogleFonts.poppins(fontSize: 9.5, color: Colors.black45)),
          ],
        ),
      ),
    );
  }

  void _showChatSheet({Map<String, dynamic>? productContext}) {
    final storeName = widget.store["storeName"] ?? "Store";
    final responseTime = widget.store["responseTime"] ?? "< 1h";
    final logoUrl = (widget.store["logoUrl"] ?? "").toString();
    final letter = storeName.isNotEmpty ? storeName[0].toUpperCase() : "S";
    bool starting = false;

    final List<Map<String, String>> badges = [
      {"icon": "verified", "label": "Verified Store"},
      {"icon": "lock", "label": "Secure Support"},
      {"icon": "bolt", "label": "Fast Replies"},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheet) => Container(
          padding: EdgeInsets.fromLTRB(
              22, 16, 22, MediaQuery.of(sheetCtx).viewInsets.bottom + 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Store avatar + online indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          wine.withOpacity(0.8),
                          const Color(0xFF8E4B5D)
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: logoUrl.isNotEmpty
                              ? Image.network(
                                  logoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      letter,
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                        color: wine,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    letter,
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                      color: wine,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                storeName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Usually replies within $responseTime",
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Trust badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: badges.map((b) {
                  final icon = b["icon"] == "verified"
                      ? Icons.verified_outlined
                      : b["icon"] == "lock"
                          ? Icons.lock_outline_rounded
                          : Icons.bolt_rounded;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4F3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: wine.withOpacity(0.10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 13, color: wine),
                        const SizedBox(width: 5),
                        Text(
                          b["label"]!,
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Start Conversation button
              GestureDetector(
                onTap: starting
                    ? null
                    : () async {
                        setSheet(() => starting = true);
                        HapticFeedback.lightImpact();

                        final storeId = (widget.store["_id"] ?? "").toString();
                        final result = await ApiService.startConversation(
                          userId: widget.userId,
                          storeId: storeId,
                        );

                        if (!sheetCtx.mounted) return;
                        Navigator.pop(sheetCtx);

                        if (result["conversation"] != null) {
                          final conv = result["conversation"] as Map;
                          final convId = (conv["_id"] ?? "").toString();
                          // sellerId on the store is a populated object {_id, fullName}
                          final sellerRaw = widget.store["sellerId"];
                          final sellerId = sellerRaw is Map
                              ? (sellerRaw["_id"] ?? "").toString()
                              : sellerRaw != null
                                  ? sellerRaw.toString()
                                  : (conv["sellerId"] ?? "").toString();

                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: convId,
                                userId: widget.userId,
                                userName: widget.userName,
                                storeId: storeId,
                                storeName: storeName,
                                storeLogoUrl: logoUrl,
                                responseTime: responseTime,
                                sellerId: sellerId,
                                productContext: productContext,
                                currentUserId: widget.userId,
                                currentUserType: 'user',
                              ),
                            ),
                          );
                        } else {
                          if (mounted) {
                            _showActionSnackBar(
                                "Couldn't start chat. Try again.");
                          }
                        }
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  decoration: BoxDecoration(
                    color: starting ? wine.withOpacity(0.6) : wine,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: wine.withOpacity(0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: starting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Start Conversation",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Action Buttons ─────────────────────────────────────────────────────────
  Widget _buildActionButtons(String phone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _actionBtn(
              icon: Icons.chat_bubble_outline_rounded,
              label: "Chat",
              filled: true,
              onTap: _showChatSheet,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionBtn(
              icon: Icons.phone_outlined,
              label: phone.isEmpty ? "Call" : phone,
              filled: false,
              onTap: () => _callStore(phone),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionBtn(
              icon: Icons.map_outlined,
              label: "Map",
              filled: false,
              onTap: _openGoogleMaps,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callStore(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleanPhone.isEmpty) {
      _showActionSnackBar("No phone number available.");
      return;
    }

    final uri = Uri.parse("tel:$cleanPhone");

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showActionSnackBar("Could not open phone app.");
      }
    } catch (e) {
      _showActionSnackBar("Could not open phone app.");
    }
  }

  void _showMapSheet() {
    final storeName = widget.store["storeName"] ?? "Store";
    final city = widget.store["city"] ?? "";
    final address = widget.store["address"] ?? "";
    final fullAddress = "$storeName, $address, $city";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
        decoration: const BoxDecoration(
          color: warmCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: wine.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.map_outlined, color: wine, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              "Store Location",
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fullAddress,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: fullAddress));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Address copied",
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    backgroundColor: wine,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: wine,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    "Copy Address",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: filled ? wine : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: wine.withOpacity(0.2)),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: wine.withOpacity(0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: filled ? Colors.white : wine),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: filled ? Colors.white : wine,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions Grid ─────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {
        "icon": Icons.local_shipping_outlined,
        "label": "Delivery",
        "color": wine,
        "onTap": _showDeliverySheet,
      },
      {
        "icon": Icons.info_outline_rounded,
        "label": "About",
        "color": const Color(0xFF6A1B9A),
        "onTap": _showAboutSheet,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: actions.map((a) {
          final color = a["color"] as Color;
          final onTap = a["onTap"] as VoidCallback;
          return Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(a["icon"] as IconData, color: color, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a["label"] as String,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: darkText.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAboutSheet() {
    final storeName = widget.store["storeName"] ?? "Store";
    final description =
        widget.store["description"] ?? "No description available.";

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _AboutStoreSheet(
        storeName: storeName,
        description: description,
      ),
    );
  }

  // ── Delivery Sheet ─────────────────────────────────────────────────────────
  void _showDeliverySheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _DeliverySheet(
        storeName: widget.store["storeName"] ?? "Store",
        deliveryInfo: widget.store["deliveryInfo"] as Map<String, dynamic>?,
      ),
    );
  }

  // ── Return Policy Sheet ────────────────────────────────────────────────────

  // ── Category Bar ───────────────────────────────────────────────────────────
  Widget _buildCategoryBar({bool compact = false}) {
    return Container(
      height: compact ? 52 : 60,
      color: compact ? Colors.transparent : softBg,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final selected = selectedCategory == cat;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? wine : Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? wine : wine.withOpacity(0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? wine.withOpacity(0.22)
                        : Colors.black.withOpacity(0.035),
                    blurRadius: selected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                cat,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  color: selected ? Colors.white : wine.withOpacity(0.75),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Featured Products ──────────────────────────────────────────────────────
  Widget _buildFeaturedSection() {
    final products = _filteredProducts;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Featured Products", "${products.length} items"),
          const SizedBox(height: 16),
          if (products.isEmpty)
            _emptyState(
              icon: Icons.shopping_bag_outlined,
              message: "No products in this category yet.",
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
                childAspectRatio: 0.60,
              ),
              itemBuilder: (context, index) {
                return _premiumProductCard(products[index]);
              },
            ),
        ],
      ),
    );
  }

  // ── Premium Product Card ───────────────────────────────────────────────────
  Widget _premiumProductCard(dynamic item) {
    final productJson = item["productId"] ?? {};
    final price = item["price"] ?? 0;
    final currency = item["currency"] ?? "ILS";
    final stockCount = item["stockCount"] ?? 0;
    final product = ProductModel.fromJson(productJson);
    final isLiked = _wishlist.contains(product.id);
    final hasDiscount = product.discountPercent > 0;
    final isBestSeller = (product.rating) >= 4.5;

    return GestureDetector(
      onTap: () => _showStoreProductSheet(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: wine.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: warmCream,
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Colors.black26),
                          )
                        : const Icon(Icons.image_outlined,
                            size: 40, color: Colors.black26),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: wine,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "-${product.discountPercent}%",
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    ),
                  ),
                if (isBestSeller && !hasDiscount)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Top Rated",
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (isLiked) {
                          _wishlist.remove(product.id);
                        } else {
                          _wishlist.add(product.id);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.black45,
                          letterSpacing: 0.4),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: darkText,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _ratingStars(product.rating, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "$price $currency",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: wine,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: stockCount > 0
                              ? () => _addToCart(item, product)
                              : () => _showStockSnackBar(
                                    "This product is currently out of stock.",
                                  ),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: stockCount > 0 ? wine : Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: stockCount > 0
                                  ? [
                                      BoxShadow(
                                        color: wine.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : [],
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: stockCount <= 0
                                ? Colors.red
                                : stockCount <= 5
                                    ? const Color(0xFFE65100)
                                    : const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          stockCount <= 0
                              ? "Out of Stock"
                              : stockCount <= 5
                                  ? "Limited Stock"
                                  : "Available",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: stockCount <= 0
                                ? Colors.red
                                : stockCount <= 5
                                    ? const Color(0xFFE65100)
                                    : const Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  void _showStoreProductSheet(dynamic item) {
    final productJson = item["productId"] ?? {};
    final product = ProductModel.fromJson(productJson);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _storeProductSheetContent(
          item: item,
          product: product,
        );
      },
    );
  }

  Widget _storeProductSheetContent({
    required dynamic item,
    required ProductModel product,
  }) {
    final price = item["price"] ?? product.price;
    final currency = item["currency"] ?? product.currency;
    final stockCount = item["stockCount"] ?? 0;
    final storeName = widget.store["storeName"] ?? "Store";
    final logoUrl = widget.store["logoUrl"] ?? "";
    final city = widget.store["city"] ?? "";

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: warmCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Container(
              height: 230,
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(
                        product.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.spa_outlined, color: wine, size: 50),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: wine.withOpacity(0.7),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      color: deepPlum,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        "$price $currency",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: wine,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: stockCount <= 0
                              ? Colors.red.withOpacity(0.08)
                              : stockCount <= 5
                                  ? const Color(0xFFFFF3E0)
                                  : const Color(0xFFEAF7F0),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          stockCount <= 0
                              ? "Out of Stock"
                              : stockCount <= 5
                                  ? "Limited Stock"
                                  : "Available",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: stockCount <= 0
                                ? Colors.red
                                : stockCount <= 5
                                    ? const Color(0xFFE65100)
                                    : const Color(0xFF2E7D52),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (product.shortDescription.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: wine.withOpacity(0.07)),
                      ),
                      child: Text(
                        product.shortDescription,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: darkText.withOpacity(0.65),
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(
                                product: product,
                                userId: widget.userId,
                                userName: widget.userName,
                              ),
                            ),
                          ),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: wine.withOpacity(0.18)),
                            ),
                            child: Center(
                              child: Text(
                                "View Details",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: wine,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: stockCount > 0
                              ? () {
                                  Navigator.pop(context);
                                  _addToCart(item, product);
                                }
                              : null,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: stockCount > 0 ? wine : Colors.black26,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                "Add to Cart",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Best Sellers ───────────────────────────────────────────────────────────
  Widget _buildBestSellersSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Best Sellers", "Top picks"),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _bestSellers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                return _bestSellerCard(_bestSellers[i]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _bestSellerCard(dynamic item) {
    final productJson = item["productId"] ?? {};
    final price = item["price"] ?? 0;
    final currency = item["currency"] ?? "ILS";
    final product = ProductModel.fromJson(productJson);

    return GestureDetector(
      onTap: () => _showStoreProductSheet(item),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: wine.withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(26)),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: warmCream,
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(product.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                size: 36,
                                color: Colors.black26))
                        : const Icon(Icons.image_outlined,
                            size: 36, color: Colors.black26),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: Colors.white, size: 11),
                        const SizedBox(width: 2),
                        Text("Best",
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.brand,
                      style: GoogleFonts.poppins(
                          fontSize: 9.5, color: Colors.black45),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(product.name,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: darkText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text("$price $currency",
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: wine)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reviews ────────────────────────────────────────────────────────────────
  Widget _buildReviewsSection() {
    final reviews = _allReviews;
    final storeRating = (widget.store["rating"] ?? 0.0).toDouble();
    final reviewCount = reviews.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Customer Reviews", ""),
          const SizedBox(height: 16),
          // ── Summary card ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5B2333), Color(0xFF2E1520)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: wine.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeRating > 0 ? storeRating.toStringAsFixed(1) : "—",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 52,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ratingStars(storeRating, size: 17),
                    const SizedBox(height: 6),
                    Text(
                      "$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}",
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewCount > 0
                            ? "Trusted by customers"
                            : "No reviews yet",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reviewCount > 0
                            ? "Based on verified purchases\nfrom our store."
                            : "Be the first to review after\nyour order.",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white60,
                          height: 1.6,
                        ),
                      ),
                      if (reviewCount > 0) ...[
                        const SizedBox(height: 14),
                        _buildRatingBar(5, reviews),
                        const SizedBox(height: 5),
                        _buildRatingBar(4, reviews),
                        const SizedBox(height: 5),
                        _buildRatingBar(3, reviews),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── Review cards or empty state ───────────────────────────
          if (reviews.isEmpty)
            _buildReviewsEmptyState()
          else
            ...reviews.map((r) => _buildStoreReviewCard(r)),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, List<dynamic> reviews) {
    final count = reviews
        .where((r) => ((r["rating"] ?? 0) as num).round() == star)
        .length;
    final pct = reviews.isEmpty ? 0.0 : count / reviews.length;
    return Row(
      children: [
        Text("$star",
            style: GoogleFonts.poppins(fontSize: 9, color: Colors.white54)),
        const SizedBox(width: 4),
        Icon(Icons.star_rounded, size: 9, color: gold),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(gold),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "$count",
          style: GoogleFonts.poppins(fontSize: 9, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildStoreReviewCard(dynamic review) {
    final rawName = (review["userName"] ?? "").toString().trim();
    final populatedName = review["userId"] is Map
        ? ((review["userId"]["fullName"] ?? "").toString().trim())
        : "";
    final name = rawName.isNotEmpty
        ? rawName
        : (populatedName.isNotEmpty ? populatedName : "Customer");
    final text = (review["comment"] ?? "").toString();
    final rating = ((review["rating"] ?? 5) as num).toDouble();
    final date = (review["createdAt"] ?? "").toString();
    final initial = name[0].toUpperCase();

    final List<Color> avatarColors = [
      wine,
      deepPlum,
      const Color(0xFF1565C0),
      const Color(0xFF6A1B9A),
      const Color(0xFF00695C),
    ];
    final avatarColor =
        avatarColors[initial.codeUnitAt(0) % avatarColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: darkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded,
                                  size: 10, color: Color(0xFF2E7D52)),
                              const SizedBox(width: 3),
                              Text(
                                "Verified purchase",
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2E7D52),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _ratingStars(rating, size: 13),
                        const SizedBox(width: 6),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: gold,
                          ),
                        ),
                        const Spacer(),
                        if (date.isNotEmpty)
                          Text(
                            _formatDate(date),
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.black38),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: darkText.withOpacity(0.75),
                  height: 1.55,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: wine.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: softPink,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rate_review_outlined,
                size: 32, color: wine.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            "No store reviews yet",
            style: GoogleFonts.playfairDisplay(
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Reviews will appear here after customers\nrate their orders.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black45,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    final images = (widget.store["galleryImages"] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();

    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Store Gallery", "A glimpse inside the store"),
          const SizedBox(height: 14),
          Row(
            children: List.generate(images.length, (index) {
              return Expanded(
                child: Container(
                  height: 120,
                  margin: EdgeInsets.only(
                    right: index == images.length - 1 ? 0 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _netImage(
                      images[index],
                      fit: BoxFit.cover,
                      placeholder: const Icon(Icons.storefront_outlined),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _galleryPlaceholder(int i) {
    final icons = [
      Icons.storefront_outlined,
      Icons.spa_outlined,
      Icons.inventory_2_outlined,
      Icons.local_florist_outlined,
      Icons.face_retouching_natural,
      Icons.photo_library_outlined,
    ];
    return Center(
      child:
          Icon(icons[i % icons.length], size: 34, color: wine.withOpacity(0.3)),
    );
  }

  // ── Recommended ────────────────────────────────────────────────────────────
  Widget _buildRecommendedSection() {
    final onboarding =
        userProfile?["onboarding"] as Map<String, dynamic>? ?? {};

    final skinType = (onboarding["skinType"] ?? "").toString().toLowerCase();

    final concerns = ((onboarding["skinConcerns"] ?? []) as List)
        .map((e) => e.toString().toLowerCase())
        .toList();

    final goals = ((onboarding["goals"] ?? []) as List)
        .map((e) => e.toString().toLowerCase())
        .toList();

    final rec = storeProducts
        .where((item) {
          final product = item["productId"] ?? {};
          final recommendedFor = product["recommendedFor"] ?? {};

          final skinTypes = ((recommendedFor["skinTypes"] ?? []) as List)
              .map((e) => e.toString().toLowerCase())
              .toList();

          final productConcerns = ((recommendedFor["concerns"] ?? []) as List)
              .map((e) => e.toString().toLowerCase())
              .toList();

          final productGoals = ((recommendedFor["goals"] ?? []) as List)
              .map((e) => e.toString().toLowerCase())
              .toList();

          final matchesSkinType =
              skinType.isNotEmpty && skinTypes.contains(skinType);

          final matchesConcerns =
              concerns.any((c) => productConcerns.contains(c));

          final matchesGoals = goals.any((g) => productGoals.contains(g));

          return matchesSkinType || matchesConcerns || matchesGoals;
        })
        .take(6)
        .toList();

    List<dynamic> finalRec = rec;

    if (finalRec.isEmpty) {
      finalRec = storeProducts
          .where((item) {
            final product = item["productId"] ?? {};
            final category =
                (product["category"] ?? "").toString().toLowerCase();

            return category == "cleanser" ||
                category == "moisturizer" ||
                category == "sunscreen" ||
                category == "serum";
          })
          .take(6)
          .toList();
    }

    if (finalRec.isEmpty) {
      finalRec = [...storeProducts];
      finalRec.sort((a, b) {
        final pA = a["productId"] ?? {};
        final pB = b["productId"] ?? {};
        final rA = (pA["rating"] ?? 0) as num;
        final rB = (pB["rating"] ?? 0) as num;
        return rB.compareTo(rA);
      });
      finalRec = finalRec.take(6).toList();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _sectionHeader(
              "Recommended For You",
              "Based on your skin profile",
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: finalRec.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                return _bestSellerCard(finalRec[i]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Skeleton loader ────────────────────────────────────────────────────────
  Widget _buildSkeletonGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: 0.60,
        children: List.generate(
            4,
            (_) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      _shimmer(height: 140, radius: 0, topRadius: 28),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _shimmer(height: 10, radius: 6, width: 60),
                            const SizedBox(height: 8),
                            _shimmer(height: 13, radius: 6),
                            const SizedBox(height: 4),
                            _shimmer(height: 13, radius: 6, width: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
      ),
    );
  }

  Widget _shimmer(
      {required double height,
      required double radius,
      double? width,
      double topRadius = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: topRadius > 0
                ? BorderRadius.only(
                    topLeft: Radius.circular(topRadius),
                    topRight: Radius.circular(topRadius),
                    bottomLeft: Radius.circular(radius),
                    bottomRight: Radius.circular(radius),
                  )
                : BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: darkText)),
            if (subtitle.isNotEmpty)
              Text(subtitle,
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
          ],
        ),
      ],
    );
  }

  Widget _ratingStars(double rating, {double size = 12}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star_rounded, color: gold, size: size);
        } else if (i < rating) {
          return Icon(Icons.star_half_rounded, color: gold, size: size);
        } else {
          return Icon(Icons.star_border_rounded,
              color: Colors.black26, size: size);
        }
      }),
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: wine.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45)),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature coming soon",
            style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: deepPlum,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Delivery Information Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _DeliverySheet extends StatefulWidget {
  final String storeName;
  final Map<String, dynamic>? deliveryInfo;
  const _DeliverySheet({required this.storeName, this.deliveryInfo});

  @override
  State<_DeliverySheet> createState() => _DeliverySheetState();
}

class _DeliverySheetState extends State<_DeliverySheet>
    with TickerProviderStateMixin {
  // ── Palette (mirrors parent) ───────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);
  // ignore: unused_field
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color gold = Color(0xFFD4AF37);
  static const Color softPink = Color(0xFFF8E8EC);
  // ignore: unused_field
  static const Color deepPlum = Color(0xFF2E1520);

  late final List<AnimationController> _sectionCtrl;
  late final List<Animation<double>> _sectionFade;
  late final List<Animation<Offset>> _sectionSlide;

  // ── Data getters — read from deliveryInfo, fall back to sensible defaults ──

  List<Map<String, String>> get _areas {
    final raw = widget.deliveryInfo?["areas"];
    if (raw is List && raw.isNotEmpty) {
      return raw.map<Map<String, String>>((a) {
        final m =
            (a is Map) ? Map<String, dynamic>.from(a) : <String, dynamic>{};
        return {
          "name": m["name"]?.toString() ?? "",
          "time": m["time"]?.toString() ?? "1–2 days",
        };
      }).toList();
    }
    return const [
      {"name": "Nablus", "time": "Same day"},
      {"name": "Ramallah", "time": "1–2 days"},
      {"name": "Jenin", "time": "1–2 days"},
      {"name": "Jerusalem", "time": "2–3 days"},
      {"name": "Tulkarm", "time": "1–2 days"},
      {"name": "Qalqilya", "time": "1–2 days"},
      {"name": "Jericho", "time": "2–3 days"},
      {"name": "Bethlehem", "time": "2–3 days"},
    ];
  }

  List<Map<String, dynamic>> get _workingHours {
    final raw = widget.deliveryInfo?["workingHours"];
    if (raw is List && raw.isNotEmpty) {
      return raw.map<Map<String, dynamic>>((h) {
        final m =
            (h is Map) ? Map<String, dynamic>.from(h) : <String, dynamic>{};
        return {
          "day": m["day"]?.toString() ?? "",
          "hours": m["hours"]?.toString() ?? "",
          "isOpen": m["isOpen"] as bool? ?? true,
        };
      }).toList();
    }
    return const [
      {
        "day": "Sunday – Thursday",
        "hours": "10:00 AM – 8:00 PM",
        "isOpen": true
      },
      {"day": "Saturday", "hours": "11:00 AM – 6:00 PM", "isOpen": true},
      {"day": "Friday", "hours": "Closed", "isOpen": false},
    ];
  }

  List<Map<String, dynamic>> get _computedMethods {
    final di = widget.deliveryInfo;
    final methods = (di?["methods"] is Map)
        ? Map<String, dynamic>.from(di!["methods"] as Map)
        : <String, dynamic>{};
    final showCourier = methods["localCourier"] as bool? ?? true;
    final showExpress = methods["expressDelivery"] as bool? ?? true;
    final showPickup = methods["storePickup"] as bool? ?? true;
    final freeOver = di?["freeDeliveryOver"] ?? 150;
    final expressFee = di?["expressFee"] ?? 25;

    return [
      if (showCourier)
        {
          "icon": Icons.directions_bike_outlined,
          "title": "Local Courier",
          "sub": "Standard delivery · 1–2 days",
          "badge": "Free over $freeOver ₪",
          "color": wine,
        },
      if (showExpress)
        {
          "icon": Icons.electric_bolt_rounded,
          "title": "Express Delivery",
          "sub": "Same-day delivery · main city only",
          "badge": "$expressFee ₪",
          "color": const Color(0xFFE65100),
        },
      if (showPickup)
        {
          "icon": Icons.store_outlined,
          "title": "Store Pickup",
          "sub": "Pick up at our location · Free",
          "badge": "Free",
          "color": const Color(0xFF2E7D52),
        },
    ];
  }

  List<Map<String, dynamic>> get _timelineSteps {
    final raw = widget.deliveryInfo?["deliverySteps"];

    if (raw is List && raw.isNotEmpty) {
      return raw.map<Map<String, dynamic>>((s) {
        final m = Map<String, dynamic>.from(s as Map);
        return {
          "icon": _deliveryIcon(m["icon"]?.toString()),
          "title": m["title"]?.toString() ?? "",
          "sub": m["subtitle"]?.toString() ?? "",
        };
      }).toList();
    }

    return [
      {
        "icon": Icons.shopping_bag_outlined,
        "title": "Place Your Order",
        "sub": "Choose your products and complete checkout.",
      },
    ];
  }

  IconData _deliveryIcon(String? key) {
    switch (key) {
      case "shopping_bag":
        return Icons.shopping_bag_outlined;
      case "verified":
        return Icons.verified_outlined;
      case "inventory":
        return Icons.inventory_2_outlined;
      case "local_shipping":
        return Icons.local_shipping_outlined;
      default:
        return Icons.local_shipping_outlined;
    }
  }

  // ── Sections count (for staggered anims) ──────────────────────────────────
  static const _sectionCount = 6;

  @override
  void initState() {
    super.initState();
    _sectionCtrl = List.generate(
      _sectionCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      ),
    );
    _sectionFade = _sectionCtrl
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _sectionSlide = _sectionCtrl.map((c) {
      return Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic));
    }).toList();

    _staggerStart();
  }

  void _staggerStart() async {
    for (int i = 0; i < _sectionCount; i++) {
      await Future.delayed(Duration(milliseconds: 60 + i * 70));
      if (mounted) _sectionCtrl[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _sectionCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _sectionFade[index],
      child: SlideTransition(position: _sectionSlide[index], child: child),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: softBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              _buildSheetHeader(),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _animated(0, _buildFreeShippingBanner()),
                    const SizedBox(height: 24),
                    _animated(1, _buildAreasSection()),
                    const SizedBox(height: 24),
                    _animated(2, _buildTimelineSection()),
                    const SizedBox(height: 24),
                    _animated(3, _buildFeesSection()),
                    const SizedBox(height: 24),
                    _animated(4, _buildMethodsSection()),
                    const SizedBox(height: 24),
                    _animated(5, _buildHoursAndTracking()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Sheet Header ───────────────────────────────────────────────────────────
  Widget _buildSheetHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle pill
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: wine,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: wine.withOpacity(0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_shipping_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Delivery Information",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: darkText,
                      ),
                    ),
                    Text(
                      "Fast & reliable delivery",
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.black.withOpacity(0.06), height: 1),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Free Shipping Banner ───────────────────────────────────────────────────
  Widget _buildFreeShippingBanner() {
    final freeOver = widget.deliveryInfo?["freeDeliveryOver"] ?? 150;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B2333), Color(0xFF2E1520)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: wine.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.card_giftcard_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Free Delivery",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "On all orders above $freeOver ₪ — no code needed",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.82),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: gold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$freeOver ₪+",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Delivery Areas ─────────────────────────────────────────────────────────
  Widget _buildAreasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetSectionTitle(
          icon: Icons.map_outlined,
          title: "Delivery Areas",
          subtitle: "${_areas.length} cities covered",
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _areas.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.2,
          ),
          itemBuilder: (_, i) {
            final area = _areas[i];
            final isSameDay = (area["time"] ?? "").contains("Same day");
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSameDay ? wine.withOpacity(0.25) : Colors.transparent,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      color: isSameDay ? wine : Colors.black38, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      area["name"] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: darkText,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSameDay ? softPink : const Color(0xFFE8F0F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      area["time"] ?? "",
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: isSameDay ? wine : const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Delivery Timeline ──────────────────────────────────────────────────────
  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetSectionTitle(
          icon: Icons.timeline_rounded,
          title: "Order Journey",
          subtitle: "From tap to your door",
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(_timelineSteps.length, (i) {
              final step = _timelineSteps[i];
              final isLast = i == _timelineSteps.length - 1;
              return _timelineRow(
                icon: step["icon"] as IconData,
                title: step["title"] as String,
                sub: step["sub"] as String,
                isLast: isLast,
                index: i,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _timelineRow({
    required IconData icon,
    required String title,
    required String sub,
    required bool isLast,
    required int index,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: wine,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: wine.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            wine.withOpacity(0.6),
                            wine.withOpacity(0.15),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 6),
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
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black38,
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

  // ── Fees ───────────────────────────────────────────────────────────────────
  Widget _buildFeesSection() {
    final di = widget.deliveryInfo;
    final freeOver = di?["freeDeliveryOver"] ?? 150;
    final standardFee = di?["standardFee"] ?? 15;
    final expressFee = di?["expressFee"] ?? 25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetSectionTitle(
          icon: Icons.receipt_outlined,
          title: "Delivery Fees",
          subtitle: "Transparent pricing",
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF2E7D52).withOpacity(0.25), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D52).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF2E7D52), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Free Delivery",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                    Text(
                      "Orders over $freeOver ₪ ship for free",
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: const Color(0xFF2E7D52)),
                    ),
                  ],
                ),
              ),
              Text(
                "0 ₪",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _feeCard("Standard", "$standardFee ₪",
                    Icons.directions_bike_outlined, wine)),
            const SizedBox(width: 10),
            Expanded(
                child: _feeCard("Express", "$expressFee ₪",
                    Icons.electric_bolt_rounded, const Color(0xFFE65100))),
          ],
        ),
      ],
    );
  }

  Widget _feeCard(String label, String price, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: darkText)),
                Text("Flat rate",
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.black38)),
              ],
            ),
          ),
          Text(price,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              )),
        ],
      ),
    );
  }

  // ── Delivery Methods ───────────────────────────────────────────────────────
  Widget _buildMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetSectionTitle(
          icon: Icons.category_outlined,
          title: "Delivery Methods",
          subtitle: "Choose what works for you",
        ),
        const SizedBox(height: 14),
        ..._computedMethods.map((m) => _methodCard(m)),
      ],
    );
  }

  Widget _methodCard(Map<String, dynamic> m) {
    final color = m["color"] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(m["icon"] as IconData, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m["title"] as String,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: darkText)),
                const SizedBox(height: 2),
                Text(m["sub"] as String,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              m["badge"] as String,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hours & Tracking ───────────────────────────────────────────────────────
  Widget _buildHoursAndTracking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Working hours card
        _sheetSectionTitle(
          icon: Icons.access_time_rounded,
          title: "Working Hours",
          subtitle: "When we deliver",
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < _workingHours.length; i++) ...[
                _hoursRow(
                  _workingHours[i]["day"] as String? ?? "",
                  _workingHours[i]["hours"] as String? ?? "",
                  _workingHours[i]["isOpen"] as bool? ?? true,
                ),
                if (i < _workingHours.length - 1) _softDivider(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Tracking info card
        _sheetSectionTitle(
          icon: Icons.notifications_active_outlined,
          title: "Order Tracking",
          subtitle: "Stay in the loop",
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                wine.withOpacity(0.06),
                const Color(0xFFF0E4E8),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: wine.withOpacity(0.1), width: 1),
          ),
          child: Column(
            children: [
              const SizedBox(height: 14),
              _trackingRow(
                Icons.notifications_outlined,
                "Push Notifications",
                "In-app alerts keep you updated at every step of the journey.",
              ),
              const SizedBox(height: 14),
              _trackingRow(
                Icons.support_agent_outlined,
                "Live Support",
                "Chat with our team anytime if you have questions about your order.",
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Close button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: wine,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: wine.withOpacity(0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "Got it, thanks!",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hoursRow(String day, String hours, bool isOpen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOpen ? const Color(0xFF4CAF50) : Colors.black26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(day,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: darkText.withOpacity(0.8))),
          ),
          Text(
            hours,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isOpen ? darkText : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _softDivider() {
    return Divider(
      height: 1,
      color: Colors.black.withOpacity(0.06),
    );
  }

  Widget _trackingRow(IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: wine.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Icon(icon, color: wine, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: darkText)),
              const SizedBox(height: 3),
              Text(body,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: darkText.withOpacity(0.6),
                      height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Section title helper ───────────────────────────────────────────────────
  Widget _sheetSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: softPink,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: wine, size: 17),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: darkText)),
            Text(subtitle,
                style:
                    GoogleFonts.poppins(fontSize: 11, color: Colors.black38)),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Return Policy Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════

// ── Data getters — backend data with safe fallbacks ────────────────────────

class _AboutStoreSheet extends StatelessWidget {
  final String storeName;
  final String description;

  const _AboutStoreSheet({
    required this.storeName,
    required this.description,
  });

  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color softPink = Color(0xFFF8E8EC);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: wine,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  "About $storeName",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: darkText,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.6,
                color: darkText.withOpacity(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
