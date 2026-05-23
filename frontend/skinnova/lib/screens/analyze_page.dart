import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../product_model.dart';

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({super.key});

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  static const Color wine = Color(0xFF5B2333);
  static const Color bg = Color(0xFFF8F7F6);
  static const Color textDark = Color(0xFF202124);

  bool isLoading = true;
  bool isAnalyzing = false;

  List<ProductModel> products = [];
  ProductModel? selectedProduct;
  Map<String, dynamic>? analysis;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final result = await ApiService.fetchProducts();
      if (!mounted) return;

      setState(() {
        products = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> analyzeProduct() async {
    if (selectedProduct == null) return;

    setState(() {
      isAnalyzing = true;
      analysis = null;
    });

    try {
      final result = await ApiService.analyzeProductWithAI(
        productId: selectedProduct!.id,
      );

      if (!mounted) return;

      if (result["statusCode"] == 200) {
        setState(() {
          analysis = result["data"]["analysis"];
        });
      } else {
        _showError("AI analysis failed. Try again.");
      }
    } catch (e) {
      _showError("Could not connect to AI analysis.");
    } finally {
      if (mounted) {
        setState(() => isAnalyzing = false);
      }
    }
  }

  void _showProductPicker() {
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
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedProduct = product;
                          analysis = null;
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
                            //const Icon(Icons.chevron_right_rounded),
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

  Widget _selectedProductCard() {
    final product = selectedProduct;

    if (product == null) {
      return GestureDetector(
        onTap: _showProductPicker,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.add_circle_outline_rounded,
                color: wine,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                "Choose a product to analyze",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _productImage(product, 86),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand,
                  style: GoogleFonts.poppins(
                    color: wine,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: textDark,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${product.price.toStringAsFixed(0)} ${product.currency}",
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showProductPicker,
            icon: const Icon(
              Icons.tune_rounded,
              color: wine,
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisCard() {
    if (analysis == null) return const SizedBox.shrink();

    final matchLevel = analysis!["matchLevel"] ?? "Use with caution";
    final score = analysis!["score"]?.toString() ?? "0";
    final summary = analysis!["summary"] ?? "";
    final recommendation = analysis!["recommendation"] ?? "";

    final goodPoints = List<String>.from(analysis!["goodPoints"] ?? []);
    final cautionPoints = List<String>.from(analysis!["cautionPoints"] ?? []);
    final ingredientNotes =
        List<String>.from(analysis!["ingredientNotes"] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: wine,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                matchLevel,
                style: GoogleFonts.marcellus(
                  fontSize: 25,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "AI Match Score: $score%",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                summary,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _listBox("Good points", goodPoints, Icons.check_circle_outline),
        _listBox("Caution points", cautionPoints, Icons.warning_amber_rounded),
        _listBox("Ingredient notes", ingredientNotes, Icons.science_outlined),
        const SizedBox(height: 10),
        _recommendationBox(recommendation),
      ],
    );
  }

  Widget _listBox(String title, List<String> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: wine, size: 21),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "• $item",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendationBox(String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: wine),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: textDark,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFCFAF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: wine, size: 44),
              const SizedBox(height: 12),
              Text(
                "Analysis failed",
                style: GoogleFonts.marcellus(
                  fontSize: 22,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyIntro() {
    return Column(
      children: [
        const Icon(
          Icons.auto_awesome_rounded,
          color: wine,
          size: 54,
        ),
        const SizedBox(height: 14),
        Text(
          "AI Product Analysis",
          style: GoogleFonts.marcellus(
            fontSize: 30,
            color: textDark,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Choose a skincare product and let Skinova AI explain if it fits your skin needs.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.black54,
            height: 1.5,
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
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        centerTitle: true,
        title: Text(
          "Analyze",
          style: GoogleFonts.poppins(
            color: textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              children: [
                if (selectedProduct == null) ...[
                  const SizedBox(height: 60),
                  _emptyIntro(),
                  const SizedBox(height: 28),
                ],
                _selectedProductCard(),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: wine,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: selectedProduct == null || isAnalyzing
                        ? null
                        : analyzeProduct,
                    child: isAnalyzing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Analyze with AI",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 22),
                _analysisCard(),
              ],
            ),
    );
  }
}
