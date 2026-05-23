import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../product_model.dart';
import 'post_review_screen.dart';

class RateProductScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final ProductModel product;

  const RateProductScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.product,
  });

  @override
  State<RateProductScreen> createState() => _RateProductScreenState();
}

class _RateProductScreenState extends State<RateProductScreen> {
  int selectedRating = 0;

  String get ratingLabel {
    switch (selectedRating) {
      case 1:
        return "Epic fail ";
      case 2:
        return "Wouldn't recommend ";
      case 3:
        return "Worth a try ";
      case 4:
        return "Love it ";
      case 5:
        return "All time favorite ";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        size: 30, color: Color(0xFF9D9D9D)),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Rate product",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xFFE7E7E7)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sell_outlined, color: Color(0xFF333333)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: Image.network(
                          product.imageUrl,
                          height: 310,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_outlined, size: 90),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              selectedRating = starIndex;
                            });
                          },
                          icon: Icon(
                            starIndex <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 42,
                            color: starIndex <= selectedRating
                                ? const Color(0xFFF7C300)
                                : const Color(0xFFB8B8B8),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    if (selectedRating > 0)
                      Text(
                        ratingLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2A2A2A),
                        ),
                      ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: selectedRating == 0
                          ? null
                          : () async {
                              final posted = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostReviewScreen(
                                    userId: widget.userId,
                                    userName: widget.userName,
                                    product: product,
                                    rating: selectedRating,
                                    ratingTitle: ratingLabel,
                                  ),
                                ),
                              );

                              if (posted == true && mounted) {
                                Navigator.pop(context, true);
                              }
                            },
                      child: Container(
                        width: 96,
                        height: 52,
                        decoration: BoxDecoration(
                          color: selectedRating == 0
                              ? const Color(0xFFECECEC)
                              : const Color(0xFF5B2333),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Next",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: selectedRating == 0
                                ? const Color(0xFFBFBFBF)
                                : Colors.white,
                          ),
                        ),
                      ),
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
