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

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color textDark = Color(0xFF202124);
  static const Color textMuted = Color(0xFFF7F4F3);
  static const Color lightBorder = Color(0xFFF7F4F3);
  static const Color softBlue = Color(0xFFEAF4FF);
  static const Color accentBlue = Colors.black;
  File? selectedImage;
  bool isUploadingImage = false;
  UserModel? user;
  bool isLoading = true;
  List<dynamic> recentScans = [];
  bool isLoadingScans = true;
  List<GroupPostModel> userPosts = [];
  bool postsLoading = true;
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

  Future<void> pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null || user == null) return;

    setState(() {
      selectedImage = File(pickedFile.path);
      isUploadingImage = true;
    });

    final imageUrl = await ApiService.uploadProfileImage(
      userId: user!.id,
      imageFile: selectedImage!,
    );

    if (!mounted) return;

    if (imageUrl != null) {
      await loadProfile();
    }

    setState(() {
      isUploadingImage = false;
    });
  }

  Future<void> removeProfileImage() async {
    if (user == null) return;

    final success = await ApiService.removeProfileImage(userId: user!.id);

    if (!mounted) return;

    if (success) {
      setState(() {
        selectedImage = null;
      });

      await loadProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile picture removed"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to remove profile picture"),
        ),
      );
    }
  }

  void showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text("Choose photo"),
                  onTap: () {
                    Navigator.pop(context);
                    pickAndUploadProfileImage();
                  },
                ),
                if ((user?.profileImage ?? '').isNotEmpty ||
                    selectedImage != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text(
                      "Remove photo",
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      removeProfileImage();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

//collections
  List<Map<String, dynamic>> customCollections = [];
  void showNewCollectionSheet() {
    final TextEditingController collectionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4F3),
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
                        "New collection",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final name = collectionController.text.trim();

                      if (name.isEmpty || user == null) return;

                      final success = await ApiService.addCollection(
                        userId: user!.id,
                        title: name,
                      );

                      if (!mounted) return;

                      if (success != null) {
                        await loadProfile();
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Collection added successfully"),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Failed to add collection"),
                          ),
                        );
                      }
                    },
                    child: const Icon(
                      Icons.check,
                      color: Colors.grey,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: TextField(
                  controller: collectionController,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: "Name your new collection...",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
            ],
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
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }
  //collections

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadRecentScans();
    loadUserPosts();
  }

  Future<void> loadUserPosts() async {
    try {
      final posts = await ApiService.fetchPosts();

      if (!mounted) return;

      setState(() {
        userPosts =
            posts.where((post) => post.userId == widget.userId).toList();
        postsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        postsLoading = false;
      });
    }
  }

  Future<void> loadRecentScans() async {
    try {
      final result = await ApiService.fetchScanHistory(widget.userId);

      if (!mounted) return;

      setState(() {
        recentScans = result.take(4).toList();
        isLoadingScans = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingScans = false;
      });
    }
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
      const Color(0xFF4B6587),
      const Color(0xFFB71540),
      const Color(0xFF1B9CFC),
      const Color(0xFF4CAF50),
      const Color(0xFF9C27B0),
      const Color(0xFFFF5722),
      const Color(0xFF3F51B5),
      const Color(0xFF009688),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
    ];

    return colors[name.trim().length % colors.length];
  }

  Future<void> loadProfile() async {
    final result = await ApiService.fetchUserProfile(widget.userId);

    if (!mounted) return;

    setState(() {
      user = result;
      isLoading = false;
    });
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
        // .take(4)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
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
                              _buildProfileInfo(),
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
                                      'color': accentBlue,
                                      'isSpecial': true,
                                    },
                                    {
                                      'title': 'Wishlist',
                                      'images': <String>[],
                                      'asset': 'assets/icons/wishlist.svg',
                                      'color': const Color.fromARGB(
                                          255, 216, 182, 57),
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
                                title: 'Recent scans',
                                actionText: 'View all',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ScanHistoryScreen(
                                        userId: widget.userId,
                                        userName: user!.fullName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              _buildRecentScansCard(),

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
                                        currentUserId: widget.userId,
                                        currentUserName: user!.fullName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              _buildUserPostsSection(),
                              // const SizedBox(height: 14),
                              // _buildPostsRow(),
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
      return _buildEmptyPostCard();
    }

    return SizedBox(
      height: 220,
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
      onTap: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailsScreen(
              post: post,
              currentUserId: widget.userId,
              currentUserName: user!.fullName,
            ),
          ),
        );

        if (updated == true) {
          loadUserPosts();
        }
      },
      child: Container(
        width: 210,
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
                  height: 95,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return _postImagePlaceholder();
                  },
                ),
              )
            else
              _postImagePlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _postImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 95,
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

  Widget _buildRecentScansCard() {
    if (isLoadingScans) {
      return Container(
        width: double.infinity,
        height: 108,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (recentScans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'No scans yet',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textDark,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScanHistoryScreen(
              userId: widget.userId,
              userName: user!.fullName,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: recentScans.map((scan) {
              final matched = scan["matched"] == true;
              final product = scan["productId"];

              final imageUrl =
                  matched && product != null ? product["imageUrl"] ?? "" : "";

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
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported_outlined),
                        )
                      : const Icon(
                          Icons.search_off_rounded,
                          color: Color(0xFF5B2333),
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const SizedBox(width: 40),
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
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  userId: user!.id,
                  userName: user!.fullName,
                ),
              ),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: textDark,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: getAvatarColor(user!.fullName),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: selectedImage != null
                        ? Image.file(
                            selectedImage!,
                            fit: BoxFit.cover,
                            width: 72,
                            height: 72,
                          )
                        : (user!.profileImage != null &&
                                user!.profileImage!.isNotEmpty)
                            ? Image.network(
                                user!.profileImage!,
                                fit: BoxFit.cover,
                                width: 72,
                                height: 72,
                                errorBuilder: (context, error, stackTrace) {
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
                                },
                              )
                            : Center(
                                child: Text(
                                  getInitial(user!.fullName),
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: GestureDetector(
                    onTap: showProfileImageOptions,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accentBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => FollowListScreen(
                                        title: "Followers",
                                        profileUserId: widget.userId,
                                        currentUserId: widget.userId,
                                      )),
                            );

                            if (updated == true) {
                              await loadProfile();
                            }
                          },
                          child: Text(
                            '${user!.followers.length} Followers',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => FollowListScreen(
                                        title: "Following",
                                        profileUserId: widget.userId,
                                        currentUserId: widget.userId,
                                      )),
                            );

                            if (updated == true) {
                              await loadProfile();
                            }
                          },
                          child: Text(
                            '${user!.following.length} Following',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textDark,
                            ),
                          ),
                        ),
                      ],
                    )
                    // Row(
                    //   children: [
                    //     Text(
                    //       '${user!.followers.length} Followers',
                    //       style: GoogleFonts.poppins(
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w500,
                    //         color: textDark,
                    //       ),
                    //     ),
                    //     const SizedBox(width: 14),
                    //     Text(
                    //       '${user!.following.length} Following',
                    //       style: GoogleFonts.poppins(
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w500,
                    //         color: textDark,
                    //       ),
                    //     ),
                    //   ],
                    // ),
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
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  if (user == null) return;

                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        userId: user!.id,
                        user: user!,
                      ),
                    ),
                  );

                  if (updated == true) {
                    await loadProfile();
                  }
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4F3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: lightBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Edit profile',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textDark,
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
  //ios share

  Future<void> _shareProfile() async {
    if (user == null) return;

    final profileUrl = 'https://skinova.app/u/${user!.id}';

    await Share.share(
      'Check out my Skinova profile 💕\n$profileUrl',
      subject: '${user!.fullName} on Skinova',
    );
  }

  //ios

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
              fontSize: 10,
              fontWeight: FontWeight.w500,
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
        'title': 'New',
        'icon': Icons.add,
        'color': const Color(0xFFCFCFCF),
        'isNew': true,
      },
      {
        'title': 'Fails',
        'asset': 'assets/icons/fails.svg',
        'color': Color.fromARGB(255, 207, 35, 16),
        'images': <String>[],
        'isSpecial': true,
      },
      {
        'title': 'Favorites',
        'asset': 'assets/icons/fav.svg',
        'color': accentBlue,
        'images': favoriteImages,
        'isSpecial': true,
      },
      {
        'title': 'Wishlist',
        'asset': 'assets/icons/wishlist.svg',
        'color': Color.fromARGB(255, 216, 182, 57),
        'images': <String>[],
        'isSpecial': true,
      },
      ...dbCollections,
    ];

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
            //final bool isNew = item['isNew'] == true;
            final bool isNew = item['isNew'] == true;
            final bool isSpecial = item['isSpecial'] == true;
            final List<String> images = item['images'] != null
                ? List<String>.from(item['images'] as List)
                : [];
            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () async {
                  if (isNew) {
                    showNewCollectionSheet();
                  } else {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CollectionDetailsScreen(
                          title: item['title'] as String,
                          images: item['images'] != null
                              ? List<String>.from(item['images'] as List)
                              : [],
                          collectionId: item['id']?.toString() ?? '',
                        ),
                      ),
                    );

                    if (updated == true) {
                      await loadProfile();
                    }
                  }
                },
                child: Column(
                  children: [
                    if (isNew)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 40,
                          color: Color(0xFFCFCFCF),
                        ),
                      )
                    else if (images.isNotEmpty)
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
                              : Icon(
                                  (item['icon'] as IconData?) ??
                                      Icons.folder_outlined,
                                  size: 34,
                                  color: (item['color'] as Color?) ??
                                      const Color(0xFFCFCFCF),
                                ),
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
                  color: const Color(0xFFF7F4F3),
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
      height: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lightBorder, width: 1.2),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'See all',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: accentBlue,
            ),
          ),
        ),
      ),
    );
  }
}
