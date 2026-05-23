import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../product_model.dart';
import '../api_service.dart';

class PostReviewScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final ProductModel product;
  final int rating;
  final String ratingTitle;

  const PostReviewScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.product,
    required this.rating,
    required this.ratingTitle,
  });

  @override
  State<PostReviewScreen> createState() => _PostReviewScreenState();
}

class _PostReviewScreenState extends State<PostReviewScreen> {
  final TextEditingController reviewController = TextEditingController();

  bool? repurchase;
  bool? improvedSkin;
  bool? wasGift;
  bool? adverseReaction;
  String selectedTexture = "";
  String selectedUsageWeeks = "";
  bool isPosting = false;

  final List<String> textures = [
    "Oily",
    "Creamy",
    "Gel",
    "Watery",
    "Mousse",
    "Grainy",
    "Balmy",
    "Foamy",
  ];

  final List<String> usageWeeksOptions = [
    "<1",
    "1-2",
    "3-4",
    "5-6",
    "6+",
  ];

  Future<void> postReview() async {
    if (reviewController.text.trim().isEmpty) return;

    setState(() => isPosting = true);
    final result = await ApiService.addReview(
      productId: widget.product.id,
      userId: widget.userId,
      userName: widget.userName,
      rating: widget.rating.toDouble(),
      title: widget.ratingTitle,
      comment: reviewController.text.trim(),
      repurchase: repurchase,
      improvedSkin: improvedSkin,
      wasGift: wasGift,
      adverseReaction: adverseReaction,
      texture: selectedTexture,
      usageWeeks: selectedUsageWeeks,
    );

    if (result["statusCode"] == 201) {
      final userProfile = await ApiService.fetchUserProfile(widget.userId);

      await ApiService.addReviewPost(
        userId: widget.userId,
        userName: widget.userName,
        userAvatar: userProfile?.profileImage ?? "",
        content: reviewController.text.trim(),
        productId: widget.product.id,
        productName: widget.product.name,
        productImage: widget.product.imageUrl,
        rating: widget.rating.toDouble(),
        repurchase: repurchase,
        improvedSkin: improvedSkin,
        wasGift: wasGift,
        adverseReaction: adverseReaction,
        texture: selectedTexture,
        usageWeeks: selectedUsageWeeks,
      );

      setState(() => isPosting = false);

      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() => isPosting = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to post review")),
      );
    }
  }

  Widget yesNoRow(String title, bool? value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14.5),
            ),
          ),
          const SizedBox(width: 12),
          _choiceButton("Yes", value == true, () => onChanged(true)),
          const SizedBox(width: 10),
          _choiceButton("No", value == false, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _choiceButton(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5B2333) : const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: selected ? Colors.white : const Color(0xFF2A2A2A),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget chipOption({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5B2333) : const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: selected ? Colors.white : const Color(0xFF2A2A2A),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 22, color: Color(0xFF8F8F8F)),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Post review",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: isPosting ? null : postReview,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(44),
                      ),
                      child: Text(
                        isPosting ? "Posting..." : "Post",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF8D8D8D),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xFFE7E7E7)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(44),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sell_outlined,
                              color: Color(0xFF333333)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              product.name,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      "Review*",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E2E2)),
                      ),
                      child: TextField(
                        controller: reviewController,
                        maxLines: 5,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          hintText:
                              "Share your thoughts about this product here...",
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFFB7B7B7),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(18),
                          counterStyle: GoogleFonts.poppins(
                            color: const Color(0xFFB7B7B7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    yesNoRow("Would you repurchase this item?", repurchase,
                        (val) => setState(() => repurchase = val)),
                    yesNoRow(
                        "Was there a visible improvement to your skin?",
                        improvedSkin,
                        (val) => setState(() => improvedSkin = val)),
                    yesNoRow("Was this item a gift?", wasGift,
                        (val) => setState(() => wasGift = val)),
                    yesNoRow(
                        "Did your skin have an adverse reaction?",
                        adverseReaction,
                        (val) => setState(() => adverseReaction = val)),
                    const Divider(height: 28),
                    Text(
                      "Texture",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Describe the texture of this product:",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFA4A4A4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: textures.map((item) {
                        return chipOption(
                          text: item,
                          selected: selectedTexture == item,
                          onTap: () => setState(() => selectedTexture = item),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 36),
                    Text(
                      "How many weeks have you used this product for?",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: usageWeeksOptions.map((item) {
                        return chipOption(
                          text: item,
                          selected: selectedUsageWeeks == item,
                          onTap: () =>
                              setState(() => selectedUsageWeeks = item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
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
