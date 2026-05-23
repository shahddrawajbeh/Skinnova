import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../active_ingredient_model.dart';
import '../product_model.dart';
import 'product_details_screen.dart';

class IngredientDetailsScreen extends StatefulWidget {
  final String slug;
  final String userId;
  final String userName;

  const IngredientDetailsScreen({
    super.key,
    required this.slug,
    required this.userId,
    required this.userName,
  });

  @override
  State<IngredientDetailsScreen> createState() =>
      _IngredientDetailsScreenState();
}

class _IngredientDetailsScreenState extends State<IngredientDetailsScreen> {
  ActiveIngredientModel? ingredient;
  List<ProductModel> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  Future<void> loadDetails() async {
    try {
      final data = await ApiService.fetchActiveIngredientDetails(widget.slug);

      setState(() {
        ingredient = ActiveIngredientModel.fromJson(data["ingredient"]);
        products = (data["products"] as List<dynamic>? ?? [])
            .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Ingredient details error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (ingredient == null) {
      return const Scaffold(
        body: Center(child: Text("Ingredient not found")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.grey,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Container(
              height: 230,
              width: double.infinity,
              color: Colors.white,
              child: ingredient!.imageUrl.isNotEmpty
                  ? ingredient!.imageUrl.startsWith("http")
                      ? Image.network(
                          ingredient!.imageUrl,
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          ingredient!.imageUrl,
                          fit: BoxFit.contain,
                        )
                  : const Icon(Icons.science_outlined, size: 80),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient!.name,
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ingredient!.description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF444444),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Most suitable for:",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: ingredient!.suitableFor.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFEDEDED),
                            width: 1.5,
                          ),
                          color: Colors.white,
                        ),
                        child: Text(
                          item,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF5B2333),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Products containing ${ingredient!.name.toLowerCase()}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (products.isEmpty)
                    Text(
                      "No products found",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    )
                  else
                    Column(
                      children: products.map((product) {
                        return _productTile(product);
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productTile(ProductModel product) {
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.image_outlined),
            ),
            const SizedBox(width: 18),
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
                      color: const Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.brand,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  if (product.rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < product.rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 17,
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
