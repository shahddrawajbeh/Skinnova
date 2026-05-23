import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'checkout_screen.dart';
import 'rate_stores_screen.dart';

class CartScreen extends StatefulWidget {
  final String userId;

  const CartScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color bgColor = Color(0xFFF7F7F7);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color softRose = Color(0xFF111111);
  static const Color deepRose = Color(0xFF5B2333);
  static const Color darkRose = Color(0xFF5B2333);
  static const Color textDark = Color(0xFF111111);
  static const Color lineColor = Color(0xFFF7F4F3);

  bool isLoading = true;
  String? errorMessage;
  List<dynamic> cartItems = [];

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  Future<void> loadCart() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.fetchCart(widget.userId);

      if (result["statusCode"] == 200) {
        final data = result["data"];
        setState(() {
          cartItems = data["items"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load cart";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> addQuantity(
    String productId,
    String storeId,
    dynamic price,
    String currency,
  ) async {
    await ApiService.addToCart(
      userId: widget.userId,
      productId: productId,
      storeId: storeId,
      quantity: 1,
      price: price,
      currency: currency,
    );
    await loadCart();
  }

  Future<void> decreaseQuantity(
    String productId,
    String storeId,
    int currentQuantity,
  ) async {
    if (currentQuantity <= 1) {
      await removeItem(productId, storeId);
      return;
    }

    await ApiService.updateCartQuantity(
      userId: widget.userId,
      productId: productId,
      storeId: storeId,
      quantity: currentQuantity - 1,
    );

    await loadCart();
  }

  Future<void> removeItem(String productId, String storeId) async {
    final result = await ApiService.removeFromCart(
      userId: widget.userId,
      productId: productId,
      storeId: storeId,
    );

    if (result["statusCode"] == 200) {
      await loadCart();
      _showPrettySnackBar("Removed from cart");
    }
  }

  void _showPrettySnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: deepRose,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get subtotal {
    double total = 0;
    for (final item in cartItems) {
      final product = item["productId"];
      if (product != null) {
        final price = (item["price"] ?? product["price"] ?? 0).toDouble();
        final quantity = item["quantity"] ?? 1;
        total += price * quantity;
      }
    }
    return total;
  }

  double get deliveryFee => cartItems.isEmpty ? 0 : 2.99;

  double get total => subtotal + deliveryFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: lineColor),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: darkRose,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      "My Cart",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        color: darkRose,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(
                          child: Text(
                            errorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: darkRose,
                            ),
                          ),
                        )
                      : cartItems.isEmpty
                          ? _buildEmptyState()
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      0,
                                      20,
                                      24,
                                    ),
                                    itemCount: cartItems.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 14),
                                    itemBuilder: (context, index) {
                                      final item = cartItems[index];
                                      final product = item["productId"];
                                      if (product == null) {
                                        return const SizedBox.shrink();
                                      }

                                      return _cartItemCard(
                                        product: product,
                                        quantity: item["quantity"] ?? 1,
                                        store: item["storeId"],
                                        itemPrice: item["price"],
                                        itemCurrency: item["currency"],
                                      );
                                    },
                                  ),
                                ),
                                _buildBottomSummary(),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFF4EEEE),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 42,
              color: deepRose,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Your cart is empty",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: darkRose,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add some skincare products and they’ll appear here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: softRose,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartItemCard({
    required dynamic product,
    required int quantity,
    dynamic store,
    dynamic itemPrice,
    String? itemCurrency,
  }) {
    final String productId = product["_id"] ?? "";
    final String name = product["name"] ?? "Unknown product";
    final String brand = product["brand"] ?? "";
    final String imageUrl = product["imageUrl"] ?? "";
    final double price = (itemPrice ?? product["price"] ?? 0).toDouble();
    final String currency = itemCurrency ?? product["currency"] ?? "ILS";
    final String storeId = store?["_id"]?.toString() ?? "";
    final String storeName = store?["storeName"]?.toString() ?? "";
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: lineColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: darkRose.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFF4EEEE),
              borderRadius: BorderRadius.circular(22),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    "No Image",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: softRose,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: textDark,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    brand,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: softRose,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (storeName.isNotEmpty)
                    Text(
                      "From $storeName",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: softRose,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    "${price.toStringAsFixed(2)} $currency",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: darkRose,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 94,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => removeItem(productId, storeId),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8EFEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFB08A90),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F4F3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: lineColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            decreaseQuantity(productId, storeId, quantity),
                        child: const Icon(
                          Icons.remove,
                          size: 17,
                          color: darkRose,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          quantity.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textDark,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            addQuantity(productId, storeId, price, currency),
                        child: const Icon(
                          Icons.add,
                          size: 17,
                          color: darkRose,
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

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBFA),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow("Subtotal", subtotal),
          const SizedBox(height: 10),
          _summaryRow("Delivery", deliveryFee),
          const SizedBox(height: 14),
          Divider(color: lineColor, thickness: 1),
          const SizedBox(height: 14),
          _summaryRow("Total", total, isBold: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      userId: widget.userId,
                      subtotal: subtotal,
                    ),
                  ),
                );

                if (result != null && result is List) {
                  await loadCart();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RateStoresScreen(
                        userId: widget.userId,
                        orders: result,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: deepRose,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                "Proceed to Checkout",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, double amount, {bool isBold = false}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 15 : 13.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? darkRose : softRose,
          ),
        ),
        const Spacer(),
        Text(
          "\$${amount.toStringAsFixed(2)}",
          style: GoogleFonts.poppins(
            fontSize: isBold ? 17 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isBold ? darkRose : textDark,
          ),
        ),
      ],
    );
  }
}
