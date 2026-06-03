import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import '../api_service.dart';
import '../user_model.dart';
import 'collection_details_screen.dart';
import 'all_collections_screen.dart';
import 'post_page.dart';
import 'post_details_screen.dart';
import 'public_user_posts_screen.dart';
import 'follow_list_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String viewedUserId;
  final String currentUserId;

  const PublicProfileScreen({
    super.key,
    required this.viewedUserId,
    required this.currentUserId,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  // ── Palette — matches ProfileScreen exactly ───────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  // ── State ─────────────────────────────────────────────────────────────────
  UserModel? user;
  bool isLoading = true;
  bool isFollowing = false;
  bool _followLoading = false;
  List<GroupPostModel> userPosts = [];
  bool postsLoading = true;
  bool hasFollowChanged = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    loadProfile();
    loadUserPosts();
  }

  // ── Data loading ──────────────────────────────────────────────────────────
  Future<void> loadProfile() async {
    final result = await ApiService.fetchUserProfile(widget.viewedUserId);
    if (!mounted) return;
    setState(() {
      user = result;
      isFollowing =
          result?.followers.any((f) => f.id == widget.currentUserId) ?? false;
      isLoading = false;
    });
  }

  Future<void> loadUserPosts() async {
    try {
      final all = await ApiService.fetchPosts();
      if (!mounted) return;
      setState(() {
        userPosts = all.where((p) => p.userId == widget.viewedUserId).toList();
        postsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => postsLoading = false);
    }
  }

  // ── Follow / Unfollow ─────────────────────────────────────────────────────
  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);

    final ok = isFollowing
        ? await ApiService.unfollowUser(
            targetUserId: widget.viewedUserId,
            currentUserId: widget.currentUserId)
        : await ApiService.followUser(
            targetUserId: widget.viewedUserId,
            currentUserId: widget.currentUserId);

    if (ok && mounted) {
      setState(() {
        hasFollowChanged = true;
        if (isFollowing) {
          user?.followers.removeWhere((f) => f.id == widget.currentUserId);
          isFollowing = false;
        } else {
          user?.followers.add(FollowUserModel(
              id: widget.currentUserId, fullName: '', profileImage: ''));
          isFollowing = true;
        }
      });
      await loadProfile();
    }
    if (mounted) setState(() => _followLoading = false);
  }

  // ── Share ─────────────────────────────────────────────────────────────────
  Future<void> _shareProfile() async {
    if (user == null) return;
    await Share.share(
      'Check out ${user!.fullName} on Skinova 💕\nhttps://skinova.app/u/${user!.id}',
      subject: '${user!.fullName} on Skinova',
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

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isMe = widget.currentUserId == widget.viewedUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? _buildLoadingSkeleton()
            : user == null
                ? _buildErrorState()
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
                              _buildProfileInfo(isMe),
                              const SizedBox(height: 26),
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
                                onTap: () {
                                  final all = [
                                    {
                                      'title': 'Favorites',
                                      'images': _getFavoriteImages(),
                                      'asset': 'assets/icons/fav.svg',
                                      'isSpecial': true,
                                    },
                                    ...(user!.collections.map((c) => {
                                          'title': c.title,
                                          'images': c.images,
                                          'id': c.id,
                                        })).toList(),
                                  ];
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AllCollectionsScreen(
                                        collections: all,
                                        userId: widget.viewedUserId,
                                        canEdit: false,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildCollectionsRow(),
                              const SizedBox(height: 26),
                              _buildSectionHeader(
                                title: 'Posts',
                                actionLabel: 'View all',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PublicUserPostsScreen(
                                      posts: userPosts,
                                      currentUserId: widget.currentUserId,
                                      currentUserName: user!.fullName,
                                    ),
                                  ),
                                ),
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

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context, hasFollowChanged),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: whiteSmoke, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: darkText),
          ),
        ),
        Expanded(
          child: Center(
            child: Text('Profile',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkText)),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  // ── Profile info (avatar + name + bio + city + stats + actions) ───────────
  Widget _buildProfileInfo(bool isMe) {
    final hasBio = (user?.bio ?? '').isNotEmpty;
    final hasCity = (user?.city ?? '').isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar + name column
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
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
                child: (user!.profileImage?.isNotEmpty == true)
                    ? Image.network(user!.profileImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarInitial())
                    : _avatarInitial(),
              ),
            ),
            const SizedBox(width: 16),
            // Name + city + stats
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
                      const SizedBox(height: 3),
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
                        _statButton(
                          '${user!.followers.length}',
                          'Followers',
                          onTap: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FollowListScreen(
                                  title: 'Followers',
                                  profileUserId: widget.viewedUserId,
                                  currentUserId: widget.currentUserId,
                                ),
                              ),
                            );
                            if (updated == true) loadProfile();
                          },
                        ),
                        const SizedBox(width: 18),
                        _statButton(
                          '${user!.following.length}',
                          'Following',
                          onTap: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FollowListScreen(
                                  title: 'Following',
                                  profileUserId: widget.viewedUserId,
                                  currentUserId: widget.currentUserId,
                                ),
                              ),
                            );
                            if (updated == true) loadProfile();
                          },
                        ),
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
        // Action buttons: Share + Follow/Unfollow
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
            if (!isMe) ...[
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _followLoading ? null : _toggleFollow,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isFollowing ? Colors.white : wine,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isFollowing ? line : wine),
                    ),
                    alignment: Alignment.center,
                    child: _followLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isFollowing ? wine : Colors.white,
                            ),
                          )
                        : Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isFollowing ? darkText : Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _avatarInitial() {
    return Center(
      child: Text(_initial(user?.fullName ?? ''),
          style: GoogleFonts.poppins(
              fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
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
      return _emptyCompact(
          Icons.spa_outlined, 'No skin profile shared yet', '');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.asMap().entries.map((entry) {
          final isFirst = entry.key == 0;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isFirst ? wine : whiteSmoke,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isFirst ? wine : line),
            ),
            child: Text(entry.value,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isFirst ? Colors.white : darkText)),
          );
        }).toList(),
      ),
    );
  }

  // ── All concerns sheet ────────────────────────────────────────────────────
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
              Text(
                "${user?.fullName ?? ''}'s Skin Profile",
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 16),
              tags.isEmpty
                  ? Text('No skin profile shared.',
                      style: GoogleFonts.poppins(fontSize: 13, color: grey))
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: tags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: wine.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(999),
                                  border:
                                      Border.all(color: wine.withOpacity(0.20)),
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

  // ── Collections row ───────────────────────────────────────────────────────
  Widget _buildCollectionsRow() {
    final favorites = _getFavoriteImages();
    final dbCollections = user!.collections;

    final items = <Map<String, dynamic>>[
      {
        'title': 'Favorites',
        'images': favorites,
        'asset': 'assets/icons/fav.svg',
        'color': wine,
        'isSpecial': true,
      },
      ...dbCollections
          .map((c) => {
                'title': c.title,
                'images': c.images,
                'id': c.id,
                'isSpecial': false,
              })
          .toList(),
    ];

    if (items.isEmpty) {
      return _emptyCompact(Icons.collections_bookmark_outlined,
          'No collections yet', 'This user has no collections.');
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final item = items[i];
          final isSpecial = item['isSpecial'] == true;
          final images = List<String>.from(item['images'] ?? []);
          final title = item['title'] as String? ?? '';
          final count = images.length;

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CollectionDetailsScreen(
                  title: title,
                  images: images,
                  collectionId: item['id']?.toString() ?? '',
                  canEdit: false,
                  userId: '',
                ),
              ),
            ),
            child: SizedBox(
              width: 80,
              child: Column(
                children: [
                  images.isNotEmpty
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
                  Text(title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: darkText)),
                  if (!isSpecial && count > 0)
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

  Widget _buildCollectionPreview(List<String> images) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: line)),
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

  // ── Posts section ──────────────────────────────────────────────────────────
  Widget _buildPostsSection() {
    if (postsLoading) {
      return SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Container(
            width: 195,
            height: 200,
            decoration: BoxDecoration(
                color: const Color(0xFFE8E5E2),
                borderRadius: BorderRadius.circular(20)),
          ),
        ),
      );
    }

    if (userPosts.isEmpty) {
      return _emptyCompact(Icons.edit_note_outlined, 'No posts yet',
          '${user?.fullName.split(' ').first ?? 'This user'} hasn\'t shared anything yet.');
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailsScreen(
            post: post,
            currentUserId: widget.currentUserId,
            currentUserName: user!.fullName,
          ),
        ),
      ),
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
        child: Icon(Icons.image_outlined, color: grey, size: 28));
  }

  // ── Empty states ──────────────────────────────────────────────────────────
  Widget _emptyCompact(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
            child: Icon(icon, size: 20, color: wine.withOpacity(0.5)),
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
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: GoogleFonts.poppins(fontSize: 11.5, color: grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Failed to load profile',
              style: GoogleFonts.poppins(fontSize: 15, color: grey)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: loadProfile,
            child: Text('Retry',
                style: GoogleFonts.poppins(
                    color: wine, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Skeleton loading ──────────────────────────────────────────────────────
  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _skel(40, 40, radius: 12),
            const Spacer(),
            const SizedBox(width: 40)
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
                _skel(100, 14),
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
            ),
          ),
          const SizedBox(height: 26),
          _skel(100, 16),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => _skel(80, 90, radius: 18),
            ),
          ),
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
