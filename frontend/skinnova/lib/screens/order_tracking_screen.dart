import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

/// Shows the live status of a single order as a 4-step delivery timeline,
/// matching the colors/labels already used by SellerOrdersScreen.
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic>? initialOrder;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const Color bgColor = Color(0xFFF7F4F3);
  static const Color cardColor = Colors.white;
  static const Color wine = Color(0xFF5B2333);
  static const Color textDark = Color(0xFF111111);
  static const Color textSoft = Color(0xFF777777);
  static const Color lineColor = Color(0xFFE8E8E8);

  Map<String, dynamic>? order;
  bool isLoading = true;

  static const List<Map<String, dynamic>> _timelineSteps = [
    {'label': 'Order Placed', 'icon': Icons.receipt_long_rounded},
    {'label': 'Pending / Preparing', 'icon': Icons.hourglass_top_rounded},
    {'label': 'On the Way', 'icon': Icons.delivery_dining_rounded},
    {'label': 'Delivered', 'icon': Icons.home_rounded},
  ];

  @override
  void initState() {
    super.initState();
    order = widget.initialOrder;
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final fetched = await ApiService.fetchOrderById(widget.orderId);
    if (!mounted) return;
    setState(() {
      if (fetched != null) order = fetched;
      isLoading = false;
    });
  }

  // ── Status helpers (kept consistent with SellerOrdersScreen mapping) ──────
  int _currentStepIndex(String status) {
    switch (status) {
      case 'pending':
      case 'confirmed':
      case 'processing':
        return 1;
      case 'out_for_delivery':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
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

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$m';
  }

  String _shortId(String id) =>
      id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final status = (order?['status'] ?? 'pending').toString();
    final isCancelled = status == 'cancelled';
    final currentStep = _currentStepIndex(status);
    final orderId = (order?['_id'] ?? widget.orderId).toString();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: (isLoading && order == null)
                  ? const Center(child: CircularProgressIndicator(color: wine))
                  : (order == null)
                      ? Center(
                          child: Text(
                            'Order not found',
                            style: GoogleFonts.poppins(color: textSoft),
                          ),
                        )
                      : RefreshIndicator(
                          color: wine,
                          onRefresh: _loadOrder,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOrderInfoCard(orderId, status),
                                const SizedBox(height: 18),
                                isCancelled
                                    ? _buildCancelledBanner()
                                    : _buildTimelineCard(currentStep),
                                const SizedBox(height: 18),
                                _buildDeliveryCard(),
                                if (_history.isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  _buildHistoryCard(),
                                ],
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> get _history =>
      (order?['trackingHistory'] as List?)?.toList() ?? [];

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
            "Track Order",
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

  Widget _infoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: lineColor),
      ),
      child: child,
    );
  }

  Widget _buildOrderInfoCard(String orderId, String status) {
    final color = _statusColor(status);
    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Order #${_shortId(orderId)}",
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _statusLabel(status),
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.access_time_rounded, "Placed on", _formatDate(order?['createdAt'])),
          if (order?['estimatedDeliveryTime'] != null) ...[
            const SizedBox(height: 8),
            _infoRow(
              Icons.local_shipping_outlined,
              "Estimated delivery",
              _formatDate(order?['estimatedDeliveryTime']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: wine),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: GoogleFonts.poppins(fontSize: 12.5, color: textSoft),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelledBanner() {
    const cancelColor = Color(0xFFF44336);
    return _infoCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cancelColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.cancel_outlined, color: cancelColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Cancelled",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "This order was cancelled and will not be delivered.",
                  style: GoogleFonts.poppins(fontSize: 12.5, color: textSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(int currentStep) {
    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Status",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < _timelineSteps.length; i++)
            _timelineStep(
              icon: _timelineSteps[i]['icon'] as IconData,
              label: _timelineSteps[i]['label'] as String,
              isCompleted: i < currentStep,
              isCurrent: i == currentStep,
              isLast: i == _timelineSteps.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _timelineStep({
    required IconData icon,
    required String label,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    final bool isActive = isCompleted || isCurrent;
    final Color circleColor = isActive ? wine : lineColor;
    final Color iconColor = isActive ? Colors.white : textSoft;
    final Color labelColor = isActive ? textDark : textSoft;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: isCompleted ? wine : lineColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard() {
    final fullName = (order?['fullName'] ?? '').toString();
    final phone = (order?['phoneNumber'] ?? '').toString();
    final city = (order?['city'] ?? '').toString();
    final street = (order?['streetAddress'] ?? '').toString();
    final note = (order?['note'] ?? '').toString();

    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Delivery Address",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline_rounded, "Recipient", fullName),
          const SizedBox(height: 8),
          _infoRow(Icons.phone_outlined, "Phone", phone),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on_outlined, "Address", "$street, $city"),
          if (note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.edit_note_rounded, "Note", note),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tracking History",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in _history.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _statusColor((entry['status'] ?? '').toString()),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusLabel((entry['status'] ?? '').toString()),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(entry['changedAt']),
                    style: GoogleFonts.poppins(fontSize: 12, color: textSoft),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
