import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'order_tracking_screen.dart';

/// Order-level list of the current user's orders — each row links into
/// OrderTrackingScreen. (Distinct from PurchaseHistoryScreen, which lists
/// individually purchased products rather than whole orders.)
class MyOrdersScreen extends StatefulWidget {
  final String userId;

  const MyOrdersScreen({super.key, required this.userId});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  static const Color bgColor = Color(0xFFF7F4F3);
  static const Color cardColor = Colors.white;
  static const Color wine = Color(0xFF5B2333);
  static const Color textDark = Color(0xFF111111);
  static const Color textSoft = Color(0xFF777777);
  static const Color lineColor = Color(0xFFE8E8E8);

  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    final result = await ApiService.fetchOrders(widget.userId);
    if (!mounted) return;
    setState(() {
      orders = result;
      isLoading = false;
    });
  }

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
        return textSoft;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'On the way';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _shortId(String id) =>
      id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: wine))
                  : orders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: wine,
                          onRefresh: _loadOrders,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: orders.length,
                            itemBuilder: (context, index) =>
                                _buildOrderCard(orders[index]),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
            "My Orders",
            style: GoogleFonts.poppins(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: wine.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined, color: wine, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            "No orders yet",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Orders you place will show up here.",
            style: GoogleFonts.poppins(fontSize: 12.5, color: textSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final orderId = (order["_id"] ?? "").toString();
    final status = (order["status"] ?? "pending").toString();
    final color = _statusColor(status);

    final storeId = order["storeId"];
    final storeName = (storeId is Map ? storeId["storeName"] : null)?.toString() ??
        "Store";

    final items = (order["items"] as List?) ?? [];
    final itemCount = items.fold<int>(0, (sum, item) {
      final q = item is Map ? item["quantity"] : null;
      return sum + (q is num ? q.toInt() : 0);
    });

    final total = order["total"];
    final totalText = total is num ? total.toStringAsFixed(2) : "0.00";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(
              orderId: orderId,
              initialOrder: order is Map<String, dynamic> ? order : null,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: lineColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    storeName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Order #${_shortId(orderId)}  ·  ${_formatDate(order["createdAt"])}",
              style: GoogleFonts.poppins(fontSize: 12, color: textSoft),
            ),
            const SizedBox(height: 4),
            Text(
              "$itemCount item${itemCount == 1 ? '' : 's'}",
              style: GoogleFonts.poppins(fontSize: 12, color: textSoft),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "$totalText ILS",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: wine,
                  ),
                ),
                const Spacer(),
                Text(
                  "Track Order",
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: wine,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: wine),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
