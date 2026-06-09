import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_admins_screen.dart';
import 'admin_users_screen.dart';
import 'admin_stores_screen.dart';
import 'admin_products_screen.dart';
import 'admin_ads_screen.dart';
import 'admin_hero_settings_screen.dart';
import 'admin_groups_screen.dart';
import 'admin_group_posts_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_store_reports_page.dart';
import 'admin_settings_screen.dart';
import 'admin_welcome_settings_screen.dart';
import 'admin_support_center_screen.dart';
import 'admin_reports_screen.dart';
import '../services/notification_service.dart';

// ── Skinova Admin Theme (extended) ────────────────────────────────────────────
class AdminTheme {
  // Core palette
  static const Color wine      = Color(0xFF5B2333);
  static const Color wineDark  = Color(0xFF3D1723);
  static const Color wineLight = Color(0xFF7A2E47);
  static const Color wineMuted = Color(0xFFF2E8EA);
  static const Color bg        = Color(0xFFF7F4F3);
  static const Color card      = Colors.white;
  static const Color black     = Color(0xFF1A1A2E);
  static const Color textMid   = Color(0xFF3D3D4E);
  static const Color grey      = Color(0xFF8A8A9A);
  static const Color line      = Color(0xFFEEECE9);
  static const Color soft      = Color(0xFFFAF8F7);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // Card gradient palettes  [primary, secondary]
  static const List<Color> gradientWine    = [Color(0xFF5B2333), Color(0xFF8B3550)];
  static const List<Color> gradientTeal    = [Color(0xFF0F766E), Color(0xFF14B8A6)];
  static const List<Color> gradientPurple  = [Color(0xFF6D28D9), Color(0xFF8B5CF6)];
  static const List<Color> gradientBlue    = [Color(0xFF1D4ED8), Color(0xFF3B82F6)];
  static const List<Color> gradientAmber   = [Color(0xFFB45309), Color(0xFFF59E0B)];
  static const List<Color> gradientGreen   = [Color(0xFF065F46), Color(0xFF10B981)];
  static const List<Color> gradientSlate   = [Color(0xFF334155), Color(0xFF64748B)];

  // Typography
  static TextStyle title(double size, {FontWeight w = FontWeight.w600}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: w, color: black);

  static TextStyle sub(double size) =>
      GoogleFonts.poppins(fontSize: size, color: grey);

  // Card decoration
  static BoxDecoration cardDec({Color? color, bool shadow = false, double radius = 16}) =>
      BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: line),
        boxShadow: shadow
            ? [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4))]
            : null,
      );

  // Gradient decoration
  static BoxDecoration gradientDec(List<Color> colors, {double radius = 20}) =>
      BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(
          color: colors.first.withOpacity(0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        )],
      );

  // Glass decoration
  static BoxDecoration glassDec({double radius = 16}) => BoxDecoration(
    color: Colors.white.withOpacity(0.12),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
  );
}

// ── Navigation Item Model ─────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String section;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.section,
  });
}

// ── Admin Dashboard ───────────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _sidebarCtrl;
  final _searchCtrl = TextEditingController();
  bool _searchActive = false;

  final List<_NavItem> _navItems = const [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: "Overview",
      section: ""),
    _NavItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
      label: "Reports Center",
      section: ""),
    _NavItem(
      icon: Icons.admin_panel_settings_outlined,
      activeIcon: Icons.admin_panel_settings_rounded,
      label: "Admin Accounts",
      section: "Admin"),
    _NavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people_rounded,
      label: "Users",
      section: "Users"),
    _NavItem(
      icon: Icons.store_outlined,
      activeIcon: Icons.store_rounded,
      label: "Stores",
      section: "Stores"),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: "Products",
      section: "Products"),
    _NavItem(
      icon: Icons.verified_outlined,
      activeIcon: Icons.verified_rounded,
      label: "Store Badges",
      section: "Stores"),
    _NavItem(
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign_rounded,
      label: "Ads / Banners",
      section: "Content"),
    _NavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
      label: "Hero Section",
      section: "Content"),
    _NavItem(
      icon: Icons.play_circle_outline_rounded,
      activeIcon: Icons.play_circle_rounded,
      label: "Welcome Screen",
      section: "Content"),
    _NavItem(
      icon: Icons.spa_outlined,
      activeIcon: Icons.spa_rounded,
      label: "Groups",
      section: "Community"),
    _NavItem(
      icon: Icons.article_outlined,
      activeIcon: Icons.article_rounded,
      label: "Group Posts",
      section: "Community"),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: "Orders",
      section: "Commerce"),
    _NavItem(
      icon: Icons.rate_review_outlined,
      activeIcon: Icons.rate_review_rounded,
      label: "Reviews",
      section: "Commerce"),
    _NavItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: "Notifications",
      section: ""),
    _NavItem(
      icon: Icons.flag_outlined,
      activeIcon: Icons.flag_rounded,
      label: "Reports",
      section: ""),
    _NavItem(
      icon: Icons.support_agent_outlined,
      activeIcon: Icons.support_agent_rounded,
      label: "Support Center",
      section: ""),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: "Settings",
      section: ""),
  ];

  @override
  void initState() {
    super.initState();
    _sidebarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
  }

  @override
  void dispose() {
    _sidebarCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0:  return const AdminOverviewScreen();
      case 1:  return const AdminReportsScreen();
      case 2:  return const AdminAdminsScreen();
      case 3:  return const AdminUsersScreen();
      case 4:  return const AdminStoresScreen(showBadgeMode: false);
      case 5:  return const AdminProductsScreen();
      case 6:  return const AdminStoresScreen(showBadgeMode: true);
      case 7:  return const AdminAdsScreen();
      case 8:  return const AdminHeroSettingsScreen();
      case 9:  return const AdminWelcomeSettingsScreen();
      case 10: return const AdminGroupsScreen();
      case 11: return const AdminGroupPostsScreen();
      case 12: return const AdminOrdersScreen();
      case 13: return const AdminReviewsScreen();
      case 14: return const AdminNotificationsScreen();
      case 15: return const AdminStoreReportsPage();
      case 16: return const AdminSupportCenterScreen();
      case 17: return const AdminSettingsScreen();
      default: return const AdminOverviewScreen();
    }
  }

  Future<void> _logout() async {
    await NotificationService().removeTokenOnLogout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  void _navigate(int index) {
    setState(() => _selectedIndex = index);
    if (MediaQuery.of(context).size.width < 800) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 800;
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      drawer: isMobile
          ? Drawer(
              child: _buildSidebarContent(),
              backgroundColor: Colors.white,
            )
          : null,
      appBar: isMobile ? _buildMobileAppBar() : null,
      body: Row(
        children: [
          if (!isMobile)
            _buildDesktopSidebar(),
          Expanded(
            child: Column(
              children: [
                if (!isMobile) _buildDesktopTopBar(),
                Expanded(child: _buildScreen()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AdminTheme.black,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AdminTheme.gradientWine,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text("Skinova Admin",
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AdminTheme.black)),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AdminTheme.line),
      ),
    );
  }

  Widget _buildDesktopTopBar() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminTheme.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(greeting,
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AdminTheme.textMid)),
          const SizedBox(width: 4),
          const Text("✦",
              style: TextStyle(color: AdminTheme.wine, fontSize: 12)),
          const Spacer(),
          _buildSearchBar(),
          const SizedBox(width: 12),
          _buildTopBarAction(Icons.notifications_outlined, '3', () {
            setState(() => _selectedIndex = 14);
          }),
          const SizedBox(width: 8),
          _buildTopBarAction(Icons.settings_outlined, null, () {
            setState(() => _selectedIndex = 17);
          }),
        ],
      ),
    );
  }

  Widget _buildTopBarAction(IconData icon, String? badge, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AdminTheme.soft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdminTheme.line),
            ),
            child: Icon(icon, size: 18, color: AdminTheme.grey),
          ),
          if (badge != null)
            Positioned(
              top: 0, right: 0,
              child: Container(
                width: 14, height: 14,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AdminTheme.wine,
                  shape: BoxShape.circle,
                ),
                child: Text(badge,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 8,
                        fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: _searchActive ? 280 : 180,
      height: 36,
      decoration: BoxDecoration(
        color: AdminTheme.soft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _searchActive ? AdminTheme.wine : AdminTheme.line),
      ),
      child: TextField(
        controller: _searchCtrl,
        onTap: () => setState(() => _searchActive = true),
        onEditingComplete: () => setState(() => _searchActive = false),
        style: GoogleFonts.poppins(fontSize: 12.5, color: AdminTheme.black),
        decoration: InputDecoration(
          hintText: 'Search anything…',
          hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: AdminTheme.grey),
          prefixIcon: Icon(Icons.search_rounded, size: 16,
              color: _searchActive ? AdminTheme.wine : AdminTheme.grey),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return AnimatedBuilder(
      animation: _sidebarCtrl,
      builder: (_, __) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _sidebarCtrl,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          width: 248,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: AdminTheme.line)),
          ),
          child: _buildSidebarContent(),
        ),
      ),
    );
  }

  Widget _buildSidebarContent() {
    String? currentSection;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branded header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AdminTheme.gradientWine,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AdminTheme.wine.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(Icons.spa_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Skinova",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AdminTheme.black)),
                    Text("Admin Console",
                        style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: AdminTheme.grey,
                            letterSpacing: 0.3)),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: AdminTheme.line),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final showHeader =
                    item.section.isNotEmpty && item.section != currentSection;
                if (showHeader) currentSection = item.section;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader) ...[
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                        child: Text(
                          item.section.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                    _buildNavTile(index),
                  ],
                );
              },
            ),
          ),
          Container(height: 1, color: AdminTheme.line),
          // Logout
          Padding(
            padding: const EdgeInsets.all(10),
            child: _buildLogoutTile(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(int index) {
    final item = _navItems[index];
    final selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _navigate(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AdminTheme.wineMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: AdminTheme.wine.withOpacity(0.2))
              : null,
        ),
        child: Row(
          children: [
            // Left accent bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 3,
              height: 18,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: selected ? AdminTheme.wine : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              selected ? item.activeIcon : item.icon,
              size: 17,
              color: selected ? AdminTheme.wine : AdminTheme.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AdminTheme.wine : AdminTheme.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutTile() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            const SizedBox(width: 13),
            Icon(Icons.logout_rounded, size: 17, color: Colors.red.shade400),
            const SizedBox(width: 10),
            Text("Logout",
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade400)),
          ],
        ),
      ),
    );
  }
}
