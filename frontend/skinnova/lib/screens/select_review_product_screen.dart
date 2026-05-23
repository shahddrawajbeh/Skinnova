import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../product_model.dart';
import '../api_service.dart';
import 'rate_product_screen.dart';

class SelectReviewProductScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const SelectReviewProductScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<SelectReviewProductScreen> createState() =>
      _SelectReviewProductScreenState();
}

class _SelectReviewProductScreenState extends State<SelectReviewProductScreen> {
  List<ProductModel> allProducts = [];
  List<ProductModel> filteredProducts = [];
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    searchController.addListener(_filterProducts);
  }

  Future<void> fetchProducts() async {
    try {
      final products = await ApiService.fetchProducts();
      setState(() {
        allProducts = products;
        filteredProducts = products;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _filterProducts() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      filteredProducts = allProducts.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.brand.toLowerCase().contains(query) ||
            product.shortDescription.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget _buildProductTile(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 72,
              height: 72,
              color: const Color(0xFFF2F2F2),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.brand,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              final posted = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RateProductScreen(
                    userId: widget.userId,
                    userName: widget.userName,
                    product: product,
                  ),
                ),
              );

              if (posted == true && mounted) {
                Navigator.pop(context, true);
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F1F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFFB2B2B2)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E2E2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        size: 30, color: Color(0xFF9D9D9D)),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Add products",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFFB7B7B7),
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFFB7B7B7)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Text(
                            "No products found",
                            style: GoogleFonts.poppins(),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductTile(filteredProducts[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
