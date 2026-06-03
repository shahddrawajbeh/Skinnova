import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'product_details_screen.dart';
import 'product_usage_reminder_screen.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const PurchaseHistoryScreen({
    super.key,
    required this.userId,
    this.userName = '',
  });

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  // ── Palette (matches ProfileScreen) ──────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  // ── State ─────────────────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _all = [];
  Map<String, Map<String, dynamic>> _remindersByProductId = {};
  String _filter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _confirmingIds = {};

  final List<String> _filters = [
    'All',
    'Delivered',
    'In Progress',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.fetchPurchaseHistory(widget.userId);

      List<dynamic> remindersList = [];
      try {
        remindersList =
            await ApiService.getProductUsageReminders(widget.userId);
      } catch (_) {}

      if (!mounted) return;
      if (res['statusCode'] == 200) {
        final raw = (res['data']['purchases'] as List?) ?? [];
        final remindersMap = <String, Map<String, dynamic>>{};
        for (final r in remindersList) {
          final pid = (r as Map)['productId']?.toString() ?? '';
          if (pid.isNotEmpty) remindersMap[pid] = Map<String, dynamic>.from(r);
        }
        setState(() {
          _all = raw.cast<Map<String, dynamic>>();
          _remindersByProductId = remindersMap;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load purchase history';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openReminderScreen(Map<String, dynamic> purchase) {
    final productId = purchase['productId']?.toString() ?? '';
    final existing = _remindersByProductId[productId];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductUsageReminderScreen(
          userId: widget.userId,
          productId: productId,
          productName: purchase['productName']?.toString() ?? '',
          brand: purchase['brand']?.toString() ?? '',
          imageUrl: purchase['imageUrl']?.toString() ?? '',
          directionsOfUse: purchase['directionsOfUse']?.toString() ?? '',
          existingReminderId: existing?['_id']?.toString(),
          existingTimes: existing != null
              ? (existing['reminderTimes'] as List?)
                  ?.cast<Map<String, dynamic>>()
              : null,
          existingFrequencyType: existing?['frequencyType']?.toString(),
          existingIsActive: existing?['isActive'] == true,
        ),
      ),
    ).then((_) => _load());
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _all;

    if (_filter != 'All') {
      list = list.where((p) {
        final s = (p['status'] ?? '').toString();
        switch (_filter) {
          case 'Delivered':
            return s == 'delivered';
          case 'In Progress':
            return ['pending', 'confirmed', 'processing', 'out_for_delivery']
                .contains(s);
          case 'Cancelled':
            return s == 'cancelled';
          default:
            return true;
        }
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        final name = (p['productName'] ?? '').toString().toLowerCase();
        final brand = (p['brand'] ?? '').toString().toLowerCase();
        return name.contains(q) || brand.contains(q);
      }).toList();
    }

    return list;
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _viewProduct(String? productId) async {
    if (productId == null || productId.isEmpty) {
      _showSnack('Product details are no longer available');
      return;
    }
    try {
      final product = await ApiService.fetchProductById(productId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(
            product: product,
            userId: widget.userId,
            userName: widget.userName,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('This product is no longer available');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleConfirmReceived(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Delivery',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: darkText)),
        content: Text('Did you receive this order?',
            style: GoogleFonts.poppins(fontSize: 14, color: grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: grey, fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: wine,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Yes, I Received It',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _confirmingIds.add(orderId));
    final ok = await ApiService.confirmOrderReceived(orderId, widget.userId);
    if (!mounted) return;
    setState(() => _confirmingIds.remove(orderId));

    if (ok) {
      _showSnack('Order received successfully.');
      await _load();
    } else {
      _showSnack('Failed to confirm. Please try again.');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: whiteSmoke,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: darkText),
          ),
        ),
        title: Text(
          'Purchase History',
          style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w600, color: darkText),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: line, height: 1),
        ),
      );

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: wine));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: wine.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 34, color: wine),
              ),
              const SizedBox(height: 18),
              Text('Could not load purchases',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: darkText)),
              const SizedBox(height: 8),
              Text('Pull down to retry',
                  style: GoogleFonts.poppins(fontSize: 12.5, color: grey)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
                  decoration: BoxDecoration(
                      color: wine, borderRadius: BorderRadius.circular(12)),
                  child: Text('Try Again',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = _filtered;

    return RefreshIndicator(
      color: wine,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildSearchAndFilters(items.length)),
          if (_all.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmpty("You haven't purchased any products yet.",
                  showHint: true),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmpty("No purchases match your filters."),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final item = items[i];
                  final orderId = item['orderId']?.toString() ?? '';
                  final productId = item['productId']?.toString() ?? '';
                  final status = item['status']?.toString() ?? '';
                  final confirmed = item['userConfirmedDelivery'] == true;
                  final canConfirm = status == 'delivered' && !confirmed;
                  final hasReminder =
                      _remindersByProductId.containsKey(productId);
                  final reminderActive =
                      _remindersByProductId[productId]?['isActive'] == true;
                  return _PurchaseCard(
                    purchase: item,
                    onViewProduct: () =>
                        _viewProduct(item['productId']?.toString()),
                    onBuyAgain: () =>
                        _viewProduct(item['productId']?.toString()),
                    onConfirmReceived: canConfirm
                        ? () => _handleConfirmReceived(orderId)
                        : null,
                    isConfirming: _confirmingIds.contains(orderId),
                    hasReminder: hasReminder,
                    reminderActive: reminderActive,
                    onSetReminder: productId.isNotEmpty
                        ? () => _openReminderScreen(item)
                        : null,
                  );
                },
                childCount: items.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: whiteSmoke,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: line),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              style: GoogleFonts.poppins(fontSize: 13.5, color: darkText),
              decoration: InputDecoration(
                hintText: 'Search by product or brand…',
                hintStyle: GoogleFonts.poppins(fontSize: 13.5, color: grey),
                prefixIcon:
                    const Icon(Icons.search_rounded, size: 20, color: grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: grey),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        // Filter chips
        SizedBox(
          height: 54,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            itemCount: _filters.length,
            itemBuilder: (_, i) {
              final f = _filters[i];
              final active = f == _filter;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? wine : whiteSmoke,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: active ? wine : line),
                  ),
                  child: Text(
                    f,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? Colors.white : darkText),
                  ),
                ),
              );
            },
          ),
        ),
        // Result count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            '$count purchase${count == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(fontSize: 12.5, color: grey),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(String msg, {bool showHint = false}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: wine.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    size: 34, color: wine),
              ),
              const SizedBox(height: 18),
              Text(msg,
                  style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: darkText),
                  textAlign: TextAlign.center),
              if (showHint) ...[
                const SizedBox(height: 8),
                Text('Products you order will appear here.',
                    style: GoogleFonts.poppins(fontSize: 12.5, color: grey),
                    textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      );
}

// ── Purchase Card ─────────────────────────────────────────────────────────────

class _PurchaseCard extends StatelessWidget {
  final Map<String, dynamic> purchase;
  final VoidCallback onViewProduct;
  final VoidCallback onBuyAgain;
  final VoidCallback? onConfirmReceived;
  final bool isConfirming;
  final bool hasReminder;
  final bool reminderActive;
  final VoidCallback? onSetReminder;

  const _PurchaseCard({
    required this.purchase,
    required this.onViewProduct,
    required this.onBuyAgain,
    this.onConfirmReceived,
    this.isConfirming = false,
    this.hasReminder = false,
    this.reminderActive = false,
    this.onSetReminder,
  });

  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  @override
  Widget build(BuildContext context) {
    final imageUrl = (purchase['imageUrl'] ?? '').toString();
    final name = (purchase['productName'] ?? 'Unknown Product').toString();
    final brand = (purchase['brand'] ?? '').toString();
    final storeName = (purchase['storeName'] ?? '').toString();
    final quantity = purchase['quantity'] ?? 1;
    final price = (purchase['price'] as num?)?.toDouble() ?? 0;
    final currency = (purchase['currency'] ?? 'ILS').toString();
    final status = (purchase['status'] ?? 'pending').toString();
    final orderId = (purchase['orderId'] ?? '').toString();

    final confirmed = purchase['userConfirmedDelivery'] == true;
    final confirmedAt = purchase['userConfirmedDeliveryAt'];
    final formattedDate = _formatDate(purchase['purchasedAt']);
    final shortId =
        orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;
    final statusColor = _statusColor(status);
    final statusLabel = _capitalize(status.replaceAll('_', ' '));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product header ───────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                const SizedBox(width: 14),
                // Name / brand / store / status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkText),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (brand.isNotEmpty) brand,
                          if (storeName.isNotEmpty) storeName,
                        ].join(' · '),
                        style: GoogleFonts.poppins(fontSize: 12, color: grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Container(height: 1, color: line),
            const SizedBox(height: 12),

            // ── Details ──────────────────────────────────────────────────
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _detail(Icons.calendar_today_outlined,
                    formattedDate.isNotEmpty ? formattedDate : '—'),
                _detail(Icons.shopping_bag_outlined, 'Qty: $quantity'),
                _detail(Icons.payments_outlined,
                    '$currency ${price.toStringAsFixed(0)}'),
                _detail(Icons.tag_rounded, '#$shortId'),
              ],
            ),

            const SizedBox(height: 14),

            // ── Action buttons ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onViewProduct,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: wine,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'View Product',
                        style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onBuyAgain,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: whiteSmoke,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: wine.withOpacity(0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Buy Again',
                        style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: wine),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Reminder button ───────────────────────────────────────────
            if (onSetReminder != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onSetReminder,
                child: Container(
                  width: double.infinity,
                  height: 38,
                  decoration: BoxDecoration(
                    color: hasReminder
                        ? (reminderActive
                            ? const Color(0xFFF2E8EA)
                            : whiteSmoke)
                        : whiteSmoke,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasReminder ? wine.withOpacity(0.35) : line,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasReminder
                            ? Icons.alarm_on_rounded
                            : Icons.alarm_add_rounded,
                        size: 15,
                        color: hasReminder ? wine : grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasReminder
                            ? (reminderActive
                                ? 'Reminder Active'
                                : 'Reminder Off')
                            : 'Set Reminder',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: hasReminder ? wine : grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Delivery confirmation section ─────────────────────────────
            if (status == 'delivered') ...[
              const SizedBox(height: 12),
              Container(height: 1, color: line),
              const SizedBox(height: 12),
              if (confirmed)
                Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        size: 15, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        confirmedAt != null
                            ? 'Received by customer · ${_formatDate(confirmedAt)}'
                            : 'Received by customer',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700),
                      ),
                    ),
                  ],
                )
              else if (isConfirming)
                const Center(
                  child: SizedBox(
                    height: 26,
                    width: 26,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: wine),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13, color: Colors.orange.shade600),
                    const SizedBox(width: 5),
                    Text(
                      'Awaiting your confirmation',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.orange.shade700),
                    ),
                  ],
                ),
                if (onConfirmReceived != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onConfirmReceived,
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Confirm Received',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFF2E8EA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.inventory_2_outlined, color: wine, size: 28),
      );

  Widget _detail(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: grey),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: grey)),
        ],
      );

  String _formatDate(dynamic raw) {
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
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
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade400;
      case 'pending':
        return Colors.orange.shade600;
      case 'confirmed':
        return Colors.blue.shade500;
      case 'processing':
        return const Color(0xFF3D7CB5);
      case 'out_for_delivery':
        return Colors.teal.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
