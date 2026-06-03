import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class PendingStoreReviewsScreen extends StatefulWidget {
  const PendingStoreReviewsScreen({super.key});

  @override
  State<PendingStoreReviewsScreen> createState() =>
      _PendingStoreReviewsScreenState();
}

class _PendingStoreReviewsScreenState extends State<PendingStoreReviewsScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color gold = Color(0xFFD4AF37);
  static const Color deepPlum = Color(0xFF2E1520);

  List<dynamic> _reviews = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.fetchPendingStoreReviews();
      if (!mounted) return;
      setState(() {
        _reviews = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approve(dynamic review, int index) async {
    final storeId = review["storeId"].toString();
    final reviewId = review["reviewId"].toString();
    final ok = await ApiService.approveStoreReview(
        storeId: storeId, reviewId: reviewId);
    if (!mounted) return;
    if (ok) {
      setState(() => _reviews.removeAt(index));
      _showSnack("Review approved and published.", const Color(0xFF2E7D52));
    } else {
      _showSnack("Failed to approve. Try again.", wine);
    }
  }

  Future<void> _reject(dynamic review, int index) async {
    final storeId = review["storeId"].toString();
    final reviewId = review["reviewId"].toString();
    final ok = await ApiService.rejectStoreReview(
        storeId: storeId, reviewId: reviewId);
    if (!mounted) return;
    if (ok) {
      setState(() => _reviews.removeAt(index));
      _showSnack("Review rejected.", Colors.black54);
    } else {
      _showSnack("Failed to reject. Try again.", wine);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _ratingStars(double rating, {double size = 13}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star_rounded, color: gold, size: size);
        } else if (i < rating) {
          return Icon(Icons.star_half_rounded, color: gold, size: size);
        } else {
          return Icon(Icons.star_border_rounded,
              color: Colors.black26, size: size);
        }
      }),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: wine,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Pending Reviews",
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: wine),
            )
          : _error != null
              ? _buildError()
              : _reviews.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: wine,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _reviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _buildReviewCard(_reviews[index], index);
                        },
                      ),
                    ),
    );
  }

  Widget _buildReviewCard(dynamic review, int index) {
    final storeName = (review["storeName"] ?? "Unknown Store").toString();
    final rawName = (review["userName"] ?? "").toString().trim();
    final populatedName = review["userId"] is Map
        ? ((review["userId"]["fullName"] ?? "").toString().trim())
        : "";
    final name = rawName.isNotEmpty
        ? rawName
        : (populatedName.isNotEmpty ? populatedName : "Customer");
    final rating = ((review["rating"] ?? 5) as num).toDouble();
    final comment = (review["comment"] ?? "").toString();
    final date = (review["createdAt"] ?? "").toString();
    final initial = name[0].toUpperCase();

    final List<Color> avatarColors = [
      wine,
      deepPlum,
      const Color(0xFF1565C0),
      const Color(0xFF6A1B9A),
      const Color(0xFF00695C),
    ];
    final avatarColor =
        avatarColors[initial.codeUnitAt(0) % avatarColors.length];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store name badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: wine.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_outlined, size: 13, color: wine),
                const SizedBox(width: 5),
                Text(
                  storeName,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: wine,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // User row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _ratingStars(rating),
                        const SizedBox(width: 6),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: gold),
                        ),
                        const Spacer(),
                        if (date.isNotEmpty)
                          Text(
                            _formatDate(date),
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.black38),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                comment,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: darkText.withOpacity(0.75),
                  height: 1.55,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Approve / Reject buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _reject(review, index),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded,
                            size: 16, color: Colors.red.shade400),
                        const SizedBox(width: 6),
                        Text(
                          "Reject",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _approve(review, index),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D52),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D52).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          "Approve",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: wine.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.rate_review_outlined,
                  size: 36, color: wine.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              "No pending reviews",
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: darkText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "All store reviews have been\nreviewed. Check back later.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black45,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: wine.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              "Failed to load reviews",
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w500, color: darkText),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: wine,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  "Try Again",
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
