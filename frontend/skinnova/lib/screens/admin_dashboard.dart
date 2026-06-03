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
import 'admin_analytics_screen.dart';
import '../services/notification_service.dart';

// ── Skinova Admin Theme ────────────────────────────────────────────────────
class AdminTheme {
  static const Color wine = Color(0xFF5B2333);
  static const Color wineDark = Color(0xFF3D1723);
  static const Color wineMuted = Color(0xFFF2E8EA);
  static const Color bg = Color(0xFFF7F4F3);
  static const Color card = Colors.white;
  static const Color black = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);
  static const Color soft = Color(0xFFFAF8F7);

  static TextStyle title(double size, {FontWeight w = FontWeight.w600}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: w, color: black);

  static TextStyle sub(double size) =>
      GoogleFonts.poppins(fontSize: size, color: grey);

  static BoxDecoration cardDec({Color? color, bool shadow = false}) =>
      BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
        boxShadow: shadow
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]
            : null,
      );
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: "Overview",
        section: ""),
    _NavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: "Analytics",
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

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0:
        return const AdminOverviewScreen();
      case 1:
        return const AdminAnalyticsScreen();
      case 2:
        return const AdminAdminsScreen();
      case 3:
        return const AdminUsersScreen();
      case 4:
        return const AdminStoresScreen(showBadgeMode: false);
      case 5:
        return const AdminProductsScreen();
      case 6:
        return const AdminStoresScreen(showBadgeMode: true);
      case 7:
        return const AdminAdsScreen();
      case 8:
        return const AdminHeroSettingsScreen();
      case 9:
        return const AdminWelcomeSettingsScreen();
      case 10:
        return const AdminGroupsScreen();
      case 11:
        return const AdminGroupPostsScreen();
      case 12:
        return const AdminOrdersScreen();
      case 13:
        return const AdminReviewsScreen();
      case 14:
        return const AdminNotificationsScreen();
      case 15:
        return const AdminStoreReportsPage();
      case 16:
        return const AdminSupportCenterScreen();
      case 17:
        return const AdminSettingsScreen();
      default:
        return const AdminOverviewScreen();
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 750;
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      drawer: isMobile ? Drawer(child: _buildSidebarContent()) : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: AdminTheme.card,
              foregroundColor: AdminTheme.black,
              elevation: 0,
              title: Text("Skinova Admin",
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.black)),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: AdminTheme.line, height: 1),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: 240,
              decoration: const BoxDecoration(
                color: AdminTheme.card,
                border:
                    Border(right: BorderSide(color: AdminTheme.line, width: 1)),
              ),
              child: _buildSidebarContent(),
            ),
          Expanded(child: _buildScreen()),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
    String? currentSection;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AdminTheme.wine,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.spa_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Skinova",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.black)),
                    Text("Admin Panel",
                        style: GoogleFonts.poppins(
                            fontSize: 10.5, color: AdminTheme.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AdminTheme.line),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final showHeader =
                    item.section.isNotEmpty && item.section != currentSection;
                if (showHeader) currentSection = item.section;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
                        child: Text(item.section,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AdminTheme.grey,
                                letterSpacing: 0.8)),
                      ),
                    _buildNavTile(index),
                  ],
                );
              },
            ),
          ),
          Container(height: 1, color: AdminTheme.line),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _buildNavTileRaw(
              icon: Icons.logout_rounded,
              label: "Logout",
              selected: false,
              onTap: _logout,
              isLogout: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(int index) {
    final item = _navItems[index];
    final selected = _selectedIndex == index;
    return _buildNavTileRaw(
      icon: selected ? item.activeIcon : item.icon,
      label: item.label,
      selected: selected,
      onTap: () {
        setState(() => _selectedIndex = index);
        if (MediaQuery.of(context).size.width < 750) Navigator.pop(context);
      },
    );
  }

  Widget _buildNavTileRaw({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final color = isLogout
        ? Colors.red.shade400
        : selected
            ? AdminTheme.wine
            : AdminTheme.grey;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AdminTheme.wineMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: isLogout
                      ? Colors.red.shade400
                      : (selected ? AdminTheme.wine : AdminTheme.black),
                )),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String section;
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.section});
}
