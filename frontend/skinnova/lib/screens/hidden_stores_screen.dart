import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class HiddenStoresScreen extends StatefulWidget {
  final String userId;

  const HiddenStoresScreen({super.key, required this.userId});

  @override
  State<HiddenStoresScreen> createState() => _HiddenStoresScreenState();
}

class _HiddenStoresScreenState extends State<HiddenStoresScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color lineColor = Color(0xFFEEEEEE);

  List<dynamic> hiddenStores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    final result = await ApiService.fetchHiddenStores(widget.userId);
    if (!mounted) return;
    setState(() {
      hiddenStores = result;
      isLoading = false;
    });
  }

  String _getId(dynamic v) {
    if (v == null) return "";
    if (v is String) return v;
    if (v is Map) return (v[r'$oid'] ?? v['_id'] ?? '').toString();
    return v.toString();
  }

  Future<void> _unhide(dynamic store, int index) async {
    final storeId = _getId(store["_id"]);
    final success = await ApiService.unhideStore(
      userId: widget.userId,
      storeId: storeId,
    );
    if (!mounted) return;
    if (success) {
      setState(() => hiddenStores.removeAt(index));
      _showSnack("${store["storeName"] ?? "Store"} is visible again.");
    } else {
      _showSnack("Could not unhide store. Try again.");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: wine,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        content: Text(
          msg,
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hiddenStores.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: wine,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                            itemCount: hiddenStores.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) =>
                                _buildCard(hiddenStores[i], i),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: lineColor),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 17,
                color: wine,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            "Hidden Stores",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic store, int index) {
    final name = (store["storeName"] ?? "Store").toString();
    final logoUrl = (store["logoUrl"] ?? "").toString();
    final city = (store["city"] ?? "").toString();
    final rating = store["rating"];
    final ratingStr = rating != null
        ? double.tryParse(rating.toString())?.toStringAsFixed(1) ?? "—"
        : "—";
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "S";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: wine.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: logoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          letter,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: wine,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      letter,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: wine,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (city.isNotEmpty) ...[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Color(0xFF999999),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        city,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: Color(0xFFD4AF37),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      ratingStr,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => _unhide(store, index),
            style: OutlinedButton.styleFrom(
              foregroundColor: wine,
              side: const BorderSide(color: wine, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "Unhide",
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: wine.withOpacity(0.07),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.visibility_outlined,
                size: 36,
                color: wine,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "No hidden stores",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Stores you hide will appear here so you can unhide them anytime.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF888888),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
