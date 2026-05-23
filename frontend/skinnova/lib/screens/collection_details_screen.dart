import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../api_service.dart';

class CollectionDetailsScreen extends StatelessWidget {
  final String title;
  final List<String> images;
  final String collectionId;

  const CollectionDetailsScreen({
    super.key,
    required this.title,
    required this.images,
    required this.collectionId,
  });

  void _showEditDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 30,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Edit collection",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF202124),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final newName = controller.text.trim();

                      if (newName.isEmpty) return;

                      if (collectionId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("This collection cannot be renamed"),
                          ),
                        );
                        return;
                      }

                      final success = await ApiService.updateCollectionName(
                        collectionId: collectionId,
                        newTitle: newName,
                      );

                      if (!context.mounted) return;

                      if (success) {
                        Navigator.pop(context);
                        Navigator.pop(context, true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Failed to update name"),
                          ),
                        );
                      }
                    },
                    child: const Icon(
                      Icons.check,
                      color: Colors.grey,
                      size: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF202124),
                  ),
                  decoration: InputDecoration(
                    hintText: "Rename your collection...",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () async {
                  if (collectionId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("This collection cannot be deleted"),
                      ),
                    );
                    return;
                  }

                  // نعرض bottom sheet ثاني للتأكيد
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Delete collection?",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "This action cannot be undone",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // زر Delete
                            GestureDetector(
                              onTap: () async {
                                final success =
                                    await ApiService.deleteCollection(
                                  collectionId: collectionId,
                                );

                                if (!context.mounted) return;

                                if (success) {
                                  Navigator.pop(context); // يقفل confirm sheet
                                  Navigator.pop(context); // يقفل edit sheet
                                  Navigator.pop(context, true); // يرجع refresh
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text("Failed to delete collection"),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0645A),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    "Delete",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // زر Cancel
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F3F3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    "Cancel",
                                    style: GoogleFonts.poppins(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0645A),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    "Delete collection",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.chevron_left, size: 25),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF202124),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  GestureDetector(
                    onTap: () => _showEditDialog(context),
                    child: const Icon(Icons.edit_outlined, size: 25),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                "+ Add products",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5B2333),
                ),
              ),
            ),
            Expanded(
              child: images.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/no_product.svg',
                          width: 130,
                          height: 130,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          "No products here yet!",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: images.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_outlined),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
