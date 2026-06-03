import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shop_ai_chat_page.dart';

import '../api_service.dart';
import '../product_model.dart';
import 'my_skin_routine_page.dart';
import 'ask_ai_page.dart';
import 'product_details_screen.dart';
import 'skinova_products_screen.dart';
import 'shop_screen.dart';
import 'post_page.dart' show PostPage, GroupPostModel;
import 'package:skinnova/features/skin_ai/screens/skin_camera_screen.dart';
import 'package:skinnova/features/skin_ai/screens/skin_scan_history_screen.dart';
import 'scan_page.dart';
import 'compare_page.dart';
import 'analyze_page.dart';
import 'try_before_buy_page.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoToShop;
  final VoidCallback? onGoToRoutine;
  final VoidCallback? onGoToProfile;

  const HomeScreen({
    super.key,
    this.onGoToShop,
    this.onGoToRoutine,
    this.onGoToProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _wine = Color(0xFF5B2333);
  static const Color _softBg = Color(0xFFF7F4F3);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _wineMuted = Color(0xFFF2E8EA);
  static const Color _divider = Color(0xFFEDEBEA);
  static const Color _statusGreen = Color(0xFF4CAF82);
  static const Color _statusBlue = Color(0xFF5B2333);
  static const Color _statusAmber = Color(0xFFE8A838);

  // ── State ──────────────────────────────────────────────────────────────────
  String _userId = '';
  String _userName = '';
  Map<String, dynamic>? _userData;
  List<ProductModel> _products = [];
  List<GroupPostModel> _communityPosts = [];
  bool _isLoading = true;
  bool _isMorning = true;
  Map<String, dynamic>? _latestScan;
  List<dynamic> _scanHistory = [];
  Map<String, dynamic>? _homeSettings;
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';
    _userName = prefs.getString('userName') ?? '';

    if (_userId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final userResult = await ApiService.getUserProfile(userId: _userId);
    if (userResult['statusCode'] == 200) {
      _userData = userResult['data'];
      _userName = _userData?['fullName'] ?? _userName;
    }

    // Recommended products – by first concern, otherwise all
    try {
      final concerns =
          List<String>.from(_userData?['onboarding']?['skinConcerns'] ?? []);
      if (concerns.isNotEmpty) {
        _products = await ApiService.fetchProductsByConcern(concerns.first);
      } else {
        _products = await ApiService.fetchProducts();
      }
    } catch (_) {
      try {
        _products = await ApiService.fetchProducts();
      } catch (_) {}
    }

    // Community posts
    try {
      final scanHistory = await ApiService.fetchSkinScanHistory(_userId);

      _scanHistory = scanHistory;

      if (scanHistory.isNotEmpty) {
        _latestScan = scanHistory.first;
      }
    } catch (_) {}
    try {
      _homeSettings = await ApiService.getHomeSettings();
      print("HOME SETTINGS = $_homeSettings");
    } catch (_) {}
    try {
      final posts = await ApiService.fetchPosts();
      _communityPosts = posts.take(3).toList();
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  // ── Computed helpers ───────────────────────────────────────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _insight(List<String> concerns, String sensitivity) {
    if (concerns.contains('Redness') || concerns.contains('Sensitive Skin')) {
      return 'Focus on calming and barrier-restoring products today.';
    }
    if (concerns.contains('Acne & Blemishes')) {
      return 'Stay consistent — gentle care beats aggressive treatments.';
    }
    if (sensitivity == 'Very sensitive') {
      return 'Go fragrance-free today. Your barrier will thank you.';
    }
    if (concerns.contains('Dark Spots')) {
      return 'Vitamin C in the morning + SPF all day — best duo for brightness.';
    }
    if (concerns.contains('Dryness')) {
      return 'Layer your hydration: toner → serum → moisturizer for best results.';
    }
    return 'Your skin is balanced. Stay consistent with your routine today.';
  }

  List<Map<String, dynamic>> _morningSteps(
      List<String> concerns, String sensitivity, String experience) {
    if (sensitivity == 'Very sensitive') {
      return [
        {'step': 1, 'title': 'Gentle Cream Cleanser'},
        {'step': 2, 'title': 'Hydrating Toner'},
        {'step': 3, 'title': 'Barrier Repair Moisturizer'},
        {'step': 4, 'title': 'Mineral SPF 50'},
      ];
    }
    if (concerns.contains('Acne & Blemishes')) {
      return [
        {'step': 1, 'title': 'Foaming Salicylic Cleanser'},
        {'step': 2, 'title': 'Niacinamide 10% Serum'},
        {'step': 3, 'title': 'Oil-Free Moisturizer'},
        {'step': 4, 'title': 'SPF 50 Sunscreen'},
      ];
    }
    return [
      {'step': 1, 'title': 'Gentle Foaming Cleanser'},
      {'step': 2, 'title': 'Hydrating Toner'},
      {'step': 3, 'title': 'Vitamin C Serum'},
      {'step': 4, 'title': 'SPF 50 Moisturizer'},
    ];
  }

  List<Map<String, dynamic>> _eveningSteps(
      List<String> concerns, String sensitivity) {
    if (sensitivity == 'Very sensitive') {
      return [
        {'step': 1, 'title': 'Micellar Water Cleanse'},
        {'step': 2, 'title': 'Gentle Cream Cleanser'},
        {'step': 3, 'title': 'Ceramide Serum'},
        {'step': 4, 'title': 'Rich Barrier Night Cream'},
      ];
    }
    if (concerns.contains('Acne & Blemishes')) {
      return [
        {'step': 1, 'title': 'Double Cleanse'},
        {'step': 2, 'title': 'BHA Exfoliant (2×/week)'},
        {'step': 3, 'title': 'Retinol 0.3% Serum'},
        {'step': 4, 'title': 'Lightweight Moisturizer'},
      ];
    }
    return [
      {'step': 1, 'title': 'Oil Cleanser + Foam Cleanser'},
      {'step': 2, 'title': 'Hydrating Essence'},
      {'step': 3, 'title': 'Retinol 0.5% Serum'},
      {'step': 4, 'title': 'Night Cream'},
    ];
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF5B2333),
            strokeWidth: 2,
          ),
        ),
      );
    }

    final onboarding = _userData?['onboarding'] ?? {};
    final fullName = (_userData?['fullName'] as String? ?? '').isEmpty
        ? 'there'
        : (_userData?['fullName'] as String);
    final skinType = onboarding['skinType'] as String? ?? 'Combination';
    final sensitivity = onboarding['skinSensitivity'] as String? ?? '';
    final concerns =
        List<String>.from(onboarding['skinConcerns'] as List? ?? []);
    final experience = onboarding['skincareExperience'] as String? ?? '';
    final profileImage = _userData?['profileImage'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: _wine,
          onRefresh: _loadAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
            children: [
              _buildHeader(fullName, profileImage),
              const SizedBox(height: 18),
              _buildWeeklyScanBar(),
              const SizedBox(height: 22),
              _buildSkinCard(
                  skinType, sensitivity, concerns, experience, _latestScan),
              const SizedBox(height: 22),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildExploreStoreSection(),
              const SizedBox(height: 24),
              _buildRoutineSection(concerns, sensitivity, experience),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(String fullName, String? profileImage) {
    final initial = fullName.isNotEmpty && fullName != 'there'
        ? fullName[0].toUpperCase()
        : 'S';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                _greeting,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fullName == 'there' ? 'Welcome back' : fullName,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _wine.withOpacity(0.55),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Container(
        //   width: 40,
        //   height: 40,
        //   margin: const EdgeInsets.only(right: 10),
        //   decoration: BoxDecoration(
        //     color: _surface,
        //     borderRadius: BorderRadius.circular(14),
        //     border: Border.all(color: _wine.withOpacity(0.12)),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black.withOpacity(0.04),
        //         blurRadius: 8,
        //         offset: const Offset(0, 2),
        //       ),
        //     ],
        //   ),
        //   child: Icon(
        //     Icons.notifications_none_rounded,
        //     size: 20,
        //     color: _wine.withOpacity(0.65),
        //   ),
        // ),
        GestureDetector(
          onTap: widget.onGoToProfile,
          child: _avatar(initial, profileImage),
        ),
      ],
    );
  }

  Widget _avatar(String initial, String? profileImage) {
    if (profileImage != null && profileImage.isNotEmpty) {
      final url = profileImage.startsWith('http')
          ? profileImage
          : '${ApiService.baseUrl}$profileImage';
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(url),
        backgroundColor: _softBg,
        onBackgroundImageError: (_, __) {},
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: _wine, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── SKIN PROFILE CARD ──────────────────────────────────────────────────────
  Widget _buildSkinCard(
    String skinType,
    String sensitivity,
    List<String> concerns,
    String experience,
    Map<String, dynamic>? latestScan,
  ) {
    final hasScan = latestScan != null;
    final detectedConcerns = (latestScan?['detectedConcerns'] as List?) ?? [];

    final imageUrl = hasScan &&
            latestScan['imageUrl'] != null &&
            latestScan['imageUrl'].toString().isNotEmpty
        ? '${ApiService.baseUrl}${latestScan['imageUrl']}'
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _wine.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: _wine,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasScan ? "Today’s Skin Check" : "Your Skin Check",
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      if (!hasScan) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Start your first AI skin scan",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.78),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    if (imageUrl != null) ...[
                      Stack(
                        children: [
                          ClipOval(
                            child: Image.network(
                              imageUrl,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: _wine,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _skinSummaryStrip(
                        status: latestScan?['overallStatus'] ?? 'Good',
                        concernsCount: detectedConcerns.length,
                        skinType: skinType,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    hasScan
                        ? (detectedConcerns.isEmpty
                            ? 'Your skin looks calm today. Keep following your routine and track your progress.'
                            : 'Open your history to review the full result.')
                        : 'Scan your skin to get a personalized routine, detected concerns, and progress tracking.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      height: 1.35,
                      color: Colors.black87.withOpacity(0.75),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: hasScan
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SkinScanHistoryScreen(userId: _userId),
                                  ),
                                )
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _wine,
                          disabledForegroundColor: _wine.withOpacity(0.35),
                          side: BorderSide(color: _wine.withOpacity(0.18)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'History',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SkinCameraScreen(userId: _userId),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _wine,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          hasScan ? 'Scan Again' : 'Start Scan',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skinMiniStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _wine.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: _wine.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _wineMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: _wine),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _wine,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: _wine.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skinSummaryStrip({
    required String status,
    required int concernsCount,
    required String skinType,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _wine.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$status skin condition',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _wine,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tinyTag('$concernsCount concerns'),
              _tinyTag(skinType),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tinyTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: _wine.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _softInfoChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: _softBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wine.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: _wine.withOpacity(0.7)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _wine,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              color: _wine.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyScanBar() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final date = days[index];
          final hasScan = _scanHistory.any((scan) {
            final createdAt =
                DateTime.tryParse(scan['createdAt']?.toString() ?? '');
            if (createdAt == null) return false;

            return createdAt.year == date.year &&
                createdAt.month == date.month &&
                createdAt.day == date.day;
          });
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isToday ? Colors.white : _softBg.withOpacity(0.75),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isToday
                    ? _statusBlue.withOpacity(0.18)
                    : _wine.withOpacity(0.06),
              ),
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: _statusBlue.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayNames[date.weekday % 7],
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isToday ? _statusBlue : _wine.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 34,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday ? _statusBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '${date.day}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isToday ? Colors.white : _wine.withOpacity(0.45),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: hasScan ? _wine : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

// ── QUICK ACTIONS ──────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle('Quick Actions'),
            const Spacer(),
            Text(
              'Swipe to Explore',
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                color: _wine.withOpacity(0.45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 125,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _actionCard(
                title: 'Ask AI',
                width: 118,
                dark: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopAiChatPage(
                      userId: _userId,
                      userName: _userName,
                    ),
                  ),
                ),
              ),
              _actionCard(
                title: 'Add Routine',
                width: 118,
                dark: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MySkinRoutinePage(
                      userId: _userId,
                      showBackButton: true,
                    ),
                  ),
                ),
              ),
              _actionCard(
                title: 'Scan Product',
                width: 118,
                dark: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanPage(
                      userId: _userId,
                      userName: _userName,
                    ),
                  ),
                ),
              ),
              _actionCard(
                title: 'Compare Product ',
                width: 118,
                dark: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ComparePage(),
                  ),
                ),
              ),
              _actionCard(
                title: 'Try Before Buy',
                width: 118,
                dark: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TryBeforeBuyPage(
                      userId: _userId,
                      userName: _userName,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required double width,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 115,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: dark
              ? const LinearGradient(
                  colors: [Color(0xFFD8B8C2), Color(0xFF7A2632)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: dark ? null : const Color(0xFFF8E1E1),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _wine.withOpacity(dark ? 0.16 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.1,
              color: dark ? Colors.white : _wine,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExploreStoreSection() {
    final title = _homeSettings?['heroTitle'] ?? 'Explore Store';
    final subtitle = _homeSettings?['heroSubtitle'] ??
        'Discover skincare curated\nfor your unique skin';
    final buttonText = _homeSettings?['heroButtonText'] ?? 'Explore Now';
    final imageUrl = _homeSettings?['heroImageUrl'] ?? '';
    final isActive = _homeSettings?['heroIsActive'] != false;

    if (!isActive) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        widget.onGoToShop?.call();
      },
      child: Container(
        height: 230,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          image: DecorationImage(
            image: imageUrl.toString().isNotEmpty
                ? NetworkImage(imageUrl)
                : const AssetImage('assets/images/hhhome.jpg') as ImageProvider,
            fit: BoxFit.cover,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                _wine.withOpacity(0.82),
                Colors.black.withOpacity(0.25),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  buttonText,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _wine,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storeShortcutBar() {
    final items = [
      [Icons.shopping_bag_outlined, 'Shop by\nConcern', ''],
      [Icons.local_fire_department_outlined, 'Trending\nNow', ''],
      [Icons.star_border_rounded, 'Best\nSellers', ''],
      [Icons.sell_outlined, 'New\nArrivals', ''],
      [Icons.eco_outlined, 'Korean\nSkincare', ''],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SkinovaProductsScreen(
                    userId: _userId,
                    userName: _userName,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _wine),
                    ),
                    child: Icon(item[0] as IconData, size: 22, color: _wine),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item[1] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                      color: _wine,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item[2] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 8.5,
                      color: _wine.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRoutineSection(
    List<String> concerns,
    String sensitivity,
    String experience,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Today's Routine"),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            widget.onGoToRoutine?.call();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4F3),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continue your routine',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your skincare steps are ready.\nOpen your routine and keep your progress.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _wine,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Open Routine',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.self_improvement_rounded,
                  size: 78,
                  color: _wine.withOpacity(0.9),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── COMMUNITY SECTION ──────────────────────────────────────────────────────

  // ── SHARED HELPER WIDGETS ──────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: _wine,
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _softBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _wine.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _wine,
        ),
      ),
    );
  }

  Widget _concernTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: _wineMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: _wine,
        ),
      ),
    );
  }

  Widget _scoreCard(String value, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: _softBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wine.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: _wine.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}
