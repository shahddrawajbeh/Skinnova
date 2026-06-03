import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scan_page.dart';
import 'search_page.dart';
import 'ask_ai_page.dart';
import 'compare_page.dart';
import 'analyze_page.dart';
import '../api_service.dart';
import '../product_model.dart';
import 'product_details_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'group_details_screen.dart';
import '../group_model.dart';
import '../active_ingredient_model.dart';
import 'ingredient_details_screen.dart';

class SkinovaProductsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const SkinovaProductsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<SkinovaProductsScreen> createState() => _SkinovaProductsScreenState();
}

class _SkinovaProductsScreenState extends State<SkinovaProductsScreen>
    with SingleTickerProviderStateMixin {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color wine = Color(0xFF5B2333);
  static const Color softBorder = Color(0xFFE9E9E9);
  static const Color softText = Color(0xFF202124);
  static const Color mutedText = Color(0xFF7A7A7A);
  static const Color sliderBlue = Color(0xFF3A99F5);

  // ── Static content ────────────────────────────────────────────────────────
  static const _popularSearches = [
    'Niacinamide',
    'Vitamin C',
    'Retinol',
    'Hyaluronic Acid',
    'SPF 50',
    'Ceramides',
    'AHA BHA',
  ];

  static const _skintips = [
    'Apply SPF every morning — even indoors. UV rays pass through windows.',
    'Layer actives thinnest to thickest: toner → serum → moisturizer → SPF.',
    'Niacinamide and Vitamin C work well together in modern stable formulas.',
    'Retinol works best at night — daylight degrades it rapidly.',
    'Hydration ≠ moisture. Hyaluronic acid draws water in; ceramides seal it.',
  ];

  static const _concernChips = [
    {
      'label': 'Acne',
      'value': 'Acne & Blemishes',
      'icon': Icons.healing_outlined
    },
    {'label': 'Dryness', 'value': 'Dryness', 'icon': Icons.water_drop_outlined},
    {
      'label': 'Dark Spots',
      'value': 'Dark Spots',
      'icon': Icons.brightness_6_outlined
    },
    {'label': 'Redness', 'value': 'Redness', 'icon': Icons.favorite_outline},
    {'label': 'Pores', 'value': 'Visible Pores', 'icon': Icons.grain_outlined},
    {
      'label': 'Oiliness',
      'value': 'Oiliness',
      'icon': Icons.bubble_chart_outlined
    },
    {'label': 'Dullness', 'value': 'Dullness', 'icon': Icons.wb_sunny_outlined},
    {
      'label': 'Texture',
      'value': 'Uneven Texture',
      'icon': Icons.layers_outlined
    },
  ];

  // ── Existing state ────────────────────────────────────────────────────────
  String selectedConcern = 'All';
  String selectedCategory = 'All';
  String selectedSkinType = 'All';
  String searchQuery = '';
  late TabController _tabController;
  RangeValues selectedPriceRange = const RangeValues(0, 100);
  RangeValues selectedRatingRange = const RangeValues(0, 5);
  List<String> selectedSkinTags = [];
  List<String> selectedProductCategories = [];
  List<String> selectedActiveIngredients = [];
  bool personalizedAiRecommendations = false;
  bool isLoadingProducts = true;
  List<ProductModel> allProducts = [];
  List<ProductModel> recommendedProducts = [];
  List<GroupModel> allGroups = [];
  bool isLoadingGroups = true;
  bool isLoadingIngredients = true;
  List<ActiveIngredientModel> activeIngredients = [];
  List<GroupModel> medicationGroups = [];
  bool isLoadingMedicationGroups = true;

  // ── New state ─────────────────────────────────────────────────────────────
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchFocused = false;

  // ── Static lists (existing) ───────────────────────────────────────────────
  final TextEditingController searchController = TextEditingController();

  final List<String> skinTagsList = const [
    'Normal',
    'Dry',
    'Dehydrated',
    'Oily',
    'Combination',
    'Sensitive',
    'Rosacea',
    'Eczema',
    'Acne',
    'Psoriasis',
    'Melasma',
    'Contact dermatitis',
    'Keratosis pilaris',
    'Vitiligo',
    'Hyperpigmentation',
    'Anti-aging',
    'Dark circles',
    'Puffiness',
    'Dullness',
    'Razor bumps',
    'Enlarged pores',
    'Puffy under-eyes',
    'Milia',
    'Acne scars',
    'Sebaceous filaments',
  ];

  final List<String> productCategoryList = const [
    'After sun care',
    'Blemish treatment',
    'Body lotion',
    'Body wash',
    'Cleanser',
    'Complexion',
    'Exfoliator',
    'Eye treatment',
    'Face mask',
    'Face mist',
    'Face oil',
    'Foot treatment',
    'Fragrance',
    'Gel',
    'Hair conditioner',
    'Hair shampoo',
    'Hand treatment',
    'Injectable',
    'Lip treatment',
    'Moisturizer',
    'Scrub',
    'Serum',
    'Sunscreen',
    'Toner',
    'Tools',
  ];

  final List<String> activeIngredientsList = const [
    'Niacinamide',
    'Hyaluronic acid',
    'Salicylic acid',
    'Glycolic acid',
    'Lactic acid',
    'Vitamin C',
    'Retinol',
    'Adapalene',
    'Azelaic acid',
    'Ceramides',
    'Panthenol',
    'Centella asiatica',
    'Peptides',
    'Zinc',
    'Benzoyl peroxide',
  ];

  final List<String> concerns = const [
    'All',
    'Acne & Blemishes',
    'Dryness',
    'Redness',
    'Dark Spots',
    'Visible Pores',
    'Oiliness',
    'Dullness',
    'Uneven Texture',
  ];

  final List<String> categories = const ['All'];

  final List<String> skinTypes = const [
    'All',
    'Dry',
    'Oily',
    'Combination',
    'Sensitive',
    'Normal',
  ];

  // ── Computed getters ──────────────────────────────────────────────────────
  List<ActiveIngredientModel> get filteredIngredients {
    if (searchQuery.isEmpty) return activeIngredients;
    final q = searchQuery.toLowerCase();
    return activeIngredients
        .where((i) => i.name.toLowerCase().contains(q))
        .toList();
  }

  List<GroupModel> get filteredMedicationGroups {
    if (searchQuery.isEmpty) return medicationGroups;
    final q = searchQuery.toLowerCase();
    return medicationGroups
        .where((g) => g.title.toLowerCase().contains(q))
        .toList();
  }

  List<ProductModel> get filteredProducts {
    return allProducts.where((p) {
      final q = searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.shortDescription.toLowerCase().contains(q) ||
          p.brandOrigin.toLowerCase().contains(q);
      final matchesConcern = selectedConcern == 'All' ||
          p.recommendedFor.concerns.contains(selectedConcern);
      final matchesSkinType = selectedSkinType == 'All' ||
          p.recommendedFor.skinTypes.contains(selectedSkinType);
      return matchesSearch && matchesConcern && matchesSkinType;
    }).toList();
  }

  bool get _isFiltering => searchQuery.isNotEmpty || selectedConcern != 'All';

  int get _tipIndex => DateTime.now().hour % _skintips.length;

  // ── Data loading ──────────────────────────────────────────────────────────
  Future<void> loadMedicationGroups() async {
    try {
      final g = await ApiService.fetchGroupsByType("medications");
      if (!mounted) return;
      setState(() {
        medicationGroups = g;
        isLoadingMedicationGroups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingMedicationGroups = false);
    }
  }

  Future<void> loadActiveIngredients() async {
    try {
      final i = await ApiService.fetchActiveIngredients();
      if (!mounted) return;
      setState(() {
        activeIngredients = i;
        isLoadingIngredients = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingIngredients = false);
    }
  }

  Future<void> loadGroups() async {
    try {
      final g = await ApiService.fetchGroupsByType("product_categories");
      if (!mounted) return;
      setState(() {
        allGroups = g;
        isLoadingGroups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingGroups = false);
    }
  }

  // Future<void> loadCartCount() async {
  //   try {
  //     final result = await ApiService.fetchCart(widget.userId);
  //     if (result["statusCode"] == 200) {
  //       final items = (result["data"]["items"] ?? []) as List;
  //       int total = 0;
  //       for (final item in items) total += (item["quantity"] as int? ?? 1);
  //       if (!mounted) return;
  //       setState(() => cartCount = total);
  //     }
  //   } catch (_) {}
  // }

  Future<void> loadProducts() async {
    try {
      final p = await ApiService.fetchProducts();
      if (!mounted) return;
      setState(() {
        allProducts = p;
        recommendedProducts = _getRecommendedProducts(p);
        isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingProducts = false);
    }
  }

  List<ProductModel> _getRecommendedProducts(List<ProductModel> products) {
    final preferred = products
        .where((p) =>
            p.recommendedFor.skinTypes.contains('Sensitive') ||
            p.recommendedFor.skinTypes.contains('Dry') ||
            p.recommendedFor.concerns.contains('Dryness') ||
            p.recommendedFor.concerns.contains('Redness'))
        .toList();
    if (preferred.isNotEmpty) {
      preferred.sort((a, b) => b.rating.compareTo(a.rating));
      return preferred.take(6).toList();
    }
    final sorted = [...products]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(6).toList();
  }

  void _clearFilters() {
    setState(() {
      selectedConcern = 'All';
      selectedCategory = 'All';
      selectedSkinType = 'All';
      searchQuery = '';
      searchController.clear();
    });
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
    // loadCartCount();
    loadProducts();
    loadGroups();
    loadActiveIngredients();
    loadMedicationGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildSearchBar(),
                  ),
                  if (_searchFocused && searchQuery.isEmpty) ...[
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildPopularSearchSuggestions(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _buildTabBar(),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildTabContent(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Discover',
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: softText)),
                Text('Skincare · Ingredients · Medications',
                    style: GoogleFonts.poppins(fontSize: 12, color: mutedText)),
              ],
            ),
          ),
          // GestureDetector(
          //   onTap: () async {
          //     await Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //             builder: (_) => CartScreen(userId: widget.userId)));
          //     loadCartCount();
          //   },
          //   child: Stack(
          //     clipBehavior: Clip.none,
          //     children: [
          //       Container(
          //         width: 46,
          //         height: 46,
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //           borderRadius: BorderRadius.circular(14),
          //           border: Border.all(color: softBorder),
          //         ),
          //         child: const Icon(Icons.shopping_bag_outlined,
          //             color: wine, size: 22),
          //       ),
          //       if (cartCount > 0)
          //         Positioned(
          //           right: -3,
          //           top: -3,
          //           child: Container(
          //             width: 18,
          //             height: 18,
          //             decoration: const BoxDecoration(
          //                 color: wine, shape: BoxShape.circle),
          //             alignment: Alignment.center,
          //             child: Text('$cartCount',
          //                 style: GoogleFonts.poppins(
          //                     color: Colors.white,
          //                     fontSize: 9,
          //                     fontWeight: FontWeight.w700)),
          //           ),
          //         ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: whiteSmoke,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _searchFocused ? wine.withOpacity(0.4) : softBorder),
            ),
            child: TextField(
              controller: searchController,
              focusNode: _searchFocusNode,
              onChanged: (v) => setState(() => searchQuery = v),
              style: GoogleFonts.poppins(fontSize: 14, color: softText),
              decoration: InputDecoration(
                hintText: _searchHintText,
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: mutedText),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF7A7A7A), size: 22),
                suffixIcon: searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() {
                          searchQuery = '';
                          searchController.clear();
                        }),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: Color(0xFF7A7A7A)),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _searchHintText {
    switch (_tabController.index) {
      case 1:
        return 'Search ingredients e.g. niacinamide';
      case 2:
        return 'Search conditions e.g. acne';
      default:
        return 'Search products, brands…';
    }
  }

  // ── Popular search suggestions (shown when bar is focused + empty) ─────────
  Widget _buildPopularSearchSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Popular',
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: mutedText,
                letterSpacing: 0.4)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularSearches.map((term) {
            return GestureDetector(
              onTap: () => setState(() {
                searchQuery = term;
                searchController.text = term;
                _searchFocusNode.unfocus();
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: whiteSmoke,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: softBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded,
                        size: 13, color: wine.withOpacity(0.6)),
                    const SizedBox(width: 5),
                    Text(term,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: softText)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicator: UnderlineTabIndicator(
        borderSide: const BorderSide(width: 2, color: wine),
        insets: const EdgeInsets.symmetric(horizontal: 20),
      ),
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: wine,
      unselectedLabelColor: mutedText,
      labelStyle:
          GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400),
      splashFactory: NoSplash.splashFactory,
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      dividerColor: softBorder,
      tabs: const [
        Tab(text: 'Products'),
        Tab(text: 'Ingredients'),
        Tab(text: 'Medications'),
      ],
    );
  }

  // ── Tab content router ────────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildProductsTab();
      case 1:
        return _buildIngredientsTab();
      case 2:
        return _buildMedicationsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRODUCTS TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProductsTab() {
    if (isLoadingProducts) return _buildProductsSkeleton();
    if (_isFiltering) return _buildFilteredProductsView();
    return _buildProductsDiscoveryView();
  }

  Widget _buildProductsDiscoveryView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(),
        const SizedBox(height: 24),
        _buildSectionHeader('Explore by Concern'),
        const SizedBox(height: 14),
        _buildConcernChips(),
        const SizedBox(height: 26),
        _buildSectionHeader('Browse by Category'),
        const SizedBox(height: 14),
        _buildCategoryGrid(),
      ],
    );
  }

  Widget _buildFilteredProductsView() {
    final products = filteredProducts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active filter indicator
        if (selectedConcern != 'All') ...[
          _buildActiveFilterBadge(),
          const SizedBox(height: 16),
        ],
        if (products.isEmpty)
          _buildEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No products found',
            subtitle: 'Try a different search term or remove filters.',
            onClear: _clearFilters,
          )
        else ...[
          Text('${products.length} result${products.length == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(fontSize: 12, color: mutedText)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _productListTile(products[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveFilterBadge() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: wine.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(selectedConcern,
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600, color: wine)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => selectedConcern = 'All'),
                child: Icon(Icons.close_rounded, size: 14, color: wine),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Statistics row ─────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard(
          isLoadingProducts ? '—' : '${allProducts.length}+',
          'Products',
          Icons.inventory_2_outlined,
        ),
        const SizedBox(width: 10),
        _statCard(
          isLoadingIngredients ? '—' : '${activeIngredients.length}+',
          'Ingredients',
          Icons.science_outlined,
        ),
        const SizedBox(width: 10),
        _statCard(
          isLoadingMedicationGroups ? '—' : '${medicationGroups.length}+',
          'Conditions',
          Icons.medication_outlined,
        ),
      ],
    );
  }

  Widget _statCard(String count, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: whiteSmoke,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: softBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: wine),
            const SizedBox(height: 6),
            Text(count,
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: softText)),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 10, color: mutedText)),
          ],
        ),
      ),
    );
  }

  // ── Concern chips ──────────────────────────────────────────────────────────
  Widget _buildConcernChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _concernChips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = _concernChips[i];
          final isSelected = selectedConcern == chip['value'] as String;
          return GestureDetector(
            onTap: () => setState(() {
              selectedConcern = chip['value'] as String;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? wine : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? wine : softBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    chip['icon'] as IconData,
                    size: 14,
                    color: isSelected ? Colors.white : mutedText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    chip['label'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : softText,
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

  // ── Category grid (Products tab) ──────────────────────────────────────────
  Widget _buildCategoryGrid() {
    if (isLoadingGroups) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.75,
        children: List.generate(
            6, (_) => _Skeleton(height: double.infinity, radius: 18)),
      );
    }
    if (allGroups.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category_outlined,
        title: 'No categories yet',
        subtitle: 'Categories will appear here once available.',
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allGroups.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.75,
      ),
      itemBuilder: (_, i) {
        final g = allGroups[i];
        return _PressableCard(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupDetailsScreen(
                    groupSlug: g.slug,
                    userId: widget.userId,
                    userName: widget.userName),
              )),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: whiteSmoke,
              image: g.coverImage.isNotEmpty
                  ? DecorationImage(
                      image: g.coverImage.startsWith('http')
                          ? NetworkImage(g.coverImage)
                          : AssetImage(g.coverImage) as ImageProvider,
                      fit: BoxFit.cover,
                      opacity: 0.30,
                    )
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.28)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(14),
              child: Text(g.title,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        );
      },
    );
  }

  // ── Products skeleton ─────────────────────────────────────────────────────
  Widget _buildProductsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: _Skeleton(height: 72, radius: 16)),
          const SizedBox(width: 10),
          Expanded(child: _Skeleton(height: 72, radius: 16)),
          const SizedBox(width: 10),
          Expanded(child: _Skeleton(height: 72, radius: 16)),
        ]),
        const SizedBox(height: 22),
        _Skeleton(width: 140, height: 18, radius: 8),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, __) =>
                _Skeleton(width: 90, height: 40, radius: 20),
          ),
        ),
        const SizedBox(height: 22),
        _Skeleton(width: 160, height: 18, radius: 8),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.75,
          children: List.generate(
              6, (_) => _Skeleton(height: double.infinity, radius: 18)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INGREDIENTS TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildIngredientsTab() {
    if (isLoadingIngredients) return _buildIngredientsSkeleton();
    if (searchQuery.isNotEmpty) return _buildFilteredIngredientsView();
    return _buildIngredientsDiscoveryView();
  }

  Widget _buildIngredientsDiscoveryView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDidYouKnowCard(),
        const SizedBox(height: 24),
        if (activeIngredients.isNotEmpty) ...[
          _buildSectionHeader('Popular Ingredients'),
          const SizedBox(height: 14),
          _buildPopularIngredientsScroll(),
          const SizedBox(height: 26),
          _buildSectionHeader('All Ingredients'),
          const SizedBox(height: 14),
        ],
        _buildIngredientsGridFrom(activeIngredients),
      ],
    );
  }

  Widget _buildFilteredIngredientsView() {
    final items = filteredIngredients;
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.science_outlined,
        title: 'No ingredients found',
        subtitle: 'Try a different ingredient name.',
        onClear: () => setState(() {
          searchQuery = '';
          searchController.clear();
        }),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${items.length} result${items.length == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(fontSize: 12, color: mutedText)),
        const SizedBox(height: 12),
        _buildIngredientsGridFrom(items),
      ],
    );
  }

  // ── Did You Know card ─────────────────────────────────────────────────────
  Widget _buildDidYouKnowCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B2333), Color(0xFF8B3A50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                      Text('Skincare Tip',
                          style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _skintips[_tipIndex],
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: Colors.white,
                  height: 1.55,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  // ── Popular ingredients horizontal scroll ─────────────────────────────────
  Widget _buildPopularIngredientsScroll() {
    final popular = activeIngredients.take(6).toList();
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: popular.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final ing = popular[i];
          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IngredientDetailsScreen(
                      slug: ing.slug,
                      userId: widget.userId,
                      userName: widget.userName),
                )),
            child: Container(
              width: 130,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: whiteSmoke,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: softBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: wine.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.science_outlined, size: 14, color: wine),
                  ),
                  Text(ing.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: softText,
                          height: 1.3)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Ingredients grid ──────────────────────────────────────────────────────
  Widget _buildIngredientsGridFrom(List<ActiveIngredientModel> items) {
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.science_outlined,
        title: 'No ingredients yet',
        subtitle: 'Ingredient library will appear here.',
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.75,
      ),
      itemBuilder: (_, i) {
        final ing = items[i];
        return _PressableCard(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IngredientDetailsScreen(
                    slug: ing.slug,
                    userId: widget.userId,
                    userName: widget.userName),
              )),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: whiteSmoke,
              image: ing.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: ing.imageUrl.startsWith('http')
                          ? NetworkImage(ing.imageUrl)
                          : AssetImage(ing.imageUrl) as ImageProvider,
                      fit: BoxFit.cover,
                      opacity: 0.28,
                    )
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [Colors.transparent, wine.withOpacity(0.22)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(14),
              child: Text(ing.name,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: softText)),
            ),
          ),
        );
      },
    );
  }

  // ── Ingredients skeleton ──────────────────────────────────────────────────
  Widget _buildIngredientsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Skeleton(height: 90, radius: 20),
        const SizedBox(height: 22),
        _Skeleton(width: 170, height: 18, radius: 8),
        const SizedBox(height: 14),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) =>
                _Skeleton(width: 130, height: 90, radius: 16),
          ),
        ),
        const SizedBox(height: 22),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.75,
          children: List.generate(
              6, (_) => _Skeleton(height: double.infinity, radius: 18)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MEDICATIONS TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMedicationsTab() {
    if (isLoadingMedicationGroups) return _buildMedicationsSkeleton();
    if (searchQuery.isNotEmpty) return _buildFilteredMedicationsView();
    return _buildMedicationsDiscoveryView();
  }

  Widget _buildMedicationsDiscoveryView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConditionsInfoCard(),
        const SizedBox(height: 24),
        _buildSectionHeader('Skin Condition Groups'),
        const SizedBox(height: 14),
        _buildMedicationGroupsGridFrom(medicationGroups),
      ],
    );
  }

  Widget _buildFilteredMedicationsView() {
    final items = filteredMedicationGroups;
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.medication_outlined,
        title: 'No conditions found',
        subtitle: 'Try a different condition name.',
        onClear: () => setState(() {
          searchQuery = '';
          searchController.clear();
        }),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${items.length} result${items.length == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(fontSize: 12, color: mutedText)),
        const SizedBox(height: 12),
        _buildMedicationGroupsGridFrom(items),
      ],
    );
  }

  Widget _buildConditionsInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: whiteSmoke,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: softBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: wine.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.info_outline_rounded, color: wine, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Skin Condition Library',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: softText)),
                const SizedBox(height: 3),
                Text(
                    'Browse conditions, learn about treatments, and find relevant products.',
                    style: GoogleFonts.poppins(
                        fontSize: 11.5, color: mutedText, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationGroupsGridFrom(List<GroupModel> items) {
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.medication_outlined,
        title: 'No groups yet',
        subtitle: 'Skin condition groups will appear here.',
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.75,
      ),
      itemBuilder: (_, i) {
        final g = items[i];
        return _PressableCard(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupDetailsScreen(
                    groupSlug: g.slug,
                    userId: widget.userId,
                    userName: widget.userName),
              )),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: whiteSmoke,
              image: g.coverImage.isNotEmpty
                  ? DecorationImage(
                      image: g.coverImage.startsWith('http')
                          ? NetworkImage(g.coverImage)
                          : AssetImage(g.coverImage) as ImageProvider,
                      fit: BoxFit.cover,
                      opacity: 0.30,
                    )
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.28)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(14),
              child: Text(g.title,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMedicationsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Skeleton(height: 84, radius: 20),
        const SizedBox(height: 22),
        _Skeleton(width: 190, height: 18, radius: 8),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.75,
          children: List.generate(
              4, (_) => _Skeleton(height: double.infinity, radius: 18)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED COMPONENTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600, color: softText));
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                  color: wine.withOpacity(0.07), shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: wine.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: softText)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12.5, color: mutedText)),
            if (onClear != null) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(foregroundColor: wine),
                child: Text('Clear Search',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRODUCT LIST TILE (existing, kept)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _productListTile(ProductModel product) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
                product: product,
                userId: widget.userId,
                userName: widget.userName),
          )),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: wine.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
                color: wine.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: const Color(0xFFF6F1F0),
                    borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: product.imageUrl.isNotEmpty
                    ? Hero(
                        tag: product.id,
                        child: Image.network(product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported_outlined,
                                size: 26,
                                color: Colors.black38)))
                    : const Icon(Icons.image_outlined,
                        size: 26, color: Colors.black38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: wine.withOpacity(0.58))),
                    const SizedBox(height: 2),
                    Text(product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: softText,
                            height: 1.35)),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        if (product.recommendedFor.skinTypes.isNotEmpty)
                          _miniTag(product.recommendedFor.skinTypes.first),
                        if (product.recommendedFor.concerns.isNotEmpty)
                          _miniTag(product.recommendedFor.concerns.first),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 15, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(product.rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                                fontSize: 11.5, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text('${product.reviews.length} reviews',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: mutedText)),
                      ],
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

  Widget _miniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF7F2F1),
          borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w500, color: wine)),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILTER BOTTOM SHEETS (existing, unchanged)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _sheetHandle() {
    return Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
            color: const Color(0xFFE5E5E5),
            borderRadius: BorderRadius.circular(20)));
  }

  Widget _sheetHeader(
      {required String title,
      required VoidCallback onClose,
      required VoidCallback onDone}) {
    return Column(
      children: [
        const SizedBox(height: 10),
        _sheetHandle(),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close_rounded,
                      size: 32, color: Color(0xFFB9B9B9))),
              Expanded(
                child: Center(
                  child: Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: softText)),
                ),
              ),
              GestureDetector(
                  onTap: onDone,
                  child: const Icon(Icons.check_rounded,
                      size: 32, color: Color(0xFFB9B9B9))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFE9E9E9)),
      ],
    );
  }

  Widget _filterMainRow({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Expanded(
                child: Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: softText))),
            const Icon(Icons.chevron_right_rounded,
                size: 30, color: Color(0xFF2F2F2F)),
          ],
        ),
      ),
    );
  }

  Widget _customCheckBox(bool isSelected) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
          color: isSelected ? wine : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isSelected ? wine : const Color(0xFF6F6F6F), width: 1.8)),
      child: isSelected
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : null,
    );
  }

  Widget _multiSelectRow(
      {required String title,
      required bool isSelected,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Row(
          children: [
            Expanded(
                child: Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: softText,
                        height: 1.2))),
            _customCheckBox(isSelected),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.50,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _sheetHandle(),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPriceRange = const RangeValues(0, 100);
                        selectedRatingRange = const RangeValues(0, 5);
                        selectedSkinTags.clear();
                        selectedProductCategories.clear();
                        selectedActiveIngredients.clear();
                        personalizedAiRecommendations = false;
                      });
                    },
                    child: Text('Reset',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: mutedText)),
                  ),
                  Expanded(
                    child: Center(
                        child: Text('Search filters',
                            style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: softText))),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Apply',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: mutedText)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE9E9E9)),
            Expanded(
              child: ListView(
                children: [
                  _filterMainRow(title: 'Price', onTap: _showPriceSheet),
                  _filterMainRow(title: 'Rating', onTap: _showRatingSheet),
                  _filterMainRow(
                    title: 'Skin tags',
                    onTap: () => _showMultiSelectSheet(
                        title: 'Skin tags',
                        items: skinTagsList,
                        selectedItems: selectedSkinTags,
                        onApply: (v) => setState(() => selectedSkinTags = v)),
                  ),
                  _filterMainRow(
                    title: 'Active ingredients',
                    onTap: () => _showMultiSelectSheet(
                        title: 'Active ingredients',
                        items: activeIngredientsList,
                        selectedItems: selectedActiveIngredients,
                        onApply: (v) =>
                            setState(() => selectedActiveIngredients = v)),
                  ),
                  _filterMainRow(
                    title: 'Product category',
                    onTap: () => _showMultiSelectSheet(
                        title: 'Product category',
                        items: productCategoryList,
                        selectedItems: selectedProductCategories,
                        onApply: (v) =>
                            setState(() => selectedProductCategories = v)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMultiSelectSheet({
    required String title,
    required List<String> items,
    required List<String> selectedItems,
    required ValueChanged<List<String>> onApply,
  }) {
    List<String> tempSelected = List<String>.from(selectedItems);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            children: [
              _sheetHeader(
                  title: title,
                  onClose: () => Navigator.pop(context),
                  onDone: () {
                    onApply(tempSelected);
                    Navigator.pop(context);
                  }),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 6, bottom: 10),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final sel = tempSelected.contains(item);
                    return _multiSelectRow(
                      title: item,
                      isSelected: sel,
                      onTap: () => setModalState(() {
                        sel
                            ? tempSelected.remove(item)
                            : tempSelected.add(item);
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriceSheet() {
    RangeValues tempRange = selectedPriceRange;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.34,
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            children: [
              _sheetHeader(
                  title: 'Price',
                  onClose: () => Navigator.pop(context),
                  onDone: () {
                    setState(() => selectedPriceRange = tempRange);
                    Navigator.pop(context);
                  }),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('£${tempRange.start.round()}',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    Text(
                        tempRange.end.round() >= 100
                            ? '£100+'
                            : '£${tempRange.end.round()}',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    activeTrackColor: sliderBlue,
                    inactiveTrackColor: const Color(0xFFC8C8C8),
                    thumbColor: sliderBlue,
                    overlayColor: sliderBlue.withOpacity(0.12),
                    trackHeight: 6,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10)),
                child: RangeSlider(
                    values: tempRange,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (v) => setModalState(() => tempRange = v)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRatingSheet() {
    RangeValues tempRange = selectedRatingRange;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.34,
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            children: [
              _sheetHeader(
                  title: 'Rating',
                  onClose: () => Navigator.pop(context),
                  onDone: () {
                    setState(() => selectedRatingRange = tempRange);
                    Navigator.pop(context);
                  }),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${tempRange.start.round()} stars',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('${tempRange.end.round()} stars',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    activeTrackColor: sliderBlue,
                    inactiveTrackColor: const Color(0xFFC8C8C8),
                    thumbColor: sliderBlue,
                    overlayColor: sliderBlue.withOpacity(0.12),
                    trackHeight: 6,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10)),
                child: RangeSlider(
                    values: tempRange,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    onChanged: (v) => setModalState(() => tempRange = v)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton loader ───────────────────────────────────────────────────────────
class _Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  const _Skeleton({this.width, required this.height, this.radius = 8});

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.45, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E5E2),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

// ── Pressable card ────────────────────────────────────────────────────────────
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
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
