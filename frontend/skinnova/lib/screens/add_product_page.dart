import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color wine = Color(0xFF5B2333);

  static const Color cardColor = Colors.white;
  static const Color softBorder = Color(0xFFE6D9D6);
  static const Color softFill = Color(0xFFFCF8F7);
  static const Color textDark = Color(0xFF2B1C1F);

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final shortDescriptionController = TextEditingController();
  final imageUrlController = TextEditingController();
  final brandOriginController = TextEditingController();

  final priceController = TextEditingController();
  final currencyController = TextEditingController(text: "USD");
  final stockCountController = TextEditingController();
  final sizeController = TextEditingController();
  final discountPercentController = TextEditingController(text: "0");

  final ingredientNameController = TextEditingController();
  final ingredientDescriptionController = TextEditingController();

  final goalController = TextEditingController();

  bool inStock = true;

  bool alcoholFree = false;
  bool euAllergenFree = false;
  bool fragranceFree = false;
  bool oilFree = false;
  bool parabenFree = false;
  bool siliconeFree = false;
  bool sulfateFree = false;
  bool crueltyFree = false;
  bool fungalAcneSafe = false;
  bool reefSafe = false;
  bool vegan = false;

  bool isLoading = false;

  final List<Map<String, dynamic>> ingredients = [];
  final List<String> selectedSkinTypes = [];
  final List<String> selectedConcerns = [];
  final List<String> selectedGoals = [];

  final List<String> skinTypeOptions = [
    "Dry",
    "Oily",
    "Combination",
    "Normal",
    "Sensitive",
  ];

  final List<String> concernOptions = [
    "Acne & Blemishes",
    "Blackheads",
    "Dark Spots",
    "Dryness",
    "Oiliness",
    "Redness",
    "Dullness",
    "Uneven Texture",
    "Visible Pores",
    "Dark Circles",
    "Fine Lines & Wrinkles",
    "Sensitive Skin",
  ];

  final List<String> goalOptions = [
    "Scan and analyze my skin",
    "Fix my skin concerns",
    "Get personalized product recommendations",
    "Build a skincare routine",
    "Track my skin progress",
    "Learn about skincare ingredients",
  ];

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    shortDescriptionController.dispose();
    imageUrlController.dispose();
    brandOriginController.dispose();

    priceController.dispose();
    currencyController.dispose();
    stockCountController.dispose();
    sizeController.dispose();
    discountPercentController.dispose();

    ingredientNameController.dispose();
    ingredientDescriptionController.dispose();
    goalController.dispose();
    super.dispose();
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(priceController.text.trim());
    final stockCount = int.tryParse(stockCountController.text.trim());
    final discountPercent = int.tryParse(discountPercentController.text.trim());

    if (price == null || stockCount == null || discountPercent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid numeric values")),
      );
      return;
    }

    if (price < 0 || stockCount < 0 || discountPercent < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Values cannot be negative")),
      );
      return;
    }

    setState(() => isLoading = true);

    final body = {
      "brand": brandController.text.trim(),
      "name": nameController.text.trim(),
      "shortDescription": shortDescriptionController.text.trim(),
      "imageUrl": imageUrlController.text.trim(),
      "rating": 0,
      "reviews": [],
      "whatsInside": {
        "alcoholFree": alcoholFree,
        "euAllergenFree": euAllergenFree,
        "fragranceFree": fragranceFree,
        "oilFree": oilFree,
        "parabenFree": parabenFree,
        "siliconeFree": siliconeFree,
        "sulfateFree": sulfateFree,
        "crueltyFree": crueltyFree,
        "fungalAcneSafe": fungalAcneSafe,
        "reefSafe": reefSafe,
        "vegan": vegan,
      },
      "ingredients": ingredients,
      "brandOrigin": brandOriginController.text.trim(),
      "price": price,
      "currency": currencyController.text.trim(),
      "inStock": inStock,
      "stockCount": stockCount,
      "size": sizeController.text.trim(),
      "discountPercent": discountPercent,
      "recommendedFor": {
        "skinTypes": selectedSkinTypes,
        "concerns": selectedConcerns,
        "goals": selectedGoals,
      },
      "isPublished": true,
    };

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:5000/api/products"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product added successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void addIngredient() {
    final name = ingredientNameController.text.trim();
    final description = ingredientDescriptionController.text.trim();

    if (name.isEmpty || description.isEmpty) return;

    setState(() {
      ingredients.add({
        "name": name,
        "description": description,
      });
      ingredientNameController.clear();
      ingredientDescriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteSmoke,
      appBar: AppBar(
        backgroundColor: whiteSmoke,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Add Product",
          style: GoogleFonts.marcellus(
            color: wine,
            fontSize: 26,
          ),
        ),
        iconTheme: const IconThemeData(color: wine),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _sectionTitle("Basic Info"),
            _card(
              child: Column(
                children: [
                  _textField(nameController, "Product Name"),
                  _textField(brandController, "Brand"),
                  _textField(shortDescriptionController, "Short Description"),
                  _textField(imageUrlController, "Image URL"),
                  _textField(brandOriginController, "Brand Origin"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle("Purchase Info"),
            _card(
              child: Column(
                children: [
                  _textField(
                    priceController,
                    "Price",
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  _textField(currencyController, "Currency"),
                  _textField(
                    stockCountController,
                    "Stock Count",
                    keyboardType: TextInputType.number,
                  ),
                  _textField(sizeController, "Size"),
                  _textField(
                    discountPercentController,
                    "Discount Percent",
                    keyboardType: TextInputType.number,
                  ),
                  _switchTile(
                    "In Stock",
                    inStock,
                    (v) => setState(() => inStock = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle("What's Inside"),
            _card(
              child: Column(
                children: [
                  _switchTile(
                    "Alcohol Free",
                    alcoholFree,
                    (v) => setState(() => alcoholFree = v),
                  ),
                  _switchTile(
                    "EU Allergen Free",
                    euAllergenFree,
                    (v) => setState(() => euAllergenFree = v),
                  ),
                  _switchTile(
                    "Fragrance Free",
                    fragranceFree,
                    (v) => setState(() => fragranceFree = v),
                  ),
                  _switchTile(
                    "Oil Free",
                    oilFree,
                    (v) => setState(() => oilFree = v),
                  ),
                  _switchTile(
                    "Paraben Free",
                    parabenFree,
                    (v) => setState(() => parabenFree = v),
                  ),
                  _switchTile(
                    "Silicone Free",
                    siliconeFree,
                    (v) => setState(() => siliconeFree = v),
                  ),
                  _switchTile(
                    "Sulfate Free",
                    sulfateFree,
                    (v) => setState(() => sulfateFree = v),
                  ),
                  _switchTile(
                    "Cruelty Free",
                    crueltyFree,
                    (v) => setState(() => crueltyFree = v),
                  ),
                  _switchTile(
                    "Fungal Acne Safe",
                    fungalAcneSafe,
                    (v) => setState(() => fungalAcneSafe = v),
                  ),
                  _switchTile(
                    "Reef Safe",
                    reefSafe,
                    (v) => setState(() => reefSafe = v),
                  ),
                  _switchTile(
                    "Vegan",
                    vegan,
                    (v) => setState(() => vegan = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle("Recommended For"),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label("Skin Types"),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skinTypeOptions.map((type) {
                      final isSelected = selectedSkinTypes.contains(type);
                      return _choiceChip(
                        label: type,
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            isSelected
                                ? selectedSkinTypes.remove(type)
                                : selectedSkinTypes.add(type);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  _label("Concerns"),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: concernOptions.map((concern) {
                      final isSelected = selectedConcerns.contains(concern);
                      return _choiceChip(
                        label: concern,
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            isSelected
                                ? selectedConcerns.remove(concern)
                                : selectedConcerns.add(concern);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  _label("Goals"),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: goalOptions.map((goal) {
                      final isSelected = selectedGoals.contains(goal);
                      return _choiceChip(
                        label: goal,
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            isSelected
                                ? selectedGoals.remove(goal)
                                : selectedGoals.add(goal);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle("Ingredients"),
            _card(
              child: Column(
                children: [
                  _plainField(ingredientNameController, "Ingredient Name"),
                  const SizedBox(height: 12),
                  _plainField(
                    ingredientDescriptionController,
                    "Ingredient Description",
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _smallButton("Add Ingredient", addIngredient),
                  ),
                  const SizedBox(height: 12),
                  ...ingredients.map(
                    (ingredient) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        ingredient["name"],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: wine,
                        ),
                      ),
                      subtitle: Text(
                        ingredient["description"],
                        style: GoogleFonts.poppins(color: textDark),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            ingredients.remove(ingredient);
                          });
                        },
                        icon: const Icon(Icons.delete_outline, color: wine),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: wine,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Save Product",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: wine,
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: softBorder),
        boxShadow: [
          BoxShadow(
            color: wine.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Required";
          }
          return null;
        },
        decoration: _inputDecoration(label),
      ),
    );
  }

  Widget _plainField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color: wine.withOpacity(0.7),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: softFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: softBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: wine, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }

  Widget _smallButton(String text, VoidCallback onTap) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: wine,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _switchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: wine,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
      ),
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: selected ? Colors.white : wine,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: wine,
      backgroundColor: whiteSmoke,
      side: const BorderSide(color: softBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}
