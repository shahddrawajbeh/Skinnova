import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'collection_details_screen.dart';

class AllCollectionsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> collections;

  const AllCollectionsScreen({
    super.key,
    required this.collections,
  });

  Widget _buildCollectionPreview(List<String> images) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(14),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          if (index < images.length && images[index].isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_outlined,
                      color: Colors.white70,
                      size: 30,
                    ),
                  );
                },
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_pharmacy_outlined,
              color: Colors.white70,
              size: 30,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF202124);
    const Color accentBlue = Color(0xFF4DA3FF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.chevron_left,
                      size: 30,
                      color: textDark,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Collections",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.add,
                    size: 30,
                    color: accentBlue,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  itemCount: collections.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final item = collections[index];
                    final String title =
                        item['title']?.toString() ?? 'Collection';
                    final List<String> images = item['images'] != null
                        ? List<String>.from(item['images'] as List)
                        : <String>[];

                    final bool isSpecial = item['isSpecial'] == true;
                    final String? asset = item['asset']?.toString();
                    final Color? iconColor = item['color'] as Color?;

                    return GestureDetector(
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CollectionDetailsScreen(
                              title: title,
                              images: images,
                              collectionId: item['id']?.toString() ?? '',
                            ),
                          ),
                        );

                        if (updated == true) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F7F6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: images.isNotEmpty
                                  ? _buildCollectionPreview(images)
                                  : isSpecial
                                      ? Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F3F3),
                                            borderRadius:
                                                BorderRadius.circular(22),
                                          ),
                                          child: Center(
                                            child: asset != null
                                                ? SvgPicture.asset(
                                                    asset,
                                                    width: 42,
                                                    height: 42,
                                                    fit: BoxFit.contain,
                                                  )
                                                : Icon(
                                                    Icons.folder_outlined,
                                                    color: iconColor ??
                                                        Colors.grey,
                                                    size: 38,
                                                  ),
                                          ),
                                        )
                                      : _buildCollectionPreview(images),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
