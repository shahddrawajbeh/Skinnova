import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'seller_add_product_page.dart';
import 'seller_create_offer_page.dart';
import 'seller_messages_screen.dart';
import 'seller_orders_screen.dart';
import 'seller_products_screen.dart';
import 'seller_analytics_screen.dart';
import 'seller_store_reviews_screen.dart';
import 'seller_store_profile_screen.dart';
import 'seller_store_settings_screen.dart';
import 'seller_notifications_screen.dart';
import 'seller_help_support_screen.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  // ─── Palette ───────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color cardWhite = Colors.white;
  static const Color gold = Color(0xFFD4AF37);
  static const Color line = Color(0xFFEEECE9);

  // ─── Navigation ────────────────────────────────────────────────────────────
  int _selectedNav =
      0; // 0=Dashboard, 1=Orders, 2=Products, 3=Messages(push), 4=More

  // ─── Store data ────────────────────────────────────────────────────────────
  Map<String, dynamic>? _store;
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String _storeId = "";
  String _storeName = "My Store";
  String _storeLogo = "";
  int _unreadMessages = 0;
  int _pendingAds = 0;
  // Approval gate
  String _storeApprovalStatus = "pending"; // pending, approved, rejected
  String _storeRejectionReason = "";

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ─── Data loading ──────────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerId = prefs.getString('userId') ?? '';

      final store = await ApiService.fetchMySellerStore();
      if (!mounted) return;

      final sid = (store["_id"] ?? "").toString();
      final approval = (store["approvalStatus"] ?? "pending").toString();
      final rejection = (store["rejectionReason"] ?? "").toString();

      setState(() {
        _store = store;
        _storeId = sid;
        _storeName = store["storeName"] ?? "My Store";
        _storeLogo = store["logoUrl"] ?? "";
        _storeApprovalStatus = approval;
        _storeRejectionReason = rejection;
      });

      // Gate: if not approved + active, don't load analytics
      if (approval != "approved" || store["isActive"] != true) {
        setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        ApiService.fetchStoreAnalytics(sid),
        ApiService.fetchSellerAds(),
        if (sellerId.isNotEmpty) ApiService.fetchSellerConversations(sellerId),
      ]);

      if (!mounted) return;
      final analytics = results[0] as Map<String, dynamic>;
      final ads = results[1] as List<dynamic>;
      final convs = results.length > 2 ? results[2] as List<dynamic> : [];
      final unread = convs.fold<int>(
          0, (s, c) => s + ((c['sellerUnreadCount'] as int?) ?? 0));

      setState(() {
        _analytics = analytics;
        _pendingAds = ads.where((a) => a["status"] == "pending").length;
        _unreadMessages = unread;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessagesUnread() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerId = prefs.getString('userId') ?? '';
      if (sellerId.isEmpty) return;
      final convs = await ApiService.fetchSellerConversations(sellerId);
      if (!mounted) return;
      final total = convs.fold<int>(
          0, (s, c) => s + ((c['sellerUnreadCount'] as int?) ?? 0));
      setState(() => _unreadMessages = total);
    } catch (_) {}
  }

  // ─── Navigation helpers ────────────────────────────────────────────────────
  int get _stackIndex {
    if (_selectedNav == 4) return 3;
    if (_selectedNav < 4) return _selectedNav;
    return 0;
  }

  void _onNavTap(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SellerMessagesScreen()),
      ).then((_) => _loadMessagesUnread());
      return;
    }
    setState(() => _selectedNav = index);
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SellerNotificationsScreen()),
    );
  }

  void _openAnalytics() {
    if (_storeId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SellerAnalyticsScreen(storeId: _storeId)),
    );
  }

  void _openReviews() {
    if (_storeId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SellerStoreReviewsScreen(storeId: _storeId)),
    );
  }

  void _openStoreProfile() async {
    if (_store == null || _storeId.isEmpty) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              SellerStoreProfileScreen(store: _store!, storeId: _storeId)),
    );
    if (updated == true) _loadAll();
  }

  void _openStoreSettings() async {
    if (_store == null || _storeId.isEmpty) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              SellerStoreSettingsScreen(store: _store!, storeId: _storeId)),
    );
    if (updated == true) _loadAll();
  }

  void _openHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SellerHelpSupportScreen()),
    );
  }

  void _openAddProduct() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SellerAddProductPage()),
    );
    if (added == true) _loadAll();
  }

  void _openCreateOffer() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SellerCreateOfferPage()),
    );
    if (created == true) _loadAll();
  }

  // ─── Approval gate screen ──────────────────────────────────────────────────
  Widget _buildGateScreen() {
    final isPending = _storeApprovalStatus == "pending";
    final isRejected = _storeApprovalStatus == "rejected";
    final color = isPending ? Colors.orange.shade600 : Colors.red.shade500;
    final icon =
        isPending ? Icons.hourglass_empty_rounded : Icons.cancel_rounded;
    final title = isPending ? "Store Under Review" : "Store Request Rejected";
    final subtitle = isPending
        ? "Your store is being reviewed by our admin team. You'll receive a notification once it's approved."
        : "Your store request was not approved.";

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 0,
        title: Text("Seller Dashboard",
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 48),
              ),
              const SizedBox(height: 24),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: darkText)),
              const SizedBox(height: 12),
              if (_storeName.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF2E8EA),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(_storeName,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: wine,
                          fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 12),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, color: grey, height: 1.6)),
              if (isRejected && _storeRejectionReason.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade200)),
                  child: Text("Reason: $_storeRejectionReason",
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.red.shade700,
                          height: 1.5)),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh_rounded,
                    size: 18, color: Colors.white),
                label: Text("Refresh Status",
                    style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: wine,
                  padding:
                      const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Show gate screen if store is not approved/active
    if (!_isLoading && _storeApprovalStatus != "approved") {
      return _buildGateScreen();
    }

    return Scaffold(
      backgroundColor: softBg,
      body: _isLoading
          ? _buildSkeleton()
          : SafeArea(
              child: IndexedStack(
                index: _stackIndex,
                children: [
                  _buildDashboard(),
                  SellerOrdersScreen(storeId: _storeId),
                  SellerProductsScreen(
                    storeId: _storeId,
                    onAddProduct: _openAddProduct,
                  ),
                  _buildMorePage(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DASHBOARD TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: wine,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardTopBar(),
            const SizedBox(height: 18),
            _buildStoreHeaderCard(),
            const SizedBox(height: 18),
            _buildStatsScroll(),
            const SizedBox(height: 20),
            if (_hasAlerts) ...[
              _buildSectionLabel("Today's Tasks"),
              const SizedBox(height: 10),
              _buildAlerts(),
              const SizedBox(height: 20),
            ],
            _buildSectionLabel("Quick Actions"),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 22),
            _buildSectionLabel("Management"),
            const SizedBox(height: 12),
            _buildManagementList(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Dashboard top bar ────────────────────────────────────────────────────
  Widget _buildDashboardTopBar() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Seller Center",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              Text(
                "Manage your store",
                style: GoogleFonts.poppins(fontSize: 12, color: grey),
              ),
            ],
          ),
        ),
        _iconButton(
          Icons.notifications_none_rounded,
          badge: 0,
          onTap: _openNotifications,
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon, {int badge = 0, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: darkText, size: 20),
          ),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: wine,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    badge > 99 ? "99+" : "$badge",
                    style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Store header card ─────────────────────────────────────────────────────
  Widget _buildStoreHeaderCard() {
    final isVerified = _store?["isVerified"] == true;
    final level = _store?["verificationLevel"]?.toString() ?? "standard";
    final isActive = _store?["isActive"] != false;
    final rating = (_store?["rating"] ?? 0).toDouble();
    final followers = _store?["followersCount"] ?? 0;
    final city = _store?["city"] ?? "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [deepPlum, wine],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: wine.withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: status + actions
          Row(
            children: [
              _statusChip(isActive),
              const Spacer(),
              _headerIconBtn(Icons.edit_outlined, onTap: _openStoreProfile),
              const SizedBox(width: 8),
              _headerIconBtn(Icons.settings_outlined,
                  onTap: _openStoreSettings),
            ],
          ),
          const SizedBox(height: 18),
          // Logo
          _storeLogoWidget(72),
          const SizedBox(height: 14),
          // Name
          Text(
            _storeName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          // Verification badge
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)]),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 5),
                  Text(
                    level == "trusted"
                        ? "Trusted Store"
                        : level == "premium"
                            ? "Premium Store"
                            : "Verified Store",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: Colors.white.withOpacity(0.20), width: 1),
              ),
              child: Text(
                "New Store · Pending Verification",
                style:
                    GoogleFonts.poppins(fontSize: 9.5, color: Colors.white70),
              ),
            ),
          const SizedBox(height: 14),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (city.isNotEmpty) ...[
                const Icon(Icons.location_on_rounded,
                    color: Colors.white38, size: 12),
                const SizedBox(width: 3),
                Text(city,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.white60)),
                const SizedBox(width: 14),
              ],
              const Icon(Icons.star_rounded, color: gold, size: 12),
              const SizedBox(width: 3),
              Text(rating.toStringAsFixed(1),
                  style:
                      GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
              const SizedBox(width: 14),
              const Icon(Icons.people_outline_rounded,
                  color: Colors.white38, size: 12),
              const SizedBox(width: 3),
              Text("$followers",
                  style:
                      GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _storeLogoWidget(double radius) {
    final letter = _storeName.isNotEmpty ? _storeName[0].toUpperCase() : "S";
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
          child: _storeLogo.isEmpty
              ? Center(
                  child: Text(
                    letter,
                    style: GoogleFonts.poppins(
                      fontSize: radius * 0.36,
                      fontWeight: FontWeight.w700,
                      color: wine,
                    ),
                  ),
                )
              : _storeLogo.startsWith('http')
                  ? Image.network(
                      _storeLogo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(letter,
                            style: GoogleFonts.poppins(
                                fontSize: radius * 0.36,
                                fontWeight: FontWeight.w700,
                                color: wine)),
                      ),
                    )
                  : Image.asset(
                      _storeLogo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(letter,
                            style: GoogleFonts.poppins(
                                fontSize: radius * 0.36,
                                fontWeight: FontWeight.w700,
                                color: wine)),
                      ),
                    )),
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.greenAccent.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? Colors.greenAccent.withOpacity(0.4)
              : Colors.red.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.greenAccent : Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? "Active" : "Inactive",
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.20), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  // ─── Stats horizontal scroll ───────────────────────────────────────────────
  Widget _buildStatsScroll() {
    final pending = _analytics["pendingOrders"] ?? 0;
    final items = [
      {
        "label": "Products",
        "value": "${_analytics["productsCount"] ?? 0}",
        "icon": Icons.inventory_2_outlined,
        "color": const Color(0xFF1565C0),
      },
      {
        "label": "Orders",
        "value": "${_analytics["totalOrders"] ?? 0}",
        "icon": Icons.receipt_long_outlined,
        "color": const Color(0xFF7B1FA2),
      },
      {
        "label": "Revenue",
        "value":
            "₪${(_analytics["revenueThisMonth"] ?? 0.0).toStringAsFixed(0)}",
        "icon": Icons.trending_up_rounded,
        "color": const Color(0xFF2E7D32),
        "sub": "this month",
      },
      {
        "label": "Rating",
        "value": "${(_analytics["ratingAverage"] ?? 0.0).toStringAsFixed(1)} ⭐",
        "icon": Icons.star_rounded,
        "color": const Color(0xFFE65100),
      },
      {
        "label": "Followers",
        "value": "${_analytics["followersCount"] ?? 0}",
        "icon": Icons.people_outline,
        "color": const Color(0xFF00838F),
      },
      {
        "label": "Messages",
        "value": "$_unreadMessages",
        "icon": Icons.chat_bubble_outline_rounded,
        "color": wine,
        "sub": "unread",
      },
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          final color = item["color"] as Color;
          final sub = item["sub"] as String?;
          return Container(
            width: 88,
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.09),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: color.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(item["icon"] as IconData, color: color, size: 14),
                ),
                const Spacer(),
                Text(
                  item["value"] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                Text(
                  sub ?? (item["label"] as String),
                  style: GoogleFonts.poppins(
                      fontSize: 8.5, color: grey, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Alerts ────────────────────────────────────────────────────────────────
  bool get _hasAlerts {
    final pending = (_analytics["pendingOrders"] ?? 0) as int;
    final outOfStock = (_analytics["outOfStockCount"] ?? 0) as int;
    return pending > 0 ||
        _unreadMessages > 0 ||
        outOfStock > 0 ||
        _pendingAds > 0;
  }

  Widget _buildAlerts() {
    final pending = (_analytics["pendingOrders"] ?? 0) as int;
    final outOfStock = (_analytics["outOfStockCount"] ?? 0) as int;
    final lowStock = (_analytics["lowStockCount"] ?? 0) as int;

    final alerts = <Map<String, dynamic>>[];
    if (pending > 0)
      alerts.add({
        "msg":
            "$pending new order${pending > 1 ? 's' : ''} waiting for confirmation",
        "color": const Color(0xFFE53935),
        "icon": Icons.receipt_long_outlined,
        "action": () => setState(() => _selectedNav = 1),
      });
    if (_unreadMessages > 0)
      alerts.add({
        "msg":
            "$_unreadMessages unread message${_unreadMessages > 1 ? 's' : ''} from customers",
        "color": const Color(0xFFF57C00),
        "icon": Icons.chat_bubble_outline_rounded,
        "action": () => _onNavTap(3),
      });
    if (outOfStock > 0)
      alerts.add({
        "msg": "$outOfStock product${outOfStock > 1 ? 's' : ''} out of stock",
        "color": const Color(0xFFD32F2F),
        "icon": Icons.inventory_2_outlined,
        "action": () => setState(() => _selectedNav = 2),
      });
    if (lowStock > 0)
      alerts.add({
        "msg":
            "$lowStock product${lowStock > 1 ? 's' : ''} running low on stock",
        "color": const Color(0xFFF9A825),
        "icon": Icons.warning_amber_rounded,
        "action": () => setState(() => _selectedNav = 2),
      });
    if (_pendingAds > 0)
      alerts.add({
        "msg":
            "$_pendingAds ad${_pendingAds > 1 ? 's' : ''} pending admin approval",
        "color": const Color(0xFF7B1FA2),
        "icon": Icons.campaign_outlined,
        "action": null,
      });

    return Column(
      children: alerts
          .map((a) => _alertTile(
                msg: a["msg"] as String,
                color: a["color"] as Color,
                icon: a["icon"] as IconData,
                onTap: a["action"] as VoidCallback?,
              ))
          .toList(),
    );
  }

  Widget _alertTile({
    required String msg,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: darkText),
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  // ─── Quick actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {
        "label": "Add Product",
        "icon": Icons.add_circle_outline_rounded,
        "primary": true,
        "onTap": _openAddProduct,
      },
      {
        "label": "Create Offer",
        "icon": Icons.campaign_outlined,
        "primary": true,
        "onTap": _openCreateOffer,
      },
      {
        "label": "View Orders",
        "icon": Icons.receipt_long_outlined,
        "primary": false,
        "onTap": () => setState(() => _selectedNav = 1),
      },
      {
        "label": "Messages",
        "icon": Icons.chat_bubble_outline_rounded,
        "primary": false,
        "badge": _unreadMessages,
        "onTap": () => _onNavTap(3),
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: actions.map((a) {
        final isPrimary = a["primary"] as bool;
        final badge = (a["badge"] as int?) ?? 0;
        return GestureDetector(
          onTap: a["onTap"] as VoidCallback,
          child: Container(
            decoration: BoxDecoration(
              color: isPrimary ? wine : cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: isPrimary ? null : Border.all(color: line),
              boxShadow: [
                BoxShadow(
                  color: isPrimary
                      ? wine.withOpacity(0.25)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: isPrimary ? 16 : 8,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  a["icon"] as IconData,
                  color: isPrimary ? Colors.white : wine,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Text(
                  a["label"] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? Colors.white : darkText,
                  ),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isPrimary ? Colors.white : wine,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      child: Text(
                        "$badge",
                        style: GoogleFonts.poppins(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: isPrimary ? wine : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Management list ───────────────────────────────────────────────────────
  Widget _buildManagementList() {
    final items = [
      {
        "label": "My Products",
        "sub": "Add, edit stock & prices",
        "icon": Icons.inventory_2_outlined,
        "color": const Color(0xFF1565C0),
        "badge": 0,
        "onTap": () => setState(() => _selectedNav = 2),
      },
      {
        "label": "Ads & Offers",
        "sub": "Manage campaigns & promotions",
        "icon": Icons.campaign_outlined,
        "color": const Color(0xFF7B1FA2),
        "badge": _pendingAds,
        "onTap": _openCreateOffer,
      },
      {
        "label": "Store Reviews",
        "sub": "${_analytics["reviewsCount"] ?? 0} approved reviews",
        "icon": Icons.star_outline_rounded,
        "color": const Color(0xFFE65100),
        "badge": 0,
        "onTap": _openReviews,
      },
      {
        "label": "Analytics",
        "sub": "Revenue, orders & trends",
        "icon": Icons.bar_chart_rounded,
        "color": const Color(0xFF2E7D32),
        "badge": 0,
        "onTap": _openAnalytics,
      },
      {
        "label": "Store Settings",
        "sub": "Delivery, hours & preferences",
        "icon": Icons.settings_outlined,
        "color": grey,
        "badge": 0,
        "onTap": _openStoreSettings,
      },
    ];

    return Column(
      children: items
          .map((item) => _managementCard(
                label: item["label"] as String,
                sub: item["sub"] as String,
                icon: item["icon"] as IconData,
                color: item["color"] as Color,
                badge: item["badge"] as int,
                onTap: item["onTap"] as VoidCallback,
              ))
          .toList(),
    );
  }

  Widget _managementCard({
    required String label,
    required String sub,
    required IconData icon,
    required Color color,
    int badge = 0,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.09),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: GoogleFonts.poppins(fontSize: 11.5, color: grey),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: wine,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    "$badge",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MORE TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMorePage() {
    final items = [
      {
        "section": "Performance",
        "entries": [
          {
            "label": "Analytics",
            "sub": "Revenue, orders & store growth",
            "icon": Icons.bar_chart_rounded,
            "color": const Color(0xFF2E7D32),
            "onTap": _openAnalytics,
          },
          {
            "label": "Store Reviews",
            "sub": "Customer feedback & ratings",
            "icon": Icons.star_outline_rounded,
            "color": const Color(0xFFE65100),
            "onTap": _openReviews,
          },
        ],
      },
      {
        "section": "Store",
        "entries": [
          {
            "label": "Ads & Offers",
            "sub": "Create & manage promotions",
            "icon": Icons.campaign_outlined,
            "color": const Color(0xFF7B1FA2),
            "badge": _pendingAds,
            "onTap": _openCreateOffer,
          },
          {
            "label": "Store Profile",
            "sub": "Edit store information & images",
            "icon": Icons.storefront_outlined,
            "color": wine,
            "onTap": _openStoreProfile,
          },
          {
            "label": "Store Settings",
            "sub": "Delivery, hours & preferences",
            "icon": Icons.settings_outlined,
            "color": grey,
            "onTap": _openStoreSettings,
          },
        ],
      },
      {
        "section": "Account",
        "entries": [
          {
            "label": "Notifications",
            "sub": "Manage seller notifications",
            "icon": Icons.notifications_none_rounded,
            "color": const Color(0xFF00838F),
            "onTap": _openNotifications,
          },
          {
            "label": "Help & Support",
            "sub": "FAQ and contact support",
            "icon": Icons.help_outline_rounded,
            "color": grey,
            "onTap": _openHelpSupport,
          },
          {
            "label": "Sign Out",
            "sub": "Log out of seller account",
            "icon": Icons.logout_rounded,
            "color": const Color(0xFFD32F2F),
            "onTap": () => _confirmSignOut(),
          },
        ],
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini store header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [deepPlum, wine],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                _storeLogoWidget(52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _storeName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Seller Dashboard",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "Seller",
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // Section groups
          ...items.map((section) {
            final entries = section["entries"] as List<Map<String, dynamic>>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section["section"] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: line),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: List.generate(entries.length, (i) {
                      final e = entries[i];
                      final color = e["color"] as Color;
                      final badge = (e["badge"] as int?) ?? 0;
                      final isLast = i == entries.length - 1;
                      return Column(
                        children: [
                          ListTile(
                            onTap: e["onTap"] as VoidCallback?,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(e["icon"] as IconData,
                                  color: color, size: 20),
                            ),
                            title: Text(
                              e["label"] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: darkText,
                              ),
                            ),
                            subtitle: Text(
                              e["sub"] as String,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: grey),
                            ),
                            trailing: SizedBox(
                              width: 36,
                              child: Center(
                                child: badge > 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: wine,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          "$badge",
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 13,
                                        color: grey,
                                      ),
                              ),
                            ),
                          ),
                          if (!isLast)
                            Divider(
                                height: 1,
                                color: line,
                                indent: 68,
                                endIndent: 16),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Icon(Icons.logout_rounded,
                color: Color(0xFFD32F2F), size: 36),
            const SizedBox(height: 12),
            Text("Sign Out?",
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkText)),
            const SizedBox(height: 8),
            Text("You will be logged out of your seller account.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: grey)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text("Sign Out",
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel",
                  style: GoogleFonts.poppins(fontSize: 13, color: grey)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    final items = [
      {
        "icon": Icons.home_outlined,
        "active": Icons.home_rounded,
        "label": "Home"
      },
      {
        "icon": Icons.receipt_long_outlined,
        "active": Icons.receipt_long_rounded,
        "label": "Orders"
      },
      {
        "icon": Icons.inventory_2_outlined,
        "active": Icons.inventory_2_rounded,
        "label": "Products"
      },
      {
        "icon": Icons.chat_bubble_outline_rounded,
        "active": Icons.chat_bubble_rounded,
        "label": "Messages"
      },
      {
        "icon": Icons.grid_view_outlined,
        "active": Icons.grid_view_rounded,
        "label": "More"
      },
    ];

    // For display, messages tab highlights when its index is "selected" but we never keep it selected
    final displayIndex = _selectedNav == 3 ? -1 : _selectedNav;

    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        border: Border(top: BorderSide(color: line, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = displayIndex == i;
              final item = items[i];
              final showBadge = i == 3 && _unreadMessages > 0;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onNavTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? wine.withOpacity(0.10)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isActive
                                  ? (item["active"] as IconData)
                                  : (item["icon"] as IconData),
                              color: isActive ? wine : grey,
                              size: 22,
                            ),
                          ),
                          if (showBadge)
                            Positioned(
                              top: -2,
                              right: -4,
                              child: Container(
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: wine,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    _unreadMessages > 99
                                        ? "99+"
                                        : "$_unreadMessages",
                                    style: GoogleFonts.poppins(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item["label"] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive ? wine : grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Loading skeleton ───────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const _Shimmer(width: 180, height: 44, radius: 14),
              const Spacer(),
              const _Shimmer(width: 44, height: 44, radius: 14),
              const SizedBox(width: 10),
              const _Shimmer(width: 44, height: 44, radius: 14),
            ]),
            const SizedBox(height: 18),
            const _Shimmer(width: double.infinity, height: 240, radius: 30),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  _Shimmer(width: 88, height: 96, radius: 22),
                  SizedBox(width: 10),
                  _Shimmer(width: 88, height: 96, radius: 22),
                  SizedBox(width: 10),
                  _Shimmer(width: 88, height: 96, radius: 22),
                  SizedBox(width: 10),
                  _Shimmer(width: 88, height: 96, radius: 22),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _Shimmer(width: 120, height: 18, radius: 8),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: const [
                _Shimmer(
                    width: double.infinity,
                    height: double.infinity,
                    radius: 20),
                _Shimmer(
                    width: double.infinity,
                    height: double.infinity,
                    radius: 20),
                _Shimmer(
                    width: double.infinity,
                    height: double.infinity,
                    radius: 20),
                _Shimmer(
                    width: double.infinity,
                    height: double.infinity,
                    radius: 20),
              ],
            ),
            const SizedBox(height: 20),
            const _Shimmer(width: 110, height: 18, radius: 8),
            const SizedBox(height: 12),
            ...List.generate(
                4,
                (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _Shimmer(
                          width: double.infinity, height: 72, radius: 22),
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
    );
  }
}

// ── Shimmer skeleton block ─────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _Shimmer(
      {required this.width, required this.height, required this.radius});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E5E2),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}
