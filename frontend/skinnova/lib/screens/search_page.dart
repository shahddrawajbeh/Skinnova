import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skincare_finder_page.dart';
import '../product_model.dart';
import '../api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_details_screen.dart';

class SearchPage extends StatefulWidget {
  final String? initialCategory;

  const SearchPage({
    super.key,
    this.initialCategory,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const Color bgColor = Color(0xFFF7F4F3);
  static const Color cardColor = Color(0xFFF7F4F3);
  static const Color softRose = Color(0xFFF7F4F3);
  static const Color deepRose = Color(0xFF5B2333);
  static const Color darkRose = Color(0xFF5B2333);
  static const Color textDark = Color(0xFF111111);
  static const Color lineColor = Color(0xFFF7F4F3);

  Set<String> favoriteIds = {};
  String? currentUserId;
  String selectedCategory = 'All';
  String? currentUserName;
  List<String> selectedSteps = [];
  List<String> selectedSkinTypes = [];
  List<String> selectedConcerns = [];
  final TextEditingController searchController = TextEditingController();
  Future<void> loadUserAndFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    final userName = prefs.getString("userName");

    if (userId == null) return;

    currentUserId = userId;
    currentUserName = userName;

    try {
      final favoriteProducts = await ApiService.fetchFavorites(userId);
      setState(() {
        favoriteIds = favoriteProducts.map((e) => e.id).toSet();
      });
    } catch (e) {
      print("Favorites load error: $e");
    }
  }

  Future<void> toggleFavorite(ProductModel product) async {
    if (currentUserId == null) return;

    try {
      final result = await ApiService.toggleFavorite(
        userId: currentUserId!,
        productId: product.id,
      );

      if (result["statusCode"] == 200) {
        final isFavorite = result["data"]["isFavorite"];

        setState(() {
          if (isFavorite == true) {
            favoriteIds.add(product.id);
          } else {
            favoriteIds.remove(product.id);
          }
        });
      }
    } catch (e) {
      print("Toggle favorite error: $e");
    }
  }

  final List<String> categories = const [
    'All',
  ];
  List<ProductModel> products = [];
  bool isLoading = true;
  String? errorMessage;
  bool matchesCategoryFromTitle(ProductModel product, String category) {
    final name = product.name.toLowerCase();
    final desc = product.shortDescription.toLowerCase();
    final c = category.toLowerCase();

    if (c == 'cleanser') {
      return name.contains('cleanser') ||
          name.contains('foam') ||
          name.contains('gel cleanser') ||
          desc.contains('cleanser');
    }

    if (c == 'oil cleanser') {
      return name.contains('cleansing oil') ||
          name.contains('oil cleanser') ||
          name.contains('cleansing balm') ||
          desc.contains('cleansing oil') ||
          desc.contains('cleansing balm');
    }

    if (c == 'serum / essence') {
      return name.contains('serum') ||
          name.contains('essence') ||
          name.contains('ampoule') ||
          desc.contains('serum') ||
          desc.contains('essence') ||
          desc.contains('ampoule');
    }

    if (c == 'moisturizer') {
      return name.contains('cream') ||
          name.contains('moisturizer') ||
          name.contains('gel cream') ||
          desc.contains('moisturizer');
    }

    if (c == 'sunscreen') {
      return name.contains('sun') ||
          name.contains('spf') ||
          desc.contains('sunscreen') ||
          desc.contains('spf');
    }

    if (c == 'eye care') {
      return name.contains('eye') || desc.contains('eye');
    }

    return false;
  }

  List<ProductModel> get filteredProducts {
    return products.where((product) {
      final query = searchController.text.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          product.brand.toLowerCase().contains(query) ||
          product.name.toLowerCase().contains(query) ||
          product.shortDescription.toLowerCase().contains(query) ||
          product.brandOrigin.toLowerCase().contains(query);

      final productName = product.name.toLowerCase();
      final productDesc = product.shortDescription.toLowerCase();

      final matchesStep = selectedSteps.isEmpty ||
          selectedSteps.any((step) {
            final s = step.toLowerCase();

            if (s == 'cleanser') {
              return productName.contains('cleanser') ||
                  productName.contains('foam') ||
                  productName.contains('gel') ||
                  productDesc.contains('cleanser');
            }

            if (s == 'oil cleanser') {
              return productName.contains('cleansing oil') ||
                  productName.contains('oil cleanser') ||
                  productDesc.contains('cleansing oil');
            }

            if (s == 'toner') {
              return productName.contains('toner') ||
                  productDesc.contains('toner');
            }

            if (s == 'serum') {
              return productName.contains('serum') ||
                  productName.contains('ampoule') ||
                  productName.contains('essence') ||
                  productDesc.contains('serum') ||
                  productDesc.contains('ampoule') ||
                  productDesc.contains('essence');
            }

            if (s == 'moisturizer') {
              return productName.contains('cream') ||
                  productName.contains('moisturizer') ||
                  productName.contains('gel cream') ||
                  productDesc.contains('moisturizer');
            }

            if (s == 'sunscreen') {
              return productName.contains('sun') ||
                  productName.contains('spf') ||
                  productDesc.contains('sunscreen') ||
                  productDesc.contains('spf');
            }

            if (s == 'eye cream') {
              return productName.contains('eye') || productDesc.contains('eye');
            }

            return false;
          });

      final matchesSkinType = selectedSkinTypes.isEmpty ||
          selectedSkinTypes.any((skinType) => product.recommendedFor.skinTypes
              .map((e) => e.toLowerCase())
              .contains(skinType.toLowerCase()));

      final matchesConcern = selectedConcerns.isEmpty ||
          selectedConcerns.any((concern) => product.recommendedFor.concerns
              .map((e) => e.toLowerCase())
              .contains(concern.toLowerCase()));

      return matchesSearch && matchesStep && matchesSkinType && matchesConcern;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      selectedSteps = [widget.initialCategory!];
    }
    loadProducts();
    loadUserAndFavorites();
  }

  // Future<void> addProductToCart(ProductModel product) async {
  //   if (currentUserId == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Please log in first")),
  //     );
  //     return;
  //   }

  //   try {
  //     final result = await ApiService.addToCart(
  //       userId: currentUserId!,
  //       productId: product.id,
  //       quantity: 1,
  //     );

  //     if (result["statusCode"] == 200) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           behavior: SnackBarBehavior.floating,
  //           backgroundColor: const Color(0xFF663F44),
  //           elevation: 0,
  //           margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(18),
  //           ),
  //           duration: const Duration(seconds: 2),
  //           content: Row(
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(6),
  //                 decoration: const BoxDecoration(
  //                   color: Colors.white24,
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: const Icon(
  //                   Icons.check,
  //                   color: Colors.white,
  //                   size: 16,
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               const Expanded(
  //                 child: Text(
  //                   "Product added to cart",
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Failed to add product to cart")),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Error: $e")),
  //     );
  //   }
  // }

  Future<void> loadProducts() async {
    try {
      final fetchedProducts = await ApiService.fetchProducts();
      setState(() {
        products = fetchedProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget _activeFilterChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: lineColor),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: deepRose,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: lineColor, width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: darkRose,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Discover',
                    style: GoogleFonts.marcellus(
                      fontSize: 27,
                      color: darkRose,
                      height: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: lineColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: darkRose.withOpacity(0.025),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: softRose,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: (_) => setState(() {}),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: textDark,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search products, brands...',
                                hintStyle: GoogleFonts.poppins(
                                  color: softRose,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SkincareFinderPage(),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          selectedSteps =
                              List<String>.from(result['steps'] ?? []);
                          selectedSkinTypes =
                              List<String>.from(result['skinTypes'] ?? []);
                          selectedConcerns =
                              List<String>.from(result['concerns'] ?? []);
                        });
                      }
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: lineColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: darkRose.withOpacity(0.025),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: deepRose,
                        size: 23,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        decoration: BoxDecoration(
                          color: isSelected ? deepRose : cardColor,
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(
                            color: isSelected ? deepRose : lineColor,
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : softRose,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Text(
                    selectedSteps.isEmpty &&
                            selectedSkinTypes.isEmpty &&
                            selectedConcerns.isEmpty
                        ? 'All Products'
                        : 'Filtered Products',
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w500,
                      color: darkRose,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '${filteredProducts.length} items',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: softRose,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (selectedSteps.isNotEmpty ||
                          selectedSkinTypes.isNotEmpty ||
                          selectedConcerns.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedSteps.clear();
                              selectedSkinTypes.clear();
                              selectedConcerns.clear();
                              selectedCategory = 'All';
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              'Clear',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: deepRose,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              if (selectedSteps.isNotEmpty ||
                  selectedSkinTypes.isNotEmpty ||
                  selectedConcerns.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...selectedSteps.map((e) => _activeFilterChip(e)),
                      ...selectedSkinTypes.map((e) => _activeFilterChip(e)),
                      ...selectedConcerns.map((e) => _activeFilterChip(e)),
                    ],
                  ),
                ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Center(
                            child: Text(
                              errorMessage!,
                              style: GoogleFonts.poppins(),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: filteredProducts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return _productCard(product);
                            },
                          ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _productCard(ProductModel product) {
    return GestureDetector(
      onTap: () async {
        if (currentUserId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please log in first")),
          );
          return;
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
              product: product,
              userId: currentUserId!,
              userName: currentUserName ?? "Anonymous",
            ),
          ),
        );

        if (result == true) {
          await loadUserAndFavorites();
        }
      },
      child: Container(
        height: 162,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: lineColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: darkRose.withOpacity(0.03),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 93,
              height: 93,
              decoration: BoxDecoration(
                color: const Color(0xFFF4EEEE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Hero(
                      tag: product.id,
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              "No Image",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: softRose,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        toggleFavorite(product);
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          favoriteIds.contains(product.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 15,
                          color: const Color(0xFFFF8E8E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 98,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: textDark,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "by ${product.brand}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: softRose,
                        fontWeight: FontWeight.w400,
                        height: 1.1,
                      ),
                    ),
                    // const SizedBox(height: 6),
                    // Text(
                    //   product.shortDescription,
                    //   maxLines: 2,
                    //   overflow: TextOverflow.ellipsis,
                    //   style: GoogleFonts.poppins(
                    //     fontSize: 11.5,
                    //     color: softRose,
                    //     fontWeight: FontWeight.w400,
                    //     height: 1.35,
                    //   ),
                    // ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          "\$${product.price.toStringAsFixed(2)}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: darkRose,
                            height: 1,
                          ),
                        ),
                        const Spacer(),
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
}
