import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../product_model.dart';
import '../api_service.dart';
import '../review_model.dart';
import 'post_page.dart';
import 'buy_product_from_store_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;
  final String userId;
  final String userName;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.userId,
    required this.userName,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  // ── Product state ─────────────────────────────────────────────────────────
  late ProductModel currentProduct;
  late List<ReviewModel> displayedReviews;
  late double displayedRating;
  bool isFavorite = false;
  bool isFavoriteLoading = false;
  bool favoriteChanged = false;
  bool isSavedToCollection = false;

  // ── Async data ────────────────────────────────────────────────────────────
  List<GroupPostModel> productReviewPosts = [];
  bool reviewPostsLoading = true;
  List<ProductModel> sameBrandProducts = [];
  bool sameBrandLoading = true;
  List<dynamic> productStores = [];
  bool storesLoading = true;
  Map<String, dynamic> _analytics = {};
  bool _analyticsLoading = true;
  List<Map<String, dynamic>> userCollections = [];
  String? selectedCollectionId;
  List<dynamic> recentlyUsedUsers = [];
  bool recentlyUsedUsersLoading = true;
  // ── AI Suitability ────────────────────────────────────────────────────────
  Map<String, dynamic>? _suitabilityResult;
  bool _suitabilityLoading = false;
  String? _suitabilityError;
  // ── Tab controller ────────────────────────────────────────────────────────
  late TabController _tabController;

  // ── Rating distribution ───────────────────────────────────────────────────
  Map<int, int> get _ratingDistribution {
    final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in displayedReviews) {
      final k = r.rating.round().clamp(1, 5);
      dist[k] = (dist[k] ?? 0) + 1;
    }
    return dist;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    currentProduct = widget.product;
    displayedReviews = List.from(widget.product.reviews);
    displayedRating = widget.product.rating;
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    loadFavoriteState();
    loadSavedState();
    _loadLatestProduct();
    _loadProductReviewPosts();
    _loadSameBrandProducts();
    _loadProductStores();
    _fetchAnalytics();
    _loadRecentlyUsedUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentlyUsedUsers() async {
    try {
      final users = await ApiService.fetchRecentlyUsedUsers(widget.product.id);

      if (!mounted) return;

      setState(() {
        recentlyUsedUsers = users;
        recentlyUsedUsersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        recentlyUsedUsersLoading = false;
      });

      debugPrint("Load recently used users error: $e");
    }
  }

  // ── Data loading ──────────────────────────────────────────────────────────
  Future<void> _loadLatestProduct() async {
    try {
      final p = await ApiService.fetchProductById(widget.product.id);
      if (!mounted) return;
      setState(() {
        currentProduct = p;
        displayedReviews = List.from(p.reviews);
        displayedRating = p.rating;
      });
    } catch (_) {}
  }

  Future<void> _fetchAnalytics() async {
    try {
      final data = await ApiService.fetchProductAnalytics(widget.product.id);
      if (!mounted) return;
      setState(() {
        _analytics = data;
        _analyticsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _analyticsLoading = false);
    }
  }

  Future<void> _loadProductReviewPosts() async {
    try {
      final posts =
          await ApiService.fetchReviewPostsByProduct(widget.product.id);
      if (!mounted) return;
      setState(() {
        productReviewPosts = posts;
        reviewPostsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => reviewPostsLoading = false);
    }
  }

  Future<void> _loadSameBrandProducts() async {
    try {
      final products =
          await ApiService.fetchProductsByBrand(widget.product.brand);
      if (!mounted) return;
      setState(() {
        sameBrandProducts =
            products.where((p) => p.id != widget.product.id).toList();
        sameBrandLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => sameBrandLoading = false);
    }
  }

  Future<void> _loadProductStores() async {
    try {
      final stores = await ApiService.fetchStoresForProduct(widget.product.id);
      if (!mounted) return;
      final sorted = [...stores]..sort((a, b) {
          final pa = (a['price'] ?? 0) as num;
          final pb = (b['price'] ?? 0) as num;
          return pa.compareTo(pb);
        });
      setState(() {
        productStores = sorted;
        storesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => storesLoading = false);
    }
  }

  Future<void> loadFavoriteState() async {
    try {
      final favorites = await ApiService.fetchFavorites(widget.userId);
      if (!mounted) return;
      setState(
          () => isFavorite = favorites.any((e) => e.id == widget.product.id));
    } catch (_) {}
  }

  Future<void> loadSavedState() async {
    try {
      final saved = await ApiService.isProductInAnyCollection(
          userId: widget.userId, imageUrl: widget.product.imageUrl);
      if (!mounted) return;
      setState(() => isSavedToCollection = saved);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (isFavoriteLoading) return;
    setState(() {
      isFavoriteLoading = true;
      favoriteChanged = true;
    });
    try {
      final result = await ApiService.toggleFavorite(
          userId: widget.userId, productId: widget.product.id);
      if (!mounted) return;
      if (result["statusCode"] == 200) {
        setState(() => isFavorite = result["data"]["isFavorite"] == true);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => isFavoriteLoading = false);
  }

  // ── Collection sheet ──────────────────────────────────────────────────────
  Future<void> _openAddToCollectionSheet() async {
    try {
      final result = await ApiService.getUserProfile(userId: widget.userId);
      final data = result["data"];
      final List collections = data["collections"] ?? [];
      final favProducts = await ApiService.fetchFavorites(widget.userId);

      setState(() {
        userCollections = [
          {
            "id": "favorites",
            "title": "Favorites",
            "images": favProducts
                .map((p) => p.imageUrl)
                .where((img) => img.isNotEmpty)
                .toList(),
            "isSpecial": true,
          },
          ...collections
              .map((e) => {
                    "id": e["_id"],
                    "title": e["title"],
                    "images": List<String>.from(e["images"] ?? []),
                    "isSpecial": false,
                  })
              .toList(),
        ];
      });

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _collectionSheet(),
      );
    } catch (e) {
      debugPrint("Load collections error: $e");
    }
  }

  Widget _collectionSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: line, borderRadius: BorderRadius.circular(100)),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded,
                        size: 28, color: Colors.grey.shade400),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Save to collection',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: darkText)),
                    ),
                  ),
                  const SizedBox(width: 28),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showNewCollectionSheet();
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                      color: whiteSmoke,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: line)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: wine),
                      const SizedBox(width: 8),
                      Text('Create new collection',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: wine)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: userCollections.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final col = userCollections[index];
                    final title = col["title"] ?? "Collection";
                    final images = List<String>.from(col["images"] ?? []);
                    final isSelected =
                        selectedCollectionId == col["id"]?.toString();
                    final isSpecial = col["isSpecial"] == true;
                    final colId = col["id"]?.toString() ?? "";

                    return GestureDetector(
                      onTap: () async {
                        if (colId.isEmpty) return;

                        if (isSpecial && colId == "favorites") {
                          Navigator.pop(context);
                          await _toggleFavorite();
                          if (!mounted) return;
                          _showProductAddedMessage(isFavorite
                              ? 'Added to Favorites'
                              : 'Removed from Favorites');
                          return;
                        }

                        setSheetState(() => selectedCollectionId = colId);
                        final ok = await ApiService.addProductToCollection(
                            collectionId: colId,
                            imageUrl: widget.product.imageUrl);
                        if (!mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                          setState(() => isSavedToCollection = true);
                          Future.delayed(const Duration(milliseconds: 250), () {
                            if (!mounted) return;
                            _showProductAddedMessage('Saved to $title');
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to add product')));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? wine : whiteSmoke,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isSelected ? wine : line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                              child: Text(title,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isSelected ? Colors.white : darkText),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(height: 8),
                            Expanded(child: _collectionPreview(images)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _collectionPreview(List<String> images) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: const Color(0xFFEFEDEB),
          borderRadius: BorderRadius.circular(14)),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 6, mainAxisSpacing: 6),
        itemBuilder: (_, i) {
          if (i < images.length && images[i].isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(images[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _emptyBottleIcon()),
            );
          }
          return Container(
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10)),
            child: _emptyBottleIcon(),
          );
        },
      ),
    );
  }

  Widget _emptyBottleIcon() => Icon(Icons.local_pharmacy_outlined,
      size: 22, color: Colors.grey.shade400);

  void _showNewCollectionSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: line, borderRadius: BorderRadius.circular(100))),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child:
                        const Icon(Icons.close, color: Colors.grey, size: 26)),
                Expanded(
                  child: Center(
                    child: Text('New collection',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: darkText)),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final name = ctrl.text.trim();
                    if (name.isEmpty) return;
                    final ok = await ApiService.addCollection(
                        userId: widget.userId,
                        title: name,
                        images: widget.product.imageUrl.isNotEmpty
                            ? [widget.product.imageUrl]
                            : []);
                    if (!mounted) return;
                    if (ok != null) {
                      setState(() => isSavedToCollection = true);
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (!mounted) return;
                        _showProductAddedMessage('Saved to $name');
                      });
                    }
                  },
                  child: const Icon(Icons.check, color: Colors.grey, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.poppins(fontSize: 15, color: darkText),
              decoration: InputDecoration(
                hintText: 'Name your new collection…',
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                filled: true,
                fillColor: whiteSmoke,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: wine)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductAddedMessage([String text = 'Product saved!']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF4CAF50), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: darkText)),
              ),
              GestureDetector(
                onTap: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                child: const Icon(Icons.close_rounded,
                    size: 20, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stores bottom sheet ───────────────────────────────────────────────────
  void _showStoresBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Where to buy',
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: darkText)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: whiteSmoke, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Prices shown are from sellers on Skinova',
                style: GoogleFonts.poppins(fontSize: 11.5, color: grey)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: productStores.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = productStores[index];
                  final store = item["storeId"] ?? {};
                  final storeName = store["storeName"]?.toString() ?? "Store";
                  final logoUrl = store["logoUrl"]?.toString() ?? "";
                  final city = store["city"]?.toString() ?? "";
                  final storeRating = (store["rating"] ?? 0.0) as num;
                  final price = (item["price"] ?? 0) as num;
                  final currency = item["currency"]?.toString() ?? "ILS";
                  final stockCount = (item["stockCount"] ?? 0) as int;
                  final isAvailable =
                      item["isAvailable"] != false && stockCount > 0;
                  final isBestPrice = index == 0;
                  final firstLetter =
                      storeName.isNotEmpty ? storeName[0].toUpperCase() : "S";

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BuyProductFromStoreScreen(
                              product: widget.product,
                              storeProduct: Map<String, dynamic>.from(item),
                              userId: widget.userId,
                              userName: widget.userName,
                            ),
                          ));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: isBestPrice ? wine.withOpacity(0.3) : line),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(
                        children: [
                          // Logo
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                                color: whiteSmoke, shape: BoxShape.circle),
                            child: ClipOval(
                              child: logoUrl.isNotEmpty
                                  ? Image.network(logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                          child: Text(firstLetter,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: wine))))
                                  : Center(
                                      child: Text(firstLetter,
                                          style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: wine))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Store info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(storeName,
                                          style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: darkText),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    if (isBestPrice)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFFFF3E0),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: Text('Best price',
                                            style: GoogleFonts.poppins(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    const Color(0xFFE65100))),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    if (city.isNotEmpty) ...[
                                      Icon(Icons.location_on_outlined,
                                          size: 12, color: grey),
                                      const SizedBox(width: 2),
                                      Text(city,
                                          style: GoogleFonts.poppins(
                                              fontSize: 11, color: grey)),
                                      const SizedBox(width: 8),
                                    ],
                                    if (storeRating > 0) ...[
                                      const Icon(Icons.star_rounded,
                                          size: 12, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(storeRating.toStringAsFixed(1),
                                          style: GoogleFonts.poppins(
                                              fontSize: 11, color: grey)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: !isAvailable
                                        ? const Color(0xFFF8ECEC)
                                        : stockCount <= 5
                                            ? const Color(0xFFFFF3E0)
                                            : const Color(0xFFEFF7EF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    !isAvailable
                                        ? 'Out of Stock'
                                        : stockCount <= 5
                                            ? 'Limited Stock'
                                            : 'Available',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: !isAvailable
                                          ? const Color(0xFFC62828)
                                          : stockCount <= 5
                                              ? const Color(0xFFE65100)
                                              : const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Price + buy
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$price $currency',
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: wine)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: wine,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Buy',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ),
                            ],
                          ),
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

  // ── Review sheet ──────────────────────────────────────────────────────────
  Future<void> _openReviewSheet() async {
    int step = 1;
    int stars = 0;
    final reviewCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) => Container(
          margin: const EdgeInsets.only(top: 24),
          padding: EdgeInsets.fromLTRB(
              22, 22, 22, 22 + MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        size: 28, color: Colors.black38),
                  ),
                ),
                const SizedBox(height: 4),
                if (step == 1) ...[
                  Text('How was the product?',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: darkText)),
                  const SizedBox(height: 4),
                  Text('Share your experience with the community.',
                      style: GoogleFonts.poppins(fontSize: 13, color: grey)),
                  const SizedBox(height: 24),
                  Row(
                    children: List.generate(
                        5,
                        (i) => GestureDetector(
                              onTap: () => setModal(() => stars = i + 1),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                    i < stars
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    size: 42,
                                    color: i < stars
                                        ? wine
                                        : Colors.grey.shade300),
                              ),
                            )),
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  Text('Tell others about the product',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: darkText)),
                  const SizedBox(height: 4),
                  Text('Share helpful details with the community.',
                      style: GoogleFonts.poppins(fontSize: 13, color: grey)),
                  const SizedBox(height: 18),
                  TextField(
                    controller: reviewCtrl,
                    maxLines: 6,
                    onChanged: (_) => setModal(() {}),
                    style: GoogleFonts.poppins(fontSize: 14, color: darkText),
                    decoration: InputDecoration(
                      hintText:
                          'Write what you liked, how you used it, and tips.',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.black38, height: 1.7),
                      filled: true,
                      fillColor: whiteSmoke,
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: wine)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: step == 1 ? 0.5 : 1.0,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(wine),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (step == 2)
                      TextButton(
                        onPressed: () => setModal(() => step = 1),
                        child: Text('Back',
                            style: GoogleFonts.poppins(
                                color: darkText, fontWeight: FontWeight.w500)),
                      ),
                    const Spacer(),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: step == 1
                            ? stars == 0
                                ? null
                                : () => setModal(() => step = 2)
                            : reviewCtrl.text.trim().isEmpty
                                ? null
                                : () async {
                                    try {
                                      final result = await ApiService.addReview(
                                        productId: widget.product.id,
                                        userId: widget.userId,
                                        userName: widget.userName,
                                        rating: stars.toDouble(),
                                        title: "",
                                        comment: reviewCtrl.text.trim(),
                                        repurchase: null,
                                        improvedSkin: null,
                                        wasGift: null,
                                        adverseReaction: null,
                                        texture: "",
                                        usageWeeks: "",
                                      );
                                      if (!mounted) return;
                                      if (result["statusCode"] == 201) {
                                        await _loadLatestProduct();
                                        await _fetchAnalytics();
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content:
                                                    Text('Review submitted!')));
                                      }
                                    } catch (_) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Something went wrong')));
                                    }
                                  },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: wine,
                          disabledBackgroundColor: Colors.grey.shade200,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(step == 1 ? 'Next' : 'Submit',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final product = currentProduct;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, favoriteChanged);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── App bar ──────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context, favoriteChanged),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: whiteSmoke,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: Colors.black54),
                      ),
                    ),
                    const Spacer(),
                    // Favorite
                    GestureDetector(
                      onTap: isFavoriteLoading ? null : _toggleFavorite,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: whiteSmoke,
                            borderRadius: BorderRadius.circular(14)),
                        child: isFavoriteLoading
                            ? const Center(
                                child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)))
                            : Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: wine,
                                size: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Save to collection
                    GestureDetector(
                      onTap: _openAddToCollectionSheet,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: whiteSmoke,
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(
                          isSavedToCollection
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isSavedToCollection ? wine : Colors.black54,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Scrollable body ──────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageAndUsersArea(product),
                      const SizedBox(height: 20),
                      _buildProductHeader(product),
                      const SizedBox(height: 16),
                      _buildWhatsInsideStrip(product),
                      const SizedBox(height: 4),
                      _buildTabBar(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildActiveTabContent(product),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Product image + "also used by" ────────────────────────────────────────
  Widget _buildImageAndUsersArea(ProductModel product) {
    return Column(
      children: [
        // "Also used by" row
        if (recentlyUsedUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
            child: _buildAlsoUsedBy(),
          ),
        // Product image
        Center(
          child: Hero(
            tag: product.id,
            child: SizedBox(
              height: 240,
              child: product.imageUrl.isNotEmpty
                  ? Image.network(product.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _imagePlaceholder())
                  : _imagePlaceholder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlsoUsedBy() {
    final users = recentlyUsedUsers.take(3).toList();
    final count = recentlyUsedUsers.length;

    final colors = [
      const Color(0xFF5B2333).withOpacity(0.7),
      const Color(0xFF2E7D32).withOpacity(0.7),
      const Color(0xFF1565C0).withOpacity(0.7),
    ];

    return Row(
      children: [
        ...users.asMap().entries.map((entry) {
          final i = entry.key;
          final user = entry.value;

          final fullName = user["fullName"]?.toString() ?? "User";
          final profileImage = user["profileImage"]?.toString() ?? "";
          final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : "U";

          return Transform.translate(
            offset: Offset(i * -6.0, 0),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: colors[i % colors.length],
              backgroundImage:
                  profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
              child: profileImage.isEmpty
                  ? Text(
                      initial,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          );
        }).toList(),
        const SizedBox(width: 12),
        Text(
          count == 1
              ? '1 Skinova user recently used this'
              : '$count Skinova users recently used this',
          style: GoogleFonts.poppins(fontSize: 12, color: grey),
        ),
      ],
    );
  }

  // ── Product header (brand, name, rating, price) ───────────────────────────
  Widget _buildProductHeader(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand + stock
          Row(
            children: [
              Expanded(
                child: Text(product.brand.toUpperCase(),
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: wine.withOpacity(0.6))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Product name
          Text(product.name,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: darkText)),
          const SizedBox(height: 12),
          // Rating row
          Row(
            children: [
              ...List.generate(
                  5,
                  (i) => Icon(
                      i < displayedRating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 18)),
              const SizedBox(width: 8),
              Text(displayedRating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: darkText)),
              const SizedBox(width: 6),
              Text('(${displayedReviews.length} reviews)',
                  style: GoogleFonts.poppins(fontSize: 12, color: grey)),
            ],
          ),
        ],
      ),
    );
  }

  // ── What's Inside strip ───────────────────────────────────────────────────
  Widget _buildWhatsInsideStrip(ProductModel product) {
    final flags = <String>{};
    final w = product.whatsInside;
    if (w.fragranceFree) flags.add('Fragrance Free');
    if (w.alcoholFree) flags.add('Alcohol Free');
    if (w.parabenFree) flags.add('Paraben Free');
    if (w.siliconeFree) flags.add('Silicone Free');
    if (w.sulfateFree) flags.add('Sulfate Free');
    if (w.crueltyFree) flags.add('Cruelty Free');
    if (w.vegan) flags.add('Vegan');
    if (w.oilFree) flags.add('Oil Free');
    if (w.fungalAcneSafe) flags.add('Fungal Acne Safe');
    if (w.reefSafe) flags.add('Reef Safe');
    if (w.euAllergenFree) flags.add('EU Allergen Free');
    if (flags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        itemCount: flags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final tag = flags.elementAt(i);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: wine.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, size: 12, color: wine),
                const SizedBox(width: 4),
                Text(tag,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: wine)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: darkText,
      unselectedLabelColor: grey,
      indicatorColor: darkText,
      indicatorWeight: 2,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle:
          GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w400),
      dividerColor: line,
      tabs: const [
        Tab(text: 'Overview'),
        Tab(text: 'Analytics'),
        Tab(text: 'Ingredients'),
        Tab(text: 'Reviews'),
        Tab(text: 'AI Match'),
      ],
    );
  }

  Widget _buildActiveTabContent(ProductModel product) {
    switch (_tabController.index) {
      case 0:
        return _buildOverviewTab(product);
      case 1:
        return _buildAnalyticsTab();
      case 2:
        return _buildIngredientsTab(product);
      case 3:
        return _buildReviewsTab();
      case 4:
        return _buildAiMatchTab(product);
      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AI MATCH TAB
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _analyzeProduct() async {
    if (widget.userId.isEmpty) {
      setState(() {
        _suitabilityError = 'Sign in to use AI analysis.';
        _suitabilityLoading = false;
      });
      return;
    }
    setState(() {
      _suitabilityLoading = true;
      _suitabilityError = null;
    });
    try {
      final result = await ApiService.analyzeProductSuitability(
        userId: widget.userId,
        productId: currentProduct.id,
      );
      if (!mounted) return;
      if (result['statusCode'] == 200 &&
          result['data']['success'] == true) {
        setState(() {
          _suitabilityResult =
              Map<String, dynamic>.from(result['data'] as Map);
          _suitabilityLoading = false;
        });
      } else {
        setState(() {
          _suitabilityError = (result['data']['message'] as String?) ??
              'Analysis failed. Please try again.';
          _suitabilityLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suitabilityError = 'Could not connect. Please try again.';
        _suitabilityLoading = false;
      });
    }
  }

  Widget _buildAiMatchTab(ProductModel product) {
    if (_suitabilityLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const CircularProgressIndicator(color: wine),
            const SizedBox(height: 18),
            Text('Analyzing product suitability…',
                style: GoogleFonts.poppins(fontSize: 13, color: grey)),
            const SizedBox(height: 6),
            Text('This may take a few seconds.',
                style: GoogleFonts.poppins(fontSize: 11.5, color: grey)),
          ],
        ),
      );
    }

    if (_suitabilityError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: wine),
            const SizedBox(height: 12),
            Text(_suitabilityError!,
                style: GoogleFonts.poppins(fontSize: 13.5, color: darkText),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _analyzeProduct,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                    color: wine, borderRadius: BorderRadius.circular(12)),
                child: Text('Try Again',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      );
    }

    if (_suitabilityResult == null) {
      return _buildAiMatchIntro(product);
    }

    return _buildAiMatchResult(_suitabilityResult!);
  }

  Widget _buildAiMatchIntro(ProductModel product) {
    final hasIngredients = product.ingredients.isNotEmpty ||
        product.directionsOfUse.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B2333), Color(0xFF7A3146)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text('AI Skin Match',
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ]),
              const SizedBox(height: 10),
              Text(
                'Let Skinova AI check if this product suits your skin type, concerns, and routine.',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white.withOpacity(0.9)),
              ),
              const SizedBox(height: 4),
              Text(
                hasIngredients
                    ? 'Ingredients and directions of use will be analyzed.'
                    : 'Product information will be used for analysis.',
                style: GoogleFonts.poppins(
                    fontSize: 11.5, color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: widget.userId.isEmpty ? null : _analyzeProduct,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: widget.userId.isEmpty
                  ? Colors.grey.shade300
                  : wine,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.biotech_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.userId.isEmpty
                      ? 'Sign in to analyze'
                      : 'Analyze for My Skin',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'This analysis uses your skin profile, latest scan, and active routine for personalization.',
          style: GoogleFonts.poppins(fontSize: 11.5, color: grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAiMatchResult(Map<String, dynamic> data) {
    final score = (data['matchScore'] as num?)?.toInt() ?? 0;
    final verdict = (data['verdict'] ?? 'neutral').toString();
    final summary = (data['summary'] ?? '').toString();
    final benefits = (data['benefits'] as List?)?.cast<String>() ?? [];
    final warnings = (data['warnings'] as List?)?.cast<String>() ?? [];
    final conflicts = (data['conflicts'] as List?) ?? [];
    final usageAdvice =
        data['usageAdvice'] as Map? ?? {};

    Color scoreColor;
    if (score >= 70) scoreColor = const Color(0xFF2E7D52);
    else if (score >= 45) scoreColor = const Color(0xFFE65100);
    else scoreColor = Colors.red.shade600;

    Color verdictColor;
    String verdictLabel;
    switch (verdict) {
      case 'recommended':
        verdictColor = const Color(0xFF2E7D52);
        verdictLabel = 'Recommended';
        break;
      case 'use_with_caution':
        verdictColor = const Color(0xFFE65100);
        verdictLabel = 'Use With Caution';
        break;
      case 'not_recommended':
        verdictColor = Colors.red.shade600;
        verdictLabel = 'Not Recommended';
        break;
      default:
        verdictColor = const Color(0xFF3D7CB5);
        verdictLabel = 'Neutral';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score + verdict row
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: whiteSmoke,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: line),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(fit: StackFit.expand, children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 6,
                    backgroundColor: line,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                  Center(
                    child: Text('$score%',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: scoreColor)),
                  ),
                ]),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Match Score',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: grey)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: verdictColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: verdictColor.withOpacity(0.25)),
                      ),
                      child: Text(verdictLabel,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: verdictColor)),
                    ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(summary,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: darkText, height: 1.45)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        if (benefits.isNotEmpty) ...[
          const SizedBox(height: 14),
          _aiSection(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF2E7D52),
            title: 'Why It May Help',
            items: benefits,
            itemColor: const Color(0xFF2E7D52),
            bgColor: const Color(0xFFEFF7EF),
          ),
        ],

        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 14),
          _aiSection(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFE65100),
            title: 'Warnings',
            items: warnings,
            itemColor: const Color(0xFFE65100),
            bgColor: const Color(0xFFFFF3E0),
          ),
        ],

        if (conflicts.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildConflictsCard(conflicts),
        ],

        if (usageAdvice.isNotEmpty &&
            (usageAdvice['bestTime'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildUsageAdviceCard(usageAdvice),
        ],

        const SizedBox(height: 14),
        // Re-analyze + disclaimer
        GestureDetector(
          onTap: _analyzeProduct,
          child: Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              color: whiteSmoke,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: line),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh_rounded, size: 16, color: wine),
                const SizedBox(width: 6),
                Text('Re-Analyze',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: wine)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'This is general skincare guidance, not medical advice. Consult a dermatologist for medical concerns.',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: grey, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _aiSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
    required Color itemColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: itemColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 7),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: itemColor)),
          ]),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                            color: itemColor,
                            shape: BoxShape.circle)),
                    Expanded(
                      child: Text(item,
                          style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: darkText,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildConflictsCard(List conflicts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.report_problem_outlined,
                size: 16, color: Colors.red.shade600),
            const SizedBox(width: 7),
            Text('Routine Conflicts',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700)),
          ]),
          const SizedBox(height: 12),
          ...conflicts.map((c) {
            final map = c as Map;
            final ingA = (map['ingredientA'] ?? '').toString();
            final ingB = (map['ingredientB'] ?? '').toString();
            final severity = (map['severity'] ?? 'low').toString();
            final reason = (map['reason'] ?? '').toString();
            final rec = (map['recommendation'] ?? '').toString();
            Color sevColor = severity == 'high'
                ? Colors.red.shade600
                : severity == 'medium'
                    ? const Color(0xFFE65100)
                    : Colors.grey.shade600;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: sevColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('$ingA  +  $ingB',
                            style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: darkText)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: sevColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(severity,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: sevColor)),
                      ),
                    ],
                  ),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(reason,
                        style: GoogleFonts.poppins(
                            fontSize: 11.5, color: grey)),
                  ],
                  if (rec.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.tips_and_updates_outlined,
                            size: 13, color: wine),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(rec,
                              style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: wine,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUsageAdviceCard(Map advice) {
    final bestTime = (advice['bestTime'] ?? '').toString();
    final frequency = (advice['frequency'] ?? '').toString();
    final instructions = (advice['instructions'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E8EA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: wine.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.access_time_rounded, size: 16, color: wine),
            const SizedBox(width: 7),
            Text('Usage Advice',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: wine)),
          ]),
          const SizedBox(height: 12),
          if (bestTime.isNotEmpty)
            _adviceRow('Best time', bestTime),
          if (frequency.isNotEmpty)
            _adviceRow('Frequency', frequency),
          if (instructions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(instructions,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: darkText, height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _adviceRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text('$label: ',
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: wine)),
            Text(value,
                style: GoogleFonts.poppins(fontSize: 12.5, color: darkText)),
          ],
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // OVERVIEW TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab(ProductModel product) {
    final bestFor = [
      ...product.recommendedFor.concerns,
      ...product.recommendedFor.skinTypes,
      ...product.recommendedFor.goals,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Best suited for
        if (bestFor.isNotEmpty) ...[
          _sectionLabel('Best suited for'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bestFor
                .map((item) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: const Color(0xFFEDEDED), width: 1.4),
                      ),
                      child: Text(item,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: wine,
                              fontWeight: FontWeight.w500)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 28),
        ],

        // Description
        if (product.shortDescription.isNotEmpty) ...[
          _sectionLabel('Description'),
          const SizedBox(height: 10),
          Text(product.shortDescription,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.65,
                  color: darkText.withOpacity(0.8))),
          const SizedBox(height: 28),
        ],

        // Directions of use
        if (product.directionsOfUse.isNotEmpty) ...[
          _sectionLabel('Directions of use'),
          const SizedBox(height: 10),
          Text(product.directionsOfUse,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.65,
                  color: darkText.withOpacity(0.8))),
          const SizedBox(height: 28),
        ],

        // Product details
        if (product.brandOrigin.isNotEmpty || product.size.isNotEmpty) ...[
          _sectionLabel('Product details'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: whiteSmoke,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (product.brandOrigin.isNotEmpty)
                  _detailRow('Brand origin', product.brandOrigin),
                if (product.size.isNotEmpty)
                  _detailRow('Size / Volume', product.size),
                if (product.category.isNotEmpty)
                  _detailRow('Category', product.category),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],

        // Where to buy
        _sectionLabel('Where to buy'),
        const SizedBox(height: 12),
        _buildWhereToBuyCard(),
        const SizedBox(height: 28),

        // More from same brand
        if (!sameBrandLoading && sameBrandProducts.isNotEmpty) ...[
          _sectionLabel('More from ${currentProduct.brand}'),
          const SizedBox(height: 14),
          _buildSameBrandScroll(),
        ],
      ],
    );
  }

  Widget _buildWhereToBuyCard() {
    if (storesLoading) {
      return Container(
        height: 72,
        decoration: BoxDecoration(
            color: whiteSmoke, borderRadius: BorderRadius.circular(16)),
        child: const Center(
            child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (productStores.isEmpty) {
      return _emptyState(
          Icons.store_mall_directory_outlined,
          'Not available in stores yet',
          'This product is not listed by any seller on Skinova yet.');
    }

    final count = productStores.length;
    final lowestPrice = productStores.fold<num>(
        double.infinity, (min, s) => math.min(min, (s['price'] ?? 0) as num));
    final currency = (productStores.first['currency'] ?? 'ILS').toString();

    return GestureDetector(
      onTap: _showStoresBottomSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: line),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: wine.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.store_outlined, color: wine, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available in $count store${count > 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkText)),
                  Text(
                    lowestPrice < double.infinity
                        ? 'From $lowestPrice $currency'
                        : 'Check store prices',
                    style: GoogleFonts.poppins(fontSize: 12, color: grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildSameBrandScroll() {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sameBrandProducts.take(8).length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final item = sameBrandProducts[i];
          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(
                      product: item,
                      userId: widget.userId,
                      userName: widget.userName),
                )),
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: whiteSmoke,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: line),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(item.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _imagePlaceholder())
                        : _imagePlaceholder(),
                  ),
                  const SizedBox(height: 6),
                  Text(item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: darkText,
                          height: 1.3)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ANALYTICS TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAnalyticsTab() {
    if (_analyticsLoading) {
      return Column(
        children: [
          _skeletonBox(height: 90),
          const SizedBox(height: 16),
          _skeletonBox(height: 60),
          const SizedBox(height: 16),
          _skeletonBox(height: 60),
          const SizedBox(height: 16),
          _skeletonBox(height: 60),
        ],
      );
    }

    final reviewCount = (_analytics['reviewCount'] ?? 0) as int;

    if (reviewCount == 0) {
      return _emptyState(
        Icons.analytics_outlined,
        'No analytics yet',
        'Analytics will appear once users start reviewing this product.',
      );
    }

    final avgRating = (_analytics['avgRating'] ?? 0.0) as num;
    final repurchaseRate = _analytics['repurchaseRate'] as int?;
    final improvedRate = _analytics['improvedSkinRate'] as int?;
    final adverseRate = _analytics['adverseReactionRate'] as int?;
    final skinTypes = (_analytics['skinTypeBreakdown'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: wine.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: wine.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(avgRating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: wine)),
                  Row(
                    children: List.generate(
                        5,
                        (i) => Icon(
                            i < avgRating.round()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 16)),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Based on $reviewCount review${reviewCount == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: darkText)),
                    const SizedBox(height: 4),
                    Text('From real Skinova users',
                        style:
                            GoogleFonts.poppins(fontSize: 11.5, color: grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Community feedback
        _sectionLabel('Community feedback'),
        const SizedBox(height: 14),
        if (repurchaseRate != null)
          _analyticsBar('Would repurchase', repurchaseRate,
              const Color(0xFF2E7D32), const Color(0xFFEFF7EF)),
        if (improvedRate != null)
          _analyticsBar('Improved their skin', improvedRate,
              const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
        if (adverseRate != null)
          _analyticsBar('Had adverse reactions', adverseRate,
              const Color(0xFFC62828), const Color(0xFFFDECEC)),
        if (repurchaseRate == null &&
            improvedRate == null &&
            adverseRate == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Reviewers did not share detailed feedback yet.',
              style: GoogleFonts.poppins(fontSize: 13, color: grey),
            ),
          ),

        // Skin type breakdown
        if (skinTypes.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('Skin type of reviewers'),
          const SizedBox(height: 14),
          ...skinTypes.map((entry) {
            final type = entry['type']?.toString() ?? '';
            final pct = (entry['percentage'] ?? 0) as int;
            return _analyticsBar(type, pct, wine, wine.withOpacity(0.08));
          }).toList(),
        ],
      ],
    );
  }

  Widget _analyticsBar(
      String label, int percentage, Color barColor, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: darkText)),
              ),
              Text('$percentage%',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: barColor)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 8, color: bgColor),
                FractionallySizedBox(
                  widthFactor: percentage / 100.0,
                  child: Container(height: 8, color: barColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INGREDIENTS TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildIngredientsTab(ProductModel product) {
    final allFlags = <String, bool>{
      'Alcohol Free': product.whatsInside.alcoholFree,
      'EU Allergen Free': product.whatsInside.euAllergenFree,
      'Fragrance Free': product.whatsInside.fragranceFree,
      'Oil Free': product.whatsInside.oilFree,
      'Paraben Free': product.whatsInside.parabenFree,
      'Silicone Free': product.whatsInside.siliconeFree,
      'Sulfate Free': product.whatsInside.sulfateFree,
      'Cruelty Free': product.whatsInside.crueltyFree,
      'Fungal Acne Safe': product.whatsInside.fungalAcneSafe,
      'Reef Safe': product.whatsInside.reefSafe,
      'Vegan': product.whatsInside.vegan,
    };
    final activeFlags = allFlags.entries.where((e) => e.value).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // What's inside flags
        if (activeFlags.isNotEmpty) ...[
          _sectionLabel("What's inside"),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeFlags
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: wine.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 13, color: wine),
                          const SizedBox(width: 5),
                          Text(e.key,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: wine,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 28),
        ] else ...[
          _sectionLabel("What's inside"),
          const SizedBox(height: 10),
          Text('No ingredient flags have been set for this product.',
              style: GoogleFonts.poppins(fontSize: 13, color: grey)),
          const SizedBox(height: 28),
        ],

        // Ingredient list
        _sectionLabel('Full ingredient list'),
        const SizedBox(height: 12),
        product.ingredients.isEmpty
            ? _emptyState(Icons.science_outlined, 'No ingredients listed',
                'The full ingredient list has not been added yet.')
            : Column(
                children: product.ingredients.map((ing) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: whiteSmoke,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ing.name,
                            style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: darkText)),
                        if (ing.description.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(ing.description,
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  height: 1.5,
                                  color: darkText.withOpacity(0.65))),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REVIEWS TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildReviewsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating summary header
        if (displayedReviews.isNotEmpty) _buildRatingSummary(),

        // Write review button
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _openReviewSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: wine,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Write a Review',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Product reviews
        if (displayedReviews.isEmpty)
          _emptyState(Icons.rate_review_outlined, 'No reviews yet',
              'Be the first to share your experience with this product.')
        else ...[
          _sectionLabel(
              '${displayedReviews.length} Review${displayedReviews.length == 1 ? '' : 's'}'),
          const SizedBox(height: 14),
          ...displayedReviews.map(_buildReviewCard).toList(),
        ],

        // Community review posts
        if (!reviewPostsLoading && productReviewPosts.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('From the community'),
          const SizedBox(height: 14),
          ...productReviewPosts.map(_buildReviewPostCard).toList(),
        ],
      ],
    );
  }

  Widget _buildRatingSummary() {
    final total = displayedReviews.length;
    final dist = _ratingDistribution;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteSmoke,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          // Big number
          Column(
            children: [
              Text(displayedRating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                      fontSize: 44, fontWeight: FontWeight.w700, color: wine)),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                        i < displayedRating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 14)),
              ),
              const SizedBox(height: 2),
              Text('$total reviews',
                  style: GoogleFonts.poppins(fontSize: 10.5, color: grey)),
            ],
          ),
          const SizedBox(width: 18),
          // Distribution bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = dist[star] ?? 0;
                final pct = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('$star',
                          style:
                              GoogleFonts.poppins(fontSize: 10, color: grey)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          size: 10, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            children: [
                              Container(height: 6, color: Colors.grey.shade200),
                              FractionallySizedBox(
                                widthFactor: pct,
                                child:
                                    Container(height: 6, color: Colors.amber),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text('$count',
                            textAlign: TextAlign.right,
                            style:
                                GoogleFonts.poppins(fontSize: 10, color: grey)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: wine.withOpacity(0.12),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : 'A',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: wine, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.userName.isEmpty ? 'Anonymous' : review.userName,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: darkText),
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                        i < review.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 14)),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.6,
                    color: darkText.withOpacity(0.7))),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewPostCard(GroupPostModel post) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: whiteSmoke,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: wine.withOpacity(0.10),
                child: Text(
                  post.userName.isNotEmpty
                      ? post.userName[0].toUpperCase()
                      : 'U',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: wine, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(post.userName,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: darkText)),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                        i < post.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 14)),
              ),
            ],
          ),
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(post.content,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.55,
                    color: darkText.withOpacity(0.72))),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 15, color: grey),
              const SizedBox(width: 4),
              Text('${post.likes.length}',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: grey)),
              const SizedBox(width: 14),
              Icon(Icons.chat_bubble_outline, size: 15, color: grey),
              const SizedBox(width: 4),
              Text('${post.comments.length}',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: grey)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600, color: darkText));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.poppins(fontSize: 12, color: grey)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: darkText)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: wine.withOpacity(0.06), shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: wine.withOpacity(0.5)),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkText)),
            const SizedBox(height: 5),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12.5, color: grey)),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox({double height = 60}) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
          color: whiteSmoke, borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Icon(Icons.image_not_supported_outlined,
          size: 56, color: wine.withOpacity(0.22)),
    );
  }
}

// ── Donut chart (kept for potential reuse) ────────────────────────────────────
class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  const DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (s, v) => s + v);
    if (total == 0) return;
    double startAngle = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.28
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      paint.color = colors[i];
      canvas.drawArc((Offset.zero & size).deflate(size.width * 0.14),
          startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
