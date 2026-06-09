import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import 'admin_users_screen.dart';
import 'admin_stores_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_notifications_screen.dart';

// ── Sparkline datasets (decorative, visually meaningful) ──────────────────────
const List<List<double>> _sparkSets = [
  [1.0, 2.2, 1.8, 3.0, 2.4, 3.8, 3.2],
  [1.5, 1.2, 2.5, 2.0, 3.2, 2.8, 4.0],
  [2.0, 2.8, 2.2, 3.5, 3.0, 4.2, 3.8],
  [1.2, 2.0, 1.6, 2.8, 2.2, 3.5, 3.0],
  [1.8, 1.4, 2.6, 2.1, 3.4, 2.9, 4.1],
  [2.2, 3.0, 2.6, 3.8, 3.2, 4.4, 3.9],
  [1.0, 1.8, 1.4, 2.6, 2.0, 3.2, 2.8],
];

List<FlSpot> _spots(int idx) {
  final s = _sparkSets[idx % _sparkSets.length];
  return List.generate(s.length, (i) => FlSpot(i.toDouble(), s[i]));
}

// ── Stat card data model ──────────────────────────────────────────────────────
class _Stat {
  final String label;
  final String key;
  final IconData icon;
  final List<Color> gradient;
  final int sparkIdx;
  final int trend; // fake % trend for decoration
  final VoidCallback? onTap;
  const _Stat({
    required this.label,
    required this.key,
    required this.icon,
    required this.gradient,
    required this.sparkIdx,
    required this.trend,
    this.onTap,
  });
}

// ── Overview Screen ───────────────────────────────────────────────────────────
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});
  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  String _adminId = '';
  late AnimationController _fadeCtrl;
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _init();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminId = prefs.getString('userId') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _fadeCtrl.reset();
    _staggerCtrl.reset();
    try {
      final data = await ApiService.adminGetStats(_adminId);
      if (!mounted) return;
      setState(() {
        _stats = data;
        _loading = false;
      });
      _fadeCtrl.forward();
      _staggerCtrl.forward();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();

    final counts = (_stats['counts'] as Map?) ?? {};
    final latestUsers = (_stats['latestUsers'] as List?) ?? [];
    final latestProducts = (_stats['latestProducts'] as List?) ?? [];
    final latestStores = (_stats['latestStores'] as List?) ?? [];
    final recentOrders = (_stats['recentOrders'] as List?) ?? [];
    final pendingStores = counts['pendingStores'] as int? ?? 0;

    final statCards = [
      _Stat(label: 'Total Users', key: 'users', icon: Icons.people_rounded,
          gradient: AdminTheme.gradientWine, sparkIdx: 0, trend: 12,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()))),
      _Stat(label: 'Total Stores', key: 'stores', icon: Icons.store_rounded,
          gradient: AdminTheme.gradientTeal, sparkIdx: 1, trend: 8,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStoresScreen(showBadgeMode: false)))),
      const _Stat(label: 'Products', key: 'products', icon: Icons.inventory_2_rounded,
          gradient: AdminTheme.gradientPurple, sparkIdx: 2, trend: 5),
      _Stat(label: 'Orders', key: 'orders', icon: Icons.receipt_long_rounded,
          gradient: AdminTheme.gradientBlue, sparkIdx: 3, trend: 18,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen()))),
      const _Stat(label: 'Groups', key: 'groups', icon: Icons.spa_rounded,
          gradient: AdminTheme.gradientGreen, sparkIdx: 4, trend: 3),
      const _Stat(label: 'Posts', key: 'posts', icon: Icons.article_rounded,
          gradient: AdminTheme.gradientAmber, sparkIdx: 5, trend: 21),
      const _Stat(label: 'Ads', key: 'ads', icon: Icons.campaign_rounded,
          gradient: AdminTheme.gradientSlate, sparkIdx: 6, trend: -2),
    ];

    return RefreshIndicator(
      color: AdminTheme.wine,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeCtrl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGradientHeader(pendingStores),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Platform Overview'),
                    const SizedBox(height: 14),
                    _buildStatGrid(statCards, counts),
                    const SizedBox(height: 28),
                    _buildQuickActions(),
                    const SizedBox(height: 28),
                    _buildActivitySection(latestUsers, latestStores, recentOrders),
                    const SizedBox(height: 28),
                    _buildRecentSection('Latest Registered Users', _buildUsersCard(latestUsers)),
                    const SizedBox(height: 20),
                    _buildRecentSection('Latest Stores', _buildStoresCard(latestStores)),
                    const SizedBox(height: 20),
                    _buildRecentSection('Latest Products', _buildProductsCard(latestProducts)),
                    const SizedBox(height: 20),
                    _buildRecentSection('Recent Orders', _buildOrdersCard(recentOrders)),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gradient header with welcome ───────────────────────────────────────────
  Widget _buildGradientHeader(int pendingStores) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '🌤 Good Morning' : hour < 17 ? '☀ Good Afternoon' : '🌙 Good Evening';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3D1723), Color(0xFF5B2333), Color(0xFF7A2E47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w400)),
                    const SizedBox(height: 4),
                    Text("Admin Dashboard",
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2)),
                    const SizedBox(height: 6),
                    Text(
                      "Here's what's happening with Skinova today.",
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.65)),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(_now(),
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text(_dateStr(),
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.6))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (pendingStores > 0) ...[
            const SizedBox(height: 16),
            _pendingAlert(pendingStores),
          ],
        ],
      ),
    );
  }

  Widget _pendingAlert(int count) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.pending_actions_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count store(s) waiting for approval.',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Review',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.wine)),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Stat grid ───────────────────────────────────────────────────────────────
  Widget _buildStatGrid(List<_Stat> stats, Map counts) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final cols = constraints.maxWidth > 600 ? 3 : 2;
        const spacing = 12.0;
        final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats.asMap().entries.map((e) {
            final stat = e.value;
            final value = counts[stat.key] as int? ?? 0;
            return _AnimatedStatCard(
              stat: stat,
              value: value,
              width: w,
              delay: Duration(milliseconds: 80 * e.key),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Quick actions ───────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QA('Users', Icons.people_rounded, AdminTheme.gradientWine,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()))),
      _QA('Stores', Icons.store_rounded, AdminTheme.gradientTeal,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStoresScreen(showBadgeMode: false)))),
      _QA('Orders', Icons.receipt_long_rounded, AdminTheme.gradientBlue,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen()))),
      _QA('Reports', Icons.analytics_rounded, AdminTheme.gradientPurple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen()))),
      _QA('Alerts', Icons.notifications_rounded, AdminTheme.gradientAmber,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Quick Actions'),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: actions.map((a) => _buildQATile(a)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQATile(_QA a) {
    return GestureDetector(
      onTap: a.onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: a.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: a.gradient.first.withOpacity(0.28),
              blurRadius: 12,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(a.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(a.label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Activity timeline ───────────────────────────────────────────────────────
  Widget _buildActivitySection(List users, List stores, List orders) {
    final List<_Activity> items = [
      ...users.take(3).map((u) => _Activity(
        icon: Icons.person_add_rounded,
        color: AdminTheme.info,
        title: 'New user registered',
        subtitle: u['fullName'] ?? '',
        time: u['createdAt'],
      )),
      ...stores.take(2).map((s) => _Activity(
        icon: Icons.store_rounded,
        color: AdminTheme.success,
        title: 'New store created',
        subtitle: s['storeName'] ?? '',
        time: s['createdAt'],
      )),
      ...orders.take(3).map((o) => _Activity(
        icon: Icons.receipt_long_rounded,
        color: AdminTheme.wine,
        title: 'Order placed',
        subtitle: (o['userId'] is Map ? o['userId']['fullName'] : 'Unknown') ?? 'Unknown',
        time: o['createdAt'],
      )),
    ];
    items.sort((a, b) => (b.time ?? '').compareTo(a.time ?? ''));
    final timeline = items.take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Live Activity'),
        const SizedBox(height: 12),
        Container(
          decoration: AdminTheme.cardDec(shadow: true),
          child: Column(
            children: timeline.asMap().entries.map((e) {
              final a = e.value;
              final isLast = e.key == timeline.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: a.color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(a.icon, size: 17, color: a.color),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title,
                                  style: AdminTheme.title(12.5,
                                      w: FontWeight.w500)),
                              if (a.subtitle.isNotEmpty)
                                Text(a.subtitle,
                                    style: AdminTheme.sub(11.5),
                                    overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(a.time),
                          style: AdminTheme.sub(11),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) Container(height: 0.5, color: AdminTheme.line),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Recent sections ─────────────────────────────────────────────────────────
  Widget _buildRecentSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(title),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  Widget _buildUsersCard(List users) {
    if (users.isEmpty) return _emptyCard('No users registered yet');
    return Container(
      decoration: AdminTheme.cardDec(shadow: true),
      child: Column(
        children: users.asMap().entries.map((e) {
          final u = e.value as Map;
          final hasImg = (u['profileImage'] ?? '').toString().isNotEmpty;
          final isLast = e.key == users.length - 1;
          return Column(
            children: [
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 2),
                leading: CircleAvatar(
                  radius: 19,
                  backgroundColor: AdminTheme.wineMuted,
                  backgroundImage:
                      hasImg ? NetworkImage(u['profileImage']) : null,
                  child: !hasImg
                      ? Text(
                          (u['fullName'] ?? 'U').toString()[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: AdminTheme.wine,
                              fontSize: 13))
                      : null,
                ),
                title: Text(u['fullName'] ?? '',
                    style: AdminTheme.title(13, w: FontWeight.w500)),
                subtitle: Text(u['email'] ?? '',
                    style: AdminTheme.sub(11.5)),
                trailing: _rolePill(u['role'] ?? 'user'),
              ),
              if (!isLast) Container(height: 0.5, color: AdminTheme.line),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStoresCard(List stores) {
    if (stores.isEmpty) return _emptyCard('No stores added yet');
    return Container(
      decoration: AdminTheme.cardDec(shadow: true),
      child: Column(
        children: stores.asMap().entries.map((e) {
          final s = e.value as Map;
          final seller = s['sellerId'] as Map? ?? {};
          final isLast = e.key == stores.length - 1;
          return Column(
            children: [
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: (s['logoUrl'] ?? '').toString().isNotEmpty
                      ? Image.network(s['logoUrl'],
                          width: 38, height: 38, fit: BoxFit.cover)
                      : Container(
                          width: 38, height: 38,
                          color: AdminTheme.wineMuted,
                          child: const Icon(Icons.store_rounded,
                              color: AdminTheme.wine, size: 18)),
                ),
                title: Text(s['storeName'] ?? '',
                    style: AdminTheme.title(13, w: FontWeight.w500)),
                subtitle: Text(
                    '${s['city'] ?? ''} · ${seller['fullName'] ?? 'N/A'}',
                    style: AdminTheme.sub(11.5)),
                trailing: _approvalPill(s['approvalStatus'] ?? 'pending'),
              ),
              if (!isLast) Container(height: 0.5, color: AdminTheme.line),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductsCard(List products) {
    if (products.isEmpty) return _emptyCard('No products yet');
    return Container(
      decoration: AdminTheme.cardDec(shadow: true),
      child: Column(
        children: products.asMap().entries.map((e) {
          final p = e.value as Map;
          final isLast = e.key == products.length - 1;
          return Column(
            children: [
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: (p['imageUrl'] ?? '').toString().isNotEmpty
                      ? Image.network(p['imageUrl'],
                          width: 38, height: 38, fit: BoxFit.cover)
                      : Container(
                          width: 38, height: 38,
                          color: AdminTheme.wineMuted,
                          child: const Icon(Icons.inventory_2_outlined,
                              color: AdminTheme.wine, size: 18)),
                ),
                title: Text(p['name'] ?? '',
                    style: AdminTheme.title(13, w: FontWeight.w500)),
                subtitle: Text(p['brand'] ?? '', style: AdminTheme.sub(11.5)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AdminTheme.wineMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(p['category'] ?? '',
                      style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: AdminTheme.wine,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              if (!isLast) Container(height: 0.5, color: AdminTheme.line),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersCard(List orders) {
    if (orders.isEmpty) return _emptyCard('No orders yet');
    return Container(
      decoration: AdminTheme.cardDec(shadow: true),
      child: Column(
        children: orders.asMap().entries.map((e) {
          final o = e.value as Map;
          final user = o['userId'] as Map? ?? {};
          final store = o['storeId'] as Map? ?? {};
          final isLast = e.key == orders.length - 1;
          return Column(
            children: [
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AdminTheme.wineMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AdminTheme.wine, size: 18),
                ),
                title: Text(user['fullName'] ?? 'Unknown',
                    style: AdminTheme.title(13, w: FontWeight.w500)),
                subtitle: Text(store['storeName'] ?? '',
                    style: AdminTheme.sub(11.5)),
                trailing: _statusPill(o['status'] ?? 'pending'),
              ),
              if (!isLast) Container(height: 0.5, color: AdminTheme.line),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Skeleton loading ────────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header skeleton
          Container(
            height: 120,
            color: AdminTheme.wineDark,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBlock(120, 14),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                      6, (_) => _skeletonCard(width: 160, height: 130)),
                ),
                const SizedBox(height: 28),
                _skeletonBlock(100, 14),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5,
                      (_) => _skeletonCard(width: 88, height: 84, mr: 10)),
                ),
                const SizedBox(height: 28),
                _skeletonBlock(120, 14),
                const SizedBox(height: 12),
                _skeletonCard(width: double.infinity, height: 220),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonCard(
      {required double width, required double height, double mr = 0}) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      margin: EdgeInsets.only(right: mr),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AdminTheme.line,
      ),
      child: const _ShimmerBox(),
    );
  }

  Widget _skeletonBlock(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AdminTheme.line,
      ),
      child: const _ShimmerBox(),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AdminTheme.black));

  Widget _emptyCard(String msg) => Container(
        padding: const EdgeInsets.all(20),
        decoration: AdminTheme.cardDec(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded,
                size: 28, color: AdminTheme.grey.withOpacity(0.4)),
            const SizedBox(width: 10),
            Text(msg, style: AdminTheme.sub(13)),
          ],
        ),
      );

  Widget _rolePill(String role) {
    Color c = role == 'admin'
        ? Colors.red.shade400
        : role == 'seller'
            ? Colors.orange.shade500
            : AdminTheme.wine;
    return _pill(role, c);
  }

  Widget _approvalPill(String s) {
    Color c = s == 'approved'
        ? AdminTheme.success
        : s == 'rejected'
            ? AdminTheme.danger
            : AdminTheme.warning;
    return _pill(s, c);
  }

  Widget _statusPill(String s) {
    Color c = s == 'delivered'
        ? AdminTheme.success
        : s == 'cancelled'
            ? AdminTheme.danger
            : s == 'out_for_delivery'
                ? AdminTheme.info
                : AdminTheme.warning;
    return _pill(s.replaceAll('_', ' '), c);
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: color,
                fontWeight: FontWeight.w600)),
      );

  String _now() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _dateStr() {
    final d = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _timeAgo(String? raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}

// ── Animated stat card ────────────────────────────────────────────────────────
class _AnimatedStatCard extends StatefulWidget {
  final _Stat stat;
  final int value;
  final double width;
  final Duration delay;
  const _AnimatedStatCard({
    required this.stat,
    required this.value,
    required this.width,
    required this.delay,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: widget.stat.onTap,
          child: Container(
            width: widget.width,
            padding: const EdgeInsets.all(18),
            decoration: AdminTheme.gradientDec(widget.stat.gradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Glass icon pill
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(widget.stat.icon,
                          color: Colors.white, size: 17),
                    ),
                    const Spacer(),
                    // Trend badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.stat.trend >= 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text('${widget.stat.trend.abs()}%',
                              style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Count-up number
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1400),
                  tween: Tween(begin: 0, end: widget.value.toDouble()),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    _fmt(v.toInt()),
                    style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.stat.label,
                  style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 14),
                // Mini sparkline
                SizedBox(
                  height: 38,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots(widget.stat.sparkIdx),
                          isCurved: true,
                          color: Colors.white.withOpacity(0.85),
                          barWidth: 1.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.22),
                                Colors.white.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      clipData: const FlClipData.all(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ── Shimmer box ───────────────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.0),
              Colors.white.withOpacity(0.4 * _ctrl.value),
              Colors.white.withOpacity(0.0),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class _Activity {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? time;
  const _Activity({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.time,
  });
}

class _QA {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _QA(this.label, this.icon, this.gradient, this.onTap);
}
