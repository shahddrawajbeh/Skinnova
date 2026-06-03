import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'store_profile_screen.dart';
import 'shop_ai_chat_page.dart';
import 'hidden_stores_screen.dart';
import 'notifications_page.dart';
import 'cart_screen.dart';

class ShopScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ShopScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // ─── Palette ───────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color softPink = Color(0xFFF8E8EC);
  static const Color gold = Color(0xFFD4AF37);
  static const Color dustyRose = Color(0xFFE8AABA);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color deepPlum = Color(0xFF2E1520);

  // ─── Data ──────────────────────────────────────────────────────────────────
  List<dynamic> stores = [];
  List<dynamic> storeProducts = [];
  List<dynamic> filteredStores = [];
  List<dynamic> filteredProducts = [];
  List<dynamic> ads = [];
  Set<String> hiddenStoreIds = {};
  List<dynamic> followedStores = [];
  Set<String> followedStoreIds = {};
  int _unreadCount = 0;
  bool isLoading = true;
  String searchText = "";
  int cartCount = 0;
  // ─── Slider ────────────────────────────────────────────────────────────────
  final PageController _sliderController =
      PageController(viewportFraction: 0.88);
  int currentSlide = 0;
  Timer? _timer;

  // ─── Discover / Filter ─────────────────────────────────────────────────────
  List<dynamic> trendingStoreProducts = [];
  int selectedDiscoverIndex = -1;
  List<dynamic> needStores = [];

  // ─── Search animation ──────────────────────────────────────────────────────
  static const List<String> _searchHints = [
    "Search for niacinamide...",
    "Find K-Beauty stores...",
    "Explore by skin concern...",
    "What's trending this week?",
  ];
  int _hintIndex = 0;
  Timer? _hintTimer;
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _likedProducts = {};

  // ─── Scroll ────────────────────────────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTop = false;
  String _productSort = "default";
  Future<void> loadCartCount() async {
    try {
      final result = await ApiService.fetchCart(widget.userId);
      if (result["statusCode"] == 200) {
        final items = (result["data"]["items"] ?? []) as List;
        int total = 0;
        for (final item in items) total += (item["quantity"] as int? ?? 1);
        if (!mounted) return;
        setState(() => cartCount = total);
      }
    } catch (_) {}
  }

  final List<Map<String, dynamic>> discoverItems = [
    {"title": "All", "emoji": "✨", "type": "all", "value": ""},
    {"title": "New stores", "emoji": "🔥", "type": "newStores", "value": ""},
    {"title": "Has Offers", "emoji": "💸", "type": "offers", "value": ""},
    {
      "title": "SPF Stores",
      "emoji": "☀️",
      "type": "category",
      "value": "sunscreen"
    },
    {
      "title": "Gentle Skin",
      "emoji": "🌿",
      "type": "concern",
      "value": "sensitive"
    },
    {"title": "K-Beauty", "emoji": "🇰🇷", "type": "origin", "value": "Korea"},
    {"title": "Local", "emoji": "🇵🇸", "type": "origin", "value": "Palestine"},
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
    _scrollController.addListener(_onScroll);
    _loadShopData();
    _loadUnreadCount();
    _startSlider();
    _startHintCycle();
    loadCartCount();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hintTimer?.cancel();
    _sliderController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _startHintCycle() {
    _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _searchHints.length);
    });
  }

  void _startSlider() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_sliderController.hasClients || ads.isEmpty) return;
      final next = currentSlide == ads.length - 1 ? 0 : currentSlide + 1;
      _sliderController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadShopData() async {
    try {
      final results = await Future.wait([
        ApiService.fetchStores(),
        ApiService.fetchAllStoreProducts(),
        ApiService.fetchTrendingStoreProducts(),
        ApiService.fetchApprovedAds(),
        ApiService.fetchHiddenStores(widget.userId),
        ApiService.fetchFollowedStores(widget.userId),
      ]);

      if (!mounted) return;

      final storesResult = results[0] as List<dynamic>;
      final productsResult = results[1] as List<dynamic>;
      final trendingResult = results[2] as List<dynamic>;
      final adsResult = results[3] as List<dynamic>;
      final hiddenList = results[4] as List<dynamic>;
      final followedList = results[5] as List<dynamic>;

      final hidden =
          hiddenList.map((s) => _getId(s)).where((id) => id.isNotEmpty).toSet();
      final followed = followedList
          .map((s) => _getId(s))
          .where((id) => id.isNotEmpty)
          .toSet();
      final visibleStores = storesResult
          .where((s) => !hidden.contains(_getId(s["_id"])))
          .toList();

      setState(() {
        stores = storesResult;
        storeProducts = productsResult;
        hiddenStoreIds = hidden;
        followedStores = followedList;
        followedStoreIds = followed;
        filteredStores = visibleStores;
        filteredProducts = productsResult;
        ads = adsResult;
        trendingStoreProducts = trendingResult;
        needStores = visibleStores;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Shop load error: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadUnreadCount() async {
    final count = await ApiService.getUnreadNotificationCount(widget.userId);
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  void _search(String value) {
    setState(() {
      searchText = value.toLowerCase().trim();

      if (searchText.isEmpty) {
        filteredStores = stores
            .where((s) => !hiddenStoreIds.contains(_getId(s["_id"])))
            .toList();
        filteredProducts = storeProducts;
        selectedDiscoverIndex = -1;
        return;
      }

      filteredStores = stores.where((store) {
        if (hiddenStoreIds.contains((store["_id"] ?? "").toString()))
          return false;
        final name = (store["storeName"] ?? "").toString().toLowerCase();
        final city = (store["city"] ?? "").toString().toLowerCase();
        final address = (store["address"] ?? "").toString().toLowerCase();
        final rating = (store["rating"] ?? "").toString().toLowerCase();
        return name.contains(searchText) ||
            city.contains(searchText) ||
            address.contains(searchText) ||
            rating.contains(searchText);
      }).toList();

      filteredProducts = storeProducts.where((item) {
        final product = item["productId"] ?? {};
        final store = item["storeId"] ?? {};
        final pName = (product["name"] ?? "").toString().toLowerCase();
        final brand = (product["brand"] ?? "").toString().toLowerCase();
        final cat = (product["category"] ?? "").toString().toLowerCase();
        final origin = (product["brandOrigin"] ?? "").toString().toLowerCase();
        final desc =
            (product["shortDescription"] ?? "").toString().toLowerCase();
        final sName = (store["storeName"] ?? "").toString().toLowerCase();
        final sCity = (store["city"] ?? "").toString().toLowerCase();
        final skinTypes =
            ((product["recommendedFor"]?["skinTypes"] ?? []) as List)
                .join(" ")
                .toLowerCase();
        final concerns =
            ((product["recommendedFor"]?["concerns"] ?? []) as List)
                .join(" ")
                .toLowerCase();
        final goals = ((product["recommendedFor"]?["goals"] ?? []) as List)
            .join(" ")
            .toLowerCase();
        return pName.contains(searchText) ||
            brand.contains(searchText) ||
            cat.contains(searchText) ||
            origin.contains(searchText) ||
            desc.contains(searchText) ||
            sName.contains(searchText) ||
            sCity.contains(searchText) ||
            skinTypes.contains(searchText) ||
            concerns.contains(searchText) ||
            goals.contains(searchText);
      }).toList();
    });
  }

  List<dynamic> get topStores {
    final list = List<dynamic>.from(stores);
    list.sort((a, b) {
      final r1 = double.tryParse((a["rating"] ?? 0).toString()) ?? 0;
      final r2 = double.tryParse((b["rating"] ?? 0).toString()) ?? 0;
      return r2.compareTo(r1);
    });
    return list.take(5).toList();
  }

  List<dynamic> get trendingProducts => trendingStoreProducts;

  List<dynamic> get _sortedProducts {
    final list = List<dynamic>.from(filteredProducts);
    if (_productSort == "priceAsc") {
      list.sort((a, b) =>
          (a["price"] ?? 0).toDouble().compareTo((b["price"] ?? 0).toDouble()));
    } else if (_productSort == "priceDesc") {
      list.sort((a, b) =>
          (b["price"] ?? 0).toDouble().compareTo((a["price"] ?? 0).toDouble()));
    } else if (_productSort == "topRated") {
      list.sort((a, b) => (b["reviewPostsRating"] ?? 0.0)
          .toDouble()
          .compareTo((a["reviewPostsRating"] ?? 0.0).toDouble()));
    } else {
      // Default: followed-store products score +10, bubbles them to the top
      list.sort((a, b) {
        final aId =
            _getId(a["storeId"] is Map ? a["storeId"]["_id"] : a["storeId"]);
        final bId =
            _getId(b["storeId"] is Map ? b["storeId"]["_id"] : b["storeId"]);
        final aScore = followedStoreIds.contains(aId) ? 10 : 1;
        final bScore = followedStoreIds.contains(bId) ? 10 : 1;
        return bScore.compareTo(aScore);
      });
    }
    return list;
  }

  Widget _logo(String logoUrl, String name, double size) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "S";
    if (logoUrl.startsWith("assets/")) {
      return Image.asset(logoUrl, width: size, height: size, fit: BoxFit.cover);
    }
    if (logoUrl.isNotEmpty) {
      return Image.network(
        logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Text(letter,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500, color: wine)),
        ),
      );
    }
    return Center(
      child: Text(letter,
          style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w500, color: wine)),
    );
  }

  // Extracts a plain string ID from a MongoDB value (string, Map, or $oid object)
  static String _getId(dynamic v) {
    if (v == null) return "";
    if (v is String) return v;
    if (v is Map) return (v[r'$oid'] ?? v['_id'] ?? '').toString();
    return v.toString();
  }

  Future<void> _openStore(dynamic store) async {
    final storeId = _getId(store["_id"]);
    final fullStore = await ApiService.fetchStoreById(storeId);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreProfileScreen(
          store: fullStore,
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );

    if (!mounted) return;

    if (result is Map && result['hidden'] == true) {
      final hiddenId = result['storeId'].toString();
      setState(() {
        hiddenStoreIds.add(hiddenId);
        filteredStores =
            filteredStores.where((s) => _getId(s["_id"]) != hiddenId).toList();
        needStores =
            needStores.where((s) => _getId(s["_id"]) != hiddenId).toList();
        followedStores =
            followedStores.where((s) => _getId(s["_id"]) != hiddenId).toList();
        followedStoreIds.remove(hiddenId);
      });
    } else {
      final updated = await ApiService.fetchFollowedStores(widget.userId);
      if (!mounted) return;
      setState(() {
        followedStores = updated;
        followedStoreIds =
            updated.map((s) => _getId(s)).where((id) => id.isNotEmpty).toSet();
      });
    }
  }

  Widget _revealSection(Widget child, {int order = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -(order * 0.08), end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, v, child) {
        final t = v.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PRODUCT CARD — reusable across grid contexts
  // ─────────────────────────────────────────────────────────────
  Widget _productCard(dynamic item, {bool showPrice = true}) {
    final product = item["productId"] ?? {};
    final productId = (product["_id"] ?? item["_id"] ?? "").toString();
    final productName = product["name"] ?? "Product";
    final brand = product["brand"] ?? "";
    final imageUrl = product["imageUrl"] ?? "";
    final price = (item["price"] ?? 0).toDouble();
    final currency = item["currency"] ?? "ILS";
    final priceDisplay = price > 0
        ? (currency == "ILS"
            ? "₪${price.toStringAsFixed(0)}"
            : "$currency ${price.toStringAsFixed(0)}")
        : null;
    final isLiked = _likedProducts.contains(productId);

    return _PressableCard(
      onTap: () => _showProductSheet(item),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.spa_outlined,
                                color: wine,
                                size: 28),
                          ),
                        )
                      : const Icon(Icons.spa_outlined, color: wine, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 9),
            if (brand.isNotEmpty)
              Text(
                brand.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: wine.withOpacity(0.72),
                  letterSpacing: 0.6,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: darkText,
                height: 1.25,
              ),
            ),
            const Spacer(),
            if (showPrice && priceDisplay != null)
              Text(
                priceDisplay,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: wine,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget _productGrid(List<dynamic> items) {
  //   if (items.isEmpty) return _emptyText("No products available");
  //   return GridView.builder(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     itemCount: items.length,
  //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: 2,
  //       crossAxisSpacing: 14,
  //       mainAxisSpacing: 14,
  //       childAspectRatio: 0.72,
  //     ),
  //     itemBuilder: (_, i) => _productCard(items[i]),
  //   );
  // }
  Widget _productGrid(List<dynamic> items, {bool showPrice = true}) {
    if (items.isEmpty) return _emptyText("No products available");
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) => _productCard(
        items[i],
        showPrice: showPrice,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SEARCH RESULTS VIEW — replaces sections when query is active
  // ─────────────────────────────────────────────────────────────
  Widget _searchResultsView() {
    final hasStores = filteredStores.isNotEmpty;
    final hasProducts = filteredProducts.isNotEmpty;
    final total = filteredStores.length + filteredProducts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: "Results for ",
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.black45),
                  ),
                  TextSpan(
                    text: '"$searchText"',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: wine,
                    ),
                  ),
                ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: softPink,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "$total found",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: wine,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (!hasStores && !hasProducts) ...[
          const SizedBox(height: 24),
          _emptyText('No results found for "$searchText"'),
        ],
        if (hasStores) ...[
          const SizedBox(height: 24),
          _sectionTitle(
            "Stores",
            "${filteredStores.length} match${filteredStores.length == 1 ? '' : 'es'}",
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 152,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filteredStores.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final store = filteredStores[index];
                final name = store["storeName"] ?? "Store";
                final logoUrl = store["logoUrl"] ?? "";
                final city = store["city"] ?? "";
                return _PressableCard(
                  onTap: () => _openStore(store),
                  child: Container(
                    width: 148,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: wine.withOpacity(0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: dustyRose.withOpacity(0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 68,
                          decoration: BoxDecoration(
                            color: softPink.withOpacity(0.45),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(28)),
                          ),
                          child: Center(
                            child: Container(
                              height: 50,
                              width: 50,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [
                                  wine.withOpacity(0.8),
                                  const Color(0xFF8E4B5D),
                                ]),
                                boxShadow: [
                                  BoxShadow(
                                    color: wine.withOpacity(0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    ClipOval(child: _logo(logoUrl, name, 44)),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 9, 12, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: darkText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(Icons.location_on_rounded,
                                    size: 11, color: wine.withOpacity(0.45)),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    city,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                        fontSize: 10, color: Colors.black38),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (hasProducts) ...[
          const SizedBox(height: 28),
          _sectionTitle(
            "Products",
            "${filteredProducts.length} match${filteredProducts.length == 1 ? '' : 'es'}",
          ),
          const SizedBox(height: 14),
          //_productGrid(filteredProducts),
          _productGrid(filteredProducts, showPrice: false),
        ],
      ],
    );
  }

  void _applyDiscoverFilter(Map<String, dynamic> item, int index) {
    final type = item["type"];
    final value = item["value"].toString().toLowerCase();

    List<dynamic> resultStores = [];

    if (type == "all") {
      resultStores = stores;
    } else if (type == "newStores") {
      final sorted = List<dynamic>.from(stores);

      sorted.sort((a, b) {
        final aDate = DateTime.tryParse((a["createdAt"] ?? "").toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse((b["createdAt"] ?? "").toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      resultStores = sorted.take(2).toList();
    } else if (type == "offers") {
      final offerStoreIds = ads
          .map((ad) {
            final store = ad["storeId"];
            return _getId(store is Map ? store["_id"] : store);
          })
          .where((id) => id.isNotEmpty)
          .toSet();

      resultStores = stores.where((s) {
        return offerStoreIds.contains(_getId(s["_id"]));
      }).toList();
    } else {
      final ids = storeProducts
          .where((sp) {
            final p = sp["productId"] ?? {};

            final category = (p["category"] ?? "").toString().toLowerCase();
            final origin = (p["brandOrigin"] ?? "").toString().toLowerCase();
            final concerns = ((p["recommendedFor"]?["concerns"] ?? []) as List)
                .join(" ")
                .toLowerCase();
            final skinTypes =
                ((p["recommendedFor"]?["skinTypes"] ?? []) as List)
                    .join(" ")
                    .toLowerCase();

            if (type == "category") return category.contains(value);
            if (type == "origin") return origin.contains(value);
            if (type == "concern") {
              return concerns.contains(value) || skinTypes.contains(value);
            }

            return false;
          })
          .map((sp) {
            final s = sp["storeId"];
            return _getId(s is Map ? s["_id"] : s);
          })
          .where((id) => id.isNotEmpty)
          .toSet();

      resultStores =
          stores.where((s) => ids.contains(_getId(s["_id"]))).toList();
    }

    resultStores = resultStores
        .where((s) => !hiddenStoreIds.contains(_getId(s["_id"])))
        .toList();

    final selectedStoreIds = resultStores
        .map((s) => _getId(s["_id"]))
        .where((id) => id.isNotEmpty)
        .toSet();

    setState(() {
      selectedDiscoverIndex = index;

      // المهم: All Stores يعتمد على filteredStores
      filteredStores = resultStores;
      needStores = resultStores;

      if (type == "all") {
        filteredProducts = storeProducts;
      } else {
        filteredProducts = storeProducts.where((sp) {
          final s = sp["storeId"];
          final id = _getId(s is Map ? s["_id"] : s);
          return selectedStoreIds.contains(id);
        }).toList();
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // PRODUCT QUICK-VIEW SHEET
  // ─────────────────────────────────────────────────────────────
  void _showProductSheet(dynamic item) {
    final product = item["productId"] ?? {};
    final productId = (product["_id"] ?? item["_id"] ?? "").toString();
    final store = item["storeId"];
    final storeObj = store is Map ? store : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheetState) {
          final liked = _likedProducts.contains(productId);

          void toggleHeart() {
            setState(() {
              if (_likedProducts.contains(productId)) {
                _likedProducts.remove(productId);
              } else {
                _likedProducts.add(productId);
              }
            });
            setSheetState(() {});
          }

          return _productSheetContent(
            product: product,
            item: item,
            storeObj: storeObj,
            isLiked: liked,
            onToggleHeart: toggleHeart,
          );
        },
      ),
    );
  }

  Widget _productSheetContent({
    required dynamic product,
    required dynamic item,
    dynamic storeObj,
    required bool isLiked,
    required VoidCallback onToggleHeart,
  }) {
    final name = product["name"] ?? "Product";
    final brand = product["brand"] ?? "";
    final imageUrl = product["imageUrl"] ?? "";
    final description =
        (product["shortDescription"] ?? product["description"] ?? "")
            .toString();
    final price = (item["price"] ?? 0).toDouble();
    final currency = item["currency"] ?? "ILS";
    final priceDisplay = price > 0
        ? (currency == "ILS"
            ? "₪${price.toStringAsFixed(0)}"
            : "$currency ${price.toStringAsFixed(0)}")
        : null;
    final reviewCount = (item["reviewPostsCount"] ?? 0) as int;
    final reviewRating = (item["reviewPostsRating"] ?? 0.0).toDouble();
    final hasReviews = reviewCount > 0;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.84),
      decoration: const BoxDecoration(
        color: warmCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            // Hero image
            Container(
              height: 220,
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                children: [
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: SizedBox.expand(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.spa_outlined,
                                  color: wine, size: 48)),
                        ),
                      ),
                    )
                  else
                    const Center(
                        child: Icon(Icons.spa_outlined, color: wine, size: 48)),
                  // Floating heart
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand.isNotEmpty)
                    Text(
                      brand.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: wine.withOpacity(0.7),
                        letterSpacing: 0.9,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: deepPlum,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // if (priceDisplay != null)
                      //   Text(
                      //     priceDisplay,
                      //     style: GoogleFonts.poppins(
                      //       fontSize: 22,
                      //       fontWeight: FontWeight.w500,
                      //       color: wine,
                      //     ),
                      //   ),
                      const Spacer(),
                      if (hasReviews)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(reviewRating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              Text(
                                "  ($reviewCount)",
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.black38),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: dustyRose.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "New",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: wine,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: wine.withOpacity(0.06)),
                      ),
                      child: Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (storeObj != null) ...[
                    _storeInfoRow(storeObj),
                    const SizedBox(height: 14),
                  ],
                  // CTA
                  GestureDetector(
                    onTap: storeObj != null
                        ? () {
                            Navigator.pop(context);
                            _openStore(storeObj);
                          }
                        : () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: wine,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: wine.withOpacity(0.32),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              storeObj != null ? "Visit Store" : "Close",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            if (storeObj != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 18),
                            ],
                          ],
                        ),
                      ),
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

  Widget _storeInfoRow(dynamic store) {
    final name = store["storeName"] ?? "Store";
    final logo = store["logoUrl"] ?? "";
    final rating = store["rating"] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: wine.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [wine.withOpacity(0.8), const Color(0xFF8E4B5D)]),
            ),
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: ClipOval(child: _logo(logo, name, 32)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Sold by",
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.black38)),
                Text(name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: darkText,
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                const SizedBox(width: 3),
                Text(
                    (double.tryParse(rating.toString()) ?? 0)
                        .toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    final options = [
      {
        "label": "Default",
        "value": "default",
        "icon": Icons.auto_awesome_rounded
      },
      {
        "label": "Price: Low → High",
        "value": "priceAsc",
        "icon": Icons.arrow_upward_rounded
      },
      {
        "label": "Price: High → Low",
        "value": "priceDesc",
        "icon": Icons.arrow_downward_rounded
      },
      {"label": "Top Rated", "value": "topRated", "icon": Icons.star_rounded},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (_, setSheet) => Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          decoration: const BoxDecoration(
            color: warmCream,
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
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                "Sort Products",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: deepPlum,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final value = opt["value"] as String;
                final icon = opt["icon"] as IconData;
                final label = opt["label"] as String;
                final selected = _productSort == value;

                return GestureDetector(
                  onTap: () {
                    setState(() => _productSort = value);
                    setSheet(() {});
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? softPink : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? wine.withOpacity(0.22)
                            : wine.withOpacity(0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon,
                            color: selected ? wine : Colors.black38, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w500 : FontWeight.w500,
                            color: selected ? wine : darkText,
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              color: wine, size: 18),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _onScroll() {
    final show = _scrollController.offset > 300;
    if (show != _showScrollTop) setState(() => _showScrollTop = show);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  Widget _simpleShopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            "Shop",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: darkText,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bell icon with unread badge
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NotificationsPage(userId: widget.userId),
                      ),
                    );
                    if (mounted) setState(() => _unreadCount = 0);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: wine.withOpacity(0.10),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: wine,
                          size: 22,
                        ),
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            decoration: const BoxDecoration(
                              color: wine,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _unreadCount > 99 ? "99+" : "$_unreadCount",
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CartScreen(userId: widget.userId),
                      ),
                    );
                    loadCartCount();
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: wine.withOpacity(0.10),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: wine,
                          size: 22,
                        ),
                      ),
                      if (cartCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: wine,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                cartCount > 99 ? '99+' : '$cartCount',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warmCream,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: wine),
              )
            : Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadShopData,
                    color: wine,
                    backgroundColor: Colors.white,
                    displacement: 40,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header is edge-to-edge — no outer horizontal padding
                          _simpleShopHeader(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _revealSection(_searchBar(), order: 0),
                                const SizedBox(height: 24),
                                if (searchText.isNotEmpty)
                                  _searchResultsView()
                                else ...[
                                  _revealSection(_heroSlider(), order: 1),
                                  const SizedBox(height: 24),
                                  _revealSection(
                                    _followingStoresSection(),
                                    order: 2,
                                  ),
                                  const SizedBox(height: 28),
                                  //_revealSection(_discoverSection(), order: 3),
                                  const SizedBox(height: 28),
                                  _revealSection(
                                    _exploreStoresBlock(),
                                    order: 3,
                                  ),
                                  const SizedBox(height: 28),
                                  _revealSection(
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _sectionTitle(
                                          "Popular Across Stores",
                                          "Based on carts, reviews, and purchases",
                                        ),
                                        const SizedBox(height: 14),
                                        _trendingProducts(),
                                      ],
                                    ),
                                    order: 4,
                                  ),
                                  const SizedBox(height: 28),
                                  _revealSection(_aiBanner(), order: 5),
                                  const SizedBox(height: 28),
                                  _revealSection(
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            _sectionTitle("All Products",
                                                "${_sortedProducts.length} products"),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: _showSortSheet,
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 7),
                                                decoration: BoxDecoration(
                                                  color:
                                                      _productSort != "default"
                                                          ? softPink
                                                          : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                  border: Border.all(
                                                    color: _productSort !=
                                                            "default"
                                                        ? wine.withOpacity(0.22)
                                                        : wine
                                                            .withOpacity(0.10),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                        Icons.sort_rounded,
                                                        color: wine,
                                                        size: 14),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      _productSort != "default"
                                                          ? "Sorted"
                                                          : "Sort",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: wine,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        //  _productGrid(_sortedProducts),
                                        _productGrid(_sortedProducts,
                                            showPrice: false),
                                      ],
                                    ),
                                    order: 6,
                                  ),

                                  const SizedBox(height: 28),
                                  // _revealSection(
                                  //   Column(
                                  //     crossAxisAlignment:
                                  //         CrossAxisAlignment.start,
                                  //     children: [
                                  //       Row(
                                  //         children: [
                                  //           _sectionTitle("All Stores",
                                  //               "${filteredStores.length} stores"),
                                  //           const Spacer(),
                                  //           if (hiddenStoreIds.isNotEmpty)
                                  //             GestureDetector(
                                  //               onTap: () async {
                                  //                 await Navigator.push(
                                  //                   context,
                                  //                   MaterialPageRoute(
                                  //                     builder: (_) =>
                                  //                         HiddenStoresScreen(
                                  //                       userId: widget.userId,
                                  //                     ),
                                  //                   ),
                                  //                 );
                                  //                 if (mounted) _loadShopData();
                                  //               },
                                  //               child: Text(
                                  //                 "Hidden (${hiddenStoreIds.length})",
                                  //                 style: GoogleFonts.poppins(
                                  //                   fontSize: 12,
                                  //                   color: wine,
                                  //                   fontWeight: FontWeight.w500,
                                  //                 ),
                                  //               ),
                                  //             ),
                                  //         ],
                                  //       ),
                                  //       const SizedBox(height: 14),
                                  //       _allStores(),
                                  //     ],
                                  //   ),
                                  //   order: 7,
                                  // ),
                                ],
                                _shopFooter(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Floating buttons ──────────────────────────────────
                  Positioned(
                    bottom: 24,
                    right: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Scroll-to-top circle — visible after scrolling 300px
                        AnimatedScale(
                          scale: _showScrollTop ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          alignment: Alignment.bottomRight,
                          child: AnimatedOpacity(
                            opacity: _showScrollTop ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 220),
                            child: GestureDetector(
                              onTap: _scrollToTop,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: wine.withOpacity(0.12),
                                      width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    color: wine,
                                    size: 22),
                              ),
                            ),
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

  Widget _exploreStoresBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _exploreHeader(),
        const SizedBox(height: 16),
        _discoverSection(),
        const SizedBox(height: 18),
        _allStores(),
      ],
    );
  }

  Widget _exploreHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: wine,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Explore Stores",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${filteredStores.length} stores matched your mood",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LOADING STATE — branded, not a raw spinner
  // ─────────────────────────────────────────────────────────────
  Widget _loadingState() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                const _ShimmerBlock(
                    width: double.infinity, height: 58, radius: 26),
                const SizedBox(height: 24),
                // Hero slider
                const _ShimmerBlock(
                    width: double.infinity, height: 172, radius: 32),
                const SizedBox(height: 24),
                // Section title
                const _ShimmerBlock(width: 160, height: 18, radius: 8),
                const SizedBox(height: 14),
                // Chip row
                const Row(children: [
                  _ShimmerBlock(width: 82, height: 42, radius: 999),
                  SizedBox(width: 10),
                  _ShimmerBlock(width: 112, height: 42, radius: 999),
                  SizedBox(width: 10),
                  _ShimmerBlock(width: 76, height: 42, radius: 999),
                  SizedBox(width: 10),
                  _ShimmerBlock(width: 96, height: 42, radius: 999),
                ]),
                const SizedBox(height: 16),
                // Store cards
                const Row(children: [
                  _ShimmerBlock(width: 148, height: 152, radius: 28),
                  SizedBox(width: 12),
                  _ShimmerBlock(width: 148, height: 152, radius: 28),
                  SizedBox(width: 12),
                  _ShimmerBlock(width: 60, height: 152, radius: 28),
                ]),
                const SizedBox(height: 28),
                const _ShimmerBlock(width: 140, height: 18, radius: 8),
                const SizedBox(height: 14),
                // Top store cards
                const Row(children: [
                  _ShimmerBlock(width: 130, height: 162, radius: 24),
                  SizedBox(width: 12),
                  _ShimmerBlock(width: 130, height: 162, radius: 24),
                  SizedBox(width: 12),
                  _ShimmerBlock(width: 70, height: 162, radius: 24),
                ]),
                const SizedBox(height: 28),
                const _ShimmerBlock(width: 150, height: 18, radius: 8),
                const SizedBox(height: 14),
                // Trending product cards
                const Row(children: [
                  _ShimmerBlock(width: 165, height: 232, radius: 28),
                  SizedBox(width: 14),
                  _ShimmerBlock(width: 165, height: 232, radius: 28),
                ]),
                const SizedBox(height: 28),
                // AI banner
                const _ShimmerBlock(
                    width: double.infinity, height: 130, radius: 28),
                const SizedBox(height: 28),
                // Product grid skeleton
                const _ShimmerBlock(width: 150, height: 18, radius: 8),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (_, __) => const _ShimmerBlock(
                      width: double.infinity,
                      height: double.infinity,
                      radius: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER — personalized, editorial, premium
  // ─────────────────────────────────────────────────────────────
  Widget _header() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? "Good morning"
        : hour < 17
            ? "Good afternoon"
            : "Good evening";
    final firstName = widget.userName.trim().isNotEmpty
        ? widget.userName.trim().split(' ').first
        : "Beautiful";
    final tagline = hour < 12
        ? "Your morning ritual awaits."
        : hour < 17
            ? "Treat your skin this afternoon."
            : "Wind down with the right routine.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [softPink, warmCream],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: wine.withOpacity(0.62),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: firstName,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: deepPlum,
                          height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: "'s  ",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: wine.withOpacity(0.6),
                          height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: "skincare",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          color: darkText.withOpacity(0.38),
                          height: 1.9,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      height: 2,
                      width: 18,
                      decoration: BoxDecoration(
                        color: dustyRose,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tagline,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: darkText.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: wine.withOpacity(0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child:
                const Icon(Icons.shopping_bag_outlined, color: wine, size: 24),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SEARCH BAR — cycling animated hint, focus-aware border
  // ─────────────────────────────────────────────────────────────
  Widget _searchBar() {
    final active = _searchFocusNode.hasFocus || searchText.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: active ? wine.withOpacity(0.22) : Colors.transparent,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? wine.withOpacity(0.13)
                : Colors.black.withOpacity(0.055),
            blurRadius: active ? 30 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(
            Icons.search_rounded,
            color: active ? wine : Colors.black38,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                TextField(
                  focusNode: _searchFocusNode,
                  onChanged: _search,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: darkText,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  cursorColor: wine,
                  cursorWidth: 1.5,
                ),
                // Animated hint — only visible when field is empty and unfocused
                if (searchText.isEmpty && !_searchFocusNode.hasFocus)
                  IgnorePointer(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOut)),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _searchHints[_hintIndex],
                        key: ValueKey(_hintIndex),
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: Colors.black38,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (searchText.isNotEmpty)
            GestureDetector(
              onTap: () {
                _search("");
                _searchFocusNode.unfocus();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: wine.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: wine),
              ),
            )
          else
            const SizedBox(width: 18),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // NEED STORES — editorial card with logo band + pill CTA
  // ─────────────────────────────────────────────────────────────
  // Widget _needStores() {
  //   if (needStores.isEmpty) {
  //     return _emptyText("No stores match this filter");
  //   }

  //   return SizedBox(
  //     height: 165,
  //     child: ListView.separated(
  //       scrollDirection: Axis.horizontal,
  //       itemCount: needStores.length,
  //       separatorBuilder: (_, __) => const SizedBox(width: 12),
  //       itemBuilder: (context, index) {
  //         final store = needStores[index];
  //         final name = store["storeName"] ?? "Store";
  //         final logoUrl = store["logoUrl"] ?? "";
  //         final city = store["city"] ?? "";
  //         final rating = store["rating"] ?? 0;

  //         return _PressableCard(
  //           onTap: () => _openStore(store),
  //           child: Container(
  //             width: 148,
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(28),
  //               border: Border.all(color: wine.withOpacity(0.06)),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: dustyRose.withOpacity(0.18),
  //                   blurRadius: 20,
  //                   offset: const Offset(0, 8),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 // Logo band — softPink tinted area
  //                 Container(
  //                   height: 68,
  //                   decoration: BoxDecoration(
  //                     color: softPink.withOpacity(0.45),
  //                     borderRadius:
  //                         const BorderRadius.vertical(top: Radius.circular(28)),
  //                   ),
  //                   child: Center(
  //                     child: Container(
  //                       height: 50,
  //                       width: 50,
  //                       padding: const EdgeInsets.all(3),
  //                       decoration: BoxDecoration(
  //                         shape: BoxShape.circle,
  //                         gradient: LinearGradient(
  //                           colors: [
  //                             wine.withOpacity(0.8),
  //                             const Color(0xFF8E4B5D),
  //                           ],
  //                         ),
  //                         boxShadow: [
  //                           BoxShadow(
  //                             color: wine.withOpacity(0.18),
  //                             blurRadius: 12,
  //                             offset: const Offset(0, 4),
  //                           ),
  //                         ],
  //                       ),
  //                       child: Container(
  //                         decoration: const BoxDecoration(
  //                           color: Colors.white,
  //                           shape: BoxShape.circle,
  //                         ),
  //                         child: ClipOval(child: _logo(logoUrl, name, 44)),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 // Info section
  //                 Padding(
  //                   padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         name,
  //                         maxLines: 1,
  //                         overflow: TextOverflow.ellipsis,
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 12.5,
  //                           fontWeight: FontWeight.w500,
  //                           color: darkText,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 2),
  //                       Row(
  //                         children: [
  //                           Icon(Icons.location_on_rounded,
  //                               size: 11, color: wine.withOpacity(0.45)),
  //                           const SizedBox(width: 2),
  //                           Expanded(
  //                             child: Text(
  //                               city,
  //                               maxLines: 1,
  //                               overflow: TextOverflow.ellipsis,
  //                               style: GoogleFonts.poppins(
  //                                   fontSize: 10, color: Colors.black38),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 8),
  //                       Row(
  //                         children: [
  //                           // Rating badge
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                                 horizontal: 6, vertical: 3),
  //                             decoration: BoxDecoration(
  //                               color: const Color(0xFFFFB800).withOpacity(0.1),
  //                               borderRadius: BorderRadius.circular(999),
  //                             ),
  //                             child: Row(
  //                               mainAxisSize: MainAxisSize.min,
  //                               children: [
  //                                 const Icon(Icons.star_rounded,
  //                                     size: 11, color: Color(0xFFFFB800)),
  //                                 const SizedBox(width: 2),
  //                                 Text(
  //                                   (double.tryParse(rating.toString()) ?? 0)
  //                                       .toStringAsFixed(1),
  //                                   style: GoogleFonts.poppins(
  //                                     fontSize: 9.5,
  //                                     fontWeight: FontWeight.w500,
  //                                     color: darkText,
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                           const Spacer(),
  //                           // Pill CTA
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                                 horizontal: 9, vertical: 4),
  //                             decoration: BoxDecoration(
  //                               color: wine.withOpacity(0.08),
  //                               borderRadius: BorderRadius.circular(999),
  //                             ),
  //                             child: Row(
  //                               mainAxisSize: MainAxisSize.min,
  //                               children: [
  //                                 Text(
  //                                   "Visit",
  //                                   style: GoogleFonts.poppins(
  //                                     fontSize: 10,
  //                                     fontWeight: FontWeight.w500,
  //                                     color: wine,
  //                                   ),
  //                                 ),
  //                                 const SizedBox(width: 3),
  //                                 const Icon(Icons.arrow_forward_rounded,
  //                                     size: 11, color: wine),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  // ─────────────────────────────────────────────────────────────
  // DISCOVER CHIPS — filled gradient when selected, white at rest
  // ─────────────────────────────────────────────────────────────
  Widget _discoverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Store Filters",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
            const Spacer(),
            if (selectedDiscoverIndex != -1)
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDiscoverIndex = -1;
                    filteredStores = stores
                        .where(
                            (s) => !hiddenStoreIds.contains(_getId(s["_id"])))
                        .toList();
                    needStores = filteredStores;
                    filteredProducts = storeProducts;
                  });
                },
                child: Text(
                  "Clear",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: wine,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: discoverItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final item = discoverItems[index];
              final selected = selectedDiscoverIndex == index;

              return GestureDetector(
                onTap: () => _applyDiscoverFilter(item, index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: selected ? wine : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? wine : wine.withOpacity(0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: selected
                            ? wine.withOpacity(0.22)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: selected ? 18 : 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item["title"],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HERO SLIDER — premium campaign carousel
  // ─────────────────────────────────────────────────────────────
  Widget _heroSlider() {
    if (ads.isEmpty) return _heroEditorialPlaceholder();
    return Container(
      color: warmCream,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _sliderController,
              itemCount: ads.length,
              onPageChanged: (i) => setState(() => currentSlide = i),
              itemBuilder: (_, index) {
                final ad = ads[index];
                final store = ad["storeId"];
                final storeName =
                    store is Map ? (store["storeName"] ?? "") : "";
                return _HeroAdCard(
                  title: ad["title"] ?? "Special Offer",
                  subtitle: ad["subtitle"] ?? "",
                  imageUrl: ad["imageUrl"] ?? "",
                  buttonText: ad["buttonText"] ?? "Shop Now",
                  storeName: storeName,
                  index: index,
                  total: ads.length,
                  isActive: currentSlide == index,
                  onTap: () {
                    if (store is Map) _openStore(store);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _premiumDots(),
        ],
      ),
    );
  }

  Widget _heroEditorialPlaceholder() {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A0A10),
            deepPlum,
            wine,
            Color(0xFF8B3A52),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.28, 0.68, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: wine.withOpacity(0.40),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Large ambient glow top-right
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      gold.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom-left ambient glow
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Decorative diagonal line 1
            Positioned(
              right: 52,
              top: 18,
              child: Transform.rotate(
                angle: -0.45,
                child: Container(
                  width: 1,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        gold.withOpacity(0.28),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            // Decorative diagonal line 2
            Positioned(
              right: 68,
              top: 26,
              child: Transform.rotate(
                angle: -0.45,
                child: Container(
                  width: 1,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        gold.withOpacity(0.14),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            // Bottom gradient vignette
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 110,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gold glassmorphic label
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: gold.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: gold.withOpacity(0.32),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          "SKINOVA PICKS",
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                            color: gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Gold accent micro-label
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gold.withOpacity(0.30),
                              gold.withOpacity(0.80),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        "CURATED FOR YOU",
                        style: GoogleFonts.poppins(
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.8,
                          color: gold.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Curated Store\nOffers",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Approved seller campaigns will appear here",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.62),
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

  Widget _premiumDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(ads.length, (index) {
        final isActive = currentSlide == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          height: isActive ? 7 : 6,
          width: isActive ? 28 : 6,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [wine, Color(0xFF8E4B5D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isActive ? null : dustyRose.withOpacity(0.45),
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: wine.withOpacity(0.52),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECTION TITLE — accent bar + editorial typography
  // ─────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title, String subtitle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: darkText,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TOP STORES — ranked badges, Playfair Display for top 3
  // ─────────────────────────────────────────────────────────────
  Widget _topStores() {
    if (topStores.isEmpty) return _emptyText("No stores found");

    return SizedBox(
      height: 162,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: topStores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final store = topStores[index];
          final name = store["storeName"] ?? "Store";
          final logoUrl = store["logoUrl"] ?? "";
          final rating = store["rating"] ?? 0;

          // Ring dims for lower-ranked stores
          final ringColors = index < 3
              ? [wine, const Color(0xFF8E4B5D)]
              : [
                  wine.withOpacity(0.45),
                  const Color(0xFF8E4B5D).withOpacity(0.45)
                ];

          // Badge config per rank
          final badgeColor = index == 0
              ? const Color(0xFFFFD36A)
              : index == 1
                  ? const Color(0xFFBFC0C6)
                  : dustyRose;

          return GestureDetector(
            onTap: () => _openStore(store),
            child: SizedBox(
              width: 95,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 84,
                        width: 84,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: ringColors),
                          boxShadow: [
                            BoxShadow(
                              color: wine.withOpacity(index < 3 ? 0.18 : 0.07),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: ClipOval(child: _logo(logoUrl, name, 74)),
                        ),
                      ),
                      // Rank badge for top 3
                      if (index < 3)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: index == 0
                                ? const Icon(Icons.workspace_premium_rounded,
                                    size: 13, color: Colors.white)
                                : Center(
                                    child: Text(
                                      "${index + 1}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  // Playfair Display italic for top 3 names
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: index < 3
                        ? GoogleFonts.playfairDisplay(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            color: darkText,
                          )
                        : GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: darkText.withOpacity(0.7),
                          ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded,
                          color: index < 3
                              ? const Color(0xFFFFB800)
                              : Colors.black26,
                          size: 13),
                      const SizedBox(width: 3),
                      Text(
                        (double.tryParse(rating.toString()) ?? 0)
                            .toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black45),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TRENDING PRODUCTS — correct hierarchy, price, smart rating
  // ─────────────────────────────────────────────────────────────
  Widget _trendingProducts() {
    if (trendingProducts.isEmpty) return _emptyText("No products found");

    return SizedBox(
      height: 232,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: trendingProducts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = trendingProducts[index];
          final product = item["productId"] ?? {};
          final productId = (product["_id"] ?? item["_id"] ?? "").toString();
          final productName = product["name"] ?? "Product";
          final brand = product["brand"] ?? "";
          final imageUrl = product["imageUrl"] ?? "";
          final price = (item["price"] ?? 0).toDouble();
          final currency = item["currency"] ?? "ILS";
          final reviewCount = (item["reviewPostsCount"] ?? 0) as int;
          final reviewRating = (item["reviewPostsRating"] ?? 0.0).toDouble();
          final hasReviews = reviewCount > 0;
          final liked = _likedProducts.contains(productId);
          final priceDisplay = price > 0
              ? (currency == "ILS"
                  ? "₪${price.toStringAsFixed(0)}"
                  : "$currency ${price.toStringAsFixed(0)}")
              : null;

          return _PressableCard(
            onTap: () => _showProductSheet(item),
            child: Container(
              width: 165,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: dustyRose.withOpacity(0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with rank badge overlay
                  Stack(
                    children: [
                      Container(
                        height: 106,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: imageUrl.toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.spa_outlined,
                                      color: wine,
                                      size: 32),
                                ),
                              )
                            : const Icon(Icons.spa_outlined,
                                color: wine, size: 32),
                      ),
                      // Heart / wishlist button — top-left

                      // Flame badge for top 3
                      if (index < 3)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: index == 0 ? wine : wine.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("🔥", style: TextStyle(fontSize: 9)),
                                const SizedBox(width: 3),
                                Text(
                                  "#${index + 1}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Brand — primary identity signal
                  if (brand.isNotEmpty)
                    Text(
                      brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: wine.withOpacity(0.75),
                        letterSpacing: 0.8,
                      ),
                    ),
                  const SizedBox(height: 2),
                  // Product name — what matters most
                  Text(
                    productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: darkText,
                      height: 1.25,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price or blank
                      // if (priceDisplay != null)
                      //   Text(
                      //     priceDisplay,
                      //     style: GoogleFonts.poppins(
                      //       fontSize: 13,
                      //       fontWeight: FontWeight.w500,
                      //       color: wine,
                      //     ),
                      //   ),
                      const Spacer(),
                      // Smart rating: real stars OR "New" badge
                      if (hasReviews)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 13),
                              const SizedBox(width: 2),
                              Text(
                                reviewRating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                    fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: dustyRose.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "New",
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: wine,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // AI BANNER — immersive, Playfair Display, decorative circles
  // ─────────────────────────────────────────────────────────────
  Widget _aiBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShopAiChatPage(
            userId: widget.userId,
            userName: widget.userName,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [wine, deepPlum],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: wine.withOpacity(0.32),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              // Decorative ambient circles
              Positioned(
                right: -28,
                top: -28,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.055),
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: -22,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.035),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon row

                    const SizedBox(height: 16),
                    // Two-tone editorial heading
                    Text(
                      "Your personal",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      "Skin Advisor",
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        height: 1.0,
                      ),
                    ),

                    const SizedBox(height: 20),
                    // CTA pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.14),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Need Help?",
                            style: GoogleFonts.poppins(
                              color: wine,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              color: wine, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS — per-store product data for peek previews
  // ─────────────────────────────────────────────────────────────
  List<String> _storeProductImages(String storeId) {
    final urls = <String>[];
    for (final sp in storeProducts) {
      final s = sp["storeId"];
      final id = s is Map ? s["_id"]?.toString() : s?.toString();
      if (id != storeId) continue;
      final url = (sp["productId"]?["imageUrl"] ?? "").toString();
      if (url.isNotEmpty) urls.add(url);
      if (urls.length >= 3) break;
    }
    return urls;
  }

  int _storeProductCount(String storeId) {
    int n = 0;
    for (final sp in storeProducts) {
      final s = sp["storeId"];
      final id = s is Map ? s["_id"]?.toString() : s?.toString();
      if (id == storeId) n++;
    }
    return n;
  }

  Widget _productPeek(List<String> images, int total) {
    if (images.isEmpty) return const SizedBox.shrink();
    const double sz = 24;
    const double gap = 16;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: sz,
          width: images.length * gap + (sz - gap),
          child: Stack(
            children: List.generate(
              images.length,
              (i) => Positioned(
                left: i * gap,
                child: Container(
                  height: sz,
                  width: sz,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: softPink,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.spa_outlined,
                        size: 11,
                        color: wine.withOpacity(0.45),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (total > 3) ...[
          const SizedBox(width: 5),
          Text(
            "+${total - 3}",
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: wine.withOpacity(0.55),
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  // FOLLOWING STORES
  // ─────────────────────────────────────────────────────────────
  // Widget _followingStoresSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       _sectionTitle("Following", "${followedStores.length} stores"),
  //       const SizedBox(height: 14),
  //       followedStores.isEmpty
  //           ? _followingEmptyState()
  //           : SizedBox(
  //               height: 148,
  //               child: ListView.separated(
  //                 scrollDirection: Axis.horizontal,
  //                 padding: const EdgeInsets.symmetric(horizontal: 2),
  //                 itemCount: followedStores.length,
  //                 separatorBuilder: (_, __) => const SizedBox(width: 12),
  //                 itemBuilder: (_, i) => _followingStoreCard(followedStores[i]),
  //               ),
  //             ),
  //     ],
  //   );
  // }
  Widget _followingStoresSection() {
    if (followedStores.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: wine.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: dustyRose.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: softPink.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.storefront_rounded, color: wine, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Follow stores to see them here",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: darkText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          "Following Stores",
          "${followedStores.length} stores you follow",
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: followedStores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = followedStores[index];
              final name = store["storeName"] ?? "Store";
              final logoUrl = store["logoUrl"] ?? "";
              final city = store["city"] ?? "";
              final rating = store["rating"] ?? 0;

              return GestureDetector(
                onTap: () => _openStore(store),
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: wine.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: dustyRose.withOpacity(0.14),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: softPink.withOpacity(0.65),
                        ),
                        child: ClipOval(
                          child: _logo(logoUrl, name, 48),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFB800),
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  (double.tryParse(rating.toString()) ?? 0)
                                      .toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: darkText,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "Visit",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: wine,
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
            },
          ),
        ),
      ],
    );
  }

  Widget _followingStoreCard(dynamic store) {
    final name = (store["storeName"] ?? "Store").toString();
    final logoUrl = (store["logoUrl"] ?? "").toString();
    final city = (store["city"] ?? "").toString();
    final followersCount = (store["followersCount"] as num?)?.toInt() ?? 0;
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "S";

    return GestureDetector(
      onTap: () => _openStore(store),
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: wine.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: wine.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: wine.withOpacity(0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: logoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(letter,
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: wine)),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(letter,
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: wine))),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: darkText),
            ),
            if (city.isNotEmpty)
              Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: const Color(0xFF999999)),
              ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.people_outline_rounded,
                    size: 11, color: Color(0xFFAAAAAA)),
                const SizedBox(width: 3),
                Text(
                  _formatCount(followersCount),
                  style: GoogleFonts.poppins(
                      fontSize: 10.5, color: const Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _followingEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: wine.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: wine.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.store_outlined, color: wine, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Follow stores you love",
                  style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: darkText),
                ),
                const SizedBox(height: 3),
                Text(
                  "They'll appear here and their products will show first.",
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF999999),
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}k";
    return "$n";
  }

  // ALL STORES — hero first card + 2-col grid with product peeks
  // ─────────────────────────────────────────────────────────────
  Widget _allStores() {
    if (filteredStores.isEmpty) return _emptyText("No stores found");

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredStores.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final store = filteredStores[index];
        final name = store["storeName"] ?? "Store";
        final logoUrl = store["logoUrl"] ?? "";
        final city = store["city"] ?? "";
        final rating = (double.tryParse((store["rating"] ?? 0).toString()) ?? 0)
            .toStringAsFixed(1);
        final followers = store["followersCount"] ?? 0;

        return GestureDetector(
          onTap: () => _openStore(store),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: wine.withOpacity(0.07)),
              boxShadow: [
                BoxShadow(
                  color: dustyRose.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: softPink,
                  ),
                  child: ClipOval(
                    child: _logo(logoUrl, name, 58),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: wine.withOpacity(0.45)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _miniStoreBadge(Icons.star_rounded, rating),
                          const SizedBox(width: 7),
                          _miniStoreBadge(Icons.favorite_rounded, "$followers"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: wine.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: wine,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniStoreBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: softPink.withOpacity(0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: wine),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: wine,
            ),
          ),
        ],
      ),
    );
  }

  Widget _allStoreHeroCard(dynamic store) {
    final name = store["storeName"] ?? "Store";
    final logoUrl = store["logoUrl"] ?? "";
    final city = store["city"] ?? "";
    final rating = store["rating"] ?? 0;
    final storeId = store["_id"]?.toString() ?? "";
    final isVerified = store["isVerified"] == true;
    final verificationLevel =
        store["verificationLevel"]?.toString() ?? "standard";
    final images = _storeProductImages(storeId);
    final total = _storeProductCount(storeId);

    return _PressableCard(
      onTap: () => _openStore(store),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isVerified
              ? LinearGradient(
                  colors: [
                    const Color(0xFFE8F0FE).withOpacity(0.7),
                    warmCream,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [softPink.withOpacity(0.55), warmCream],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isVerified
                ? const Color(0xFF1565C0).withOpacity(0.15)
                : wine.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: isVerified
                  ? const Color(0xFF1565C0).withOpacity(0.10)
                  : dustyRose.withOpacity(0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 76,
                  width: 76,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isVerified
                        ? const LinearGradient(colors: [
                            Color(0xFF1565C0),
                            Color(0xFF1E88E5),
                          ])
                        : const LinearGradient(
                            colors: [wine, Color(0xFF8E4B5D)]),
                    boxShadow: [
                      BoxShadow(
                        color: isVerified
                            ? const Color(0xFF1565C0).withOpacity(0.25)
                            : wine.withOpacity(0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(child: _logo(logoUrl, name, 68)),
                  ),
                ),
                if (isVerified)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      height: 22,
                      width: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1565C0).withOpacity(0.40),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.verified_rounded,
                          size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1565C0).withOpacity(0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 4),
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
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: wine.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_outlined,
                              size: 11, color: wine.withOpacity(0.8)),
                          const SizedBox(width: 4),
                          Text(
                            "New Store",
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: wine,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 7),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: deepPlum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 12, color: wine.withOpacity(0.45)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.black45),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB800), size: 14),
                      const SizedBox(width: 3),
                      Text(
                        (double.tryParse(rating.toString()) ?? 0)
                            .toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _productPeek(images, total),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: wine,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Explore",
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 13, color: Colors.white),
                          ],
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

  Widget _allStoreGridCard(dynamic store) {
    final name = store["storeName"] ?? "Store";
    final logoUrl = store["logoUrl"] ?? "";
    final city = store["city"] ?? "";
    final rating = store["rating"] ?? 0;
    final storeId = store["_id"]?.toString() ?? "";
    final images = _storeProductImages(storeId);
    final total = _storeProductCount(storeId);

    return _PressableCard(
      onTap: () => _openStore(store),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: dustyRose.withOpacity(0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _logo(logoUrl, name, 64),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: darkText,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded,
                    size: 11, color: wine.withOpacity(0.45)),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.black38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFB800), size: 12),
                const SizedBox(width: 2),
                Text(
                  (double.tryParse(rating.toString()) ?? 0).toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (images.isNotEmpty) ...[
              _productPeek(images, total),
              const SizedBox(height: 7),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: wine.withOpacity(0.07),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "View Store",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: wine,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SHOP FOOTER — brand closing moment
  // ─────────────────────────────────────────────────────────────
  Widget _shopFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 1,
                width: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, wine.withOpacity(0.2)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.spa_outlined,
                    color: wine.withOpacity(0.32), size: 16),
              ),
              Container(
                height: 1,
                width: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [wine.withOpacity(0.2), Colors.transparent],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Skinova",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: wine.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Built for every skin story.",
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EMPTY STATE — illustrated, not plain text
  // ─────────────────────────────────────────────────────────────
  Widget _emptyText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: wine.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: softPink.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded,
                color: wine.withOpacity(0.5), size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRESSABLE CARD — scale-down micro-interaction on press
// ─────────────────────────────────────────────────────────────────────────────
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableCard({required this.child, required this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _HeroAdCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String buttonText;
  final String storeName;
  final int index;
  final int total;
  final bool isActive;
  final VoidCallback onTap;

  const _HeroAdCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.buttonText,
    required this.storeName,
    required this.index,
    required this.total,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isActive ? 1.0 : 0.97,
        duration: const Duration(milliseconds: 250),
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.white,
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(color: const Color(0xFF0F4A3B)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.58),
                        Colors.black.withOpacity(0.25),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isNotEmpty
                            ? title
                            : 'Fresh Deals,\nFresh Skincare!',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          height: 1.18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle.isNotEmpty
                            ? subtitle
                            : 'Up to 50% off on your favorite essentials.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.78),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          buttonText.isNotEmpty
                              ? buttonText.toUpperCase()
                              : 'GRAB THE DEALS',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER BLOCK — animated skeleton placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _ShimmerBlock extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBlock({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
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
    _anim = Tween<double>(begin: 0.22, end: 0.60).animate(
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
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE8AABA).withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
