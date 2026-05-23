import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class SellerAddProductPage extends StatefulWidget {
  const SellerAddProductPage({super.key});

  @override
  State<SellerAddProductPage> createState() => _SellerAddProductPageState();
}

class _SellerAddProductPageState extends State<SellerAddProductPage> {
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);

  List<dynamic> products = [];
  dynamic selectedProduct;

  final priceController = TextEditingController();
  final stockController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final result = await ApiService.fetchProducts();

      setState(() {
        products = result.map((p) => p.toJson()).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Load products error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveProduct() async {
    if (selectedProduct == null ||
        priceController.text.trim().isEmpty ||
        stockController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final result = await ApiService.addStoreProduct(
        productId: selectedProduct["_id"],
        price: double.parse(priceController.text.trim()),
        stockCount: int.parse(stockController.text.trim()),
      );

      if (!mounted) return;

      if (result["statusCode"] == 201 || result["statusCode"] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product added to your store")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["data"]["message"] ?? "Failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: softBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: wine),
        centerTitle: true,
        title: Text(
          "Add Product",
          style: GoogleFonts.poppins(
            color: wine,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Choose a product",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<dynamic>(
                        value: selectedProduct,
                        isExpanded: true,
                        hint: Text(
                          "Select product",
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        items: products.map((product) {
                          return DropdownMenuItem(
                            value: product,
                            child: Text(
                              "${product["brand"] ?? ""} - ${product["name"] ?? ""}",
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 12.5),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedProduct = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _field(
                    controller: priceController,
                    hint: "Price",
                    icon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: stockController,
                    hint: "Stock count",
                    icon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: wine,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Add to Store",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: wine),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
