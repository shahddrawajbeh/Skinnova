import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminStoresScreen extends StatefulWidget {
  final bool showBadgeMode;
  const AdminStoresScreen({super.key, this.showBadgeMode = false});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  bool _loading = true;
  List _stores = [];
  int _total = 0;
  String _adminId = '';
  final _searchCtrl = TextEditingController();
  String _approvalFilter = '';

  static const List<String> _badgeLevels = ['standard', 'premium', 'trusted'];

  @override
  void initState() {
    super.initState();
    // In badge mode, default filter to approved stores
    if (widget.showBadgeMode) _approvalFilter = 'approved';
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
      final data = await ApiService.adminGetStores(_adminId,
          search: _searchCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        var list = (data['stores'] as List? ?? []);
        // Filter by approvalStatus in badge mode
        if (_approvalFilter.isNotEmpty) {
          list = list
              .where((s) => (s as Map)['approvalStatus'] == _approvalFilter)
              .toList();
        }
        _stores = list;
        _total = data['total'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showEditDialog([Map? store]) {
    final nameCtrl = TextEditingController(text: store?['storeName'] ?? '');
    final cityCtrl = TextEditingController(text: store?['city'] ?? '');
    final phoneCtrl = TextEditingController(text: store?['phone'] ?? '');
    final descCtrl = TextEditingController(text: store?['description'] ?? '');
    final addrCtrl = TextEditingController(text: store?['address'] ?? '');
    final sellerCtrl = TextEditingController(
        text: store?['sellerId']?['_id'] ?? store?['sellerId'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(store == null ? "Add Store" : "Edit Store",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AdminTheme.black)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field("Store Name *", nameCtrl),
            const SizedBox(height: 10),
            _field("City *", cityCtrl),
            const SizedBox(height: 10),
            _field("Phone", phoneCtrl),
            const SizedBox(height: 10),
            _field("Address", addrCtrl),
            const SizedBox(height: 10),
            _field("Description", descCtrl, maxLines: 3),
            if (store == null) ...[
              const SizedBox(height: 10),
              _field("Seller / Owner User ID", sellerCtrl),
            ],
          ])),
        ),
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
                if (store == null) {
                  await ApiService.adminCreateStore(_adminId, {
                    'storeName': nameCtrl.text.trim(),
                    'city': cityCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'address': addrCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'sellerId': sellerCtrl.text.trim(),
                  });
                  _showSnack("Store created");
                } else {
                  await ApiService.adminUpdateStore(_adminId, store['_id'], {
                    'storeName': nameCtrl.text.trim(),
                    'city': cityCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'address': addrCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                  });
                  _showSnack("Store updated");
                }
                _load();
              } catch (e) {
                _showSnack(e.toString(), error: true);
              }
            },
            child:
                Text("Save", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStoreDetails(Map store) {
    final seller = store['sellerId'] as Map? ?? {};
    final approval = store['approvalStatus'] ?? 'pending';
    final verStatus = store['verificationStatus'] ?? 'not_submitted';
    final docUrl = (store['verificationDocumentUrl'] ?? '').toString();
    final docType = (store['verificationDocumentType'] ?? '').toString();
    final rejReason = (store['rejectionReason'] ?? '').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Store Details — ${store['storeName'] ?? ''}",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AdminTheme.black)),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Logo + cover preview
              if ((store['logoUrl'] ?? '').toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(store['logoUrl'],
                      height: 80, width: 80, fit: BoxFit.cover),
                ),
              const SizedBox(height: 12),
              _dr("Store Name", store['storeName'] ?? ''),
              _dr("City", store['city'] ?? ''),
              _dr("Address", store['address'] ?? ''),
              _dr("Phone", store['phone'] ?? ''),
              _dr("Owner",
                  "${seller['fullName'] ?? 'N/A'} (${seller['email'] ?? ''})"),
              _dr("Approval", approval),
              _dr("Verification", verStatus),
              _dr("Badge Level", store['verificationLevel'] ?? 'standard'),
              _dr("Active", store['isActive'] == true ? 'Yes' : 'No'),
              if (rejReason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text("Rejection Reason: $rejReason",
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, color: Colors.red.shade700)),
                ),
              ],
              if (docUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text("Verification Document ($docType):",
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AdminTheme.grey,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: docUrl.toLowerCase().endsWith('.pdf')
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AdminTheme.wineMuted,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            const Icon(Icons.picture_as_pdf_rounded,
                                color: AdminTheme.wine),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text("PDF Document",
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, color: AdminTheme.wine))),
                          ]),
                        )
                      : Image.network(docUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 40)),
                ),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close",
                  style: GoogleFonts.poppins(color: AdminTheme.grey))),
        ],
      ),
    );
  }

  Widget _dr(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 100,
              child: Text("$label:",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AdminTheme.grey))),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AdminTheme.black,
                      fontWeight: FontWeight.w500))),
        ]),
      );

  void _showRejectDialog(Map store) {
    final reasons = [
      "Missing business license or verification document",
      "Invalid or unclear verification document",
      "Incomplete store information",
      "Invalid phone number or contact information",
      "Store logo or cover image is inappropriate",
      "Store description is unclear or misleading",
      "Store does not match Skinova policies",
      "Duplicate store request",
      "Suspicious or fake store information",
      "Other reason",
    ];

    String selectedReason = reasons.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Reject Store Request",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AdminTheme.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose the reason for rejecting this store request:",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AdminTheme.grey,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedReason,
                isExpanded: true,
                decoration: _inputDec("Rejection reason"),
                items: reasons
                    .map(
                      (reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(
                          reason,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 12.5),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setS(() => selectedReason = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: AdminTheme.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);

                final ok = await ApiService.adminRejectStoreWithReason(
                  _adminId,
                  store['_id'],
                  selectedReason,
                );

                if (ok) {
                  _showSnack("Store rejected");
                  _load();
                } else {
                  _showSnack("Failed to reject", error: true);
                }
              },
              child: Text(
                "Reject",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDialog(Map store) {
    String level = store['verificationLevel'] ?? 'standard';
    bool verified = store['isVerified'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Store Badge — ${store['storeName']}",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AdminTheme.black)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("Verification Level", style: AdminTheme.sub(12)),
            const SizedBox(height: 8),
            ..._badgeLevels.map((l) => RadioListTile<String>(
                  title: Text(l[0].toUpperCase() + l.substring(1),
                      style: GoogleFonts.poppins(fontSize: 13)),
                  subtitle: Text(_badgeDesc(l), style: AdminTheme.sub(11)),
                  value: l,
                  groupValue: level,
                  activeColor: AdminTheme.wine,
                  onChanged: (v) => setS(() => level = v!),
                )),
            const Divider(),
            SwitchListTile(
              title: Text("Mark as Verified",
                  style: GoogleFonts.poppins(fontSize: 13)),
              subtitle: Text("Shows verified badge to users",
                  style: AdminTheme.sub(11)),
              value: verified,
              activeColor: AdminTheme.wine,
              onChanged: (v) => setS(() => verified = v),
            ),
          ]),
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
                await ApiService.adminSetStoreBadge(
                    _adminId, store['_id'], level, verified);
                _showSnack("Badge updated");
                _load();
              },
              child: Text("Save Badge",
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _badgeDesc(String l) {
    if (l == 'trusted') return 'Gold badge — highest trust level';
    if (l == 'premium') return 'Silver badge — premium seller';
    return 'Default — no special badge';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AdminTheme.wine))
              : _stores.isEmpty
                  ? _emptyState()
                  : _buildList(),
        ),
      ],
    );
  }

  Widget _topBar() => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        color: AdminTheme.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(widget.showBadgeMode ? "Store Badges & Approval" : "Stores",
                  style: AdminTheme.title(20)),
              const SizedBox(width: 10),
              _badge(_stores.length),
              const Spacer(),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _load(),
                decoration: _inputDec("Search stores...").copyWith(
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: AdminTheme.grey)),
                style: GoogleFonts.poppins(fontSize: 13),
              )),
              if (!widget.showBadgeMode) ...[
                const SizedBox(width: 10),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _approvalFilter.isEmpty ? null : _approvalFilter,
                    hint: Text("Status",
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AdminTheme.grey)),
                    borderRadius: BorderRadius.circular(12),
                    items: ['', 'pending', 'approved', 'rejected']
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.isEmpty ? 'All' : s,
                                style: GoogleFonts.poppins(fontSize: 13))))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _approvalFilter = v ?? '');
                      _load();
                    },
                  ),
                ),
              ],
            ]),
          ],
        ),
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _stores.length,
        itemBuilder: (_, i) => _buildRow(_stores[i] as Map),
      );

  Widget _buildRow(Map s) {
    final isActive = s['isActive'] != false;
    final isVerified = s['isVerified'] == true;
    final approval = s['approvalStatus'] ?? 'pending';
    final level = s['verificationLevel'] ?? 'standard';
    final seller = s['sellerId'] as Map? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AdminTheme.cardDec(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (s['logoUrl'] ?? '').toString().isNotEmpty
                ? Image.network(s['logoUrl'],
                    width: 46, height: 46, fit: BoxFit.cover)
                : Container(
                    width: 46,
                    height: 46,
                    color: AdminTheme.wineMuted,
                    child: const Icon(Icons.store_rounded,
                        color: AdminTheme.wine, size: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(s['storeName'] ?? '',
                    style: AdminTheme.title(13.5, w: FontWeight.w500)),
                if (isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded,
                      size: 14, color: Colors.blue),
                ],
              ]),
              Text("${s['city'] ?? ''} • ${seller['fullName'] ?? 'N/A'}",
                  style: AdminTheme.sub(12)),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _pill(approval, _approvalColor(approval)),
                  _pill(
                    s['verificationStatus'] ?? 'not_submitted',
                    _verificationStatusColor(
                      s['verificationStatus'] ?? 'not_submitted',
                    ),
                  ),
                  if (level != 'standard') _levelBadge(level),
                ],
              ),
            ]),
          ),
          _dot(isActive),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 18, color: AdminTheme.grey),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) async {
              if (v == 'details') _showStoreDetails(s);
              if (v == 'badge') _showBadgeDialog(s);
              if (v == 'approve') {
                await ApiService.adminApproveStore(_adminId, s['_id']);
                _showSnack("Store approved — user promoted to seller");
                _load();
              }
              if (v == 'reject') {
                _showRejectDialog(s);
              }
              if (v == 'toggle') {
                final ok = await _confirm(
                  isActive
                      ? "Deactivate this store? It will be hidden from users."
                      : "Activate this store? It will be visible to users if approved.",
                );

                if (ok) {
                  await ApiService.adminToggleStoreActive(_adminId, s['_id']);
                  _showSnack(
                      isActive ? "Store deactivated" : "Store activated");
                  _load();
                }
              }
              if (v == 'delete') {
                if (await _confirm("Delete this store?")) {
                  await ApiService.adminDeleteStore(_adminId, s['_id']);
                  _showSnack("Store deleted");
                  _load();
                }
              }
            },
            itemBuilder: (_) => [
              _popItem('details', 'View Details', Icons.info_outline),
              _popItem('badge', 'Set Badge', Icons.verified_outlined),
              if (approval != 'approved')
                _popItem('approve', 'Approve ✓', Icons.check_circle_outline),
              if (approval != 'rejected')
                _popItem('reject', 'Reject', Icons.cancel_outlined),
              _popItem('toggle', isActive ? 'Deactivate' : 'Activate',
                  isActive ? Icons.block_outlined : Icons.check_circle_outline),
              if (!widget.showBadgeMode)
                _popItem('delete', 'Delete', Icons.delete_outline,
                    danger: true),
            ],
          ),
        ],
      ),
    );
  }

  Color _approvalColor(String s) => s == 'approved'
      ? Colors.green.shade500
      : s == 'rejected'
          ? Colors.red.shade400
          : Colors.orange.shade400;

  Color _verificationStatusColor(String s) {
    switch (s) {
      case 'verified':
        return Colors.green.shade600;
      case 'pending_review':
        return Colors.blue.shade500;
      case 'rejected':
        return Colors.red.shade400;
      default:
        return Colors.grey.shade500;
    }
  }

  Widget _levelBadge(String level) {
    Color c =
        level == 'trusted' ? Colors.amber.shade700 : Colors.blueGrey.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
            level == 'trusted'
                ? Icons.workspace_premium_rounded
                : Icons.star_rounded,
            size: 10,
            color: c),
        const SizedBox(width: 3),
        Text(level,
            style: GoogleFonts.poppins(
                fontSize: 10, color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10.5, color: color, fontWeight: FontWeight.w600)),
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

  Widget _dot(bool a) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
            color: a ? Colors.green.shade400 : Colors.red.shade300,
            shape: BoxShape.circle),
      );

  Widget _wineBtn(String label, IconData icon, VoidCallback onTap) =>
      ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17, color: Colors.white),
        label: Text(label,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.wine,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
      );

  Widget _emptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.store_outlined,
            size: 60, color: AdminTheme.grey.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text("No stores found", style: AdminTheme.sub(15)),
      ]));

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  TextField _field(String label, TextEditingController ctrl,
          {int maxLines = 1}) =>
      TextField(
          controller: ctrl,
          maxLines: maxLines,
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
