import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class SellerOrdersScreen extends StatefulWidget {
  final String storeId;
  const SellerOrdersScreen({super.key, required this.storeId});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  // ─── Palette ───────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  late TabController _tabController;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  final Set<String> _processingIds = {};

  static const List<String> _tabs = [
    'All',
    'New',
    'Confirmed',
    'Preparing',
    'Delivering',
    'Delivered',
    'Cancelled'
  ];

  static const Map<String, String> _tabToStatus = {
    'New': 'pending',
    'Confirmed': 'confirmed',
    'Preparing': 'processing',
    'Delivering': 'out_for_delivery',
    'Delivered': 'delivered',
    'Cancelled': 'cancelled',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final orders = await ApiService.fetchSellerOrdersByStore(widget.storeId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _filtered(String tab) {
    if (tab == 'All') return _orders;
    final status = _tabToStatus[tab];
    return _orders.where((o) => o['status'] == status).toList();
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    setState(() => _processingIds.add(orderId));
    final ok =
        await ApiService.updateOrderStatus(orderId: orderId, status: newStatus);
    if (!mounted) return;
    setState(() => _processingIds.remove(orderId));
    if (ok) {
      await _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status. Try again.')),
      );
    }
  }

  // ─── Status helpers ────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'confirmed':
        return const Color(0xFF2196F3);
      case 'processing':
        return const Color(0xFF9C27B0);
      case 'out_for_delivery':
        return const Color(0xFF00BCD4);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'New Order';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.fiber_new_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'processing':
        return Icons.local_fire_department_rounded;
      case 'out_for_delivery':
        return Icons.delivery_dining_rounded;
      case 'delivered':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // Next valid status transitions
  List<String> _nextStatuses(String current) {
    switch (current) {
      case 'pending':
        return ['confirmed', 'cancelled'];
      case 'confirmed':
        return ['processing', 'cancelled'];
      case 'processing':
        return ['out_for_delivery', 'cancelled'];
      case 'out_for_delivery':
        return ['delivered'];
      default:
        return [];
    }
  }

  String _nextStatusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirm';
      case 'processing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Mark Delivered';
      case 'cancelled':
        return 'Cancel';
      default:
        return status;
    }
  }

  Color _nextStatusBtnColor(String status) {
    if (status == 'cancelled') return const Color(0xFFF44336);
    return wine;
  }

  // ─── Formatting ────────────────────────────────────────────────────────────
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
      return '${months[d.month - 1]} ${d.day}, ${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _currency(dynamic order) {
    final items = order['items'] as List<dynamic>? ?? [];
    if (items.isNotEmpty) return (items.first['currency'] ?? 'ILS').toString();
    return 'ILS';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: _isLoading
              ? _buildLoader()
              : TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    final list = _filtered(tab);
                    if (list.isEmpty) return _buildEmpty(tab);
                    return RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: wine,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _buildOrderCard(list[i]),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: warmCream,
      child: Row(
        children: [
          Text(
            'Orders',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: deepPlum,
            ),
          ),
          const SizedBox(width: 8),
          if (_orders.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: wine.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_orders.length}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: wine,
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh_rounded, color: wine, size: 22),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: warmCream,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: wine,
        unselectedLabelColor: grey,
        indicatorColor: wine,
        indicatorWeight: 2.5,
        labelStyle:
            GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
        tabs: _tabs.map((tab) {
          final count = tab == 'All' ? _orders.length : _filtered(tab).length;
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tab),
                if (count > 0 && tab != 'All') ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: tab == 'New'
                          ? const Color(0xFFFF9800).withOpacity(0.15)
                          : wine.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tab == 'New' ? const Color(0xFFFF9800) : wine,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(child: CircularProgressIndicator(color: wine));
  }

  Widget _buildEmpty(String tab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: grey.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            tab == 'All' ? 'No orders yet' : 'No ${tab.toLowerCase()} orders',
            style: GoogleFonts.poppins(fontSize: 15, color: grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['_id']?.toString() ?? '';
    final status = order['status']?.toString() ?? 'pending';
    final customer = order['userId'];
    final customerName = (customer is Map ? customer['fullName'] : null) ??
        order['fullName'] ??
        'Customer';
    final items = order['items'] as List<dynamic>? ?? [];
    final total = order['total'] as num? ?? 0;
    final currency = _currency(order);
    final createdAt = order['createdAt']?.toString();
    final isProcessing = _processingIds.contains(orderId);
    final nexts = _nextStatuses(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header strip ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(status),
                    color: _statusColor(status), size: 16),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(status),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '#${orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: grey,
                  ),
                ),
              ],
            ),
          ),
          // ── Body ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 15, color: grey),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        customerName.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$currency ${total.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: wine,
                      ),
                    ),
                  ],
                ),
                if (order['phoneNumber'] != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 13, color: grey),
                      const SizedBox(width: 4),
                      Text(
                        order['phoneNumber'].toString(),
                        style: GoogleFonts.poppins(fontSize: 12, color: grey),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${order['city'] ?? ''}, ${order['streetAddress'] ?? ''}',
                        style: GoogleFonts.poppins(fontSize: 12, color: grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(createdAt),
                        style: GoogleFonts.poppins(fontSize: 11, color: grey),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                // Items preview
                ...items.take(3).map((item) => _buildItemRow(item)),
                if (items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${items.length - 3} more items',
                      style: GoogleFonts.poppins(fontSize: 11, color: grey),
                    ),
                  ),
                if (order['note'] != null &&
                    order['note'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFECB3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_rounded,
                            size: 13, color: Color(0xFFFF8F00)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order['note'].toString(),
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: darkText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ── Action buttons ───────────────────────────────────────────────
          if (nexts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: isProcessing
                  ? const Center(
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: wine),
                      ),
                    )
                  : Row(
                      children: nexts.map((next) {
                        final isCancelBtn = next == 'cancelled';
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: nexts.indexOf(next) > 0 ? 8 : 0),
                            child: OutlinedButton(
                              onPressed: isCancelBtn
                                  ? () => _confirmCancel(orderId)
                                  : () => _updateStatus(orderId, next),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _nextStatusBtnColor(next),
                                side: BorderSide(
                                    color: _nextStatusBtnColor(next)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: Text(
                                _nextStatusLabel(next),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            )
          else if (status == 'delivered')
            _buildDeliveryConfirmBadge(order)
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildDeliveryConfirmBadge(Map<String, dynamic> order) {
    final confirmed = order['userConfirmedDelivery'] == true;
    final confirmedAt = order['userConfirmedDeliveryAt']?.toString();
    String label;
    if (confirmed) {
      label = 'Received by customer';
      if (confirmedAt != null && confirmedAt.isNotEmpty) {
        label += ' · ${_formatDate(confirmedAt)}';
      }
    } else {
      label = 'Delivered by seller — awaiting customer confirmation';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: confirmed
              ? Colors.green.withOpacity(0.07)
              : const Color(0xFFFF9800).withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: confirmed
                ? Colors.green.withOpacity(0.22)
                : const Color(0xFFFF9800).withOpacity(0.22),
          ),
        ),
        child: Row(
          children: [
            Icon(
              confirmed ? Icons.verified_rounded : Icons.access_time_rounded,
              size: 14,
              color:
                  confirmed ? Colors.green.shade700 : const Color(0xFFE65100),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: confirmed
                      ? Colors.green.shade700
                      : const Color(0xFFE65100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    final product = item['productId'];
    final name = (product is Map ? product['name'] : null) ?? 'Product';
    final imageUrl = (product is Map ? product['imageUrl'] : null) ?? '';
    final qty = item['quantity'] ?? 1;
    final price = item['price'] as num? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _productPlaceholder(),
                  )
                : _productPlaceholder(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name.toString(),
              style: GoogleFonts.poppins(fontSize: 12, color: darkText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '×$qty',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price.toStringAsFixed(0),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.inventory_2_outlined, size: 16, color: grey),
    );
  }

  void _confirmCancel(String orderId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.cancel_outlined,
                size: 44, color: Color(0xFFF44336)),
            const SizedBox(height: 12),
            Text(
              'Cancel Order?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: deepPlum,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: GoogleFonts.poppins(fontSize: 13, color: grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: grey,
                      side: const BorderSide(color: line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Keep Order',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateStatus(orderId, 'cancelled');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Cancel Order',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
