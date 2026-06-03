import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminAdsScreen extends StatefulWidget {
  const AdminAdsScreen({super.key});
  @override
  State<AdminAdsScreen> createState() => _AdminAdsScreenState();
}

class _AdminAdsScreenState extends State<AdminAdsScreen> {
  bool _loading = true;
  List _ads = [];
  int _total = 0;
  String _adminId = '';
  String _statusFilter = '';

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
      final data =
          await ApiService.adminGetAds(_adminId, status: _statusFilter);
      if (!mounted) return;
      setState(() {
        _ads = data['ads'] as List? ?? [];
        _total = data['total'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showEditDialog([Map? ad]) {
    final titleCtrl = TextEditingController(text: ad?['title'] ?? '');
    final subtitleCtrl = TextEditingController(text: ad?['subtitle'] ?? '');
    final imageCtrl = TextEditingController(text: ad?['imageUrl'] ?? '');
    final btnCtrl =
        TextEditingController(text: ad?['buttonText'] ?? 'Shop now');
    final targetCtrl = TextEditingController(text: ad?['actionTarget'] ?? '');
    // final storeCtrl = TextEditingController(
    //     text: ad?['storeId']?['_id'] ?? ad?['storeId'] ?? '');
    // final sellerCtrl = TextEditingController(
    //     text: ad?['sellerId']?['_id'] ?? ad?['sellerId'] ?? '');
    String placement = ad?['placement'] ?? 'home';
    String actionType = ad?['actionType'] ?? 'none';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text(ad == null ? "Add Banner" : "Edit Banner",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AdminTheme.black)),
                content: SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      _f("Title *", titleCtrl),
                      const SizedBox(height: 10),
                      _f("Subtitle", subtitleCtrl),
                      const SizedBox(height: 10),
                      _f("Banner Image URL *", imageCtrl),
                      const SizedBox(height: 10),
                      _f("Button Text", btnCtrl),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: placement,
                        decoration: _inputDec("Placement"),
                        items: ['home', 'shop', 'store', 'other']
                            .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p, style: GoogleFonts.poppins())))
                            .toList(),
                        onChanged: (v) => setS(() => placement = v!),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: actionType,
                        decoration: _inputDec("Tap Action"),
                        items: ['none', 'store', 'product', 'category', 'link']
                            .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t, style: GoogleFonts.poppins())))
                            .toList(),
                        onChanged: (v) => setS(() => actionType = v!),
                      ),
                      if (actionType != 'none') ...[
                        const SizedBox(height: 10),
                        _f("Action Target (ID or URL)", targetCtrl)
                      ],
                      // if (ad == null) ...[
                      //   const SizedBox(height: 10),
                      //   _f("Store ID", storeCtrl),
                      //   const SizedBox(height: 10),
                      //   _f("Owner User ID", sellerCtrl),
                      // ],
                    ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text("Cancel",
                          style: GoogleFonts.poppins(color: AdminTheme.grey))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.wine,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final data = {
                          'title': titleCtrl.text.trim(),
                          'subtitle': subtitleCtrl.text.trim(),
                          'imageUrl': imageCtrl.text.trim(),
                          'buttonText': btnCtrl.text.trim(),
                          'placement': placement,
                          'actionType': actionType,
                          'actionTarget': targetCtrl.text.trim(),
                          // if (ad == null) 'storeId': storeCtrl.text.trim(),
                          // if (ad == null) 'sellerId': sellerCtrl.text.trim(),
                        };
                        if (ad == null) {
                          await ApiService.adminCreateAd(_adminId, data);
                          _showSnack("Banner created");
                        } else {
                          await ApiService.adminUpdateAd(
                              _adminId, ad['_id'], data);
                          _showSnack("Banner updated");
                        }
                        _load();
                      } catch (e) {
                        _showSnack(e.toString(), error: true);
                      }
                    },
                    child: Text("Save",
                        style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ],
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _topBar(),
      Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AdminTheme.wine))
              : _ads.isEmpty
                  ? _emptyState()
                  : _buildList()),
    ]);
  }

  Widget _topBar() => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        color: AdminTheme.card,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text("Ads / Banners", style: AdminTheme.title(20)),
            _badge(_total),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter.isEmpty ? null : _statusFilter,
                hint: Text(
                  "Status",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AdminTheme.grey,
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
                items: ['', 'pending', 'approved', 'rejected']
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.isEmpty ? 'All' : s,
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() => _statusFilter = v ?? '');
                  _load();
                },
              ),
            ),
            // _wineBtn("Add Banner", Icons.add, () => _showEditDialog()),
          ],
        ),
      );
  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _ads.length,
        itemBuilder: (_, i) {
          final ad = _ads[i] as Map;
          final status = ad['status'] ?? 'pending';
          final isActive = ad['isActive'] != false;
          final store = ad['storeId'] as Map? ?? {};
          Color sc = status == 'approved'
              ? Colors.green.shade500
              : status == 'rejected'
                  ? Colors.red.shade400
                  : Colors.orange.shade400;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: AdminTheme.cardDec(),
            child: Column(children: [
              if ((ad['imageUrl'] ?? '').toString().isNotEmpty)
                ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(ad['imageUrl'],
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover)),
              Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(ad['title'] ?? '',
                              style:
                                  AdminTheme.title(13.5, w: FontWeight.w500)),
                          if ((store['storeName'] ?? '').toString().isNotEmpty)
                            Text(store['storeName'], style: AdminTheme.sub(12)),
                          Text(
                              "${ad['placement'] ?? 'home'} · action: ${ad['actionType'] ?? 'none'}",
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: AdminTheme.wine)),
                        ])),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                          color: sc.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(status,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: sc,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          size: 18, color: AdminTheme.grey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (v) async {
                        if (v == 'edit') _showEditDialog(ad);
                        if (v == 'approve') {
                          await ApiService.adminApproveAd(_adminId, ad['_id']);
                          _showSnack("Approved");
                          _load();
                        }
                        if (v == 'reject') {
                          await ApiService.adminRejectAd(_adminId, ad['_id']);
                          _showSnack("Rejected");
                          _load();
                        }
                        if (v == 'toggle') {
                          await ApiService.adminToggleAdActive(
                              _adminId, ad['_id']);
                          _load();
                        }
                        if (v == 'delete') {
                          if (await _confirm("Delete this banner?")) {
                            await ApiService.adminDeleteAd(_adminId, ad['_id']);
                            _showSnack("Deleted");
                            _load();
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        _popItem('edit', 'Edit', Icons.edit_outlined),
                        if (status != 'approved')
                          _popItem(
                              'approve', 'Approve', Icons.check_circle_outline),
                        if (status != 'rejected')
                          _popItem('reject', 'Reject', Icons.cancel_outlined),
                        _popItem(
                            'toggle',
                            isActive ? 'Deactivate' : 'Activate',
                            isActive
                                ? Icons.block_outlined
                                : Icons.check_outlined),
                        _popItem('delete', 'Delete', Icons.delete_outline,
                            danger: true),
                      ],
                    ),
                  ])),
            ]),
          );
        },
      );

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

  Widget _wineBtn(String label, IconData icon, VoidCallback onTap) => SizedBox(
        height: 40,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 16, color: Colors.white),
          label: Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.wine,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
  Widget _emptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.campaign_outlined,
            size: 60, color: AdminTheme.grey.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text("No banners found", style: AdminTheme.sub(15)),
      ]));

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  TextField _f(String label, TextEditingController ctrl) => TextField(
      controller: ctrl,
      decoration: _inputDec(label),
      style: GoogleFonts.poppins(fontSize: 13));

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
