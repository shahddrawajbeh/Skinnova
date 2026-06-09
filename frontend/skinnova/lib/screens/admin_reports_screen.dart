import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import 'admin_report_users_screen.dart';
import 'admin_report_stores_screen.dart';
import 'admin_report_orders_screen.dart';
import 'admin_report_products_screen.dart';
import 'admin_report_ai_screen.dart';
import 'admin_report_login_screen.dart';
import 'admin_report_notifications_screen.dart';
import 'admin_report_reviews_screen.dart';
import 'admin_report_revenue_screen.dart';
import 'admin_report_custom_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  String _adminId = '';
  final Set<int> _favorites = {};
  bool _showFavoritesOnly = false;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _init();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminId = prefs.getString("userId") ?? '';
    await _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    _fadeCtrl.reset();
    try {
      final data = await ApiService.adminReportStats(_adminId);
      if (mounted) setState(() => _stats = data);
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _fadeCtrl.forward();
    }
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _toggleFav(int idx) {
    setState(() {
      if (_favorites.contains(idx)) {
        _favorites.remove(idx);
      } else {
        _favorites.add(idx);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: RefreshIndicator(
        color: AdminTheme.wine,
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGradientHeader(),
              FadeTransition(
                opacity: _fadeCtrl,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickStats(),
                      const SizedBox(height: 28),
                      _buildReportsSectionHeader(),
                      const SizedBox(height: 14),
                      _buildReportGrid(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gradient Header ──────────────────────────────────────────────────────────
  Widget _buildGradientHeader() {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports Center',
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Generate detailed business reports and monitor platform activity.',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.65)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _loadStats,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.refresh_rounded,
                        size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('Refresh',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Stats ──────────────────────────────────────────────────────────────
  Widget _buildQuickStats() {
    final items = [
      _StatItem('Total Users', _stats['totalUsers'], Icons.people_rounded,
          AdminTheme.gradientWine),
      _StatItem('Total Stores', _stats['totalStores'], Icons.store_rounded,
          AdminTheme.gradientTeal),
      _StatItem('Total Orders', _stats['totalOrders'],
          Icons.receipt_long_rounded, AdminTheme.gradientBlue),
      _StatItem(
          'Revenue (ILS)',
          'ILS ${(_stats['totalRevenue'] ?? 0).toStringAsFixed(0)}',
          Icons.attach_money_rounded,
          AdminTheme.gradientGreen,
          isRevenue: true),
      _StatItem('AI Analyses', _stats['totalAI'], Icons.psychology_rounded,
          AdminTheme.gradientPurple),
    ];

    return Wrap(
      spacing: 11,
      runSpacing: 11,
      children: items.map((s) {
        return Container(
          width: 150,
          padding: const EdgeInsets.all(14),
          decoration: AdminTheme.gradientDec(s.gradient, radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(s.icon, size: 16, color: Colors.white),
              ),
              const SizedBox(height: 10),
              _loading
                  ? Container(
                      width: 60,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                  : s.isRevenue
                      ? Text(s.value?.toString() ?? '0',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white))
                      : TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1200),
                          tween: Tween(
                              begin: 0,
                              end: (int.tryParse(
                                          s.value?.toString() ?? '0') ??
                                      0)
                                  .toDouble()),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Text(
                            '${v.toInt()}',
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ),
              const SizedBox(height: 2),
              Text(s.label,
                  style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: Colors.white.withOpacity(0.75))),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Reports section header ───────────────────────────────────────────────────
  Widget _buildReportsSectionHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Reports',
                  style: AdminTheme.title(14, w: FontWeight.w700)),
              Text('Tap a report to generate, filter, and export.',
                  style: AdminTheme.sub(12)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => setState(
              () => _showFavoritesOnly = !_showFavoritesOnly),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _showFavoritesOnly
                  ? AdminTheme.wineMuted
                  : AdminTheme.soft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _showFavoritesOnly
                      ? AdminTheme.wine
                      : AdminTheme.line),
            ),
            child: Row(children: [
              Icon(
                _showFavoritesOnly
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 15,
                color: _showFavoritesOnly
                    ? AdminTheme.wine
                    : AdminTheme.grey,
              ),
              const SizedBox(width: 5),
              Text('Favorites',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _showFavoritesOnly
                          ? AdminTheme.wine
                          : AdminTheme.grey,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Report grid ──────────────────────────────────────────────────────────────
  Widget _buildReportGrid() {
    final all = _reportDefs();
    final visible = _showFavoritesOnly && _favorites.isEmpty
        ? all // show all if no favorites starred yet
        : _showFavoritesOnly
            ? all
                .where((e) => _favorites.contains(all.indexOf(e)))
                .toList()
            : all;

    if (visible.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Icon(Icons.star_outline_rounded,
                size: 52, color: AdminTheme.grey.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('No favorites yet. Tap ★ on any report to save it here.',
                style: AdminTheme.sub(13), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: visible.asMap().entries.map((e) {
        final globalIdx = _showFavoritesOnly ? all.indexOf(e.value) : e.key;
        return _buildReportTile(e.value, globalIdx);
      }).toList(),
    );
  }

  List<_ReportDef> _reportDefs() => [
        _ReportDef(
          icon: Icons.people_outline_rounded,
          gradient: AdminTheme.gradientWine,
          label: 'User Reports',
          description: 'Registrations, activity, purchases and AI scans',
          onGenerate: () => _open(AdminReportUsersScreen(adminId: _adminId)),
        ),
        _ReportDef(
          icon: Icons.store_outlined,
          gradient: AdminTheme.gradientTeal,
          label: 'Store Reports',
          description: 'Revenue, orders, products and ratings per store',
          onGenerate: () => _open(AdminReportStoresScreen(adminId: _adminId)),
        ),
        _ReportDef(
          icon: Icons.receipt_long_outlined,
          gradient: AdminTheme.gradientBlue,
          label: 'Order Reports',
          description: 'Order status, delivery time and payment methods',
          onGenerate: () => _open(AdminReportOrdersScreen(adminId: _adminId)),
        ),
        _ReportDef(
          icon: Icons.inventory_2_outlined,
          gradient: AdminTheme.gradientAmber,
          label: 'Product Reports',
          description: 'Sales performance, stock levels and ratings',
          onGenerate: () =>
              _open(AdminReportProductsScreen(adminId: _adminId)),
        ),
        _ReportDef(
          icon: Icons.psychology_outlined,
          gradient: AdminTheme.gradientPurple,
          label: 'AI Reports',
          description: 'Skin scan statistics and common skin concerns',
          onGenerate: () => _open(AdminReportAiScreen(adminId: _adminId)),
        ),
        _ReportDef(
          icon: Icons.login_rounded,
          gradient: AdminTheme.gradientSlate,
          label: 'Login Activity',
          description: 'Session tracking, device types and peak hours',
          onGenerate: () =>
              _open(AdminReportLoginScreen(adminId: _adminId)),
        ),
        _ReportDef(
          icon: Icons.notifications_outlined,
          gradient: AdminTheme.gradientGreen,
          label: 'Notifications',
          description: 'Delivery stats, open rates and notification types',
          onGenerate: () =>
              _open(AdminReportNotificationsScreen(adminId: _adminId)),
        ),
        _ReportDef(
          icon: Icons.star_outline_rounded,
          gradient: AdminTheme.gradientAmber,
          label: 'Review Reports',
          description: 'Store ratings, positive vs negative sentiment',
          onGenerate: () =>
              _open(AdminReportReviewsScreen(adminId: _adminId)),
        ),
        _ReportDef(
          icon: Icons.account_balance_wallet_outlined,
          gradient: AdminTheme.gradientGreen,
          label: 'Revenue Reports',
          description: 'Financial breakdown by store and period',
          onGenerate: () =>
              _open(AdminReportRevenueScreen(adminId: _adminId)),
        ),
        _ReportDef(
          icon: Icons.tune_rounded,
          gradient: AdminTheme.gradientWine,
          label: 'Custom Builder',
          description: 'Build a fully custom report with any columns',
          highlight: true,
          onGenerate: () =>
              _open(AdminReportCustomScreen(adminId: _adminId)),
        ),
      ];

  Widget _buildReportTile(_ReportDef r, int idx) {
    final isFav = _favorites.contains(idx);
    return GestureDetector(
      onTap: r.onGenerate,
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: r.highlight ? null : Colors.white,
          gradient: r.highlight
              ? LinearGradient(
                  colors: r.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          border: r.highlight
              ? null
              : Border.all(color: AdminTheme.line),
          boxShadow: [
            BoxShadow(
              color: r.highlight
                  ? r.gradient.first.withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              blurRadius: r.highlight ? 18 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: r.highlight
                        ? Colors.white.withOpacity(0.18)
                        : r.gradient.first.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    r.icon,
                    size: 19,
                    color: r.highlight ? Colors.white : r.gradient.first,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _toggleFav(idx);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isFav
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        key: ValueKey(isFav),
                        size: 18,
                        color: isFav
                            ? Colors.amber.shade500
                            : (r.highlight
                                ? Colors.white.withOpacity(0.5)
                                : AdminTheme.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              r.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: r.highlight ? Colors.white : AdminTheme.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              r.description,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: r.highlight
                    ? Colors.white.withOpacity(0.7)
                    : AdminTheme.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            // Generate button
            SizedBox(
              width: double.infinity,
              child: Material(
                color: r.highlight
                    ? Colors.white.withOpacity(0.18)
                    : r.gradient.first.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: r.onGenerate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded,
                            size: 14,
                            color: r.highlight
                                ? Colors.white
                                : r.gradient.first),
                        const SizedBox(width: 4),
                        Text('Generate',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: r.highlight
                                  ? Colors.white
                                  : r.gradient.first,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Models ────────────────────────────────────────────────────────────────────
class _StatItem {
  final String label;
  final dynamic value;
  final IconData icon;
  final List<Color> gradient;
  final bool isRevenue;
  const _StatItem(this.label, this.value, this.icon, this.gradient,
      {this.isRevenue = false});
}

class _ReportDef {
  final IconData icon;
  final List<Color> gradient;
  final String label;
  final String description;
  final bool highlight;
  final VoidCallback onGenerate;
  const _ReportDef({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.description,
    required this.onGenerate,
    this.highlight = false,
  });
}
