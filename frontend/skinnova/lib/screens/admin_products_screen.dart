import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});
  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  bool _loading = true;
  List _products = [];
  int _total = 0;
  String _adminId = '';
  final _searchCtrl = TextEditingController();
  String _categoryFilter = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminId = prefs.getString('userId') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.adminGetProducts(_adminId,
          search: _searchCtrl.text.trim(), category: _categoryFilter);
      if (!mounted) return;
      setState(() {
        _products = data['products'] as List? ?? [];
        _total = data['total'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showFullProductDialog([Map? product]) {
    // ── Text controllers ──
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final brandCtrl = TextEditingController(text: product?['brand'] ?? '');
    final brandOriginCtrl =
        TextEditingController(text: product?['brandOrigin'] ?? '');
    final catCtrl = TextEditingController(text: product?['category'] ?? '');
    final shortDescCtrl =
        TextEditingController(text: product?['shortDescription'] ?? '');
    final directionsCtrl =
        TextEditingController(text: product?['directionsOfUse'] ?? '');
    final imageCtrl = TextEditingController(text: product?['imageUrl'] ?? '');

    final sizeCtrl = TextEditingController(text: product?['size'] ?? '');

    // Ingredients list
    final List<Map<String, dynamic>> ingredients = List.from(
      (product?['ingredients'] as List? ?? []).map((i) => {
            'name': TextEditingController(text: (i as Map)['name'] ?? ''),
            'description': TextEditingController(text: i['description'] ?? ''),
          }),
    );

    // recommendedFor
    final skinTypesCtrl = TextEditingController(
        text:
            ((product?['recommendedFor'] as Map?)?['skinTypes'] as List? ?? [])
                .join(', '));
    final concernsCtrl = TextEditingController(
        text: ((product?['recommendedFor'] as Map?)?['concerns'] as List? ?? [])
            .join(', '));
    final goalsCtrl = TextEditingController(
        text: ((product?['recommendedFor'] as Map?)?['goals'] as List? ?? [])
            .join(', '));

    // Booleans
    final wi = (product?['whatsInside'] as Map?) ?? {};
    bool isPublished = product?['isPublished'] != false;
    bool isHidden = product?['isHidden'] == true;

    // whatsInside flags
    final Map<String, bool> insideFlags = {
      'alcoholFree': wi['alcoholFree'] == true,
      'euAllergenFree': wi['euAllergenFree'] == true,
      'fragranceFree': wi['fragranceFree'] == true,
      'oilFree': wi['oilFree'] == true,
      'parabenFree': wi['parabenFree'] == true,
      'siliconeFree': wi['siliconeFree'] == true,
      'sulfateFree': wi['sulfateFree'] == true,
      'crueltyFree': wi['crueltyFree'] == true,
      'fungalAcneSafe': wi['fungalAcneSafe'] == true,
      'reefSafe': wi['reefSafe'] == true,
      'vegan': wi['vegan'] == true,
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          void addIngredient() => setS(() => ingredients.add({
                'name': TextEditingController(),
                'description': TextEditingController(),
              }));

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(product == null ? "Add Product" : "Edit Product",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AdminTheme.black)),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Basic Info ──
                      _sectionLabel("Basic Information"),
                      _row2([
                        _f("Product Name *", nameCtrl),
                        _f("Brand *", brandCtrl)
                      ]),
                      const SizedBox(height: 10),
                      _row2([
                        _f("Brand Origin", brandOriginCtrl),
                        _f("Category", catCtrl, hint: "moisturizer, serum…")
                      ]),
                      const SizedBox(height: 10),
                      _f("Short Description", shortDescCtrl, maxLines: 3),
                      const SizedBox(height: 10),
                      _f("Directions of Use", directionsCtrl, maxLines: 3),
                      const SizedBox(height: 10),
                      _f("Main Image URL", imageCtrl),

                      // ── Pricing & Stock ──

                      const SizedBox(height: 10),
                      _f("Size / Volume", sizeCtrl, hint: "e.g. 50ml"),
                      const SizedBox(height: 10),

                      _switchRow("Published (visible to users)", isPublished,
                          (v) => setS(() => isPublished = v)),
                      _switchRow("Hidden (admin override)", isHidden,
                          (v) => setS(() => isHidden = v)),

                      // ── Recommended For ──
                      const SizedBox(height: 16),
                      _sectionLabel("Recommended For (comma-separated)"),
                      _f("Skin Types", skinTypesCtrl,
                          hint: "oily, dry, combination…"),
                      const SizedBox(height: 10),
                      _f("Skin Concerns", concernsCtrl,
                          hint: "acne, wrinkles, dark spots…"),
                      const SizedBox(height: 10),
                      _f("Goals", goalsCtrl, hint: "hydration, brightening…"),

                      // ── What's Inside ──
                      const SizedBox(height: 16),
                      _sectionLabel("What's Inside (certifications)"),
                      Wrap(
                        spacing: 0,
                        runSpacing: 0,
                        children: insideFlags.keys.map((key) {
                          final label = _flagLabel(key);
                          return SizedBox(
                            width: 250,
                            child: CheckboxListTile(
                              dense: true,
                              title: Text(label,
                                  style: GoogleFonts.poppins(fontSize: 12.5)),
                              value: insideFlags[key],
                              activeColor: AdminTheme.wine,
                              onChanged: (v) =>
                                  setS(() => insideFlags[key] = v!),
                            ),
                          );
                        }).toList(),
                      ),

                      // ── Ingredients ──
                      const SizedBox(height: 16),
                      Row(children: [
                        _sectionLabel("Ingredients"),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: addIngredient,
                          icon: const Icon(Icons.add,
                              size: 14, color: AdminTheme.wine),
                          label: Text("Add",
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: AdminTheme.wine)),
                        ),
                      ]),
                      ...ingredients.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              Expanded(child: _f("Name", e.value['name'])),
                              const SizedBox(width: 8),
                              Expanded(
                                  flex: 2,
                                  child: _f(
                                      "Description", e.value['description'])),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 18, color: Colors.red),
                                onPressed: () =>
                                    setS(() => ingredients.removeAt(e.key)),
                              ),
                            ]),
                          )),
                    ]),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Cancel",
                      style: GoogleFonts.poppins(color: AdminTheme.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.wine,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final data = {
                      'name': nameCtrl.text.trim(),
                      'brand': brandCtrl.text.trim(),
                      'brandOrigin': brandOriginCtrl.text.trim(),
                      'category': catCtrl.text.trim().toLowerCase(),
                      'shortDescription': shortDescCtrl.text.trim(),
                      'directionsOfUse': directionsCtrl.text.trim(),
                      'imageUrl': imageCtrl.text.trim(),
                      'size': sizeCtrl.text.trim(),
                      'isPublished': isPublished,
                      'isHidden': isHidden,
                      'recommendedFor': {
                        'skinTypes': skinTypesCtrl.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList(),
                        'concerns': concernsCtrl.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList(),
                        'goals': goalsCtrl.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList(),
                      },
                      'whatsInside': Map<String, bool>.from(insideFlags),
                      'ingredients': ingredients
                          .map((i) => {
                                'name': (i['name'] as TextEditingController)
                                    .text
                                    .trim(),
                                'description':
                                    (i['description'] as TextEditingController)
                                        .text
                                        .trim(),
                              })
                          .where((i) => (i['name'] as String).isNotEmpty)
                          .toList(),
                    };
                    if (product == null) {
                      await ApiService.adminCreateProduct(_adminId, data);
                      _showSnack("Product created");
                    } else {
                      await ApiService.adminUpdateProduct(
                          _adminId, product['_id'], data);
                      _showSnack("Product updated");
                    }
                    _load();
                  } catch (e) {
                    _showSnack(e.toString(), error: true);
                  }
                },
                child: Text("Save Product",
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _flagLabel(String key) {
    const map = {
      'alcoholFree': 'Alcohol Free',
      'euAllergenFree': 'EU Allergen Free',
      'fragranceFree': 'Fragrance Free',
      'oilFree': 'Oil Free',
      'parabenFree': 'Paraben Free',
      'siliconeFree': 'Silicone Free',
      'sulfateFree': 'Sulfate Free',
      'crueltyFree': 'Cruelty Free',
      'fungalAcneSafe': 'Fungal Acne Safe',
      'reefSafe': 'Reef Safe',
      'vegan': 'Vegan',
    };
    return map[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AdminTheme.wine))
              : _products.isEmpty
                  ? _emptyState()
                  : _buildList(),
        ),
      ],
    );
  }

  Widget _topBar() => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        color: AdminTheme.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text("Products", style: AdminTheme.title(20)),
              const SizedBox(width: 10),
              _badge(_total),
              const Spacer(),
              _wineBtn(
                  "Add Product", Icons.add, () => _showFullProductDialog()),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _load(),
                decoration: _inputDec("Search products...").copyWith(
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: AdminTheme.grey)),
                style: GoogleFonts.poppins(fontSize: 13),
              )),
              const SizedBox(width: 10),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _categoryFilter.isEmpty ? null : _categoryFilter,
                  hint: Text("Category",
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AdminTheme.grey)),
                  borderRadius: BorderRadius.circular(12),
                  items: [
                    '',
                    'moisturizer',
                    'serum',
                    'cleanser',
                    'sunscreen',
                    'toner',
                    'mask',
                    'eye cream',
                    'other'
                  ]
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.isEmpty ? 'All' : c,
                              style: GoogleFonts.poppins(fontSize: 13))))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _categoryFilter = v ?? '');
                    _load();
                  },
                ),
              ),
            ]),
          ],
        ),
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _products.length,
        itemBuilder: (_, i) => _buildRow(_products[i] as Map),
      );

  Widget _buildRow(Map p) {
    final isHidden = p['isHidden'] == true;
    final isPublished = p['isPublished'] != false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration:
          AdminTheme.cardDec(color: isHidden ? const Color(0xFFFDF5F5) : null),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (p['imageUrl'] ?? '').toString().isNotEmpty
                ? Image.network(p['imageUrl'],
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder())
                : _imgPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name'] ?? '',
                  style: AdminTheme.title(13.5, w: FontWeight.w500)),
              Text("${p['brand'] ?? ''} · ${p['category'] ?? ''}",
                  style: AdminTheme.sub(12)),
              Row(children: [
                // Text("${p['price'] ?? 0} ${p['currency'] ?? 'ILS'}",
                //     style: GoogleFonts.poppins(
                //         fontSize: 11.5,
                //         color: AdminTheme.wine,
                //         fontWeight: FontWeight.w600)),
                // const SizedBox(width: 8),
                if (!isPublished) _pill("Unpublished", Colors.grey),
                if (isHidden) _pill("Hidden", Colors.orange.shade400),
              ]),
            ]),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 18, color: AdminTheme.grey),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) async {
              if (v == 'details') _showProductDetailsDialog(p);

              if (v == 'edit') _showFullProductDialog(p);
              if (v == 'hide') {
                await ApiService.adminToggleProductHidden(_adminId, p['_id']);
                _showSnack(isHidden ? "Product shown" : "Product hidden");
                _load();
              }
              if (v == 'delete') {
                if (await _confirm("Delete this product permanently?")) {
                  await ApiService.adminDeleteProduct(_adminId, p['_id']);
                  _showSnack("Product deleted");
                  _load();
                }
              }
            },
            itemBuilder: (_) => [
              _popItem('details', 'View Details', Icons.info_outline_rounded),
              _popItem('edit', 'Edit', Icons.edit_outlined),
              _popItem(
                'hide',
                isHidden ? 'Show Product' : 'Hide Product',
                isHidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              _popItem('delete', 'Delete', Icons.delete_outline, danger: true),
            ],
          ),
        ],
      ),
    );
  }

  void _showProductDetailsDialog(Map p) {
    final wi = (p['whatsInside'] as Map?) ?? {};
    final ingredients = p['ingredients'] as List? ?? [];
    final recommended = (p['recommendedFor'] as Map?) ?? {};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          p['name'] ?? 'Product Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AdminTheme.black,
          ),
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((p['imageUrl'] ?? '').toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      p['imageUrl'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                const SizedBox(height: 14),
                _detailRow("Brand", p['brand']),
                _detailRow("Category", p['category']),
                _detailRow("Brand Origin", p['brandOrigin']),
                _detailRow("Size", p['size']),
                _detailRow("Rating", p['rating']),
                _detailRow(
                    "Published", p['isPublished'] == false ? "No" : "Yes"),
                _detailRow("Hidden", p['isHidden'] == true ? "Yes" : "No"),
                const SizedBox(height: 12),
                _sectionLabel("Description"),
                Text(
                  (p['shortDescription'] ?? 'No description').toString(),
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AdminTheme.black),
                ),
                const SizedBox(height: 12),
                _sectionLabel("Directions of Use"),
                Text(
                  (p['directionsOfUse'] ?? 'No directions').toString(),
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AdminTheme.black),
                ),
                const SizedBox(height: 12),
                _sectionLabel("Recommended For"),
                _detailRow("Skin Types",
                    ((recommended['skinTypes'] as List?) ?? []).join(', ')),
                _detailRow("Concerns",
                    ((recommended['concerns'] as List?) ?? []).join(', ')),
                _detailRow("Goals",
                    ((recommended['goals'] as List?) ?? []).join(', ')),
                const SizedBox(height: 12),
                _sectionLabel("What's Inside"),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: wi.entries
                      .where((e) => e.value == true)
                      .map((e) => _pill(_flagLabel(e.key), AdminTheme.wine))
                      .toList(),
                ),
                const SizedBox(height: 12),
                _sectionLabel("Ingredients"),
                if (ingredients.isEmpty)
                  Text("No ingredients", style: AdminTheme.sub(12))
                else
                  ...ingredients.map((i) {
                    final item = i as Map;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "• ${item['name'] ?? ''}: ${item['description'] ?? ''}",
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Close",
                style: GoogleFonts.poppins(color: AdminTheme.wine)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    final text =
        (value == null || value.toString().isEmpty) ? "-" : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AdminTheme.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AdminTheme.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
      width: 48,
      height: 48,
      color: AdminTheme.wineMuted,
      child: const Icon(Icons.image_not_supported_outlined,
          color: AdminTheme.wine, size: 20));

  Widget _sectionLabel(String l) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(l,
            style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AdminTheme.wine)),
      );

  Widget _row2(List<Widget> children) => Row(
        children: [
          Expanded(child: children[0]),
          const SizedBox(width: 10),
          Expanded(child: children[1]),
        ],
      );

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Text(label,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: AdminTheme.black)),
          const Spacer(),
          Switch(
              value: value, activeColor: AdminTheme.wine, onChanged: onChanged),
        ]),
      );

  Widget _f(String label, TextEditingController ctrl,
          {String? hint, int maxLines = 1}) =>
      TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: _inputDec(label, hint: hint),
          style: GoogleFonts.poppins(fontSize: 13));

  Widget _pill(String label, Color color) => Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      );

  PopupMenuItem<String> _popItem(String v, String l, IconData i,
          {bool danger = false}) =>
      PopupMenuItem(
          value: v,
          child: Row(children: [
            Icon(i,
                size: 16,
                color: danger ? Colors.red.shade400 : AdminTheme.grey),
            const SizedBox(width: 8),
            Text(l,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: danger ? Colors.red.shade400 : AdminTheme.black)),
          ]));

  Widget _badge(int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
            color: AdminTheme.wineMuted,
            borderRadius: BorderRadius.circular(20)),
        child: Text("$n",
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: AdminTheme.wine,
                fontWeight: FontWeight.w600)),
      );

  Widget _wineBtn(String label, IconData icon, VoidCallback onTap) =>
      ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17, color: Colors.white),
        label: Text(label,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.wine,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
      );

  Widget _emptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inventory_2_outlined,
            size: 60, color: AdminTheme.grey.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text("No products found", style: AdminTheme.sub(15)),
      ]));

  InputDecoration _inputDec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Future<bool> _confirm(String msg) async =>
      await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text("Confirm",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, color: AdminTheme.black)),
                content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text("Cancel",
                          style: GoogleFonts.poppins(color: AdminTheme.grey))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text("Confirm",
                          style: GoogleFonts.poppins(color: Colors.white))),
                ],
              )) ??
      false;

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? Colors.red.shade400 : AdminTheme.wine,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
