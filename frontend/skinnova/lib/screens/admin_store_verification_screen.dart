import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class AdminStoreVerificationScreen extends StatefulWidget {
  const AdminStoreVerificationScreen({super.key});

  @override
  State<AdminStoreVerificationScreen> createState() =>
      _AdminStoreVerificationScreenState();
}

class _AdminStoreVerificationScreenState
    extends State<AdminStoreVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const Color bg = Color(0xFFF5F5F3);
  static const Color card = Colors.white;
  static const Color black = Color(0xFF252525);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFE7E7E5);
  static const Color soft = Color(0xFFF0F0ED);
  static const Color blue = Color(0xFF1565C0);
  static const Color lightBlue = Color(0xFFE8F0FE);

  late TabController _tabController;
  List<dynamic> unverifiedStores = [];
  List<dynamic> verifiedStores = [];
  bool isLoadingUnverified = true;
  bool isLoadingVerified = true;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUnverified();
    _loadVerified();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUnverified() async {
    setState(() => isLoadingUnverified = true);
    final data = await ApiService.fetchUnverifiedStores();
    if (!mounted) return;
    setState(() {
      unverifiedStores = data;
      isLoadingUnverified = false;
    });
  }

  Future<void> _loadVerified() async {
    setState(() => isLoadingVerified = true);
    final data = await ApiService.fetchVerifiedStores();
    if (!mounted) return;
    setState(() {
      verifiedStores = data;
      isLoadingVerified = false;
    });
  }

  Future<void> _verify(String storeId, String level) async {
    setState(() => _processingIds.add(storeId));
    final ok = await ApiService.verifyStore(
        storeId: storeId, verificationLevel: level);
    if (!mounted) return;
    setState(() => _processingIds.remove(storeId));
    if (ok) {
      _showSnack("Store verified successfully", blue);
      await Future.wait([_loadUnverified(), _loadVerified()]);
    } else {
      _showSnack("Failed to verify store", Colors.redAccent);
    }
  }

  Future<void> _unverify(String storeId) async {
    final confirmed = await _showConfirmDialog(
      "Remove Verification",
      "Are you sure you want to remove verification from this store?",
    );
    if (!confirmed) return;

    setState(() => _processingIds.add(storeId));
    final ok = await ApiService.unverifyStore(storeId: storeId);
    if (!mounted) return;
    setState(() => _processingIds.remove(storeId));
    if (ok) {
      _showSnack("Verification removed", Colors.orange);
      await Future.wait([_loadUnverified(), _loadVerified()]);
    } else {
      _showSnack("Failed to remove verification", Colors.redAccent);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(title,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: black)),
            content: Text(body,
                style: GoogleFonts.poppins(fontSize: 13.5, color: grey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel", style: GoogleFonts.poppins(color: grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Confirm",
                    style: GoogleFonts.poppins(
                        color: Colors.redAccent, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showVerifyLevelSheet(String storeId, String storeName) {
    final levels = [
      {
        "value": "standard",
        "label": "Verified Store",
        "desc": "Basic trust badge for new verified sellers",
        "icon": Icons.verified_rounded,
        "color": blue,
      },
      {
        "value": "premium",
        "label": "Premium Store",
        "desc": "For stores with high quality and ratings",
        "icon": Icons.workspace_premium_rounded,
        "color": const Color(0xFF7B1FA2),
      },
      {
        "value": "trusted",
        "label": "Trusted Store",
        "desc": "Top-tier trusted sellers with proven track record",
        "icon": Icons.shield_rounded,
        "color": const Color(0xFF1B5E20),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAF8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              "Verify \"$storeName\"",
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Select the verification level to grant",
              style: GoogleFonts.poppins(fontSize: 12.5, color: grey),
            ),
            const SizedBox(height: 20),
            ...levels.map((lvl) {
              final color = lvl["color"] as Color;
              final icon = lvl["icon"] as IconData;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _verify(storeId, lvl["value"] as String);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: line),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lvl["label"] as String,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: black)),
                            const SizedBox(height: 2),
                            Text(lvl["desc"] as String,
                                style: GoogleFonts.poppins(
                                    fontSize: 11.5, color: grey)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: grey),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: black, size: 16),
          ),
        ),
        title: Text(
          "Store Verification",
          style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w600, color: black),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: blue,
          unselectedLabelColor: grey,
          indicatorColor: blue,
          indicatorWeight: 2.5,
          labelStyle:
              GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text("Pending"),
                  if (unverifiedStores.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: blue,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "${unverifiedStores.length}",
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text("Verified"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUnverifiedTab(),
          _buildVerifiedTab(),
        ],
      ),
    );
  }

  Widget _buildUnverifiedTab() {
    if (isLoadingUnverified) {
      return const Center(child: CircularProgressIndicator(color: blue));
    }
    if (unverifiedStores.isEmpty) {
      return _emptyState(
        icon: Icons.check_circle_outline_rounded,
        title: "All stores verified",
        subtitle: "There are no stores pending verification right now.",
        iconColor: blue,
      );
    }
    return RefreshIndicator(
      color: blue,
      onRefresh: _loadUnverified,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
        itemCount: unverifiedStores.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _storeCard(
          store: unverifiedStores[i],
          isVerified: false,
        ),
      ),
    );
  }

  Widget _buildVerifiedTab() {
    if (isLoadingVerified) {
      return const Center(child: CircularProgressIndicator(color: blue));
    }
    if (verifiedStores.isEmpty) {
      return _emptyState(
        icon: Icons.verified_outlined,
        title: "No verified stores yet",
        subtitle: "Approve stores from the Pending tab to see them here.",
        iconColor: grey,
      );
    }
    return RefreshIndicator(
      color: blue,
      onRefresh: _loadVerified,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
        itemCount: verifiedStores.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _storeCard(
          store: verifiedStores[i],
          isVerified: true,
        ),
      ),
    );
  }

  Widget _storeCard({required dynamic store, required bool isVerified}) {
    final storeId = store["_id"]?.toString() ?? "";
    final name = store["storeName"] ?? "Unnamed Store";
    final city = store["city"] ?? "";
    final address = store["address"] ?? "";
    final phone = store["phone"] ?? "";
    final rating = (double.tryParse((store["rating"] ?? 0).toString()) ?? 0)
        .toStringAsFixed(1);
    final logoUrl = store["logoUrl"] ?? "";
    final seller = store["sellerId"];
    final sellerName =
        seller is Map ? (seller["fullName"] ?? "Unknown seller") : "Unknown";
    final sellerEmail = seller is Map ? (seller["email"] ?? "") : "";
    final level = store["verificationLevel"]?.toString() ?? "standard";
    final verifiedAt = store["verifiedAt"] != null
        ? _formatDate(store["verifiedAt"].toString())
        : null;
    final productCount = 0;
    final isProcessing = _processingIds.contains(storeId);

    final levelColor = level == "trusted"
        ? const Color(0xFF1B5E20)
        : level == "premium"
            ? const Color(0xFF7B1FA2)
            : blue;
    final levelLabel = level == "trusted"
        ? "Trusted"
        : level == "premium"
            ? "Premium"
            : "Standard";

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVerified ? blue.withOpacity(0.15) : line,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _storeLogo(logoUrl, name),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: black,
                              ),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: levelColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                levelLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: levelColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sellerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 11.5, color: grey),
                          ),
                        ),
                      ]),
                      if (sellerEmail.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          sellerEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              GoogleFonts.poppins(fontSize: 10.5, color: grey),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Info chips ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (city.isNotEmpty) _chip(Icons.location_on_rounded, city),
                if (address.isNotEmpty)
                  _chip(Icons.maps_home_work_outlined, address),
                if (phone.isNotEmpty) _chip(Icons.phone_outlined, phone),
                _chip(Icons.star_rounded, "$rating stars",
                    color: const Color(0xFFFFB800)),
                if (isVerified && verifiedAt != null)
                  _chip(Icons.verified_rounded, "Verified $verifiedAt",
                      color: blue),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Divider ──────────────────────────────────────────────────────
          Container(height: 1, color: line),
          // ── Actions ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: isVerified
                ? _removeVerificationButton(storeId, isProcessing)
                : _verifyButton(storeId, name, isProcessing),
          ),
        ],
      ),
    );
  }

  Widget _verifyButton(String storeId, String storeName, bool isProcessing) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isProcessing
            ? null
            : () => _showVerifyLevelSheet(storeId, storeName),
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: blue.withOpacity(0.5),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Verify Store",
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _removeVerificationButton(String storeId, bool isProcessing) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isProcessing ? null : () => _unverify(storeId),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.redAccent))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.remove_circle_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Remove Verification",
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color? color}) {
    final c = color ?? grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10.5, color: c, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _storeLogo(String logoUrl, String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "S";
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
        boxShadow: [
          BoxShadow(
            color: blue.withOpacity(0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: logoUrl.isNotEmpty
            ? ClipOval(
                child: Image.network(logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                          child: Text(letter,
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: blue)),
                        )),
              )
            : Center(
                child: Text(letter,
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: blue)),
              ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 36),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: black)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: grey, height: 1.5)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
    } catch (_) {
      return "";
    }
  }
}
