import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../product_model.dart';
import '../api_service.dart';

import 'select_question_group_screen.dart';
import '../group_model.dart';

class SelectGroupTypeScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String questionText;
  final ProductModel? selectedProduct;
  final String postType;
  final String uploadedImageUrl;

  const SelectGroupTypeScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.questionText,
    required this.selectedProduct,
    required this.postType,
    required this.uploadedImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF202124);
    const Color subText = Color(0xFF6F6F6F);
    const Color accentBlue = Color(0xFF5B2333);
    const Color searchBg = Color(0xFFF5F5F5);

    Widget buildTypeCard({
      required String title,
      required String imagePath,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 138,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.60),
                BlendMode.lighten,
              ),
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
              ),
            ),
          ),
        ),
      );
    }

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
                        "Post to group",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = postType == "update"
                          ? await ApiService.addUpdatePost(
                              userId: userId,
                              userName: userName,
                              userAvatar: "",
                              content: questionText,
                              productId: selectedProduct?.id ?? "",
                              productName: selectedProduct?.name ?? "",
                              productImage: uploadedImageUrl.isNotEmpty
                                  ? uploadedImageUrl
                                  : (selectedProduct?.imageUrl ?? ""),
                              groupId: "",
                              groupTitle: "",
                              groupSlug: "",
                            )
                          : await ApiService.addQuestionPost(
                              userId: userId,
                              userName: userName,
                              userAvatar: "",
                              content: questionText,
                              productId: selectedProduct?.id ?? "",
                              productName: selectedProduct?.name ?? "",
                              productImage: uploadedImageUrl.isNotEmpty
                                  ? uploadedImageUrl
                                  : (selectedProduct?.imageUrl ?? ""),
                              groupId: "",
                              groupTitle: "",
                              groupSlug: "",
                            );

                      if (!context.mounted) return;

                      if (result["statusCode"] == 201) {
                        Navigator.pop(context, true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              postType == "update"
                                  ? "Failed to post update"
                                  : "Failed to post question",
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accentBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Skip",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: searchBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search for a group...",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: const Color(0xFFB5B5B5),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFFB5B5B5),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      "What is your post about?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Share your post to a group.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: subText,
                      ),
                    ),
                    const SizedBox(height: 22),
                    buildTypeCard(
                      title: "Skin types",
                      imagePath: "assets/images/skintypes.jpg",
                      onTap: () async {
                        final posted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectQuestionGroupScreen(
                              userId: userId,
                              userName: userName,
                              questionText: questionText,
                              selectedProduct: selectedProduct,
                              groupType: "skin_types",
                              screenTitle: "Select group",
                              postType: postType,
                              uploadedImageUrl: uploadedImageUrl,
                            ),
                          ),
                        );

                        if (posted == true && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    buildTypeCard(
                      title: "Skin colors",
                      imagePath: "assets/images/skincolors.jpg",
                      onTap: () async {
                        final posted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectQuestionGroupScreen(
                              userId: userId,
                              userName: userName,
                              questionText: questionText,
                              selectedProduct: selectedProduct,
                              groupType: "skin_colors",
                              screenTitle: "Select group",
                              postType: postType,
                              uploadedImageUrl: uploadedImageUrl,
                            ),
                          ),
                        );

                        if (posted == true && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    buildTypeCard(
                      title: "Product categories",
                      imagePath: "assets/images/productcat.jpg",
                      onTap: () async {
                        final posted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectQuestionGroupScreen(
                              userId: userId,
                              userName: userName,
                              questionText: questionText,
                              selectedProduct: selectedProduct,
                              groupType: "product_categories",
                              screenTitle: "Select group",
                              postType: postType,
                              uploadedImageUrl: uploadedImageUrl,
                            ),
                          ),
                        );

                        if (posted == true && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
