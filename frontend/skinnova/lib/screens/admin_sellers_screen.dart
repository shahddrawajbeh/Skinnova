import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class AdminSellersScreen extends StatefulWidget {
  const AdminSellersScreen({super.key});

  @override
  State<AdminSellersScreen> createState() => _AdminSellersScreenState();
}

class _AdminSellersScreenState extends State<AdminSellersScreen> {
  static const Color card = Colors.white;
  static const Color black = Color(0xFF252525);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFE7E7E5);
  static const Color accent = Color(0xFF2E7D6B);

  bool _loading = true;
  List _sellers = [];
  int _total = 0;
  String _adminId = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminId = prefs.getString('userId') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.adminGetSellers(_adminId,
          search: _searchCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _sellers = data['sellers'] as List? ?? [];
        _total = data['total'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _showStores(Map seller) async {
    final stores =
        await ApiService.adminGetSellerStores(_adminId, seller['_id']);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("${seller['fullName']} – Stores",
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
        content: SizedBox(
          width: 400,
          child: stores.isEmpty
              ? Text("No stores", style: GoogleFonts.poppins(color: grey))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: (stores as List).map((s) {
                    final store = s as Map;
                    return ListTile(
                      leading: const Icon(Icons.store_rounded, color: accent),
                      title: Text(store['storeName'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 13)),
                      subtitle: Text(store['city'] ?? '',
                          style:
                              GoogleFonts.poppins(fontSize: 12, color: grey)),
                      trailing: Icon(
                        store['isActive'] == true
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: store['isActive'] == true
                            ? Colors.green
                            : Colors.red,
                        size: 18,
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close", style: GoogleFonts.poppins(color: grey))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _sellers.isEmpty
                  ? _emptyState()
                  : _buildList(),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Sellers",
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w600, color: black)),
              const SizedBox(width: 10),
              _countBadge(_total),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _load(),
            decoration: _inputDec("Search sellers...").copyWith(
              prefixIcon:
                  const Icon(Icons.search, size: 18, color: Colors.grey),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _sellers.length,
      itemBuilder: (_, i) => _buildRow(_sellers[i] as Map),
    );
  }

  Widget _buildRow(Map s) {
    final hasImage = (s['profileImage'] ?? '').toString().isNotEmpty;
    final isActive = s['isActive'] != false;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE4E4E1),
            backgroundImage: hasImage ? NetworkImage(s['profileImage']) : null,
            child: !hasImage
                ? Text(
                    (s['fullName'] ?? 'S').toString().isNotEmpty
                        ? (s['fullName'] as String)[0].toUpperCase()
                        : 'S',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, color: black),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['fullName'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: black)),
                Text(s['email'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 12, color: grey)),
                Text("${s['storeCount'] ?? 0} store(s)",
                    style: GoogleFonts.poppins(fontSize: 11, color: accent)),
              ],
            ),
          ),
          _activeBadge(isActive),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 18, color: Colors.grey),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) async {
              if (v == 'stores') _showStores(s);
              if (v == 'toggle') {
                await ApiService.adminToggleSellerActive(_adminId, s['_id']);
                _load();
              }
              if (v == 'reject') {
                await ApiService.adminRejectSeller(_adminId, s['_id']);
                _showSnack("Seller demoted to user");
                _load();
              }
              if (v == 'delete') {
                final ok = await _confirm("Delete seller?");
                if (ok) {
                  await ApiService.adminDeleteSeller(_adminId, s['_id']);
                  _showSnack("Seller deleted");
                  _load();
                }
              }
            },
            itemBuilder: (_) => [
              _popItem('stores', 'View Stores', Icons.store_outlined),
              _popItem('toggle', isActive ? 'Deactivate' : 'Activate',
                  isActive ? Icons.block_outlined : Icons.check_circle_outline),
              _popItem(
                  'reject', 'Demote to User', Icons.arrow_downward_outlined),
              _popItem('delete', 'Delete', Icons.delete_outline, danger: true),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popItem(String value, String label, IconData icon,
          {bool danger = false}) =>
      PopupMenuItem(
        value: value,
        child: Row(children: [
          Icon(icon, size: 16, color: danger ? Colors.red.shade400 : grey),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: danger ? Colors.red.shade400 : black)),
        ]),
      );

  Widget _countBadge(int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Text("$n",
            style: GoogleFonts.poppins(
                fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
      );

  Widget _activeBadge(bool a) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: a ? Colors.green.shade400 : Colors.red.shade300,
          shape: BoxShape.circle,
        ),
      );

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.storefront_outlined,
              size: 60, color: grey.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text("No sellers found",
              style: GoogleFonts.poppins(fontSize: 15, color: grey)),
        ]),
      );

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Future<bool> _confirm(String msg) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Confirm",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text("Cancel", style: GoogleFonts.poppins(color: grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("Confirm",
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ) ??
      false;

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? Colors.red.shade400 : accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
