import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});
  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  String _adminId = '';

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
    setState(() => _loading = true);
    try {
      final data = await ApiService.adminGetStats(_adminId);
      if (!mounted) return;
      setState(() {
        _stats = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: AdminTheme.wine));

    final counts = (_stats['counts'] as Map?) ?? {};
    final latestUsers = (_stats['latestUsers'] as List?) ?? [];
    final latestProducts = (_stats['latestProducts'] as List?) ?? [];
    final latestStores = (_stats['latestStores'] as List?) ?? [];
    final recentOrders = (_stats['recentOrders'] as List?) ?? [];

    return RefreshIndicator(
      color: AdminTheme.wine,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Overview", style: AdminTheme.title(22)),
            const SizedBox(height: 4),
            Text("Welcome back, Admin.", style: AdminTheme.sub(13)),
            const SizedBox(height: 24),

            // Pending stores alert
            if ((counts['pendingStores'] as int? ?? 0) > 0)
              _alertCard(counts['pendingStores'] as int),

            // Stats grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.4,
              children: [
                _statCard("Users", "${counts['users'] ?? 0}",
                    Icons.people_rounded, AdminTheme.wineMuted),
                _statCard("Stores", "${counts['stores'] ?? 0}",
                    Icons.store_rounded, const Color(0xFFEAF3F0)),
                _statCard("Products", "${counts['products'] ?? 0}",
                    Icons.inventory_2_rounded, const Color(0xFFEEEAF8)),
                _statCard("Orders", "${counts['orders'] ?? 0}",
                    Icons.receipt_long_rounded, const Color(0xFFF0EDE4)),
                _statCard("Groups", "${counts['groups'] ?? 0}",
                    Icons.spa_rounded, const Color(0xFFE4F0EE)),
                _statCard("Posts", "${counts['posts'] ?? 0}",
                    Icons.article_rounded, const Color(0xFFEDF2F8)),
                _statCard("Ads", "${counts['ads'] ?? 0}",
                    Icons.campaign_rounded, const Color(0xFFF8EEE4)),
              ],
            ),

            const SizedBox(height: 28),
            _sectionTitle("Latest Registered Users"),
            const SizedBox(height: 12),
            _buildUsersList(latestUsers),

            const SizedBox(height: 28),
            _sectionTitle("Latest Stores"),
            const SizedBox(height: 12),
            _buildStoresList(latestStores),

            const SizedBox(height: 28),
            _sectionTitle("Latest Products"),
            const SizedBox(height: 12),
            _buildProductsList(latestProducts),

            const SizedBox(height: 28),
            _sectionTitle("Recent Orders"),
            const SizedBox(height: 12),
            _buildOrdersList(recentOrders),
          ],
        ),
      ),
    );
  }

  Widget _alertCard(int pendingCount) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminTheme.wineMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminTheme.wine.withOpacity(0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.pending_actions_rounded,
              color: AdminTheme.wine, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text(
            "$pendingCount store(s) waiting for approval.",
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: AdminTheme.wine,
                fontWeight: FontWeight.w500),
          )),
        ]),
      );

  Widget _statCard(String label, String value, IconData icon, Color bgColor) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: AdminTheme.black.withOpacity(0.6)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.black)),
          Text(label, style: AdminTheme.sub(11.5)),
        ]),
      );

  Widget _sectionTitle(String t) => Text(t, style: AdminTheme.title(15));

  Widget _buildUsersList(List users) {
    if (users.isEmpty) return _empty("No users yet");
    return _tableCard(users.asMap().entries.map((e) {
      final u = e.value as Map;
      final hasImage = (u['profileImage'] ?? '').toString().isNotEmpty;
      return ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AdminTheme.wineMuted,
          backgroundImage: hasImage ? NetworkImage(u['profileImage']) : null,
          child: !hasImage
              ? Text((u['fullName'] ?? 'U').toString()[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.wine,
                      fontSize: 13))
              : null,
        ),
        title: Text(u['fullName'] ?? '',
            style: AdminTheme.title(13, w: FontWeight.w500)),
        subtitle: Text(u['email'] ?? '', style: AdminTheme.sub(11.5)),
        trailing: _rolePill(u['role'] ?? 'user'),
      );
    }).toList());
  }

  Widget _buildStoresList(List stores) {
    if (stores.isEmpty) return _empty("No stores yet");
    return _tableCard(stores.map((s) {
      final store = s as Map;
      final seller = store['sellerId'] as Map? ?? {};
      return ListTile(
        dense: true,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (store['logoUrl'] ?? '').toString().isNotEmpty
              ? Image.network(store['logoUrl'],
                  width: 36, height: 36, fit: BoxFit.cover)
              : Container(
                  width: 36,
                  height: 36,
                  color: AdminTheme.wineMuted,
                  child: const Icon(Icons.store_rounded,
                      color: AdminTheme.wine, size: 18)),
        ),
        title: Text(store['storeName'] ?? '',
            style: AdminTheme.title(13, w: FontWeight.w500)),
        subtitle: Text(
            "${store['city'] ?? ''} • Owner: ${seller['fullName'] ?? 'N/A'}",
            style: AdminTheme.sub(11.5)),
        trailing: _approvalPill(store['approvalStatus'] ?? 'pending'),
      );
    }).toList());
  }

  Widget _buildProductsList(List products) {
    if (products.isEmpty) return _empty("No products yet");
    return _tableCard(products.map((p) {
      final prod = p as Map;
      return ListTile(
        dense: true,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (prod['imageUrl'] ?? '').toString().isNotEmpty
              ? Image.network(prod['imageUrl'],
                  width: 36, height: 36, fit: BoxFit.cover)
              : Container(
                  width: 36,
                  height: 36,
                  color: AdminTheme.wineMuted,
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AdminTheme.wine, size: 18)),
        ),
        title: Text(prod['name'] ?? '',
            style: AdminTheme.title(13, w: FontWeight.w500)),
        subtitle: Text(prod['brand'] ?? '', style: AdminTheme.sub(11.5)),
        trailing: Text(prod['category'] ?? '',
            style: GoogleFonts.poppins(fontSize: 11, color: AdminTheme.wine)),
      );
    }).toList());
  }

  Widget _buildOrdersList(List orders) {
    if (orders.isEmpty) return _empty("No orders yet");
    return _tableCard(orders.map((o) {
      final order = o as Map;
      final user = order['userId'] as Map? ?? {};
      final store = order['storeId'] as Map? ?? {};
      return ListTile(
        dense: true,
        title: Text(user['fullName'] ?? 'Unknown',
            style: AdminTheme.title(13, w: FontWeight.w500)),
        subtitle: Text(store['storeName'] ?? '', style: AdminTheme.sub(11.5)),
        trailing: _statusPill(order['status'] ?? 'pending'),
      );
    }).toList());
  }

  Widget _tableCard(List<Widget> children) => Container(
        decoration: AdminTheme.cardDec(),
        child: Column(
          children: children
              .asMap()
              .entries
              .map((e) => Column(children: [
                    e.value,
                    if (e.key < children.length - 1)
                      Container(height: 1, color: AdminTheme.line),
                  ]))
              .toList(),
        ),
      );

  Widget _rolePill(String role) {
    Color c = role == 'admin'
        ? Colors.red.shade400
        : role == 'seller'
            ? Colors.orange.shade400
            : AdminTheme.wine;
    return _pill(role, c);
  }

  Widget _approvalPill(String s) {
    Color c = s == 'approved'
        ? Colors.green.shade500
        : s == 'rejected'
            ? Colors.red.shade400
            : Colors.orange.shade400;
    return _pill(s, c);
  }

  Widget _statusPill(String s) {
    Color c = s == 'delivered'
        ? Colors.green.shade500
        : s == 'cancelled'
            ? Colors.red.shade400
            : Colors.orange.shade400;
    return _pill(s.replaceAll('_', ' '), c);
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10.5, color: color, fontWeight: FontWeight.w600)),
      );

  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(msg, style: AdminTheme.sub(13)),
      );
}
