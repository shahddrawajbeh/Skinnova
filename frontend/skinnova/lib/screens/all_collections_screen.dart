import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'collection_details_screen.dart';
import '../api_service.dart';

class AllCollectionsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> collections;
  final String userId;

  /// true = owner view (add/edit/delete enabled)
  /// false = visitor view (read-only)
  final bool canEdit;

  const AllCollectionsScreen({
    super.key,
    required this.collections,
    required this.userId,
    this.canEdit = false,
  });

  @override
  State<AllCollectionsScreen> createState() => _AllCollectionsScreenState();
}

class _AllCollectionsScreenState extends State<AllCollectionsScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  late List<Map<String, dynamic>> _collections;

  @override
  void initState() {
    super.initState();
    _collections = List<Map<String, dynamic>>.from(widget.collections);
  }

  // ── New collection sheet ──────────────────────────────────────────────────
  void _showNewCollectionSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: line, borderRadius: BorderRadius.circular(100))),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child:
                        const Icon(Icons.close, color: Colors.grey, size: 26)),
                Expanded(
                  child: Center(
                    child: Text('New collection',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: darkText)),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final name = ctrl.text.trim();
                    if (name.isEmpty) return;
                    final result = await ApiService.addCollection(
                        userId: widget.userId, title: name);
                    if (!mounted) return;
                    if (result != null) {
                      Navigator.pop(context);
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Icon(Icons.check, color: Colors.grey, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.poppins(fontSize: 15, color: darkText),
              decoration: InputDecoration(
                hintText: 'Name your new collection…',
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                filled: true,
                fillColor: whiteSmoke,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: wine)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Collection preview 2×2 ────────────────────────────────────────────────
  Widget _buildPreview(List<String> images) {
    return Container(
      decoration: BoxDecoration(
          color: whiteSmoke, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 6, mainAxisSpacing: 6),
        itemBuilder: (_, i) {
          if (i < images.length && images[i].isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(images[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFFD9D9D9))),
            );
          }
          return Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(8)));
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
                      child: Text('Collections',
                          style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: darkText)),
                    ),
                  ),
                  if (widget.canEdit)
                    GestureDetector(
                      onTap: _showNewCollectionSheet,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: wine.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_rounded,
                            size: 22, color: wine),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
            Divider(height: 1, color: line),
            // Grid
            Expanded(
              child: _collections.isEmpty
                  ? _buildEmpty()
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        itemCount: _collections.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (_, i) => _buildCard(i),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    final item = _collections[index];
    final title = item['title']?.toString() ?? 'Collection';
    final images = item['images'] != null
        ? List<String>.from(item['images'] as List)
        : <String>[];
    final isSpecial = item['isSpecial'] == true;
    final asset = item['asset']?.toString();
    final iconColor = item['color'] as Color?;
    final collectionId = item['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollectionDetailsScreen(
              title: title,
              images: images,
              collectionId: collectionId,
              canEdit: widget.canEdit && !isSpecial && collectionId.isNotEmpty,
              userId: widget.userId,
            ),
          ),
        );
        if (updated == true) Navigator.pop(context, true);
      },
      child: Container(
        decoration: BoxDecoration(
          color: whiteSmoke,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: line),
        ),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: darkText)),
            const SizedBox(height: 4),
            Text('${images.length} item${images.length == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(fontSize: 10.5, color: grey)),
            const SizedBox(height: 10),
            Expanded(
              child: images.isNotEmpty
                  ? _buildPreview(images)
                  : Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFFF0ECEB),
                          borderRadius: BorderRadius.circular(20)),
                      child: Center(
                        child: asset != null
                            ? SvgPicture.asset(asset, width: 38, height: 38)
                            : Icon(Icons.folder_outlined,
                                color: iconColor ?? grey, size: 38),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: wine.withOpacity(0.06), shape: BoxShape.circle),
            child: Icon(Icons.collections_bookmark_outlined,
                size: 28, color: wine.withOpacity(0.4)),
          ),
          const SizedBox(height: 14),
          Text('No collections yet',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: darkText)),
          const SizedBox(height: 4),
          Text(
            widget.canEdit
                ? 'Tap + to create your first collection.'
                : 'This user has no collections yet.',
            style: GoogleFonts.poppins(fontSize: 13, color: grey),
          ),
        ],
      ),
    );
  }
}
