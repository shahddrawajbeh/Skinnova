import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scan_page.dart';
import 'search_page.dart';
import 'ask_ai_page.dart';
import 'compare_page.dart';
import 'analyze_page.dart';
import 'cart_screen.dart';
import '../api_service.dart';
import '../product_model.dart';
import 'product_details_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'group_details_screen.dart';
import '../group_model.dart';
import '../active_ingredient_model.dart';
import 'ingredient_details_screen.dart';
import 'scan_page.dart';

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
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color wine = Color(0xFF5B2333);

  String selectedConcern = 'All';
  String selectedCategory = 'All';
  String selectedSkinType = 'All';
  String searchQuery = '';
  int cartCount = 0;
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
  Future<void> loadMedicationGroups() async {
    try {
      final loadedGroups = await ApiService.fetchGroupsByType("medications");

      if (!mounted) return;

      setState(() {
        medicationGroups = loadedGroups;
        isLoadingMedicationGroups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingMedicationGroups = false;
      });
      debugPrint("Load medication groups error: $e");
    }
  }

  Future<void> loadActiveIngredients() async {
    try {
      final loadedIngredients = await ApiService.fetchActiveIngredients();

      if (!mounted) return;

      setState(() {
        activeIngredients = loadedIngredients;
        isLoadingIngredients = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingIngredients = false;
      });
      debugPrint("Load ingredients error: $e");
    }
  }

  Future<void> loadGroups() async {
    try {
      final loadedGroups =
          await ApiService.fetchGroupsByType("product_categories");

      if (!mounted) return;

      setState(() {
        allGroups = loadedGroups;
        isLoadingGroups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingGroups = false;
      });
      debugPrint("Load groups error: $e");
    }
  }

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

  final List<String> categories = const [
    'All',
  ];

  final List<String> skinTypes = const [
    'All',
    'Dry',
    'Oily',
    'Combination',
    'Sensitive',
    'Normal',
  ];

  List<Map<String, dynamic>> get quickActions => [
        {
          'title': 'Scan',
          'icon': 'assets/icons/scan.svg',
          'page': ScanPage(
            userId: widget.userId,
            userName: widget.userName,
          ),
        },
        {
          'title': 'Compare',
          'icon': 'assets/icons/compare.svg',
          'page': const ComparePage(),
        },
        {
          'title': 'Analyze',
          'icon': 'assets/icons/analyze.svg',
          'page': const AnalyzePage(),
        },
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    loadCartCount();
    loadProducts();
    loadGroups();
    loadActiveIngredients();
    loadMedicationGroups();
  }

  Future<void> loadCartCount() async {
    try {
      final result = await ApiService.fetchCart(widget.userId);

      if (result["statusCode"] == 200) {
        final data = result["data"];
        final items = data["items"] ?? [];

        int totalCount = 0;
        for (final item in items) {
          totalCount += (item["quantity"] as int? ?? 1);
        }

        if (!mounted) return;
        setState(() {
          cartCount = totalCount;
        });
      }
    } catch (_) {}
  }

  Future<void> loadProducts() async {
    try {
      final loadedProducts = await ApiService.fetchProducts();

      if (!mounted) return;

      setState(() {
        allProducts = loadedProducts;
        recommendedProducts = _getRecommendedProducts(loadedProducts);
        isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingProducts = false;
      });
      debugPrint("Load products error: $e");
    }
  }

  List<ProductModel> _getRecommendedProducts(List<ProductModel> products) {
    final preferred = products.where((product) {
      return product.recommendedFor.skinTypes.contains('Sensitive') ||
          product.recommendedFor.skinTypes.contains('Dry') ||
          product.recommendedFor.concerns.contains('Dryness') ||
          product.recommendedFor.concerns.contains('Redness');
    }).toList();

    if (preferred.isNotEmpty) {
      preferred.sort((a, b) => b.rating.compareTo(a.rating));
      return preferred.take(6).toList();
    }

    final sorted = [...products];
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(6).toList();
  }

  List<ProductModel> get featuredPicks => recommendedProducts;

  List<ProductModel> get filteredProducts {
    return allProducts.where((p) {
      final name = p.name.toLowerCase();
      final brand = p.brand.toLowerCase();
      final description = p.shortDescription.toLowerCase();
      final origin = p.brandOrigin.toLowerCase();
      final query = searchQuery.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          brand.contains(query) ||
          description.contains(query) ||
          origin.contains(query);

      final matchesConcern = selectedConcern == 'All' ||
          p.recommendedFor.concerns.contains(selectedConcern);

      final matchesCategory = selectedCategory == 'All';

      final matchesSkinType = selectedSkinType == 'All' ||
          p.recommendedFor.skinTypes.contains(selectedSkinType);

      return matchesSearch &&
          matchesConcern &&
          matchesCategory &&
          matchesSkinType;
    }).toList();
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

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Widget _buildTopTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(
              width: 2,
              color: Color(0xFF202124),
            ),
            insets: EdgeInsets.symmetric(horizontal: 28),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: const Color(0xFF202124),
          unselectedLabelColor: const Color(0xFF9B9B9B),
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          splashFactory: NoSplash.splashFactory,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          dividerColor: const Color(0xFFEAEAEA),
          tabs: const [
            Tab(text: "Products"),
            Tab(text: "Ingredients"),
            Tab(text: "Medications"),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoadingProducts
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const SizedBox(width: 48),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Products',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF202124),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CartScreen(userId: widget.userId),
                                    ),
                                  );
                                  loadCartCount();
                                },
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: const Color(0xFFEAEAEA)),
                                      ),
                                      child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Color(0xFF5B2333),
                                        size: 22,
                                      ),
                                    ),
                                    if (cartCount > 0)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF8C4B5F),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$cartCount',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildQuickActions(),
                          const SizedBox(height: 18),
                          _buildSearchAndFilterBar(),
                          const SizedBox(height: 14),
                          _buildTopTabs(),
                          const SizedBox(height: 24),
                          if (_tabController.index == 0) ...[
                            Text(
                              'Search by category',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF202124),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildCategoryGrid(),
                          ] else if (_tabController.index == 1) ...[
                            Text(
                              'Browse ingredients',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF202124),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildIngredientsGrid(),
                          ] else ...[
                            Text(
                              'Skin condition groups',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF202124),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildMedicationGroupsGrid(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String get searchHintText {
    switch (_tabController.index) {
      case 0:
        return "Search products e.g. simple cleanser";
      case 1:
        return "Search ingredients e.g. niacinamide";
      case 2:
        return "Search medications e.g. adapalene";
      default:
        return "Search";
    }
  }

  Widget _buildMedicationGroupsGrid() {
    if (isLoadingMedicationGroups) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (medicationGroups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "No medication groups found",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF202124),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medicationGroups.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.75,
      ),
      itemBuilder: (context, index) {
        final group = medicationGroups[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupDetailsScreen(
                  groupSlug: group.slug,
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFFF6F4F2),
              image: group.coverImage.isNotEmpty
                  ? DecorationImage(
                      image: group.coverImage.startsWith("http")
                          ? NetworkImage(group.coverImage)
                          : AssetImage(group.coverImage) as ImageProvider,
                      fit: BoxFit.cover,
                      opacity: 0.35,
                    )
                  : null,
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(16),
            child: Text(
              group.title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF202124),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIngredientsGrid() {
    if (isLoadingIngredients) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (activeIngredients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "No ingredients found",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF202124),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeIngredients.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.75,
      ),
      itemBuilder: (context, index) {
        final ingredient = activeIngredients[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IngredientDetailsScreen(
                  slug: ingredient.slug,
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFFF7F4F3),
              image: ingredient.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: ingredient.imageUrl.startsWith("http")
                          ? NetworkImage(ingredient.imageUrl)
                          : AssetImage(ingredient.imageUrl) as ImageProvider,
                      fit: BoxFit.cover,
                      opacity: 0.35,
                    )
                  : null,
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(16),
            child: Text(
              "${ingredient.name} ",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF202124),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF202124),
              ),
              decoration: InputDecoration(
                hintText: searchHintText,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF9B9B9B),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF7A7A7A),
                  size: 24,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            _showFilterBottomSheet();
          },
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF2F3A4A),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _sheetHeader({
    required String title,
    required VoidCallback onClose,
    required VoidCallback onDone,
  }) {
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
                child: const Icon(
                  Icons.close_rounded,
                  size: 32,
                  color: Color(0xFFB9B9B9),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: softText,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDone,
                child: const Icon(
                  Icons.check_rounded,
                  size: 32,
                  color: Color(0xFFB9B9B9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: softBorder),
      ],
    );
  }

  Widget _filterMainRow({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: softText,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 30,
              color: Color(0xFF2F2F2F),
            ),
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
          color: isSelected ? wine : const Color(0xFF6F6F6F),
          width: 1.8,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              size: 18,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _multiSelectRow({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: softText,
                  height: 1.2,
                ),
              ),
            ),
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
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.50,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
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
                      child: Text(
                        'Reset',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: mutedText,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Search filters',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: softText,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: softBorder),
              Expanded(
                child: ListView(
                  children: [
                    _filterMainRow(
                      title: 'Price',
                      onTap: _showPriceSheet,
                    ),
                    _filterMainRow(
                      title: 'Rating',
                      onTap: _showRatingSheet,
                    ),
                    _filterMainRow(
                      title: 'Skin tags',
                      onTap: () => _showMultiSelectSheet(
                        title: 'Skin tags',
                        items: skinTagsList,
                        selectedItems: selectedSkinTags,
                        onApply: (values) {
                          setState(() => selectedSkinTags = values);
                        },
                      ),
                    ),
                    _filterMainRow(
                      title: 'Active ingredients',
                      onTap: () => _showMultiSelectSheet(
                        title: 'Active ingredients',
                        items: activeIngredientsList,
                        selectedItems: selectedActiveIngredients,
                        onApply: (values) {
                          setState(() => selectedActiveIngredients = values);
                        },
                      ),
                    ),
                    _filterMainRow(
                      title: 'Product category',
                      onTap: () => _showMultiSelectSheet(
                        title: 'Product category',
                        items: productCategoryList,
                        selectedItems: selectedProductCategories,
                        onApply: (values) {
                          setState(() => selectedProductCategories = values);
                        },
                      ),
                    ),
                    _filterMainRow(
                      title: 'Personalized AI recommendations',
                      onTap: () {
                        setState(() {
                          personalizedAiRecommendations =
                              !personalizedAiRecommendations;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  _sheetHeader(
                    title: title,
                    onClose: () => Navigator.pop(context),
                    onDone: () {
                      onApply(tempSelected);
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 6, bottom: 10),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = tempSelected.contains(item);

                        return _multiSelectRow(
                          title: item,
                          isSelected: isSelected,
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                tempSelected.remove(item);
                              } else {
                                tempSelected.add(item);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPriceSheet() {
    RangeValues tempRange = selectedPriceRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.34,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  _sheetHeader(
                    title: 'Price',
                    onClose: () => Navigator.pop(context),
                    onDone: () {
                      setState(() => selectedPriceRange = tempRange);
                      Navigator.pop(context);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '£${tempRange.start.round()}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          tempRange.end.round() >= 100
                              ? '£100+'
                              : '£${tempRange.end.round()}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: sliderBlue,
                      inactiveTrackColor: const Color(0xFFC8C8C8),
                      thumbColor: sliderBlue,
                      overlayColor: sliderBlue.withOpacity(0.12),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: RangeSlider(
                      values: tempRange,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: (values) {
                        setModalState(() {
                          tempRange = values;
                        });
                      },
                    ),
                  ),
                  // const SizedBox(height: 18),
                  // Text(
                  //   '24,114 products',
                  //   style: GoogleFonts.poppins(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w500,
                  //     color: const Color(0xFF383838),
                  //   ),
                  // ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRatingSheet() {
    RangeValues tempRange = selectedRatingRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.34,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  _sheetHeader(
                    title: 'Rating',
                    onClose: () => Navigator.pop(context),
                    onDone: () {
                      setState(() => selectedRatingRange = tempRange);
                      Navigator.pop(context);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${tempRange.start.round()} stars',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${tempRange.end.round()} stars',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: sliderBlue,
                      inactiveTrackColor: const Color(0xFFC8C8C8),
                      thumbColor: sliderBlue,
                      overlayColor: sliderBlue.withOpacity(0.12),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: RangeSlider(
                      values: tempRange,
                      min: 0,
                      max: 5,
                      divisions: 5,
                      onChanged: (values) {
                        setModalState(() {
                          tempRange = values;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static const Color softBorder = Color(0xFFE9E9E9);
  static const Color softText = Color(0xFF202124);
  static const Color mutedText = Color(0xFFB7B7B7);
  static const Color sliderBlue = Color(0xFF3A99F5);

  Widget _buildCategoryGrid() {
    if (isLoadingGroups) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (allGroups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "No groups found",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF202124),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allGroups.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.75,
      ),
      itemBuilder: (context, index) {
        final group = allGroups[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupDetailsScreen(
                  groupSlug: group.slug,
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFFF6F4F2),
              image: group.coverImage.isNotEmpty
                  ? DecorationImage(
                      image: group.coverImage.startsWith("http")
                          ? NetworkImage(group.coverImage)
                          : AssetImage(group.coverImage) as ImageProvider,
                      fit: BoxFit.cover,
                      opacity: 0.35,
                    )
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.20),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(16),
              child: Text(
                group.title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF202124),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _categoryCircles() {
    final categories = [
      {
        'title': 'Cleanser',
        'icon': Icons.bubble_chart_outlined,
      },
      {
        'title': 'Serum',
        'icon': Icons.water_drop_outlined,
      },
      {
        'title': 'Moisturizer',
        'icon': Icons.spa_outlined,
      },
      {
        'title': 'Sunscreen',
        'icon': Icons.wb_sunny_outlined,
      },
      {
        'title': 'Eye Care',
        'icon': Icons.remove_red_eye_outlined,
      },
    ];

    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final item = categories[index];
          return _categoryCircleItem(
            item['title'] as String,
            item['icon'] as IconData,
          );
        },
      ),
    );
  }

  Widget _categoryCircleItem(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchPage(
              initialCategory: title,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 86,
        child: Column(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: wine.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: wine.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: wine,
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3B2B2B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(String iconPath) {
    if (iconPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
      );
    } else {
      return Image.asset(
        iconPath,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
      );
    }
  }

  Widget _buildQuickActions() {
    const Color borderColor = Color(0xFFE8E8E8);
    const Color textDark = Color(0xFF2F3A4A);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: quickActions.map((item) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => item['page'] as Widget,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: borderColor,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: _buildActionIcon(item['icon'] as String),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFinderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: wine.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: wine.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find your perfect match',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: wine,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Search and filter products based on your skin needs.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: wine.withOpacity(0.58),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search products, brands, or ingredients',
              hintStyle: GoogleFonts.poppins(
                color: wine.withOpacity(0.38),
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: wine),
              filled: true,
              fillColor: const Color(0xFFF8F5F4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 14),
          _filterLabel('Concern'),
          const SizedBox(height: 8),
          _chipSelector(
            items: concerns,
            selectedValue: selectedConcern,
            onSelected: (value) {
              setState(() {
                selectedConcern = value;
              });
            },
          ),
          const SizedBox(height: 14),
          _filterLabel('Category'),
          const SizedBox(height: 8),
          _chipSelector(
            items: categories,
            selectedValue: selectedCategory,
            onSelected: (value) {
              setState(() {
                selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 14),
          _filterLabel('Skin Type'),
          const SizedBox(height: 8),
          _chipSelector(
            items: skinTypes,
            selectedValue: selectedSkinType,
            onSelected: (value) {
              setState(() {
                selectedSkinType = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _clearFilters,
              child: Text(
                'Clear Filters',
                style: GoogleFonts.poppins(
                  color: wine,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: wine,
      ),
    );
  }

  Widget _chipSelector({
    required List<String> items,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: items.map((item) {
        final selected = item == selectedValue;

        return GestureDetector(
          onTap: () => onSelected(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? wine : const Color(0xFFF7F2F1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selected ? wine : wine.withOpacity(0.08),
              ),
            ),
            child: Text(
              item,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : wine,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String title, String trailing) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.marcellus(
              fontSize: 22,
              color: wine,
            ),
          ),
        ),
        Text(
          trailing,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: wine.withOpacity(0.55),
          ),
        ),
      ],
    );
  }

  Widget _horizontalProducts(List<ProductModel> products) {
    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: wine.withOpacity(0.08)),
        ),
        child: Text(
          'No recommendations available yet.',
          style: GoogleFonts.poppins(
            color: wine.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) => _recommendedProductCard(products[index]),
      ),
    );
  }

  Widget _recommendedProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
              product: product,
              userId: widget.userId,
              userName: widget.userName,
            ),
          ),
        );
      },
      child: Container(
        width: 175,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            size: 30,
                            color: Colors.black38,
                          ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          size: 30,
                          color: Colors.black38,
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                product.brand,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withOpacity(0.45),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '\$${product.price.toStringAsFixed(1)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF202124),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallSoftTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: whiteSmoke,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: wine,
        ),
      ),
    );
  }

  Widget _productListTile(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
              product: product,
              userId: widget.userId,
              userName: widget.userName ?? "Anonymous",
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: wine.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: wine.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F1F0),
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: product.imageUrl.isNotEmpty
                    ? Hero(
                        tag: product.id,
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            size: 28,
                            color: Colors.black38,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.image_outlined,
                        size: 28,
                        color: Colors.black38,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: wine.withOpacity(0.58),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF202124),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (product.recommendedFor.skinTypes.isNotEmpty)
                          _miniTag(product.recommendedFor.skinTypes.first),
                        if (product.recommendedFor.concerns.isNotEmpty)
                          _miniTag(product.recommendedFor.concerns.first),
                        if (product.whatsInside.fragranceFree)
                          _miniTag('Fragrance Free'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${product.reviews.length} reviews',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: wine.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${product.price.toStringAsFixed(0)} ${product.currency}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: wine,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: product.inStock
                          ? const Color(0xFFEFF7EF)
                          : const Color(0xFFF8ECEC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      product.inStock ? 'In stock' : 'Out',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: product.inStock
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: wine,
        ),
      ),
    );
  }
}

class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableCard({
    required this.child,
    required this.onTap,
  });

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() {
        _pressed = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
            0,
            _pressed ? 2 : 0,
            0,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
