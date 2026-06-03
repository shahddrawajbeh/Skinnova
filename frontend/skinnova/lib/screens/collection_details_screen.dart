import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../product_model.dart';

class CollectionDetailsScreen extends StatefulWidget {
  final String title;
  final List<String> images;
  final String collectionId;

  /// true = owner (rename / delete / add / remove enabled)
  /// false = visitor (view only)
  final bool canEdit;
  final String userId;

  const CollectionDetailsScreen({
    super.key,
    required this.title,
    required this.images,
    required this.collectionId,
    this.canEdit = false,
    this.userId = '',
  });

  @override
  State<CollectionDetailsScreen> createState() =>
      _CollectionDetailsScreenState();
}

class _CollectionDetailsScreenState extends State<CollectionDetailsScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  late String _title;
  late List<String> _images;
  bool _addingProduct = false;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _images = List<String>.from(widget.images);
  }

  // ── Rename / delete sheet ─────────────────────────────────────────────────
  void _showEditSheet() {
    final ctrl = TextEditingController(text: _title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: line, borderRadius: BorderRadius.circular(100))),
            const SizedBox(height: 14),
            Row(
              children: [
                GestureDetector(
                    onTap: () => Navigator.pop(sheetCtx),
                    child:
                        const Icon(Icons.close, color: Colors.grey, size: 26)),
                Expanded(
                  child: Center(
                    child: Text('Edit collection',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: darkText)),
                  ),
                ),
                // Save rename
                GestureDetector(
                  onTap: () async {
                    final name = ctrl.text.trim();
                    if (name.isEmpty) return;
                    final ok = await ApiService.updateCollectionName(
                        collectionId: widget.collectionId,
                        newTitle: name,
                        userId: widget.userId);
                    if (!mounted) return;
                    if (ok) {
                      setState(() => _title = name);
                      Navigator.pop(sheetCtx);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to rename')));
                    }
                  },
                  child: Text('Save',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: wine)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Rename field
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.poppins(fontSize: 15, color: darkText),
              decoration: InputDecoration(
                hintText: 'Collection name…',
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                filled: true,
                fillColor: whiteSmoke,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: wine)),
              ),
            ),
            const SizedBox(height: 16),
            // Delete button
            GestureDetector(
              onTap: () {
                Navigator.pop(sheetCtx);
                _showDeleteConfirm();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0645A),
                    borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: Text('Delete collection',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirmation ───────────────────────────────────────────────────
  void _showDeleteConfirm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: const Color(0xFFF0645A).withOpacity(0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 26, color: Color(0xFFF0645A)),
            ),
            const SizedBox(height: 14),
            Text('Delete collection?',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: darkText)),
            const SizedBox(height: 6),
            Text('This action cannot be undone.',
                style: GoogleFonts.poppins(fontSize: 13, color: grey)),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () async {
                final ok = await ApiService.deleteCollection(
                    collectionId: widget.collectionId, userId: widget.userId);
                if (!mounted) return;
                Navigator.pop(sheetCtx);
                if (ok) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete')));
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0645A),
                    borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: Text('Delete',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(sheetCtx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    color: whiteSmoke, borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500, color: darkText)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Remove product confirmation ────────────────────────────────────────────
  Future<void> _showRemoveConfirm(String imageUrl) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Remove from collection?',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: darkText)),
            const SizedBox(height: 6),
            Text('The product will be removed from this collection.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: grey)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                          color: whiteSmoke,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text('Cancel',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500, color: darkText)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF0645A),
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text('Remove',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await ApiService.removeProductFromCollection(
        collectionId: widget.collectionId,
        imageUrl: imageUrl,
        userId: widget.userId);

    if (ok && mounted) {
      setState(() => _images.remove(imageUrl));
    }
  }

  // ── Product picker ────────────────────────────────────────────────────────
  Future<void> _showProductPicker() async {
    setState(() => _addingProduct = true);
    List<ProductModel> products = [];
    try {
      products = await ApiService.fetchProducts();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _addingProduct = false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          children: [
            // Handle + header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: line,
                          borderRadius: BorderRadius.circular(100))),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close,
                              color: Colors.grey, size: 24)),
                      Expanded(
                        child: Center(
                          child: Text('Add a product',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: darkText)),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: line),
                ],
              ),
            ),
            // Product list
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 42, color: grey),
                          const SizedBox(height: 10),
                          Text('No products available',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: products.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: line),
                      itemBuilder: (_, i) {
                        final p = products[i];
                        final alreadyIn = _images.contains(p.imageUrl);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          leading: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                                color: whiteSmoke,
                                borderRadius: BorderRadius.circular(10)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: p.imageUrl.isNotEmpty
                                  ? Image.network(p.imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Icon(
                                          Icons.image_outlined,
                                          color: grey))
                                  : Icon(Icons.image_outlined, color: grey),
                            ),
                          ),
                          title: Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: darkText)),
                          subtitle: Text(p.brand,
                              style: GoogleFonts.poppins(
                                  fontSize: 11.5, color: grey)),
                          trailing: alreadyIn
                              ? const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF4CAF50), size: 22)
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                      color: wine,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text('Add',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                ),
                          onTap: alreadyIn
                              ? null
                              : () async {
                                  if (p.imageUrl.isEmpty) return;
                                  Navigator.pop(context);
                                  final ok =
                                      await ApiService.addProductToCollection(
                                          collectionId: widget.collectionId,
                                          imageUrl: p.imageUrl,
                                          userId: widget.userId);
                                  if (ok && mounted) {
                                    setState(() => _images.add(p.imageUrl));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('${p.name} added to $_title'),
                                        backgroundColor:
                                            const Color(0xFF4CAF50),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        margin: const EdgeInsets.all(14),
                                      ),
                                    );
                                  }
                                },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final canEditThis = widget.canEdit && widget.collectionId.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: whiteSmoke,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: darkText),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(_title,
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: darkText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  if (canEditThis)
                    GestureDetector(
                      onTap: _showEditSheet,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: whiteSmoke,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.edit_outlined,
                            size: 18, color: darkText),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
            Divider(height: 1, color: line),
            // ── "Add products" button (owner only) ───────────────────────
            if (canEditThis)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GestureDetector(
                  onTap: _addingProduct ? null : _showProductPicker,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: wine.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: wine.withOpacity(0.20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _addingProduct
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: wine))
                            : const Icon(Icons.add_rounded,
                                size: 18, color: wine),
                        const SizedBox(width: 6),
                        Text('Add products',
                            style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: wine)),
                      ],
                    ),
                  ),
                ),
              ),
            // ── Product grid ─────────────────────────────────────────────
            Expanded(
              child: _images.isEmpty
                  ? _buildEmpty(canEditThis)
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _images.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (_, i) =>
                          _buildProductTile(_images[i], canEditThis),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(String imageUrl, bool canEditThis) {
    return GestureDetector(
      onLongPress: canEditThis ? () => _showRemoveConfirm(imageUrl) : null,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                color: whiteSmoke,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: line)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.image_outlined, color: grey, size: 32)),
              ),
            ),
          ),
          // Remove hint (long press) — owner only
          if (canEditThis)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showRemoveConfirm(imageUrl),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool canEditThis) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
                color: wine.withOpacity(0.06), shape: BoxShape.circle),
            child: Icon(Icons.photo_library_outlined,
                size: 30, color: wine.withOpacity(0.4)),
          ),
          const SizedBox(height: 14),
          Text('No products here yet',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: darkText)),
          const SizedBox(height: 5),
          Text(
            canEditThis
                ? 'Tap "Add products" to get started.'
                : 'This collection is empty.',
            style: GoogleFonts.poppins(fontSize: 13, color: grey),
          ),
        ],
      ),
    );
  }
}
