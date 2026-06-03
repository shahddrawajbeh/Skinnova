import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class SellerProductsScreen extends StatefulWidget {
  final String storeId;
  final VoidCallback onAddProduct;
  const SellerProductsScreen({
    super.key,
    required this.storeId,
    required this.onAddProduct,
  });

  @override
  State<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen> {
  // ─── Palette ───────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  List<dynamic> _products = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  String _search = '';
  String _filter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<String> _filters = [
    'All',
    'In Stock',
    'Out of Stock',
    'Low Stock'
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final products = await ApiService.fetchAllSellerProducts(widget.storeId);
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
      _applyFilter();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _search.toLowerCase().trim();
    setState(() {
      _filtered = _products.where((p) {
        final product = p['productId'];
        final name = ((product is Map ? product['name'] : null) ?? '')
            .toString()
            .toLowerCase();
        final brand = ((product is Map ? product['brand'] : null) ?? '')
            .toString()
            .toLowerCase();
        final matchesSearch =
            query.isEmpty || name.contains(query) || brand.contains(query);

        final stock = (p['stockCount'] as num?)?.toInt() ?? 0;
        final available = p['isAvailable'] == true;
        bool matchesFilter;
        switch (_filter) {
          case 'In Stock':
            matchesFilter = available && stock > 0;
            break;
          case 'Out of Stock':
            matchesFilter = !available || stock == 0;
            break;
          case 'Low Stock':
            matchesFilter = available && stock > 0 && stock <= 5;
            break;
          default:
            matchesFilter = true;
        }
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        _buildFilterChips(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: wine))
              : _filtered.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      color: wine,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildProductCard(_filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      color: warmCream,
      child: Row(
        children: [
          Text(
            'Products',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: deepPlum,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: wine.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_products.length}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: wine,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onAddProduct,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B2333), Color(0xFF8B3A4A)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: wine.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: warmCream,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          _search = v;
          _applyFilter();
        },
        style: GoogleFonts.poppins(fontSize: 14, color: darkText),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: grey),
          prefixIcon: const Icon(Icons.search_rounded, color: grey, size: 20),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: grey),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search = '';
                    _applyFilter();
                  },
                )
              : null,
          filled: true,
          fillColor: softBg,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: warmCream,
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final selected = _filter == f;
          return GestureDetector(
            onTap: () {
              setState(() => _filter = f);
              _applyFilter();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? wine : softBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? wine : line,
                ),
              ),
              child: Text(
                f,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: grey.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            _search.isNotEmpty
                ? 'No products match your search'
                : 'No products found',
            style: GoogleFonts.poppins(fontSize: 15, color: grey),
          ),
          if (_search.isEmpty && _filter == 'All') ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: widget.onAddProduct,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B2333), Color(0xFF8B3A4A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Add your first product',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> sp) {
    final spId = sp['_id']?.toString() ?? '';
    final product = sp['productId'];
    final name = (product is Map ? product['name'] : null) ?? 'Unknown';
    final brand = (product is Map ? product['brand'] : null) ?? '';
    final imageUrl = (product is Map ? product['imageUrl'] : null) ?? '';
    final category = (product is Map ? product['category'] : null) ?? '';
    final price = (sp['price'] as num?)?.toDouble() ?? 0;
    final stock = (sp['stockCount'] as num?)?.toInt() ?? 0;
    final sold = (sp['soldCount'] as num?)?.toInt() ?? 0;
    final currency = sp['currency']?.toString() ?? 'ILS';
    final isAvailable = sp['isAvailable'] == true;

    Color stockColor;
    String stockLabel;
    if (!isAvailable || stock == 0) {
      stockColor = const Color(0xFFF44336);
      stockLabel = 'Out of Stock';
    } else if (stock <= 5) {
      stockColor = const Color(0xFFFF9800);
      stockLabel = 'Low: $stock left';
    } else {
      stockColor = const Color(0xFF4CAF50);
      stockLabel = '$stock in stock';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product image ────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                if (!isAvailable || stock == 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336).withOpacity(0.85),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(10)),
                      ),
                      child: Text(
                        'Out',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: darkText,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (brand.toString().isNotEmpty)
                              Text(
                                brand.toString(),
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: grey),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded,
                            size: 18, color: grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (val) {
                          if (val == 'edit') _openEditSheet(sp);
                          if (val == 'delete')
                            _confirmDelete(spId, name.toString());
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              const Icon(Icons.edit_outlined,
                                  size: 16, color: wine),
                              const SizedBox(width: 8),
                              Text('Edit',
                                  style: GoogleFonts.poppins(fontSize: 13)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              const Icon(Icons.delete_outline_rounded,
                                  size: 16, color: Color(0xFFF44336)),
                              const SizedBox(width: 8),
                              Text('Remove',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFFF44336))),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '$currency ${price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: wine,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: stockColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          stockLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: stockColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (category.toString().isNotEmpty) ...[
                        const Icon(Icons.category_outlined,
                            size: 11, color: grey),
                        const SizedBox(width: 3),
                        Text(
                          category.toString(),
                          style: GoogleFonts.poppins(fontSize: 11, color: grey),
                        ),
                        const SizedBox(width: 12),
                      ],
                      const Icon(Icons.shopping_bag_outlined,
                          size: 11, color: grey),
                      const SizedBox(width: 3),
                      Text(
                        '$sold sold',
                        style: GoogleFonts.poppins(fontSize: 11, color: grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image_outlined, size: 28, color: grey),
    );
  }

  // ─── Edit bottom sheet ─────────────────────────────────────────────────────
  void _openEditSheet(Map<String, dynamic> sp) {
    final spId = sp['_id']?.toString() ?? '';
    final product = sp['productId'];
    final name = (product is Map ? product['name'] : null) ?? 'Product';
    final currentPrice = (sp['price'] as num?)?.toDouble() ?? 0;
    final currentStock = (sp['stockCount'] as num?)?.toInt() ?? 0;

    final priceCtrl =
        TextEditingController(text: currentPrice.toStringAsFixed(2));
    final stockCtrl = TextEditingController(text: currentStock.toString());
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Product',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: deepPlum,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name.toString(),
                style: GoogleFonts.poppins(fontSize: 13, color: grey),
              ),
              const SizedBox(height: 20),
              Text(
                'Price',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money_rounded,
                      size: 18, color: grey),
                  hintText: 'Enter price',
                  filled: true,
                  fillColor: softBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.poppins(fontSize: 14, color: darkText),
              ),
              const SizedBox(height: 16),
              Text(
                'Stock Count',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.inventory_2_outlined,
                      size: 18, color: grey),
                  hintText: 'Enter stock count',
                  filled: true,
                  fillColor: softBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.poppins(fontSize: 14, color: darkText),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newPrice =
                              double.tryParse(priceCtrl.text.trim());
                          final newStock = int.tryParse(stockCtrl.text.trim());
                          if (newPrice == null || newStock == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please enter valid price and stock')),
                            );
                            return;
                          }
                          setSheetState(() => isSaving = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await ApiService.updateStoreProductData(
                            spId: spId,
                            price: newPrice,
                            stockCount: newStock,
                          );
                          if (!mounted) return;
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (ok) {
                            _loadProducts();
                            messenger.showSnackBar(
                              const SnackBar(
                                  content: Text('Product updated successfully'),
                                  backgroundColor: Color(0xFF4CAF50)),
                            );
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to update product')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Delete confirmation ───────────────────────────────────────────────────
  void _confirmDelete(String spId, String name) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.delete_outline_rounded,
                size: 44, color: Color(0xFFF44336)),
            const SizedBox(height: 12),
            Text(
              'Remove Product?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: deepPlum,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Remove "$name" from your store?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: grey,
                      side: const BorderSide(color: line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final ok = await ApiService.deleteStoreProduct(spId);
                      if (!mounted) return;
                      if (ok) {
                        _loadProducts();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Product removed from store'),
                              backgroundColor: Color(0xFF4CAF50)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to remove product')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Remove',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600)),
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
