import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  static const List<String> _statuses = [
    '',
    'pending',
    'confirmed',
    'processing',
    'out_for_delivery',
    'delivered',
    'cancelled'
  ];
  bool _loading = true;
  List _orders = [];
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
          await ApiService.adminGetOrders(_adminId, status: _statusFilter);
      if (!mounted) return;
      setState(() {
        _orders = data['orders'] as List? ?? [];
        _total = data['total'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showDetails(Map order) {
    final user = order['userId'] as Map? ?? {};
    final store = order['storeId'] as Map? ?? {};
    final items = (order['items'] as List?) ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Order Details",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AdminTheme.black)),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _dr("Customer", user['fullName'] ?? 'N/A'),
                _dr("Email", user['email'] ?? ''),
                _dr("Store", store['storeName'] ?? 'N/A'),
                _dr("Status", order['status'] ?? ''),
                if ((order['status'] ?? '') == 'delivered') ...[
                  _dr(
                    "Customer Confirm",
                    order['userConfirmedDelivery'] == true
                        ? "Confirmed ✅"
                        : "Pending ⏳",
                  ),
                  if (order['userConfirmedDelivery'] == true &&
                      (order['userConfirmedDeliveryAt'] ?? '')
                          .toString()
                          .isNotEmpty)
                    _dr(
                      "Confirmed At",
                      _fmtConfirmDate(
                          order['userConfirmedDeliveryAt'].toString()),
                    ),
                ],
                _dr("Payment", order['paymentMethod'] ?? ''),
                _dr("City", order['city'] ?? ''),
                _dr("Address", order['streetAddress'] ?? ''),
                _dr("Subtotal", "${order['subtotal'] ?? 0} ILS"),
                _dr("Delivery", "${order['deliveryFee'] ?? 0} ILS"),
                _dr("Total", "${order['total'] ?? 0} ILS"),
                if ((order['note'] ?? '').toString().isNotEmpty)
                  _dr("Note", order['note']),
                const SizedBox(height: 10),
                Text("Items:",
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminTheme.wine)),
                ...items.map((item) {
                  final prod = (item['productId'] as Map?) ?? {};
                  return ListTile(
                      dense: true,
                      leading: const Icon(Icons.inventory_2_outlined,
                          size: 16, color: AdminTheme.wine),
                      title: Text(prod['name'] ?? 'Product',
                          style: GoogleFonts.poppins(fontSize: 13)),
                      trailing: Text("x${item['quantity']}",
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AdminTheme.grey)));
                }),
              ])),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close",
                  style: GoogleFonts.poppins(color: AdminTheme.grey)))
        ],
      ),
    );
  }

  Widget _dr(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 80, child: Text("$label:", style: AdminTheme.sub(12))),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AdminTheme.black,
                      fontWeight: FontWeight.w500))),
        ]),
      );

  String _fmtConfirmDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const m = [
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
      return '${m[d.month - 1]} ${d.day}, ${d.year}  '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _changeStatus(String orderId, String current) async {
    final chosen = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text("Change Status",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: AdminTheme.black)),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    'pending',
                    'confirmed',
                    'processing',
                    'out_for_delivery',
                    'delivered',
                    'cancelled'
                  ]
                      .map((s) => RadioListTile<String>(
                          title: Text(s.replaceAll('_', ' '),
                              style: GoogleFonts.poppins(fontSize: 13)),
                          value: s,
                          groupValue: current,
                          activeColor: AdminTheme.wine,
                          onChanged: (v) => Navigator.pop(ctx, v)))
                      .toList()),
            ));
    if (chosen == null || chosen == current) return;
    await ApiService.adminUpdateOrderStatus(_adminId, orderId, chosen);
    _showSnack("Status → $chosen");
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(children: [
      _topBar(),
      Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AdminTheme.wine))
              : _orders.isEmpty
                  ? _emptyState()
                  : _buildList()),
    ]);
    if (Scaffold.maybeOf(context) != null) return content;
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AdminTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Orders', style: AdminTheme.title(15, w: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AdminTheme.line),
        ),
      ),
      body: content,
    );
  }

  Widget _topBar() => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        color: AdminTheme.card,
        child: Row(children: [
          Text("Orders", style: AdminTheme.title(20)),
          const SizedBox(width: 10),
          _badge(_total),
          const Spacer(),
          DropdownButtonHideUnderline(
              child: DropdownButton<String>(
            value: _statusFilter.isEmpty ? null : _statusFilter,
            hint: Text("All Status",
                style:
                    GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey)),
            borderRadius: BorderRadius.circular(12),
            items: _statuses
                .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.isEmpty ? 'All' : s.replaceAll('_', ' '),
                        style: GoogleFonts.poppins(fontSize: 13))))
                .toList(),
            onChanged: (v) {
              setState(() => _statusFilter = v ?? '');
              _load();
            },
          )),
        ]),
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _orders.length,
        itemBuilder: (_, i) {
          final o = _orders[i] as Map;
          final user = o['userId'] as Map? ?? {};
          final store = o['storeId'] as Map? ?? {};
          final status = o['status'] ?? 'pending';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: AdminTheme.cardDec(),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(user['fullName'] ?? 'Unknown',
                        style: AdminTheme.title(13.5, w: FontWeight.w500)),
                    Text(store['storeName'] ?? '', style: AdminTheme.sub(12)),
                    Text("${o['total'] ?? 0} ILS · ${o['paymentMethod'] ?? ''}",
                        style: GoogleFonts.poppins(
                            fontSize: 11.5, color: AdminTheme.wine)),
                  ])),
              _statusBadge(status),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 18, color: AdminTheme.grey),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (v) async {
                  if (v == 'details') _showDetails(o);
                  if (v == 'status') _changeStatus(o['_id'], status);
                  if (v == 'delete') {
                    if (await _confirm("Delete this order?")) {
                      await ApiService.adminDeleteOrder(_adminId, o['_id']);
                      _showSnack("Order deleted");
                      _load();
                    }
                  }
                },
                itemBuilder: (_) => [
                  _popItem('details', 'View Details', Icons.info_outline),
                  _popItem('status', 'Change Status', Icons.edit_outlined),
                  _popItem('delete', 'Delete', Icons.delete_outline,
                      danger: true),
                ],
              ),
            ]),
          );
        },
      );

  Widget _statusBadge(String status) {
    Color c;
    switch (status) {
      case 'delivered':
        c = Colors.green.shade500;
        break;
      case 'cancelled':
        c = Colors.red.shade400;
        break;
      case 'pending':
        c = Colors.orange.shade400;
        break;
      default:
        c = Colors.blue.shade400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status.replaceAll('_', ' '),
          style: GoogleFonts.poppins(
              fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }

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
        Icon(Icons.receipt_long_outlined,
            size: 60, color: AdminTheme.grey.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text("No orders found", style: AdminTheme.sub(15)),
      ]));

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
