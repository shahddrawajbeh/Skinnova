import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'product_details_screen.dart';
import '../product_model.dart';

class StoreDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  final String userId;
  final String userName;

  const StoreDetailsScreen({
    super.key,
    required this.store,
    required this.userId,
    required this.userName,
  });

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color softRose = Color(0xFFF8F5F4);
  static const Color darkText = Color(0xFF202124);

  List<dynamic> storeProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreProducts();
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
    } catch (e) {
      debugPrint("Load store products error: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _imageFromPath({
    required String path,
    required double width,
    required double height,
    required BoxFit fit,
    Widget? fallback,
  }) {
    if (path.isEmpty) {
      return fallback ?? const Icon(Icons.image_outlined);
    }

    if (path.startsWith("assets/")) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          fallback ?? const Icon(Icons.image_outlined),
    );
  }

  Widget _storeLogo(String logoUrl, String storeName) {
    final firstLetter = storeName.isNotEmpty ? storeName[0].toUpperCase() : "S";

    return _imageFromPath(
      path: logoUrl,
      width: 92,
      height: 92,
      fit: BoxFit.cover,
      fallback: Text(
        firstLetter,
        style: GoogleFonts.poppins(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: wine,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeName = widget.store["storeName"] ?? "Store";
    final logoUrl = widget.store["logoUrl"] ?? "";
    final coverImageUrl = widget.store["coverImageUrl"] ?? "";
    final city = widget.store["city"] ?? "";
    final address = widget.store["address"] ?? "";
    final description = widget.store["description"] ?? "";
    final phone = widget.store["phone"] ?? "";
    final rating = widget.store["rating"] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const Spacer(),
                  Text(
                    "Store",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: const Color(0xFFF0EAEA),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -45,
                          child: Center(
                            child: Container(
                              width: 104,
                              height: 104,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                backgroundColor: whiteSmoke,
                                child: ClipOval(
                                  child: _storeLogo(logoUrl, storeName),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 58),
                    Center(
                      child: Text(
                        storeName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "$city${address.isNotEmpty ? " • $address" : ""}",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _statCard(
                          icon: Icons.shopping_bag_outlined,
                          title: "${storeProducts.length}",
                          subtitle: "Products",
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          icon: Icons.star_rounded,
                          title: rating.toString(),
                          subtitle: "Rating",
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          icon: Icons.location_on_outlined,
                          title: city.isEmpty ? "-" : city,
                          subtitle: "City",
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            text: "Chat seller",
                            filled: true,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Chat feature coming soon"),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            icon: Icons.phone_outlined,
                            text: phone.isEmpty ? "Call store" : phone,
                            filled: false,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionTitle("About"),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
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
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        _sectionTitle("Store products"),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "${storeProducts.length} items",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (storeProducts.isEmpty)
                      Text(
                        "No products in this store yet.",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: storeProducts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 18,
                          childAspectRatio: 0.62,
                        ),
                        itemBuilder: (context, index) {
                          final item = storeProducts[index];
                          final productJson = item["productId"];
                          final price = item["price"] ?? 0;
                          final currency = item["currency"] ?? "ILS";
                          final stockCount = item["stockCount"] ?? 0;

                          final product = ProductModel.fromJson(productJson);

                          return _productGridCard(
                            product: product,
                            price: price,
                            currency: currency,
                            stockCount: stockCount,
                          );
                        },
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

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(icon, color: wine, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String text,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: filled ? wine : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: wine.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: filled ? Colors.white : wine,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : wine,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productGridCard({
    required ProductModel product,
    required dynamic price,
    required String currency,
    required dynamic stockCount,
  }) {
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
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: wine.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_outlined, size: 42),
                      )
                    : const Icon(Icons.image_outlined, size: 42),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.brand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkText,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 9),
            Row(
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "$stockCount left",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
