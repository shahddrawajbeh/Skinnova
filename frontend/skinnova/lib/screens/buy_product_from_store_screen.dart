import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../product_model.dart';
import '../api_service.dart';

class BuyProductFromStoreScreen extends StatefulWidget {
  final ProductModel product;
  final Map<String, dynamic> storeProduct;
  final String userId;
  final String userName;

  const BuyProductFromStoreScreen({
    super.key,
    required this.product,
    required this.storeProduct,
    required this.userId,
    required this.userName,
  });

  @override
  State<BuyProductFromStoreScreen> createState() =>
      _BuyProductFromStoreScreenState();
}

class _BuyProductFromStoreScreenState extends State<BuyProductFromStoreScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);

  int quantity = 1;
  bool isLoading = false;

  Future<void> _addToCart() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final storeData = widget.storeProduct["storeId"];

      final String storeId =
          storeData is Map ? storeData["_id"].toString() : storeData.toString();

      final price = widget.storeProduct["price"] ?? 0;
      final currency = widget.storeProduct["currency"] ?? "ILS";

      debugPrint("ADD CART storeId = $storeId");
      debugPrint("ADD CART productId = ${widget.product.id}");
      debugPrint("ADD CART price = $price");

      final result = await ApiService.addToCart(
        userId: widget.userId,
        productId: widget.product.id,
        storeId: storeId,
        quantity: quantity,
        price: price,
        currency: currency,
      );

      debugPrint("ADD CART RESULT = $result");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to cart")),
      );
    } catch (e) {
      debugPrint("ADD CART ERROR = $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add to cart: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final store = widget.storeProduct["storeId"] ?? {};

    final storeName = store["storeName"] ?? "Store";
    final price = widget.storeProduct["price"] ?? 0;
    final currency = widget.storeProduct["currency"] ?? "ILS";
    final stockCount = widget.storeProduct["stockCount"] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: stockCount > 0 && !isLoading ? _addToCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: wine,
              disabledBackgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    stockCount > 0 ? "Add to Cart" : "Out of Stock",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 26),
              Center(
                child: Container(
                  height: 280,
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.contain,
                        )
                      : const Icon(
                          Icons.spa_outlined,
                          color: wine,
                          size: 70,
                        ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                product.brand,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                style: GoogleFonts.poppins(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.055),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow("Store", storeName),
                    const SizedBox(height: 14),
                    _infoRow("Price", "$price $currency"),
                    const SizedBox(height: 14),
                    _infoRow(
                      "Availability",
                      stockCount <= 0
                          ? "Out of Stock"
                          : stockCount <= 5
                              ? "Limited Stock"
                              : "Available",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Text(
                    "Quantity",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                  const Spacer(),
                  _quantityButton(
                    icon: Icons.remove_rounded,
                    onTap:
                        quantity > 1 ? () => setState(() => quantity--) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      quantity.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: darkText,
                      ),
                    ),
                  ),
                  _quantityButton(
                    icon: Icons.add_rounded,
                    onTap: quantity < stockCount
                        ? () => setState(() => quantity++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black45,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade200 : wine,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: onTap == null ? Colors.grey : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
