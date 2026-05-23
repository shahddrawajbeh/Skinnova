import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'seller_add_product_page.dart';
import 'seller_create_offer_page.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color gold = Color(0xFFD4AF37);
  String storeName = "Seller";
  String storeLogo = "";
  bool isLoadingStore = true;
  int selectedTab = 0;
  int productsCount = 0;
  int pendingAdsCount = 0;
  int selectedProfileTab = 0;
  @override
  void initState() {
    super.initState();
    _loadSellerStore();
  }

  Future<void> _loadSellerStore() async {
    try {
      final store = await ApiService.fetchMySellerStore();
      final products = await ApiService.fetchProductsByStore(store["_id"]);
      final ads = await ApiService.fetchSellerAds();

      if (!mounted) return;

      setState(() {
        storeName = store["storeName"] ?? "Seller";
        storeLogo = store["logoUrl"] ?? "";
        productsCount = products.length;
        isLoadingStore = false;
        pendingAdsCount = ads.where((ad) => ad["status"] == "pending").length;
      });
    } catch (e) {
      debugPrint("Seller store error: $e");
      setState(() => isLoadingStore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _welcomeSection(),
              // const SizedBox(height: 14),
              _sellerTabs(),
              const SizedBox(height: 22),
              selectedTab == 0
                  ? _dashboardTab()
                  : selectedTab == 1
                      ? _profileTab()
                      : _ordersTab(),
            ],
          ),
        ),
      ),
      // body: SafeArea(
      //   child: SingleChildScrollView(
      //     padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      //     child: Column(
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       children: [
      //         _welcomeSection(),
      //         const SizedBox(height: 22),
      //         // _header(),
      //         // const SizedBox(height: 22),

      //         _statsGrid(),
      //         const SizedBox(height: 24),
      //         _sectionTitle("Quick Actions"),
      //         const SizedBox(height: 12),
      //         _quickActions(),
      //         const SizedBox(height: 24),
      //         _sectionTitle("Today’s Tasks"),
      //         const SizedBox(height: 12),
      //         _tasks(),
      //         const SizedBox(height: 24),
      //         _sectionTitle("Management"),
      //         const SizedBox(height: 12),
      //         _managementCards(),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }

  Widget _dashboardTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _welcomeSection(),
        const SizedBox(height: 22),
        _statsGrid(),
        const SizedBox(height: 24),
        _sectionTitle("Quick Actions"),
        const SizedBox(height: 12),
        _quickActions(),
        const SizedBox(height: 24),
        const SizedBox(height: 24),
        _sectionTitle("Management"),
        const SizedBox(height: 12),
        _managementCards(),
      ],
    );
  }

  Widget _sellerTabs() {
    final tabs = ["Dashboard", "Profile", "Orders"];

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? wine : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black45,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _profileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _storeProfileHeader(),
        const SizedBox(height: 16),
        _profileInnerTabs(),
        const SizedBox(height: 18),
        selectedProfileTab == 0
            ? _profileProductsContent()
            : _profileReviewsContent(),
      ],
    );
  }

  Widget _storeProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: wine,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _profileHeaderIcon(
                Icons.edit_rounded,
                onTap: () {
                  // هون لاحقًا افتحي صفحة تعديل معلومات الستور
                },
              ),
              const SizedBox(width: 8),
              _profileHeaderIcon(
                Icons.settings_rounded,
                onTap: () {
                  // هون لاحقًا افتحي صفحة تعديل email/password
                },
              ),
            ],
          ),
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: storeLogo.isEmpty
                  ? Icon(
                      Icons.storefront_rounded,
                      color: wine,
                      size: 38,
                    )
                  : storeLogo.startsWith("assets/")
                      ? Image.asset(
                          storeLogo,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          storeLogo,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            storeName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Manage your products, reviews and store information.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeaderIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.22),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _profileInnerTabs() {
    final tabs = ["Products", "Reviews"];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedProfileTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedProfileTab = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? wine : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black45,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _profileProductsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _profileStatsRow(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle("Store Products"),
            GestureDetector(
              onTap: () async {
                final added = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SellerAddProductPage(),
                  ),
                );

                if (added == true) {
                  _loadSellerStore();
                }
              },
              child: Text(
                "Add Product",
                style: GoogleFonts.poppins(
                  color: wine,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _managementCard(
          Icons.inventory_2_outlined,
          "My Products",
          "View and manage all products in your store",
        ),
      ],
    );
  }

  Widget _profileReviewsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Store Reviews"),
        const SizedBox(height: 12),
        _reviewCard(
          "Great seller",
          "Products arrived quickly and the packaging was clean.",
          "4.8",
        ),
        _reviewCard(
          "Nice experience",
          "The store has good skincare products and clear details.",
          "4.6",
        ),
      ],
    );
  }

  Widget _reviewCard(String title, String comment, String rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: wine.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_rounded, color: wine, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: GoogleFonts.poppins(
                    fontSize: 10.8,
                    color: Colors.black45,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Text(
            rating,
            style: GoogleFonts.poppins(
              color: wine,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _profileMiniStat(
            productsCount.toString(),
            "Products",
            Icons.inventory_2_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _profileMiniStat(
            "4.8",
            "Rating",
            Icons.star_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _profileMiniStat(
            pendingAdsCount.toString(),
            "Pending Ads",
            Icons.campaign_outlined,
          ),
        ),
      ],
    );
  }

  Widget _profileMiniStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, color: wine, size: 20),
          const SizedBox(height: 7),
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
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ordersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Orders"),
        const SizedBox(height: 12),
        _taskItem("New order", "Waiting for confirmation"),
        _taskItem("Preparing order", "Customer order is being packed"),
        _taskItem("Delivered order", "Order completed successfully"),
      ],
    );
  }

  Widget _welcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: storeLogo.isEmpty
                  ? Icon(
                      Icons.storefront_rounded,
                      color: wine,
                      size: 30,
                    )
                  : storeLogo.startsWith("assets/")
                      ? Image.asset(
                          storeLogo,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          storeLogo,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: wine,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Seller Dashboard",
            style: GoogleFonts.poppins(
              color: wine,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.notifications_none_rounded, color: wine),
        ),
      ],
    );
  }

  Widget _storeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: wine,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Container(
            height: 66,
            width: 66,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: wine,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Luna Skin Store",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _statCard(
            productsCount.toString(), "Products", Icons.inventory_2_outlined),
        _statCard("8", "Orders", Icons.receipt_long_outlined),
        _statCard("4.8", "Rating", Icons.star_rounded),
        _statCard(
          pendingAdsCount.toString(),
          "Pending Ads",
          Icons.local_offer_outlined,
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: wine.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: wine, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            "Add Product",
            Icons.add_rounded,
            onTap: () async {
              final added = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SellerAddProductPage(),
                ),
              );

              if (added == true) {
                _loadSellerStore();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            "New Offer",
            Icons.campaign_outlined,
            onTap: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SellerCreateOfferPage(),
                ),
              );

              if (created == true) {
                _loadSellerStore();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String text, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: wine,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 19),
            const SizedBox(width: 7),
            Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.priority_high_rounded, color: gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: Colors.black45,
                    )),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: wine),
        ],
      ),
    );
  }

  Widget _managementCards() {
    return Column(
      children: [
        _managementCard(Icons.inventory_2_outlined, "My Products",
            "Add products, update prices and manage stock"),
        _managementCard(Icons.local_offer_outlined, "Ads & Offers",
            "Create ads and offers for admin approval"),
      ],
    );
  }

  Widget _managementCard(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Icon(icon, color: wine, size: 25),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    )),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10.8,
                      color: Colors.black45,
                    )),
              ],
            ),
          ),
          const Icon(Icons.north_east_rounded, color: wine, size: 18),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
    );
  }
}
