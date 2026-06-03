import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class SellerAnalyticsScreen extends StatefulWidget {
  final String storeId;
  const SellerAnalyticsScreen({super.key, required this.storeId});

  @override
  State<SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends State<SellerAnalyticsScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  Map<String, dynamic> _data = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchStoreAnalytics(widget.storeId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: warmCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: deepPlum, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analytics',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: deepPlum,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: wine, size: 22),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : RefreshIndicator(
              onRefresh: _load,
              color: wine,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRevenueSection(),
                    const SizedBox(height: 20),
                    _buildOrdersSection(),
                    const SizedBox(height: 20),
                    _buildStockSection(),
                    const SizedBox(height: 20),
                    _buildPerformanceSection(),
                    const SizedBox(height: 20),
                    _buildRecentOrders(),
                    const SizedBox(height: 20),
                    _buildTopProducts(),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Revenue ───────────────────────────────────────────────────────────────
  Widget _buildRevenueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Revenue'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _bigStatCard(
                label: 'This Month',
                value:
                    'ILS ${(_data["revenueThisMonth"] ?? 0.0).toStringAsFixed(0)}',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bigStatCard(
                label: 'Total Revenue',
                value:
                    'ILS ${(_data["totalRevenue"] ?? 0.0).toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Orders ────────────────────────────────────────────────────────────────
  Widget _buildOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Orders'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _orderRow('This Month', '${_data["ordersThisMonth"] ?? 0}',
                  const Color(0xFF1565C0)),
              _divider(),
              _orderRow(
                  'Total Orders', '${_data["totalOrders"] ?? 0}', deepPlum),
              _divider(),
              _orderRow('Pending', '${_data["pendingOrders"] ?? 0}',
                  const Color(0xFFFF9800)),
              _divider(),
              _orderRow('Delivered', '${_data["completedOrders"] ?? 0}',
                  const Color(0xFF4CAF50)),
              _divider(),
              _orderRow('Cancelled', '${_data["cancelledOrders"] ?? 0}',
                  const Color(0xFFF44336)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Stock ─────────────────────────────────────────────────────────────────
  Widget _buildStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Inventory'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _smallStatCard(
                label: 'Total',
                value: '${_data["productsCount"] ?? 0}',
                color: deepPlum,
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _smallStatCard(
                label: 'In Stock',
                value: '${_data["availableProducts"] ?? 0}',
                color: const Color(0xFF4CAF50),
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _smallStatCard(
                label: 'Low Stock',
                value: '${_data["lowStockCount"] ?? 0}',
                color: const Color(0xFFFF9800),
                icon: Icons.warning_amber_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _smallStatCard(
                label: 'Out',
                value: '${_data["outOfStockCount"] ?? 0}',
                color: const Color(0xFFF44336),
                icon: Icons.remove_circle_outline_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Performance ───────────────────────────────────────────────────────────
  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Performance'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _bigStatCard(
                label: 'Rating',
                value:
                    '${(_data["ratingAverage"] ?? 0.0).toStringAsFixed(1)} ⭐',
                icon: Icons.star_rounded,
                color: const Color(0xFFE65100),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bigStatCard(
                label: 'Followers',
                value: '${_data["followersCount"] ?? 0}',
                icon: Icons.people_outline_rounded,
                color: const Color(0xFF00838F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _bigStatCard(
                label: 'Reviews',
                value: '${_data["reviewsCount"] ?? 0}',
                icon: Icons.rate_review_outlined,
                color: wine,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }

  // ─── Recent Orders ─────────────────────────────────────────────────────────
  Widget _buildRecentOrders() {
    final recent = (_data["recentOrders"] as List<dynamic>?) ?? [];
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Recent Orders'),
        const SizedBox(height: 10),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: List.generate(recent.length, (i) {
              final o = recent[i] as Map<String, dynamic>;
              final isLast = i == recent.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _statusColor(o['status'] ?? '')
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            color: _statusColor(o['status'] ?? ''),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o['customerName']?.toString() ?? 'Customer',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: darkText,
                                ),
                              ),
                              Text(
                                _formatDate(o['createdAt']?.toString()),
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: grey),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ILS ${(o['total'] as num? ?? 0).toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: wine,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _statusColor(o['status'] ?? '')
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _statusLabel(o['status']?.toString() ?? ''),
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(o['status'] ?? ''),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, color: line, indent: 64, endIndent: 16),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // ─── Top Products ──────────────────────────────────────────────────────────
  Widget _buildTopProducts() {
    final top = (_data["topProducts"] as List<dynamic>?) ?? [];
    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Top Products by Sales'),
        const SizedBox(height: 10),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: List.generate(top.length, (i) {
              final p = top[i] as Map<String, dynamic>;
              final isLast = i == top.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (p['imageUrl'] ?? '').toString().isNotEmpty
                              ? Image.network(
                                  p['imageUrl'].toString(),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _imgPlaceholder(),
                                )
                              : _imgPlaceholder(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['name']?.toString() ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: darkText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((p['brand'] ?? '').toString().isNotEmpty)
                                Text(
                                  p['brand'].toString(),
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: grey),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${p['soldCount'] ?? 0} sold',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: wine,
                              ),
                            ),
                            Text(
                              '${p['currency'] ?? 'ILS'} ${(p['price'] as num? ?? 0).toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, color: line, indent: 68, endIndent: 16),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
    );
  }

  Widget _bigStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(borderColor: color.withOpacity(0.12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: grey),
          ),
        ],
      ),
    );
  }

  Widget _smallStatCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: _cardDecoration(borderColor: color.withOpacity(0.12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 9.5, color: grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _orderRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 13, color: darkText),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: line);

  BoxDecoration _cardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor ?? line),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      color: softBg,
      child: const Icon(Icons.image_outlined, size: 20, color: grey),
    );
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
        return grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'New';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Delivering';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

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
      return '${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return '';
    }
  }
}
