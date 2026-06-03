import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class SellerStoreReviewsScreen extends StatefulWidget {
  final String storeId;
  const SellerStoreReviewsScreen({super.key, required this.storeId});

  @override
  State<SellerStoreReviewsScreen> createState() =>
      _SellerStoreReviewsScreenState();
}

class _SellerStoreReviewsScreenState extends State<SellerStoreReviewsScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color gold = Color(0xFFD4AF37);

  List<dynamic> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final reviews = await ApiService.fetchStoreReviews(widget.storeId);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(
        0, (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0));
    return sum / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: warmCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: deepPlum, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Store Reviews',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: deepPlum,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: wine, size: 22),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : _reviews.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: wine,
                  child: Column(
                    children: [
                      _buildSummaryHeader(),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: _reviews.length,
                          itemBuilder: (_, i) => _buildReviewCard(_reviews[i]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryHeader() {
    final avg = _averageRating;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1520), Color(0xFF5B2333)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, color: gold, size: 24),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_reviews.length} approved review${_reviews.length != 1 ? 's' : ''}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (i) {
              final star = 5 - i;
              final count =
                  _reviews.where((r) => (r['rating'] as num?) == star).length;
              final pct = _reviews.isEmpty ? 0.0 : count / _reviews.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.white60),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, color: gold, size: 10),
                    const SizedBox(width: 6),
                    Container(
                      width: 80,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pct,
                        child: Container(
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 20,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.white60),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final name = review['userName']?.toString() ?? 'Customer';
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final comment = review['comment']?.toString() ?? '';
    final date = _formatDate(review['createdAt']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: wine.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: wine,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                    Text(
                      date,
                      style: GoogleFonts.poppins(fontSize: 11, color: grey),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: gold,
                    size: 15,
                  );
                }),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: darkText,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline_rounded,
              size: 64, color: grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'No approved reviews yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reviews appear here after admin approval.',
            style: GoogleFonts.poppins(fontSize: 13, color: grey),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return '';
    }
  }
}
