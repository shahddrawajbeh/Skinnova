import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../product_model.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  static const Color wine = Color(0xFF5B2333);
  static const Color bg = Color(0xFFF8F7F6);
  static const Color textDark = Color(0xFF202124);

  bool isLoading = true;
  List<ProductModel> allProducts = [];
  List<ProductModel> selectedProducts = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final products = await ApiService.fetchProducts();
      if (!mounted) return;

      setState(() {
        allProducts = products;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  int _scoreProduct(ProductModel product) {
    int score = 0;

    score += (product.rating * 10).round();

    if (product.whatsInside.fragranceFree) score += 10;
    if (product.whatsInside.alcoholFree) score += 10;
    if (product.whatsInside.parabenFree) score += 8;
    if (product.whatsInside.oilFree) score += 6;
    if (product.whatsInside.sulfateFree) score += 6;
    if (product.inStock) score += 5;

    return score;
  }

  ProductModel? get bestProduct {
    if (selectedProducts.isEmpty) return null;

    final sorted = [...selectedProducts];
    sorted.sort((a, b) => _scoreProduct(b).compareTo(_scoreProduct(a)));
    return sorted.first;
  }

  void _showProductPicker() {
    final available = allProducts
        .where((p) => !selectedProducts.any((s) => s.id == p.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Choose product",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: available.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = available[index];

                    return GestureDetector(
                      onTap: () {
                        if (selectedProducts.length >= 3) return;

                        setState(() {
                          selectedProducts.add(product);
                        });

                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            _productImage(product, 64),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.brand,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: wine,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.add_circle_outline, color: wine),
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

  Widget _productImage(ProductModel product, double size) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: product.imageUrl.isNotEmpty
          ? Image.network(
              product.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported_outlined),
            )
          : const Icon(Icons.image_outlined),
    );
  }

  Widget _selectedProductCard(ProductModel product) {
    final isBest = bestProduct?.id == product.id && selectedProducts.length > 1;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isBest ? wine : const Color(0xFFEAEAEA),
          width: isBest ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedProducts.removeWhere((p) => p.id == product.id);
                });
              },
              child: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
          _productImage(product, 74),
          const SizedBox(height: 10),
          Text(
            product.brand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: wine,
            ),
          ),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: textDark,
            ),
          ),
          if (isBest) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: wine,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                "Best match",
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricRow(String title, String Function(ProductModel) valueBuilder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: selectedProducts.map((product) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    valueBuilder(product),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: textDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _booleanRow(String title, bool Function(ProductModel) checker) {
    return _metricRow(
      title,
      (product) => checker(product) ? "Yes ✓" : "No",
    );
  }

  Widget _bestMatchCard() {
    final best = bestProduct;
    if (best == null || selectedProducts.length < 2) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: wine,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _productImage(best, 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Best match",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${best.brand} ${best.name}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Score: ${_scoreProduct(best)}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              "Compare products",
              style: GoogleFonts.poppins(
                fontSize: 28,
                color: textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Choose up to 3 products and Skinova will compare price, rating, skin match, and ingredient flags.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: wine,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _showProductPicker,
              child: Text(
                "Add product",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...selectedProducts.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _selectedProductCard(p),
                );
              }),
              if (selectedProducts.length < 3)
                GestureDetector(
                  onTap: _showProductPicker,
                  child: Container(
                    width: 120,
                    height: 190,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFEAEAEA)),
                    ),
                    child: const Icon(Icons.add_rounded, color: wine, size: 34),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _bestMatchCard(),
        _metricRow(
            "Price", (p) => "${p.price.toStringAsFixed(0)} ${p.currency}"),
        _metricRow("Rating", (p) => "${p.rating.toStringAsFixed(1)} / 5"),
        _metricRow("Reviews", (p) => "${p.reviews.length} reviews"),
        _metricRow("Skin types", (p) {
          final list = p.recommendedFor.skinTypes;
          return list.isEmpty ? "Not specified" : list.take(3).join(", ");
        }),
        _metricRow("Concerns", (p) {
          final list = p.recommendedFor.concerns;
          return list.isEmpty ? "Not specified" : list.take(3).join(", ");
        }),
        _metricRow("Ingredients", (p) => "${p.ingredients.length} ingredients"),
        _booleanRow("Fragrance free", (p) => p.whatsInside.fragranceFree),
        _booleanRow("Alcohol free", (p) => p.whatsInside.alcoholFree),
        _booleanRow("Paraben free", (p) => p.whatsInside.parabenFree),
        _booleanRow("Oil free", (p) => p.whatsInside.oilFree),
        _booleanRow("Sulfate free", (p) => p.whatsInside.sulfateFree),
        _booleanRow("In stock", (p) => p.inStock),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setState(() {
              selectedProducts.clear();
            });
          },
          child: Text(
            "Clear comparison",
            style: GoogleFonts.poppins(
              color: wine,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: textDark),
        centerTitle: true,
        title: Text(
          "Compare",
          style: GoogleFonts.poppins(
            color: textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          if (selectedProducts.length < 3)
            IconButton(
              onPressed: _showProductPicker,
              icon: const Icon(Icons.add_rounded, color: wine),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : selectedProducts.isEmpty
              ? _emptyState()
              : _comparisonBody(),
    );
  }
}
