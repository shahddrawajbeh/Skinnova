import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../user_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'edit_profile_screen.dart';
import 'collection_details_screen.dart';
import 'all_collections_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'settings_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'scan_history_screen.dart';
import 'post_page.dart';
import 'post_details_screen.dart';
import 'public_user_posts_screen.dart';
import 'follow_list_screen.dart';
import 'product_details_screen.dart';
import '../product_model.dart';
import 'purchase_history_screen.dart';
import 'my_orders_screen.dart';
import 'my_product_reminders_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  // ── State ─────────────────────────────────────────────────────────────────
  File? selectedImage;
  bool isUploadingImage = false;
  UserModel? user;
  bool isLoading = true;
  List<dynamic> recentScans = [];
  bool isLoadingScans = true;
  List<GroupPostModel> userPosts = [];
  bool postsLoading = true;

  // ── Init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    loadProfile();
    loadRecentScans();
    loadUserPosts();
  }

  // ── Data loading ──────────────────────────────────────────────────────────
  Future<void> loadProfile() async {
    final result = await ApiService.fetchUserProfile(widget.userId);
    if (!mounted) return;
    setState(() {
      user = result;
      isLoading = false;
    });
  }

  Future<void> loadRecentScans() async {
    try {
      final result = await ApiService.fetchScanHistory(widget.userId);
      if (!mounted) return;
      setState(() {
        recentScans = result.take(4).toList();
        isLoadingScans = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingScans = false);
    }
  }

  Future<void> loadUserPosts() async {
    try {
      final posts = await ApiService.fetchPosts();
      if (!mounted) return;
      setState(() {
        userPosts = posts.where((p) => p.userId == widget.userId).toList();
        postsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => postsLoading = false);
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────
  Future<void> _openProductById(String productId) async {
    if (productId.isEmpty) return;
    try {
      final product = await ApiService.fetchProductById(productId);
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
              product: product,
              userId: widget.userId,
              userName: user?.fullName ?? '',
            ),
          ));
    } catch (_) {}
  }

  // ── Profile image ─────────────────────────────────────────────────────────
  Future<void> pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || user == null) return;
    setState(() {
      selectedImage = File(picked.path);
      isUploadingImage = true;
    });
    final url = await ApiService.uploadProfileImage(
        userId: user!.id, imageFile: selectedImage!);
    if (!mounted) return;
    if (url != null) await loadProfile();
    setState(() => isUploadingImage = false);
  }

  Future<void> removeProfileImage() async {
    if (user == null) return;
    final ok = await ApiService.removeProfileImage(userId: user!.id);
    if (!mounted) return;
    if (ok) {
      setState(() => selectedImage = null);
      await loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed')));
    }
  }

  void showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('Choose photo', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  pickAndUploadProfileImage();
                },
              ),
              if ((user?.profileImage ?? '').isNotEmpty ||
                  selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Remove photo',
                      style: GoogleFonts.poppins(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    removeProfileImage();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Collections ───────────────────────────────────────────────────────────
  void showNewCollectionSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: line, borderRadius: BorderRadius.circular(100))),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child:
                        const Icon(Icons.close, color: Colors.grey, size: 26)),
                Expanded(
                  child: Center(
                    child: Text('New collection',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: darkText)),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final name = ctrl.text.trim();
                    if (name.isEmpty || user == null) return;
                    final ok = await ApiService.addCollection(
                        userId: user!.id, title: name);
                    if (!mounted) return;
                    if (ok != null) {
                      await loadProfile();
                      Navigator.pop(context);
                    }
                  },
                  child: const Icon(Icons.check, color: Colors.grey, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.poppins(fontSize: 15, color: darkText),
              decoration: InputDecoration(
                hintText: 'Name your new collection…',
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                filled: true,
                fillColor: whiteSmoke,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: wine)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionPreview(List<String> images) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 4, mainAxisSpacing: 4),
        itemBuilder: (_, i) {
          if (i < images.length && images[i].isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(images[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFFE3E0DC))),
            );
          }
          return Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFE3E0DC),
                  borderRadius: BorderRadius.circular(6)));
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _initial(String name) =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF5B2333),
      Color(0xFF81A6C6),
      Color(0xFFE6B400),
      Color(0xFF6A9C89),
      Color(0xFF8E5572),
      Color(0xFF4B6587),
      Color(0xFF1B9CFC),
      Color(0xFF4CAF50),
      Color(0xFF9C27B0),
    ];
    return colors[name.trim().length % colors.length];
  }

  List<String> _getSkinTags() {
    if (user == null) return [];
    final tags = <String>[];
    if (user!.onboarding.skinType.isNotEmpty)
      tags.add(user!.onboarding.skinType);
    tags.addAll(user!.onboarding.skinConcerns);
    return tags;
  }

  List<String> _getFavoriteImages() {
    if (user == null || user!.favorites.isEmpty) return [];
    return user!.favorites
        .map((p) => p.imageUrl)
        .where((img) => img.isNotEmpty)
        .toList();
  }

  void _showAllConcernsSheet() {
    final tags = _getSkinTags();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: line, borderRadius: BorderRadius.circular(100))),
              ),
              const SizedBox(height: 16),
              Text('My Skin Profile',
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: darkText)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: wine.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: wine.withOpacity(0.20)),
                          ),
                          child: Text(tag,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: wine,
                                  fontWeight: FontWeight.w500)),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Share ─────────────────────────────────────────────────────────────────
  Future<void> _shareProfile() async {
    if (user == null) return;
    await Share.share(
      'Check out my Skinova profile 💕\nhttps://skinova.app/u/${user!.id}',
      subject: '${user!.fullName} on Skinova',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? _buildLoadingSkeleton()
            : user == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('Failed to load profile',
                            style:
                                GoogleFonts.poppins(fontSize: 15, color: grey)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: loadProfile,
                          child: Text('Retry',
                              style: GoogleFonts.poppins(
                                  color: wine, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopBar(),
                              const SizedBox(height: 22),
                              _buildProfileInfo(),
                              const SizedBox(height: 16),
                              _buildMyOrdersLink(),
                              const SizedBox(height: 10),
                              _buildPurchaseHistoryLink(),
                              const SizedBox(height: 10),
                              _buildProductRemindersLink(),
                              const SizedBox(height: 24),
                              _buildSectionHeader(
                                  title: 'Skin Profile',
                                  actionLabel: 'See all',
                                  onTap: _showAllConcernsSheet),
                              const SizedBox(height: 12),
                              _buildConcernChips(_getSkinTags()),
                              const SizedBox(height: 26),
                              _buildSectionHeader(
                                title: 'Collections',
                                actionLabel: 'View all',
                                onTap: () async {
                                  final all = [
                                    {
                                      'title': 'Favorites',
                                      'images': _getFavoriteImages(),
                                      'asset': 'assets/icons/fav.svg',
                                      'isSpecial': true
                                    },
                                    ...(user!.collections.map((c) => {
                                          'title': c.title,
                                          'images': c.images,
                                          'id': c.id
                                        })).toList(),
                                  ];
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AllCollectionsScreen(
                                        collections: all,
                                        userId: widget.userId,
                                        canEdit: true,
                                      ),
                                    ),
                                  );

                                  if (updated == true) {
                                    await loadProfile();
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildCollectionsRow(),
                              const SizedBox(height: 26),
                              _buildSectionHeader(
                                  title: 'Recently Used Products',
                                  actionLabel: 'View diary'),
                              const SizedBox(height: 12),
                              _buildRecentlyUsedSection(),
                              const SizedBox(height: 26),
                              _buildSectionHeader(
                                title: 'Recent Scans',
                                actionLabel: 'View all',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ScanHistoryScreen(
                                            userId: widget.userId,
                                            userName: user!.fullName))),
                              ),
                              const SizedBox(height: 12),
                              _buildRecentScansSection(),
                              const SizedBox(height: 26),
                              _buildSectionHeader(
                                title: 'My Posts',
                                actionLabel: 'View all',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => PublicUserPostsScreen(
                                            posts: userPosts,
                                            currentUserId: widget.userId,
                                            currentUserName: user!.fullName))),
                              ),
                              const SizedBox(height: 12),
                              _buildPostsSection(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  // ── Product Reminders link ────────────────────────────────────────────────
  Widget _buildProductRemindersLink() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyProductRemindersScreen(userId: widget.userId),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: whiteSmoke,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: wine.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.alarm_rounded, color: wine, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Product Reminders',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkText)),
                  Text('Manage your product usage reminders',
                      style: GoogleFonts.poppins(fontSize: 12, color: grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: grey),
          ],
        ),
      ),
    );
  }

  // ── My Orders link ────────────────────────────────────────────────────────
  Widget _buildMyOrdersLink() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyOrdersScreen(userId: widget.userId),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: whiteSmoke,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: wine.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_shipping_outlined,
                  color: wine, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Orders',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkText)),
                  Text('Track your orders and delivery status',
                      style: GoogleFonts.poppins(fontSize: 12, color: grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: grey),
          ],
        ),
      ),
    );
  }

  // ── Purchase History link ─────────────────────────────────────────────────
  Widget _buildPurchaseHistoryLink() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PurchaseHistoryScreen(
            userId: widget.userId,
            userName: user?.fullName ?? '',
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: whiteSmoke,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: wine.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  color: wine, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Purchase History',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkText)),
                  Text('View all your purchased products',
                      style: GoogleFonts.poppins(fontSize: 12, color: grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: grey),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        const SizedBox(width: 40),
        Expanded(
          child: Center(
            child: Text('Profile',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkText)),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                      userId: user!.id, userName: user!.fullName))),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: whiteSmoke, borderRadius: BorderRadius.circular(12)),
            child:
                const Icon(Icons.settings_outlined, color: darkText, size: 20),
          ),
        ),
      ],
    );
  }

  // ── Profile info header ───────────────────────────────────────────────────
  Widget _buildProfileInfo() {
    final hasBio = (user?.bio ?? '').isNotEmpty;
    final hasCity = (user?.city ?? '').isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar + name + stats
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: _avatarColor(user!.fullName),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: ClipOval(
                    child: selectedImage != null
                        ? Image.file(selectedImage!, fit: BoxFit.cover)
                        : (user!.profileImage?.isNotEmpty == true)
                            ? Image.network(user!.profileImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                      child: Text(_initial(user!.fullName),
                                          style: GoogleFonts.poppins(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                    ))
                            : Center(
                                child: Text(_initial(user!.fullName),
                                    style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                  ),
                ),
                if (isUploadingImage)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black38, shape: BoxShape.circle),
                      child: const Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))),
                    ),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: showProfileImageOptions,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                          color: wine,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.edit_rounded,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Name, stats
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user!.fullName,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkText)),
                    if (hasCity) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 13, color: grey),
                          const SizedBox(width: 3),
                          Text(user!.city,
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: grey)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _statButton('${user!.followers.length}', 'Followers',
                            onTap: () async {
                          final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => FollowListScreen(
                                      title: 'Followers',
                                      profileUserId: widget.userId,
                                      currentUserId: widget.userId)));
                          if (updated == true) loadProfile();
                        }),
                        const SizedBox(width: 18),
                        _statButton('${user!.following.length}', 'Following',
                            onTap: () async {
                          final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => FollowListScreen(
                                      title: 'Following',
                                      profileUserId: widget.userId,
                                      currentUserId: widget.userId)));
                          if (updated == true) loadProfile();
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Bio
        if (hasBio) ...[
          const SizedBox(height: 14),
          Text(user!.bio,
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: darkText.withOpacity(0.8),
                  height: 1.5)),
        ],
        const SizedBox(height: 16),
        // Action buttons
        Row(
          children: [
            GestureDetector(
              onTap: _shareProfile,
              child: Container(
                width: 46,
                height: 42,
                decoration: BoxDecoration(
                    color: whiteSmoke,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: line)),
                child: const Icon(Icons.ios_share_outlined,
                    color: darkText, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  if (user == null) return;
                  final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                              userId: user!.id, user: user!)));
                  if (updated == true) loadProfile();
                },
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                      color: whiteSmoke,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line)),
                  alignment: Alignment.center,
                  child: Text('Edit Profile',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkText)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statButton(String count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count,
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w700, color: darkText)),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: grey)),
        ],
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: darkText)),
        ),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                Text(actionLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: wine)),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: wine),
              ],
            ),
          ),
      ],
    );
  }

  // ── Skin concern chips ────────────────────────────────────────────────────
  Widget _buildConcernChips(List<String> tags) {
    if (tags.isEmpty) {
      return _emptyState(
        Icons.spa_outlined,
        'No skin profile yet',
        'Add your skin type and concerns in Edit Profile.',
        compact: true,
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.asMap().entries.map((entry) {
          final i = entry.key;
          final tag = entry.value;
          final isFirst = i == 0;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isFirst ? wine : whiteSmoke,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isFirst ? wine : line),
            ),
            child: Text(tag,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isFirst ? Colors.white : darkText)),
          );
        }).toList(),
      ),
    );
  }

  // ── Collections row ───────────────────────────────────────────────────────
  Widget _buildCollectionsRow() {
    final favorites = _getFavoriteImages();
    final dbCollections = user!.collections;

    final items = <Map<String, dynamic>>[
      {'isNew': true},
      {
        'title': 'Favorites',
        'images': favorites,
        'asset': 'assets/icons/fav.svg',
        'color': wine,
        'isSpecial': true
      },
      ...dbCollections
          .map((c) => {
                'title': c.title,
                'images': c.images,
                'id': c.id,
                'isSpecial': false
              })
          .toList(),
    ];

    if (items.length == 1) {
      return _emptyState(Icons.collections_bookmark_outlined,
          'No collections yet', 'Tap + to create your first collection.',
          compact: true);
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final item = items[i];
          final isNew = item['isNew'] == true;
          final isSpecial = item['isSpecial'] == true;
          final images = List<String>.from(item['images'] ?? []);
          final title = item['title'] as String? ?? '';
          final count = images.length;

          return GestureDetector(
            onTap: () async {
              if (isNew) {
                showNewCollectionSheet();
                return;
              }
              final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CollectionDetailsScreen(
                      title: title,
                      images: images,
                      collectionId: item['id']?.toString() ?? '',
                      canEdit: !isSpecial &&
                          (item['id']?.toString() ?? '').isNotEmpty,
                      userId: widget.userId,
                    ),
                  ));
              if (updated == true) loadProfile();
            },
            child: SizedBox(
              width: 80,
              child: Column(
                children: [
                  // Preview box
                  isNew
                      ? Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                              color: whiteSmoke,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: line)),
                          child: Icon(Icons.add_rounded, size: 28, color: grey),
                        )
                      : images.isNotEmpty
                          ? _buildCollectionPreview(images)
                          : Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                  color: whiteSmoke,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: line)),
                              child: Center(
                                child: item['asset'] != null
                                    ? SvgPicture.asset(item['asset'] as String,
                                        width: 30, height: 30)
                                    : Icon(Icons.folder_outlined,
                                        size: 30,
                                        color: item['color'] as Color? ?? grey),
                              ),
                            ),
                  const SizedBox(height: 6),
                  Text(isNew ? 'New' : title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: darkText)),
                  if (!isNew && !isSpecial && count > 0)
                    Text('$count item${count == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(fontSize: 10, color: grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Recently used products ─────────────────────────────────────────────────
  Widget _buildRecentlyUsedSection() {
    final products = user?.recentlyUsedProducts ?? [];
    if (products.isEmpty) {
      return _emptyState(Icons.history_outlined, 'No products yet',
          'Products you use will appear here.',
          compact: true);
    }
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final product = products[i];
          return GestureDetector(
            onTap: () => _openProductById(product.id),
            onLongPress: () => _showRemoveRecentlyUsedSheet(product),
            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                      color: whiteSmoke,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: line)),
                  padding: const EdgeInsets.all(8),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(product.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.image_outlined, color: grey, size: 22))
                      : Icon(Icons.image_outlined, color: grey, size: 22),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 78,
                  child: Text(product.brand,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 9.5, color: grey)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Remove recently used sheet ────────────────────────────────────────────
  Future<void> _showRemoveRecentlyUsedSheet(
      FavoriteProductModel product) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                  color: line, borderRadius: BorderRadius.circular(100)),
            ),
            const SizedBox(height: 20),
            // Product row
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      color: whiteSmoke,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: line)),
                  padding: const EdgeInsets.all(7),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(product.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.image_outlined, color: grey, size: 20))
                      : Icon(Icons.image_outlined, color: grey, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.brand,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: wine.withOpacity(0.7),
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(product.name,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: darkText),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Remove button
            GestureDetector(
              onTap: () => Navigator.pop(context, true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0645A),
                    borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: Text('Remove from recently used',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Cancel button
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    color: whiteSmoke, borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: darkText)),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await ApiService.removeRecentlyUsedProduct(
        userId: widget.userId, productId: product.id);

    if (!mounted) return;

    if (ok) {
      // Update list immediately without a full reload
      setState(() {
        user = UserModel(
          id: user!.id,
          fullName: user!.fullName,
          email: user!.email,
          role: user!.role,
          onboarding: user!.onboarding,
          profileImage: user!.profileImage,
          bio: user!.bio,
          city: user!.city,
          collections: user!.collections,
          favorites: user!.favorites,
          followers: user!.followers,
          following: user!.following,
          recentlyUsedProducts: user!.recentlyUsedProducts
              .where((p) => p.id != product.id)
              .toList(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from recently used'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(14),
        ),
      );
    }
  }

  // ── Recent scans ───────────────────────────────────────────────────────────
  Widget _buildRecentScansSection() {
    if (isLoadingScans) {
      return _buildHorizontalSkeletons(count: 4, width: 84, height: 84);
    }
    if (recentScans.isEmpty) {
      return _emptyState(Icons.document_scanner_outlined, 'No scans yet',
          'Scan a product label to identify it.',
          compact: true);
    }
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recentScans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final scan = recentScans[i];
          final matched = scan['matched'] == true;
          final product = scan['productId'];
          final imageUrl =
              matched && product != null ? (product['imageUrl'] ?? '') : '';
          final productId = matched && product != null
              ? (product['_id']?.toString() ?? '')
              : '';

          return GestureDetector(
            onTap:
                productId.isNotEmpty ? () => _openProductById(productId) : null,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                  color: whiteSmoke,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: line)),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported_outlined,
                            color: grey,
                            size: 22))
                    : Icon(
                        matched
                            ? Icons.search_off_rounded
                            : Icons.search_rounded,
                        color: wine.withOpacity(0.5),
                        size: 26),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Posts section ──────────────────────────────────────────────────────────
  Widget _buildPostsSection() {
    if (postsLoading) {
      return _buildHorizontalSkeletons(count: 3, width: 200, height: 200);
    }
    if (userPosts.isEmpty) {
      return _emptyState(Icons.edit_note_outlined, 'No posts yet',
          'Share your skincare reviews and tips with the community.');
    }
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: userPosts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _buildPostCard(userPosts[i]),
      ),
    );
  }

  Widget _buildPostCard(GroupPostModel post) {
    final image =
        post.images.isNotEmpty ? post.images.first : post.productImage;
    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailsScreen(
                post: post,
                currentUserId: widget.userId,
                currentUserName: user!.fullName,
              ),
            ));
        if (updated == true) loadUserPosts();
      },
      child: Container(
        width: 195,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: line),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                height: 110,
                child: image.isNotEmpty
                    ? Image.network(image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _postPlaceholder())
                    : _postPlaceholder(),
              ),
            ),
            const SizedBox(height: 8),
            if (post.content.isNotEmpty)
              Text(post.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.4,
                      color: darkText.withOpacity(0.85))),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.favorite_border, size: 13, color: grey),
                const SizedBox(width: 4),
                Text('${post.likes.length}',
                    style: GoogleFonts.poppins(fontSize: 11, color: grey)),
                const SizedBox(width: 10),
                Icon(Icons.chat_bubble_outline, size: 13, color: grey),
                const SizedBox(width: 4),
                Text('${post.comments.length}',
                    style: GoogleFonts.poppins(fontSize: 11, color: grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _postPlaceholder() {
    return Container(
      color: whiteSmoke,
      child: Icon(Icons.image_outlined, color: grey, size: 28),
    );
  }

  // ── Shared: empty state ───────────────────────────────────────────────────
  Widget _emptyState(IconData icon, String title, String subtitle,
      {bool compact = false}) {
    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
            color: whiteSmoke, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: wine.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: wine.withOpacity(0.6)),
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
                          color: darkText)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(fontSize: 11.5, color: grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
          color: whiteSmoke, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: wine.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: wine.withOpacity(0.5)),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600, color: darkText)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: grey)),
        ],
      ),
    );
  }

  // ── Shared: skeleton ──────────────────────────────────────────────────────
  Widget _buildHorizontalSkeletons(
      {required int count, required double width, required double height}) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              color: const Color(0xFFE8E5E2),
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _skel(40, 40, radius: 12),
            const Spacer(),
            _skel(40, 40, radius: 12)
          ]),
          const SizedBox(height: 22),
          Row(children: [
            _skel(78, 78, radius: 40),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skel(140, 18),
                const SizedBox(height: 10),
                _skel(100, 14)
              ],
            )),
          ]),
          const SizedBox(height: 16),
          _skel(double.infinity, 42, radius: 12),
          const SizedBox(height: 26),
          _skel(100, 16),
          const SizedBox(height: 12),
          SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, __) => _skel(90, 36, radius: 999),
              )),
          const SizedBox(height: 26),
          _skel(100, 16),
          const SizedBox(height: 12),
          _buildHorizontalSkeletons(count: 4, width: 80, height: 80),
        ],
      ),
    );
  }

  Widget _skel(double width, double height, {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: const Color(0xFFE8E5E2),
          borderRadius: BorderRadius.circular(radius)),
    );
  }
}
