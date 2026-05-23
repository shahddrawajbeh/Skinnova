import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../product_model.dart';
import '../api_service.dart';
import '../review_model.dart';
import 'post_page.dart';
import 'store_details_screen.dart';
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

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color wine = Color(0xFF5B2333);
  static const Color darkText = Color(0xFF202124);

  bool isFavorite = false;
  bool isFavoriteLoading = false;
  bool isCartLoading = false;
  bool favoriteChanged = false;

  late List<ReviewModel> displayedReviews;
  late double displayedRating;
  late ProductModel currentProduct;
  List<GroupPostModel> productReviewPosts = [];
  bool reviewPostsLoading = true;
  List<ProductModel> sameBrandProducts = [];
  bool sameBrandLoading = true;
  List<Map<String, dynamic>> userCollections = [];
  bool collectionsLoading = false;
  String? selectedCollectionId;
  bool isSavedToCollection = false;
  List<dynamic> productStores = [];
  bool storesLoading = true;
  @override
  void initState() {
    super.initState();
    currentProduct = widget.product;
    displayedReviews = List<ReviewModel>.from(widget.product.reviews);
    displayedRating = widget.product.rating;
    loadFavoriteState();
    _loadLatestProduct();
    _loadProductReviewPosts();
    _loadSameBrandProducts();
    loadSavedState();
    _loadProductStores();
  }

  Future<void> _loadProductStores() async {
    try {
      debugPrint("OPENED PRODUCT ID = ${widget.product.id}");

      final stores = await ApiService.fetchStoresForProduct(widget.product.id);

      debugPrint("STORES RESULT = $stores");
      debugPrint("STORES COUNT = ${stores.length}");

      if (!mounted) return;

      setState(() {
        productStores = stores;
        storesLoading = false;
      });
    } catch (e) {
      debugPrint("Load product stores error: $e");

      if (!mounted) return;

      setState(() {
        storesLoading = false;
      });
    }
  }

  Future<void> _openAddToCollectionSheet() async {
    try {
      final result = await ApiService.getUserProfile(userId: widget.userId);
      final data = result["data"];

      final List collections = data["collections"] ?? [];

      final favoritesProducts = await ApiService.fetchFavorites(widget.userId);

      setState(() {
        userCollections = [
          {
            "id": "favorites",
            "title": "Favorites",
            "images": favoritesProducts
                .map((p) => p.imageUrl)
                .where((img) => img.isNotEmpty)
                //.take(4)
                .toList(),
            "isSpecial": true,
          },
          {
            "id": "wishlist",
            "title": "Wishlist",
            "images": [],
            "isSpecial": true,
          },
          {
            "id": "fails",
            "title": "Fails",
            "images": [],
            "isSpecial": true,
          },
          ...collections.map((e) {
            return {
              "id": e["_id"],
              "title": e["title"],
              "images": List<String>.from(e["images"] ?? []),
              "isSpecial": false,
            };
          }).toList(),
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

  Widget _availableStoresSection() {
    if (storesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productStores.isEmpty) {
      return Text(
        "No stores selling this product yet.",
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
      );
    }

    final names = productStores.map((item) {
      final store = item["storeId"] ?? {};
      return store["storeName"] ?? "Store";
    }).toList();

    final shownNames = names.take(2).join(", ");
    final moreCount = names.length - 2;

    return GestureDetector(
      onTap: _showStoresBottomSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Where to buy",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    moreCount > 0
                        ? "$shownNames, +$moreCount more"
                        : shownNames,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 96,
              height: 46,
              child: Stack(
                children: List.generate(
                  productStores.length > 3 ? 3 : productStores.length,
                  (index) {
                    final store = productStores[index]["storeId"] ?? {};
                    final storeName = store["storeName"] ?? "S";
                    final firstLetter =
                        storeName.isNotEmpty ? storeName[0].toUpperCase() : "S";

                    final logoUrl = store["logoUrl"] ?? "";

                    return Positioned(
                      left: index * 28,
                      child: CircleAvatar(
                        radius: 23,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: logoUrl.isNotEmpty
                              ? logoUrl.startsWith("assets/")
                                  ? Image.asset(
                                      logoUrl,
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      logoUrl,
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Text(
                                        firstLetter,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: wine,
                                        ),
                                      ),
                                    )
                              : Text(
                                  firstLetter,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: wine,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoresBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.62,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Where to buy",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: darkText,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F4F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 26),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: productStores.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 30,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final item = productStores[index];
                    final store = item["storeId"] ?? {};

                    final storeName = store["storeName"] ?? "Unknown Store";
                    final logoUrl = store["logoUrl"] ?? "";
                    final price = item["price"] ?? 0;
                    final currency = item["currency"] ?? "ILS";
                    final stockCount = item["stockCount"] ?? 0;

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
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFFF4F4F4),
                            child: ClipOval(
                              child: logoUrl.isNotEmpty
                                  ? logoUrl.startsWith("assets/")
                                      ? Image.asset(
                                          logoUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          logoUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Text(
                                            firstLetter,
                                            style: GoogleFonts.poppins(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: wine,
                                            ),
                                          ),
                                        )
                                  : Text(
                                      firstLetter,
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: wine,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  storeName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: darkText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$stockCount in stock",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? const Color(0xFFFFD84D)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "$price $currency",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Prices from stores may change.",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        );
      },
    );
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
                width: 54,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_rounded,
                      size: 32,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Add to collection",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: darkText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
              const SizedBox(height: 26),
              GestureDetector(
                onTap: _showNewCollectionSheet,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      "Create new collection",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: darkText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: GridView.builder(
                  itemCount: userCollections.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 22,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final collection = userCollections[index];
                    final title = collection["title"] ?? "Collection";
                    final images =
                        List<String>.from(collection["images"] ?? []);
                    final bool isSelected =
                        selectedCollectionId == collection["id"]?.toString();

                    return GestureDetector(
                      onTap: () async {
                        final collectionId = collection["id"]?.toString() ?? "";
                        final bool isSpecial = collection["isSpecial"] == true;

                        if (collectionId.isEmpty) return;

                        if (isSpecial) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "This collection needs a separate function",
                              ),
                            ),
                          );
                          return;
                        }

                        setSheetState(() {
                          selectedCollectionId = collectionId;
                        });

                        final success = await ApiService.addProductToCollection(
                          collectionId: collectionId,
                          imageUrl: widget.product.imageUrl,
                        );

                        if (!mounted) return;

                        if (success) {
                          Navigator.pop(context);
                          setState(() {
                            isSavedToCollection = true;
                          });

                          Future.delayed(
                            const Duration(milliseconds: 250),
                            () {
                              if (!mounted) return;
                              _showProductAddedMessage();
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to add product"),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF5B2333)
                              : const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : darkText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: _collectionPreview(images),
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
        );
      },
    );
  }

  void _showNewCollectionSheet() {
    final TextEditingController collectionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4F3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child:
                        const Icon(Icons.close, color: Colors.grey, size: 28),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "New collection",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final name = collectionController.text.trim();
                      if (name.isEmpty) return;

                      final success = await ApiService.addCollection(
                        userId: widget.userId,
                        title: name,
                        images: widget.product.imageUrl.isNotEmpty
                            ? [widget.product.imageUrl]
                            : [],
                      );

                      if (!mounted) return;
                      if (success != null) {
                        setState(() {
                          isSavedToCollection = true;
                        });

                        Navigator.pop(context);
                        Navigator.pop(context);

                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (!mounted) return;
                          _showProductAddedMessage();
                        });
                      }
                    },
                    child:
                        const Icon(Icons.check, color: Colors.grey, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: TextField(
                  controller: collectionController,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: darkText,
                  ),
                  decoration: InputDecoration(
                    hintText: "Name your new collection...",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> loadSavedState() async {
    try {
      final isSaved = await ApiService.isProductInAnyCollection(
        userId: widget.userId,
        imageUrl: widget.product.imageUrl,
      );

      if (!mounted) return;

      setState(() {
        isSavedToCollection = isSaved;
      });
    } catch (e) {
      debugPrint("Saved state error: $e");
    }
  }

  void _showProductAddedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF61C97A),
                size: 36,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Product Added!",
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "You can find your collections on your profile",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                child: const Icon(Icons.close_rounded, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _collectionPreview(List<String> images) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          if (index < images.length && images[index].isNotEmpty) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images[index],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _emptyBottleIcon(),
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE3E3E3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _emptyBottleIcon(),
          );
        },
      ),
    );
  }

  Widget _emptyBottleIcon() {
    return Icon(
      Icons.local_pharmacy_outlined,
      size: 38,
      color: Colors.grey.shade400,
    );
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        sameBrandLoading = false;
      });

      debugPrint("Load same brand products error: $e");
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        reviewPostsLoading = false;
      });

      debugPrint("Load product review posts error: $e");
    }
  }

  Future<void> _loadLatestProduct() async {
    try {
      final updatedProduct =
          await ApiService.fetchProductById(widget.product.id);

      if (!mounted) return;

      setState(() {
        currentProduct = updatedProduct;
        displayedReviews = List<ReviewModel>.from(updatedProduct.reviews);
        displayedRating = updatedProduct.rating;
      });
    } catch (e) {
      debugPrint("Load latest product error: $e");
    }
  }

  Future<void> loadFavoriteState() async {
    try {
      final favoriteProducts = await ApiService.fetchFavorites(widget.userId);

      if (!mounted) return;

      setState(() {
        isFavorite = favoriteProducts.any((e) => e.id == widget.product.id);
      });
    } catch (e) {
      debugPrint("Favorites load error: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    if (isFavoriteLoading) return;

    setState(() {
      isFavoriteLoading = true;
      favoriteChanged = true;
    });

    try {
      final result = await ApiService.toggleFavorite(
        userId: widget.userId,
        productId: widget.product.id,
      );

      if (!mounted) return;

      if (result["statusCode"] == 200) {
        setState(() {
          isFavorite = result["data"]["isFavorite"] == true;
        });
      }
    } catch (e) {
      debugPrint("Toggle favorite error: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        isFavoriteLoading = false;
      });
    }
  }

  // Future<void> _addToCart() async {
  //   if (isCartLoading) return;

  //   setState(() {
  //     isCartLoading = true;
  //   });

  //   try {
  //     await ApiService.addToCart(
  //       userId: widget.userId,
  //       productId: widget.product.id,
  //       quantity: 1,
  //     );

  //     if (!mounted) return;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Added to cart")),
  //     );
  //   } catch (e) {
  //     if (!mounted) return;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Failed to add to cart")),
  //     );
  //   } finally {
  //     if (!mounted) return;

  //     setState(() {
  //       isCartLoading = false;
  //     });
  //   }
  // }

  Future<void> _openReviewSheet() async {
    int currentStep = 1;
    int selectedStars = 0;
    final TextEditingController reviewController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.only(top: 24),
              padding: EdgeInsets.fromLTRB(
                22,
                22,
                22,
                22 + MediaQuery.of(context).viewInsets.bottom,
              ),
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
                        child: const Icon(
                          Icons.close_rounded,
                          size: 30,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (currentStep == 1) ...[
                      Text(
                        "How was the product?",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Share your experience with the community.",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: List.generate(
                          5,
                          (index) => GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedStars = index + 1;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Icon(
                                index < selectedStars
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 44,
                                color: index < selectedStars
                                    ? wine
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                    ] else ...[
                      Text(
                        "Tell others about the product",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Share helpful details with the community.",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: reviewController,
                        maxLines: 6,
                        onChanged: (_) => setModalState(() {}),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: darkText,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              "Write what you liked, how you used it, and any tips.",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black45,
                            height: 1.7,
                          ),
                          filled: true,
                          fillColor: whiteSmoke,
                          contentPadding: const EdgeInsets.all(18),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: wine),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: currentStep == 1 ? 0.5 : 1,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(wine),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        if (currentStep == 2)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                currentStep = 1;
                              });
                            },
                            child: Text(
                              "Back",
                              style: GoogleFonts.poppins(
                                color: darkText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: currentStep == 1
                                ? selectedStars == 0
                                    ? null
                                    : () {
                                        setModalState(() {
                                          currentStep = 2;
                                        });
                                      }
                                : reviewController.text.trim().isEmpty
                                    ? null
                                    : () async {
                                        try {
                                          final result =
                                              await ApiService.addReview(
                                            productId: widget.product.id,
                                            userId: widget.userId,
                                            userName: widget.userName,
                                            rating: selectedStars.toDouble(),
                                            title: "",
                                            comment:
                                                reviewController.text.trim(),
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
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text("Review added"),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text("Something went wrong"),
                                            ),
                                          );
                                        }
                                      },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: wine,
                              disabledBackgroundColor: Colors.grey.shade200,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: Text(
                              currentStep == 1 ? "Next" : "Done",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = currentProduct;
    final double finalPrice = product.discountPercent > 0
        ? product.price - (product.price * product.discountPercent / 100)
        : product.price;

    final whatsInsideMap = {
      "Alcohol Free": product.whatsInside.alcoholFree,
      "EU Allergen Free": product.whatsInside.euAllergenFree,
      "Fragrance Free": product.whatsInside.fragranceFree,
      "Oil Free": product.whatsInside.oilFree,
      "Paraben Free": product.whatsInside.parabenFree,
      "Silicone Free": product.whatsInside.siliconeFree,
      "Sulfate Free": product.whatsInside.sulfateFree,
      "Cruelty Free": product.whatsInside.crueltyFree,
      "Fungal Acne Safe": product.whatsInside.fungalAcneSafe,
      "Reef Safe": product.whatsInside.reefSafe,
      "Vegan": product.whatsInside.vegan,
    };

    final trueInside =
        whatsInsideMap.entries.where((entry) => entry.value == true).toList();

    final bool hasRecommendedFor =
        product.recommendedFor.skinTypes.isNotEmpty ||
            product.recommendedFor.concerns.isNotEmpty ||
            product.recommendedFor.goals.isNotEmpty;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, favoriteChanged);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: DefaultTabController(
          length: 4,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context, favoriteChanged),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 22,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Text(
                                "Also used by",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: darkText.withOpacity(0.75),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Color(0xFFC8F5C5)),
                              const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Color(0xFFFFDDBB)),
                              const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Color(0xFFAFC4F5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 35),
                        Center(
                          child: SizedBox(
                            height: 260,
                            child: product.imageUrl.isNotEmpty
                                ? Hero(
                                    tag: product.id,
                                    child: Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          _imagePlaceholder(),
                                    ),
                                  )
                                : _imagePlaceholder(),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.brand,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: darkText.withOpacity(0.75),
                                  ),
                                ),
                              ),
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F4),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  onPressed: isFavoriteLoading
                                      ? null
                                      : _toggleFavorite,
                                  icon: isFavoriteLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Icon(
                                          isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border_rounded,
                                          color: wine,
                                          size: 28,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => _openAddToCollectionSheet(),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F4F4),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    isSavedToCollection
                                        ? Icons.bookmark
                                        : Icons.bookmark_border_rounded,
                                    color: Colors.black54,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            product.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              height: 1.25,
                              color: darkText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < displayedRating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TabBar(
                          labelColor: darkText,
                          unselectedLabelColor: darkText.withOpacity(0.75),
                          indicatorColor: darkText,
                          indicatorWeight: 2.4,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: const [
                            Tab(text: "Overview"),
                            Tab(text: "Analytics"),
                            Tab(text: "Ingredients"),
                            Tab(text: "Reviews"),
                          ],
                        ),
                        SizedBox(
                          height: 720,
                          child: TabBarView(
                            children: [
                              _overviewTab(product),
                              _analyticsTab(product),
                              _ingredientsTab(product),
                              _reviewsOnlyTab(),
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
        ),
      ),
    );
  }

  Widget _overviewTab(ProductModel product) {
    final bestSuitedFor = [
      ...product.recommendedFor.concerns,
      ...product.recommendedFor.skinTypes,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Best suited for",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: darkText,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: bestSuitedFor.map((item) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: const Color(0xFFEDEDED), width: 1.6),
                ),
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF5B2333),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 34),
          _plainTitle("Description"),
          const SizedBox(height: 12),
          Text(
            product.shortDescription.isNotEmpty
                ? product.shortDescription
                : "No description added yet.",
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.6,
              color: darkText.withOpacity(0.82),
            ),
          ),
          const SizedBox(height: 30),
          _plainTitle("Directions of use"),
          const SizedBox(height: 12),
          Text(
            product.directionsOfUse.isNotEmpty
                ? product.directionsOfUse
                : "No directions of use added yet.",
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.6,
              color: darkText.withOpacity(0.82),
            ),
          ),
          const SizedBox(height: 30),
          _plainTitle("Product details"),
          const SizedBox(height: 12),
          _simpleInfoLine("Brand Origin", product.brandOrigin),
          _simpleInfoLine("Size", product.size),
          const SizedBox(height: 30),
          _availableStoresSection(),
          const SizedBox(height: 30),
          _sameBrandSection(),
        ],
      ),
    );
  }

  Widget _sameBrandSection() {
    if (sameBrandLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sameBrandProducts.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _plainTitle("More from ${currentProduct.brand}"),
        const SizedBox(height: 18),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sameBrandProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final item = sameBrandProducts[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(
                        product: item,
                        userId: widget.userId,
                        userName: widget.userName,
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  width: 110,
                  child: Column(
                    children: [
                      Expanded(
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(
                                item.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                              )
                            : _imagePlaceholder(),
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

  Widget _analyticsTab(ProductModel product) {
    final analyticsItems = [
      {"label": "Dry", "color": const Color(0xFFFFB3B3), "value": 25.0},
      {"label": "Normal", "color": const Color(0xFF86C5ED), "value": 25.0},
      {"label": "Oily", "color": const Color(0xFFFFE58A), "value": 20.0},
      {
        "label": "Combination",
        "color": Color.fromARGB(255, 197, 42, 115),
        "value": 30.0
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Who uses this product?",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: darkText,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: analyticsItems.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: item["color"] as Color,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      item["label"] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: darkText.withOpacity(0.85),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: DonutChartPainter(
                    values: analyticsItems
                        .map((e) => e["value"] as double)
                        .toList(),
                    colors:
                        analyticsItems.map((e) => e["color"] as Color).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ingredientsTab(ProductModel product) {
    final whatsInsideMap = {
      "Alcohol Free": product.whatsInside.alcoholFree,
      "Fragrance Free": product.whatsInside.fragranceFree,
      "Oil Free": product.whatsInside.oilFree,
      "Paraben Free": product.whatsInside.parabenFree,
      "Silicone Free": product.whatsInside.siliconeFree,
      "Sulfate Free": product.whatsInside.sulfateFree,
      "Cruelty Free": product.whatsInside.crueltyFree,
      "Vegan": product.whatsInside.vegan,
      "Fungal Acne Safe": product.whatsInside.fungalAcneSafe,
      "Reef Safe": product.whatsInside.reefSafe,
    };

    final activeTags = whatsInsideMap.entries.where((e) => e.value).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 💜 WHAT'S INSIDE
          if (activeTags.isNotEmpty) ...[
            Text(
              "What’s inside",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: activeTags.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4F3),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFE8E3E1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Color(0xFF5B2333),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.key,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: const Color(0xFF5B2333),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
          ],

          /// ⚪ INGREDIENTS
          Text(
            "Ingredients",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),

          const SizedBox(height: 16),

          product.ingredients.isEmpty
              ? Text(
                  "No ingredients added yet.",
                  style: GoogleFonts.poppins(fontSize: 13),
                )
              : Column(
                  children: product.ingredients.map((ing) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ing.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                          if (ing.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              ing.description,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                height: 1.5,
                                color: darkText.withOpacity(0.65),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _reviewsOnlyTab() {
    if (reviewPostsLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _plainTitle("Review posts"),
          const SizedBox(height: 18),
          productReviewPosts.isEmpty
              ? Text(
                  "No review posts yet.",
                  style: GoogleFonts.poppins(fontSize: 13),
                )
              : Column(
                  children: productReviewPosts.map((post) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: wine.withOpacity(0.13),
                                child: Text(
                                  post.userName.isNotEmpty
                                      ? post.userName[0].toUpperCase()
                                      : "U",
                                  style: GoogleFonts.poppins(
                                    color: wine,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  post.userName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: darkText,
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < post.rating.round()
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (post.content.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              post.content,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                height: 1.55,
                                color: darkText.withOpacity(0.72),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.favorite_border,
                                  size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                "${post.likes.length}",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.chat_bubble_outline,
                                  size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                "${post.comments.length}",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _plainTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: darkText,
      ),
    );
  }

  Widget _simpleInfoLine(String label, String value) {
    if (value.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        "$label: $value",
        style: GoogleFonts.poppins(
          fontSize: 13,
          height: 1.5,
          color: darkText.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _brandAndStock(ProductModel product) {
    return Row(
      children: [
        Expanded(
          child: Text(
            product.brand.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: wine.withOpacity(0.5),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: product.inStock
                ? const Color(0xFFEFF7EF)
                : const Color(0xFFF8ECEC),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            product.inStock ? "In stock" : "Out of stock",
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
    );
  }

  Widget _ratingRow() {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
        const SizedBox(width: 5),
        Text(
          displayedRating.toStringAsFixed(1),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "(${displayedReviews.length} reviews)",
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: darkText.withOpacity(0.48),
          ),
        ),
      ],
    );
  }

  Widget _priceRow(ProductModel product, double finalPrice) {
    return Row(
      children: [
        Text(
          "${finalPrice.toStringAsFixed(2)} ${product.currency}",
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: wine,
          ),
        ),
        const SizedBox(width: 10),
        if (product.discountPercent > 0)
          Text(
            "${product.price.toStringAsFixed(2)} ${product.currency}",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: darkText.withOpacity(0.32),
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: wine.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: wine.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.marcellus(
        fontSize: 23,
        color: wine,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: darkText.withOpacity(0.45),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipBlock(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: wine.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: items.map((item) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: whiteSmoke,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: wine,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _reviewsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: wine.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: wine.withOpacity(0.035),
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
              _sectionTitle("Reviews"),
              const Spacer(),
              GestureDetector(
                onTap: _openReviewSheet,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: wine,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.white, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        "Write review",
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          displayedReviews.isEmpty
              ? _emptyText("No reviews yet.")
              : Column(
                  children: displayedReviews.map((review) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: whiteSmoke,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: wine.withOpacity(0.14),
                                child: Text(
                                  review.userName.isNotEmpty
                                      ? review.userName[0].toUpperCase()
                                      : "A",
                                  style: GoogleFonts.poppins(
                                    color: wine,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  review.userName.isEmpty
                                      ? "Anonymous"
                                      : review.userName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: darkText,
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (starIndex) => Icon(
                                    starIndex < review.rating.round()
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: Colors.amber,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (review.comment.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              review.comment,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                height: 1.65,
                                color: darkText.withOpacity(0.68),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _emptyText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: darkText.withOpacity(0.48),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 64,
        color: wine.withOpacity(0.28),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  DonutChartPainter({
    required this.values,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final rect = Offset.zero & size;

    double startAngle = -90 * 3.1415926535 / 180;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.30
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * 3.1415926535;

      paint.color = colors[i];

      canvas.drawArc(
        rect.deflate(size.width * 0.15),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
