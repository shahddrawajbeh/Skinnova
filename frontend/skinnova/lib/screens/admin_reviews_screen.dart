import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});
  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  bool _loading = true;
  List _reviews = [];
  int _total = 0;
  String _adminId = '';
  bool _showProductReviews = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminId = prefs.getString('userId') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _reviews = [];
    });
    try {
      final data = _showProductReviews
          ? await ApiService.adminGetProductReviews(_adminId)
          : await ApiService.adminGetStoreReviews(_adminId);
      if (!mounted) return;
      setState(() {
        _reviews = data['reviews'] as List? ?? [];
        _total = data['total'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _topBar(),
      Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AdminTheme.wine))
              : _reviews.isEmpty
                  ? _emptyState()
                  : _buildList()),
    ]);
  }

  Widget _topBar() => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        color: AdminTheme.card,
        child: Row(children: [
          Text("Reviews", style: AdminTheme.title(20)),
          const SizedBox(width: 10),
          _badge(_total),
          const Spacer(),
          ToggleButtons(
            isSelected: [_showProductReviews, !_showProductReviews],
            onPressed: (i) {
              setState(() => _showProductReviews = i == 0);
              _load();
            },
            borderRadius: BorderRadius.circular(12),
            selectedColor: Colors.white,
            fillColor: AdminTheme.wine,
            color: AdminTheme.grey,
            constraints: const BoxConstraints(minHeight: 38, minWidth: 90),
            children: [
              Text("Products", style: GoogleFonts.poppins(fontSize: 13)),
              Text("Stores", style: GoogleFonts.poppins(fontSize: 13)),
            ],
          ),
        ]),
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _reviews.length,
        itemBuilder: (_, i) {
          final r = _reviews[i] as Map;
          final rating = (r['rating'] as num?)?.toDouble() ?? 0;
          final name = _showProductReviews
              ? (r['productName'] ?? 'Product')
              : (r['storeName'] ?? 'Store');
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: AdminTheme.cardDec(),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(r['userName'] ?? 'User',
                          style: AdminTheme.title(13.5, w: FontWeight.w500)),
                      Text(name, style: AdminTheme.sub(12)),
                    ])),
                Row(
                    children: List.generate(
                        5,
                        (i) => Icon(
                            i < rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 14,
                            color: Colors.amber.shade600))),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: AdminTheme.grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) async {
                    if (v == 'delete') {
                      if (!await _confirm("Delete this review?")) return;
                      bool ok;
                      if (_showProductReviews) {
                        ok = await ApiService.adminDeleteProductReview(_adminId,
                            r['productId'].toString(), r['_id'].toString());
                      } else {
                        ok = await ApiService.adminDeleteStoreReview(_adminId,
                            r['storeId'].toString(), r['_id'].toString());
                      }
                      if (ok) {
                        _showSnack("Review deleted");
                        _load();
                      }
                    }
                    if (!_showProductReviews) {
                      if (v == 'approve') {
                        await ApiService.adminUpdateStoreReviewStatus(
                            _adminId,
                            r['storeId'].toString(),
                            r['_id'].toString(),
                            'approved');
                        _showSnack("Approved");
                        _load();
                      }
                      if (v == 'reject') {
                        await ApiService.adminUpdateStoreReviewStatus(
                            _adminId,
                            r['storeId'].toString(),
                            r['_id'].toString(),
                            'rejected');
                        _showSnack("Rejected");
                        _load();
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    if (!_showProductReviews) ...[
                      _popItem(
                          'approve', 'Approve', Icons.check_circle_outline),
                      _popItem('reject', 'Reject', Icons.cancel_outlined),
                    ],
                    _popItem('delete', 'Delete', Icons.delete_outline,
                        danger: true),
                  ],
                ),
              ]),
              if ((r['title'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(r['title'],
                    style: AdminTheme.title(13, w: FontWeight.w500)),
              ],
              if ((r['comment'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(r['comment'],
                    style: AdminTheme.sub(12.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
              if (!_showProductReviews &&
                  (r['status'] ?? '').toString().isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _statusPill(r['status'])),
            ]),
          );
        },
      );

  Widget _statusPill(String status) {
    Color c = status == 'approved'
        ? Colors.green.shade500
        : status == 'rejected'
            ? Colors.red.shade400
            : Colors.orange.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: GoogleFonts.poppins(
              fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }

  PopupMenuItem<String> _popItem(String v, String l, IconData i,
          {bool danger = false}) =>
      PopupMenuItem(
          value: v,
          child: Row(children: [
            Icon(i,
                size: 16,
                color: danger ? Colors.red.shade400 : AdminTheme.grey),
            const SizedBox(width: 8),
            Text(l,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: danger ? Colors.red.shade400 : AdminTheme.black)),
          ]));

  Widget _badge(int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
            color: AdminTheme.wineMuted,
            borderRadius: BorderRadius.circular(20)),
        child: Text("$n",
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: AdminTheme.wine,
                fontWeight: FontWeight.w600)),
      );

  Widget _emptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.rate_review_outlined,
            size: 60, color: AdminTheme.grey.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text("No reviews found", style: AdminTheme.sub(15)),
      ]));

  Future<bool> _confirm(String msg) async =>
      await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text("Confirm",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, color: AdminTheme.black)),
                content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text("Cancel",
                          style: GoogleFonts.poppins(color: AdminTheme.grey))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text("Confirm",
                          style: GoogleFonts.poppins(color: Colors.white))),
                ],
              )) ??
      false;

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? Colors.red.shade400 : AdminTheme.wine,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
