import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:skinnova/screens/tracker_page.dart';
import 'home_screen.dart';
import 'skinova_products_screen.dart';
import 'profile_screen.dart';
import 'package:skinnova/screens/post_page.dart';
import 'skinova_ai_scan_flow.dart';
import 'tracker_page.dart';
import 'shop_screen.dart';
import 'my_skin_routine_page.dart';

class MainNavigationScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const MainNavigationScreen(
      {super.key, required this.userId, required this.userName});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color softPink = Color(0xFFF8E8EC);
  static const Color warmCream = Color(0xFFFBF8F5);

  int selectedIndex = 0;

  List<Widget> get pages => [
        HomeScreen(
          onGoToShop: () {
            setState(() {
              selectedIndex = 3;
            });
          },
          onGoToRoutine: () {
            setState(() {
              selectedIndex = 2; // TrackerPage
            });
          },
          onGoToProfile: () {
            setState(() {
              selectedIndex = 5; // ProfileScreen
            });
          },
        ),
        PostPage(
          userId: widget.userId,
          userName: widget.userName,
        ),
        TrackerPage(userId: widget.userId),
        ShopScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
        SkinovaProductsScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
        //MySkinRoutinePage(userId: widget.userId),
        ProfileScreen(userId: widget.userId),
      ];

  final List<IconData> navIcons = const [
    Icons.home_outlined,
    Icons.article_outlined,
    Icons.qr_code_scanner_rounded,
    Icons.storefront_rounded,
    Icons.medical_services_outlined,
    //Icons.spa_outlined,
    Icons.person_outline_rounded,
  ];

  void _onTap(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warmCream,
      extendBody: true,
      body: pages[selectedIndex],
      bottomNavigationBar: _floatingNavBar(context),
    );
  }

  Widget _floatingNavBar(BuildContext context) {
    // Respect device bottom inset (home bar) on top of our 12px gap
    final bottomPad = MediaQuery.of(context).padding.bottom + 12.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottomPad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              // Soft white glass — opacity lets body content tint through
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 0.9,
              ),
              boxShadow: [
                // Primary depth shadow
                BoxShadow(
                  color: wine.withOpacity(0.09),
                  blurRadius: 22,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                // Subtle ambient shadow
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: List.generate(navIcons.length, (index) {
                final isSelected = selectedIndex == index;
                return _navItem(index, isSelected);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        // Opaque so taps register even on transparent areas
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with animated soft-pink bubble when selected
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                width: isSelected ? 44 : 36,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected ? softPink : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  // Faint wine glow ring on selected
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: wine.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedScale(
                    scale: isSelected ? 1.14 : 1.0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    child: Icon(
                      navIcons[index],
                      size: 20,
                      color: isSelected ? wine : Colors.black38,
                    ),
                  ),
                ),
              ),
              // Tiny selection dot — slides in/out with size animation
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                width: isSelected ? 4 : 0,
                height: isSelected ? 4 : 0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: wine.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _navLabel(int index) {
  switch (index) {
    case 0:
      return 'Home';
    case 1:
      return 'Posts';
    case 2:
      return 'Scan';
    case 3:
      return 'Shop';
    case 4:
      return 'Products';
    case 6:
      return 'Profile';
    default:
      return '';
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF5B2333),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
