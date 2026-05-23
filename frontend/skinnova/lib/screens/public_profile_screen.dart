import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../api_service.dart';
import '../user_model.dart';
import 'collection_details_screen.dart';
import 'post_page.dart';
import 'post_details_screen.dart';
import 'public_user_posts_screen.dart';
import 'all_collections_screen.dart';
import '../user_model.dart';

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
  static const Color wine = Color(0xFF5B2333);
  static const Color textDark = Color(0xFF202124);
  static const Color lightBorder = Color(0xFFF7F4F3);
  static const Color accentBlue = Colors.black;

  UserModel? user;
  bool isLoading = true;
  bool isFollowing = false;
  List<GroupPostModel> userPosts = [];
  bool postsLoading = true;
  bool hasFollowChanged = false;
  @override
  void initState() {
    super.initState();
    loadProfile();
    loadUserPosts();
  }

  Future<void> loadUserPosts() async {
    try {
      final allPosts = await ApiService.fetchPosts();

      if (!mounted) return;

      setState(() {
        userPosts = allPosts
            .where((post) => post.userId == widget.viewedUserId)
            .toList();
        postsLoading = false;
      });
    } catch (e) {
      print("LOAD USER POSTS ERROR: $e");

      if (!mounted) return;

      setState(() {
        postsLoading = false;
      });
    }
  }

  Future<void> loadProfile() async {
    final result = await ApiService.fetchUserProfile(widget.viewedUserId);

    if (!mounted) return;

    setState(() {
      user = result;
      isFollowing = result?.followers
              .any((follower) => follower.id == widget.currentUserId) ??
          false;
      isLoading = false;
    });
  }

  String getInitial(String name) {
    if (name.trim().isEmpty) return "?";
    return name.trim()[0].toUpperCase();
  }

  Color getAvatarColor(String name) {
    final colors = [
      const Color(0xFF5B2333),
      const Color(0xFF81A6C6),
      const Color(0xFFE6B400),
      const Color(0xFFE7685B),
      const Color(0xFF6A9C89),
      const Color(0xFF8E5572),
    ];

    return colors[name.trim().length % colors.length];
  }

  List<String> _getSkinTags() {
    if (user == null) return [];

    final tags = <String>[];

    if (user!.onboarding.skinType.isNotEmpty) {
      tags.add(user!.onboarding.skinType);
    }

    tags.addAll(user!.onboarding.skinConcerns);

    return tags;
  }

  List<String> _getFavoriteImages() {
    if (user == null || user!.favorites.isEmpty) return [];

    return user!.favorites
        .map((product) => product.imageUrl)
        .where((image) => image.isNotEmpty)
        .take(4)
        .toList();
  }

  Future<void> _shareProfile() async {
    if (user == null) return;

    final profileUrl = 'https://skinova.app/u/${user!.id}';

    await Share.share(
      'Check out ${user!.fullName} on Skinova 💕\n$profileUrl',
      subject: '${user!.fullName} on Skinova',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.currentUserId == widget.viewedUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : user == null
                ? Center(
                    child: Text(
                      "Failed to load profile",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: textDark,
                      ),
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 22),
                              _buildProfileInfo(isMe),
                              const SizedBox(height: 22),
                              _buildSectionHeader(
                                title: 'Skin type and concerns',
                                actionText: 'See all',
                                onTap: showAllConcernsSheet,
                              ),
                              const SizedBox(height: 14),
                              _buildConcernChips(_getSkinTags()),
                              const SizedBox(height: 22),
                              _buildSectionHeader(
                                title: 'Collections',
                                actionText: 'View all',
                                onTap: () {
                                  final dbCollections =
                                      (user?.collections ?? [])
                                          .map((collection) {
                                    return {
                                      'title': collection.title,
                                      'images': collection.images,
                                      'id': collection.id,
                                    };
                                  }).toList();

                                  final allCollections = [
                                    {
                                      'title': 'Fails',
                                      'images': <String>[],
                                      'asset': 'assets/icons/fails.svg',
                                      'color': const Color.fromARGB(
                                          255, 207, 35, 16),
                                      'isSpecial': true,
                                    },
                                    {
                                      'title': 'Favorites',
                                      'images': _getFavoriteImages(),
                                      'asset': 'assets/icons/fav.svg',
                                      'isSpecial': true,
                                    },
                                    {
                                      'title': 'Wishlist',
                                      'images': <String>[],
                                      'asset': 'assets/icons/wishlist.svg',
                                      'isSpecial': true,
                                    },
                                    ...dbCollections,
                                  ];

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AllCollectionsScreen(
                                        collections: allCollections,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _buildCollectionsCard(),
                              const SizedBox(height: 22),
                              _buildSectionHeader(
                                title: 'Recently used products',
                                actionText: 'View diary',
                              ),
                              const SizedBox(height: 14),
                              _buildRecentlyUsedCard(),
                              const SizedBox(height: 22),
                              _buildSectionHeader(
                                title: 'Posts',
                                actionText: 'View all',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PublicUserPostsScreen(
                                        posts: userPosts,
                                        currentUserId: widget.currentUserId,
                                        currentUserName: user!.fullName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              _buildUserPostsSection(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildUserPostsSection() {
    if (postsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (userPosts.isEmpty) {
      return _emptySoftCard("No posts to show yet.");
    }

    return SizedBox(
      height: 330,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: userPosts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final post = userPosts[index];
          return _buildPublicPostCard(post);
        },
      ),
    );
  }

  Widget _buildPublicPostCard(GroupPostModel post) {
    final image =
        post.images.isNotEmpty ? post.images.first : post.productImage;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailsScreen(
              post: post,
              currentUserId: widget.currentUserId,
              currentUserName: user!.fullName,
            ),
          ),
        );
      },
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFF0F0F0),
            width: 1.4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.content.isNotEmpty ? post.content : "No caption",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.35,
                color: textDark,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 14),
            if (image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  image,
                  width: double.infinity,
                  height: 170,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _postImagePlaceholder();
                  },
                ),
              )
            else
              _postImagePlaceholder(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.favorite_border_rounded,
                  size: 20,
                  color: Colors.grey,
                ),
                const SizedBox(width: 5),
                Text(
                  "${post.likes.length}",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  "${post.comments.length} Comments",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _postImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: Colors.grey,
        size: 32,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          // onTap: () => Navigator.pop(context),
          onTap: () => Navigator.pop(context, hasFollowChanged),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: textDark,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Profile',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildProfileInfo(bool isMe) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: getAvatarColor(user!.fullName),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child:
                    user!.profileImage != null && user!.profileImage!.isNotEmpty
                        ? Image.network(
                            user!.profileImage!,
                            fit: BoxFit.cover,
                            width: 72,
                            height: 72,
                            errorBuilder: (context, error, stackTrace) {
                              return _avatarInitial();
                            },
                          )
                        : _avatarInitial(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user!.fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Skinova member",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${user!.followers.length} Followers',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '${user!.following.length} Following',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            GestureDetector(
              onTap: _shareProfile,
              child: Container(
                width: 50,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4F3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: lightBorder),
                ),
                child: const Icon(
                  Icons.ios_share_outlined,
                  color: textDark,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (!isMe)
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final success = isFollowing
                        ? await ApiService.unfollowUser(
                            targetUserId: widget.viewedUserId,
                            currentUserId: widget.currentUserId,
                          )
                        : await ApiService.followUser(
                            targetUserId: widget.viewedUserId,
                            currentUserId: widget.currentUserId,
                          );

                    if (success && user != null) {
                      setState(() {
                        hasFollowChanged = true;

                        if (isFollowing) {
                          user!.followers.removeWhere(
                            (follower) => follower.id == widget.currentUserId,
                          );
                          isFollowing = false;
                        } else {
                          user!.followers.add(
                            FollowUserModel(
                              id: widget.currentUserId,
                              fullName: "",
                              profileImage: "",
                            ),
                          );
                          isFollowing = true;
                        }
                      });

                      await loadProfile();
                    }
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isFollowing ? Colors.white : wine,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isFollowing ? lightBorder : wine,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isFollowing ? textDark : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _avatarInitial() {
    return Center(
      child: Text(
        getInitial(user!.fullName),
        style: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(
                actionText,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: accentBlue,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: accentBlue,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConcernChips(List<String> tags) {
    if (tags.isEmpty) {
      return _emptySoftCard("No skin tags yet.");
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.map((item) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFCFC),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFF7F4F3),
                width: 1,
              ),
            ),
            child: Text(
              item,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: accentBlue.withOpacity(0.92),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCollectionsCard() {
    final dbCollections = (user?.collections ?? []).map((collection) {
      return {
        'title': collection.title,
        'images': collection.images,
        'id': collection.id,
      };
    }).toList();

    final favoriteImages = _getFavoriteImages();

    final items = [
      {
        'title': 'Fails',
        'images': <String>[],
        'asset': 'assets/icons/fails.svg',
        'color': const Color.fromARGB(255, 207, 35, 16),
        'isSpecial': true,
      },
      {
        'title': 'Favorites',
        'asset': 'assets/icons/fav.svg',
        'images': favoriteImages,
        'isSpecial': true,
      },
      {
        'title': 'Wishlist',
        'asset': 'assets/icons/wishlist.svg',
        'images': <String>[],
        'isSpecial': true,
      },
      ...dbCollections,
    ];

    if (items.isEmpty) {
      return _emptySoftCard("No public collections yet.");
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) {
            final bool isSpecial = item['isSpecial'] == true;
            final List<String> images = item['images'] != null
                ? List<String>.from(item['images'] as List)
                : [];

            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CollectionDetailsScreen(
                        title: item['title'] as String,
                        images: images,
                        collectionId: item['id']?.toString() ?? '',
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    if (images.isNotEmpty)
                      _buildCollectionPreview(images)
                    else if (isSpecial)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: item['asset'] != null
                              ? SvgPicture.asset(
                                  item['asset'] as String,
                                  width: 34,
                                  height: 34,
                                  fit: BoxFit.contain,
                                )
                              : const Icon(Icons.folder_outlined),
                        ),
                      )
                    else
                      _buildCollectionPreview(images),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 80,
                      child: Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void showAllConcernsSheet() {
    final tags = _getSkinTags();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 28,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Tags",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                  ],
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 14,
                    children: tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFEAEAEA),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: textDark,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollectionPreview(List<String> images) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          if (index < images.length && images[index].isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _emptyCollectionSquare();
                },
              ),
            );
          }

          return _emptyCollectionSquare();
        },
      ),
    );
  }

  Widget _emptyCollectionSquare() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildRecentlyUsedCard() {
    final products = [
      'assets/categories/mois.jpg',
      'assets/categories/cleanser.jpg',
      'assets/categories/belmish.jpg',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: products.map((image) {
          return Container(
            width: 84,
            height: 84,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: Color(0xFFF7F4F3),
                  size: 22,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyPostCard() {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lightBorder, width: 1.2),
      ),
      alignment: Alignment.center,
      child: Text(
        'No posts to show yet.',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _emptySoftCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey,
        ),
      ),
    );
  }
}
