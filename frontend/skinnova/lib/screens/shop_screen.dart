import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'store_details_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'shop_ai_chat_page.dart';

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
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color softPink = Color(0xFFF8E8EC);
  static const Color gold = Color(0xFFD4AF37);

  List<dynamic> stores = [];
  List<dynamic> storeProducts = [];
  List<dynamic> filteredStores = [];
  List<dynamic> filteredProducts = [];
  List<dynamic> ads = [];
  bool isLoading = true;
  String searchText = "";

  final PageController _sliderController =
      PageController(viewportFraction: 0.88);
  int currentSlide = 0;
  Timer? _timer;

  List<dynamic> trendingStoreProducts = [];
  int selectedDiscoverIndex = -1;
  List<dynamic> needStores = [];
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
    _loadShopData();
    _startSlider();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sliderController.dispose();
    super.dispose();
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
      final storesResult = await ApiService.fetchStores();
      final productsResult = await ApiService.fetchAllStoreProducts();
      final trendingResult = await ApiService.fetchTrendingStoreProducts();
      final adsResult = await ApiService.fetchApprovedAds();

      if (!mounted) return;

      setState(() {
        stores = storesResult;
        storeProducts = productsResult;
        filteredStores = storesResult;
        filteredProducts = productsResult;
        ads = adsResult;
        trendingStoreProducts = trendingResult;
        needStores = storesResult;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Shop load error: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _search(String value) {
    setState(() {
      searchText = value.toLowerCase().trim();

      if (searchText.isEmpty) {
        filteredStores = stores;
        filteredProducts = storeProducts;
        selectedDiscoverIndex = -1;
        return;
      }

      filteredStores = stores.where((store) {
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

        final productName = (product["name"] ?? "").toString().toLowerCase();
        final brand = (product["brand"] ?? "").toString().toLowerCase();
        final category = (product["category"] ?? "").toString().toLowerCase();
        final brandOrigin =
            (product["brandOrigin"] ?? "").toString().toLowerCase();
        final shortDescription =
            (product["shortDescription"] ?? "").toString().toLowerCase();
        final storeName = (store["storeName"] ?? "").toString().toLowerCase();
        final storeCity = (store["city"] ?? "").toString().toLowerCase();

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

        return productName.contains(searchText) ||
            brand.contains(searchText) ||
            category.contains(searchText) ||
            brandOrigin.contains(searchText) ||
            shortDescription.contains(searchText) ||
            storeName.contains(searchText) ||
            storeCity.contains(searchText) ||
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

  List<dynamic> get trendingProducts {
    return trendingStoreProducts;
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
          child: Text(
            letter,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: wine,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Text(
        letter,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: wine,
        ),
      ),
    );
  }

  void _openStore(dynamic store) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailsScreen(
          store: Map<String, dynamic>.from(store),
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: wine))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const SizedBox(height: 18),
                    _searchBar(),
                    const SizedBox(height: 24),
                    _heroSlider(),
                    _sectionTitle(
                        "Shop by Need", "Find stores that match what you need"),
                    const SizedBox(height: 14),
                    _discoverSection(),
                    const SizedBox(height: 16),
                    _needStores(),
                    // const SizedBox(height: 24),
                    // _sectionTitle(
                    //     "Skinova Picks", "Smart shortcuts for better shopping"),
                    // const SizedBox(height: 14),
                    // _shopPicks(),
                    // const SizedBox(height: 24),
                    // _sectionTitle(
                    //     "Shop by Origin", "Explore products by brand origin"),
                    // const SizedBox(height: 14),
                    // _originPicks(),
                    const SizedBox(height: 28),
                    _sectionTitle(
                        "Stores You'll Love", "Community favorites this week"),
                    const SizedBox(height: 14),
                    _topStores(),
                    const SizedBox(height: 28),
                    _sectionTitle("Trending Products", "Popular now"),
                    const SizedBox(height: 14),
                    _trendingProducts(),
                    const SizedBox(height: 28),
                    _aiBanner(),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        _sectionTitle(
                            "All Stores", "${filteredStores.length} stores"),
                        const Spacer(),
                        //const Icon(Icons.tune_rounded, color: wine, size: 22),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _allStores(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _needStores() {
    if (needStores.isEmpty) {
      return _emptyText("No stores match this filter");
    }

    return SizedBox(
      height: 135,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: needStores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final store = needStores[index];

          final name = store["storeName"] ?? "Store";
          final logoUrl = store["logoUrl"] ?? "";
          final city = store["city"] ?? "";
          final rating = store["rating"] ?? 0;

          return GestureDetector(
            onTap: () => _openStore(store),
            child: Container(
              width: 145,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: wine.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: softBg,
                        child: ClipOval(
                          child: _logo(logoUrl, name, 44),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFFFB800),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: Colors.black45,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Explore store",
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: wine,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _discoverSection() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: discoverItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = discoverItems[index];
          final selected = selectedDiscoverIndex == index;

          return GestureDetector(
            onTap: () {
              final type = item["type"];
              final value = item["value"].toString().toLowerCase();

              setState(() {
                selectedDiscoverIndex = index;

                if (type == "all") {
                  needStores = stores;
                } else if (type == "newStores") {
                  needStores = stores.take(6).toList();
                } else if (type == "offers") {
                  final offerStoreIds = ads
                      .map((ad) {
                        final store = ad["storeId"];
                        if (store is Map) return store["_id"]?.toString();
                        return store?.toString();
                      })
                      .where((id) => id != null)
                      .toSet();

                  needStores = stores.where((store) {
                    return offerStoreIds.contains(store["_id"]?.toString());
                  }).toList();
                } else if (type == "origin") {
                  final matchedStoreIds = storeProducts.where((sp) {
                    final product = sp["productId"] ?? {};
                    final origin =
                        (product["brandOrigin"] ?? "").toString().toLowerCase();
                    return origin.contains(value);
                  }).map((sp) {
                    final store = sp["storeId"];
                    if (store is Map) return store["_id"]?.toString();
                    return store?.toString();
                  }).toSet();

                  needStores = stores.where((store) {
                    return matchedStoreIds.contains(store["_id"]?.toString());
                  }).toList();
                } else if (type == "category") {
                  final matchedStoreIds = storeProducts.where((sp) {
                    final product = sp["productId"] ?? {};
                    final category =
                        (product["category"] ?? "").toString().toLowerCase();
                    return category.contains(value);
                  }).map((sp) {
                    final store = sp["storeId"];
                    if (store is Map) return store["_id"]?.toString();
                    return store?.toString();
                  }).toSet();

                  needStores = stores.where((store) {
                    return matchedStoreIds.contains(store["_id"]?.toString());
                  }).toList();
                } else if (type == "concern") {
                  final matchedStoreIds = storeProducts.where((sp) {
                    final product = sp["productId"] ?? {};

                    final concerns =
                        ((product["recommendedFor"]?["concerns"] ?? []) as List)
                            .join(" ")
                            .toLowerCase();

                    final skinTypes =
                        ((product["recommendedFor"]?["skinTypes"] ?? [])
                                as List)
                            .join(" ")
                            .toLowerCase();

                    return concerns.contains(value) ||
                        skinTypes.contains(value);
                  }).map((sp) {
                    final store = sp["storeId"];
                    if (store is Map) return store["_id"]?.toString();
                    return store?.toString();
                  }).toSet();

                  needStores = stores.where((store) {
                    return matchedStoreIds.contains(store["_id"]?.toString());
                  }).toList();
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? wine : wine.withOpacity(0.12),
                  width: selected ? 1.8 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? wine.withOpacity(0.12)
                        : Colors.black.withOpacity(0.045),
                    blurRadius: selected ? 16 : 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    item["emoji"],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    item["title"],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? wine : darkText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: wine,
            ),
          ),
        ),
        Column(
          children: [
            Text(
              "Shop",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: wine,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onChanged: _search,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded, color: Colors.black38),
          hintText: "Search stores, products or brands...",
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.black38,
          ),
        ),
      ),
    );
  }

  Widget _heroSlider() {
    if (ads.isEmpty) {
      return Container(
        height: 165,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -20,
              child: Icon(
                Icons.campaign_outlined,
                size: 120,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: gold, size: 30),
                const Spacer(),
                Text(
                  "Skinova Deals",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Approved store offers will appear here",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.82),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _sliderController,
            itemCount: ads.length,
            onPageChanged: (index) => setState(() => currentSlide = index),
            itemBuilder: (context, index) {
              final ad = ads[index];

              final title = ad["title"] ?? "Special Offer";
              final subtitle = ad["subtitle"] ?? "";
              final imageUrl = ad["imageUrl"] ?? "";
              final buttonText = ad["buttonText"] ?? "Shop now";
              final store = ad["storeId"];

              return GestureDetector(
                onTap: () {
                  if (store != null && store is Map) {
                    _openStore(store);
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: 12,
                    left: index == 0 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imageUrl.toString().isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: wine,
                                  child: const Icon(
                                    Icons.campaign_outlined,
                                    color: Colors.white,
                                    size: 46,
                                  ),
                                ),
                              )
                            : Container(
                                color: wine,
                                child: const Icon(
                                  Icons.campaign_outlined,
                                  color: Colors.white,
                                  size: 46,
                                ),
                              ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.62),
                                Colors.black.withOpacity(0.18),
                              ],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                  ),
                                ),
                                child: Text(
                                  "Sponsored",
                                  style: GoogleFonts.poppins(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  buttonText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: wine,
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
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            ads.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 7,
              width: currentSlide == index ? 20 : 7,
              decoration: BoxDecoration(
                color: currentSlide == index ? wine : Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: darkText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _topStores() {
    if (topStores.isEmpty) return _emptyText("No stores found");

    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: topStores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final store = topStores[index];

          final name = store["storeName"] ?? "Store";
          final logoUrl = store["logoUrl"] ?? "";
          final rating = store["rating"] ?? 0;

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
                        height: 82,
                        width: 82,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              wine.withOpacity(0.9),
                              const Color(0xFF8E4B5D),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: wine.withOpacity(0.16),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: _logo(logoUrl, name, 74),
                          ),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD36A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB800),
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rating.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
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

  Widget _featuredStoreCard(dynamic store) {
    final name = store["storeName"] ?? "Store";
    final logoUrl = store["logoUrl"] ?? "";
    final city = store["city"] ?? "";
    final rating = store["rating"] ?? 0;

    return GestureDetector(
      onTap: () => _openStore(store),
      child: Container(
        height: 145,
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: wine,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: wine.withOpacity(0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child: ClipOval(child: _logo(logoUrl, name, 76)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Top store this week",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    city,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFD36A), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "Explore",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

  Widget _trendingProducts() {
    if (trendingProducts.isEmpty) return _emptyText("No products found");

    return SizedBox(
      height: 218,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: trendingProducts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = trendingProducts[index];
          final store = item["storeId"] ?? {};
          final product = item["productId"] ?? {};

          final productName = product["name"] ?? "Product";
          final brand = product["brand"] ?? "Brand";
          final imageUrl = product["imageUrl"] ?? "";
          final price = item["price"] ?? 0;
          final currency = item["currency"] ?? "ILS";

          return Container(
            width: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 96,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: softBg,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: imageUrl.toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.spa_outlined,
                                  color: wine,
                                  size: 32,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.spa_outlined,
                              color: wine,
                              size: 32,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: Colors.black45,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 15),
                          const SizedBox(width: 3),
                          Text(
                            "${item["reviewPostsRating"]?.toStringAsFixed(1) ?? "0.0"}",
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${item["reviewPostsCount"] ?? 0} reviews",
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: wine,
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _aiBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                  "Need help choosing?",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Find products that match your skin needs.",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ShopAiChatPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "Get Advice",
                style: GoogleFonts.poppins(
                  color: wine,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _allStores() {
    if (filteredStores.isEmpty) {
      return _emptyText("No stores match your search");
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredStores.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final store = filteredStores[index];

        final name = store["storeName"] ?? "Store";
        final logoUrl = store["logoUrl"] ?? "";
        final city = store["city"] ?? "";

        return GestureDetector(
          onTap: () => _openStore(store),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: wine.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 72,
                  width: 72,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: softBg,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: _logo(logoUrl, name, 82),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: wine.withOpacity(0.5),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: wine.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "View Store",
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
      },
    );
  }

  Widget _featuredAllStore(dynamic store) {
    final name = store["storeName"] ?? "Store";
    final logoUrl = store["logoUrl"] ?? "";
    final city = store["city"] ?? "";
    final rating = store["rating"] ?? 0;

    return GestureDetector(
      onTap: () => _openStore(store),
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: wine.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: wine.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              height: 82,
              width: 82,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: _logo(logoUrl, name, 82),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Featured store",
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: wine,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB800), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_rounded,
                          color: wine, size: 18),
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

  Widget _emptyText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.black45,
        ),
      ),
    );
  }
}
