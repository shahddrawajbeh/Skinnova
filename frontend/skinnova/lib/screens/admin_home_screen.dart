import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_product_page.dart';

import '../admin_story_user_model.dart';
import '../api_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const Color bg = Color(0xFFF5F5F3);
  static const Color card = Colors.white;
  static const Color black = Color.fromARGB(255, 37, 37, 37);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFE7E7E5);
  static const Color soft = Color(0xFFF0F0ED);
  List<AdminStoryUserModel> users = [];
  bool isLoadingUsers = true;
  int productsCount = 0;
  Future<void> _loadProductsCount() async {
    try {
      final count = await ApiService.getProductsCount();

      if (!mounted) return;
      setState(() {
        productsCount = count;
      });
    } catch (e) {
      print("LOAD PRODUCTS COUNT ERROR: $e");
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadProductsCount();
  }

  Future<void> _loadUsers() async {
    try {
      final fetchedUsers = await ApiService.getAllUsersForAdmin();
      print("FETCHED USERS: ${fetchedUsers.length}");
      print("FETCHED USERS DATA: $fetchedUsers");

      if (!mounted) return;

      setState(() {
        users = fetchedUsers;
        isLoadingUsers = false;
      });
    } catch (e) {
      print("LOAD USERS ERROR: $e");

      if (!mounted) return;
      setState(() {
        isLoadingUsers = false;
      });
    }
  }

  Widget _buildMiniCardsSection() {
    return SizedBox(
      height: 190,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMiniDashboardCard(
            title: "Users",
            subtitle: "Registered accounts",
            value: "${users.length}",
            icon: Icons.people_alt_outlined,
            bgColor: const Color(0xFFD9ECE8),
            iconBg: const Color(0xFFE7F4F1),
            onTap: () {},
          ),
          const SizedBox(width: 14),
          _buildMiniDashboardCard(
            title: "Products",
            subtitle: "Manage items",
            value: "$productsCount",
            icon: Icons.inventory_2_outlined,
            bgColor: const Color(0xFFE2D8F0),
            iconBg: const Color(0xFFEEE6F8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddProductPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          _buildMiniDashboardCard(
            title: "Groups",
            subtitle: "Community spaces",
            value: "08",
            icon: Icons.grid_view_rounded,
            bgColor: const Color(0xFFE8D6C6),
            iconBg: const Color(0xFFF3E8DD),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDashboardCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(34),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: black,
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: black.withOpacity(0.65),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: _buildSideMenu(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 22),
              _buildHeaderCard(),
              const SizedBox(height: 22),
              _buildSectionHeader("Main Sections"),
              const SizedBox(height: 14),
              _buildMiniCardsSection(),
              const SizedBox(height: 24),
              _buildSectionHeader("Quick Actions"),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: "Add Product",
                      icon: Icons.add_box_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddProductPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      title: "Add Group",
                      icon: Icons.group_add_outlined,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: "Manage Users",
                      icon: Icons.manage_accounts_outlined,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      title: "Settings",
                      icon: Icons.settings_outlined,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const SizedBox(height: 18),
          if (isLoadingUsers)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (users.isEmpty)
            Text(
              "No users found",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: grey,
              ),
            )
          else
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _buildStoryUserItem(user);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: line),
            ),
            child: const Icon(
              Icons.menu_rounded,
              color: black,
              size: 23,
            ),
          ),
        ),
        const Spacer(),
        Column(
          children: [
            Text(
              "Hi Admin",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: black,
              ),
            ),
            Text(
              "Welcome to your dashboard",
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: grey,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: line),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: black,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildStoryUserItem(AdminStoryUserModel user) {
    final hasImage = user.profileImage.trim().isNotEmpty;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: black,
              width: 1.2,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE4E4E1),
            backgroundImage: hasImage ? NetworkImage(user.profileImage) : null,
            child: !hasImage
                ? Text(
                    user.fullName.isNotEmpty
                        ? user.fullName.trim()[0].toUpperCase()
                        : "U",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: black,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 58,
          child: Text(
            user.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallAvatar(String letter) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Color(0xFFE4E4E1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: black,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: black,
      ),
    );
  }

  Widget _buildMainCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: black, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12.3,
                      color: grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: black, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.72,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F7F5),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(34),
            bottomRight: Radius.circular(34),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5E5E2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "A",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hi Admin",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: black,
                            ),
                          ),
                          Text(
                            "admin profile",
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: black, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Divider(color: line, height: 1),
                const SizedBox(height: 18),
                _menuItem(Icons.people_outline, "Manage Users", () {}),
                _menuItem(Icons.inventory_2_outlined, "Products", () {}),
                _menuItem(Icons.grid_view_rounded, "Groups", () {}),
                _menuItem(Icons.category_outlined, "Categories", () {}),
                _menuItem(Icons.settings_outlined, "Settings", () {}),
                _menuItem(Icons.help_outline_rounded, "Help", () {}),
                const Spacer(),
                _menuItem(Icons.logout_rounded, "Logout", () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Icon(icon, color: black, size: 21),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: black,
          ),
        ),
      ),
    );
  }
}
