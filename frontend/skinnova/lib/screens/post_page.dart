import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'select_review_product_screen.dart';
import '../api_service.dart';
import 'post_details_screen.dart';
import 'question_post_screen.dart';
import 'update_post_screen.dart';
import 'search_posts_screen.dart';

class PostCommentModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String comment;
  final DateTime? createdAt;
  final String? parentCommentId;
  final String replyToUserName;
  final List<String> likes;

  const PostCommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.comment,
    this.parentCommentId,
    this.replyToUserName = "",
    this.createdAt,
    this.likes = const [],
  });

  factory PostCommentModel.fromJson(Map<String, dynamic> json) {
    return PostCommentModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      parentCommentId: json['parentCommentId'],
      replyToUserName: json['replyToUserName'] ?? '',
      likes: List<String>.from(json['likes'] ?? []),
    );
  }
}

class GroupPostModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String tag;
  final String postType;
  final String content;
  final List<String> images;
  final String timeText;
  final bool isEdited;
  final DateTime? createdAt;
  final double rating;
  final String productName;
  final String productImage;
  final bool? repurchase;
  final bool? improvedSkin;
  final bool? wasGift;
  final bool? adverseReaction;
  final String texture;
  final String usageWeeks;
  final List<String> likes;
  final List<PostCommentModel> comments;
  final String groupId;
  final String groupTitle;
  final String groupSlug;

  const GroupPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.tag,
    this.postType = "update",
    required this.content,
    required this.images,
    required this.timeText,
    this.isEdited = false,
    this.createdAt,
    this.rating = 0,
    this.productName = "",
    this.productImage = "",
    this.repurchase,
    this.improvedSkin,
    this.wasGift,
    this.adverseReaction,
    this.texture = "",
    this.usageWeeks = "",
    this.likes = const [],
    this.comments = const [],
    this.groupId = "",
    this.groupTitle = "",
    this.groupSlug = "",
  });

  factory GroupPostModel.fromJson(Map<String, dynamic> json) {
    return GroupPostModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      tag: json['tag'] ?? '',
      postType: json['postType'] ?? 'update',
      content: json['content'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      timeText: json['timeText'] ?? 'Just now',
      isEdited: json['isEdited'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      rating: (json['rating'] ?? 0).toDouble(),
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      repurchase: json['repurchase'],
      improvedSkin: json['improvedSkin'],
      wasGift: json['wasGift'],
      adverseReaction: json['adverseReaction'],
      texture: json['texture'] ?? '',
      usageWeeks: json['usageWeeks'] ?? '',
      likes: List<String>.from(json['likes'] ?? []),
      comments: (json['comments'] as List? ?? [])
          .map((e) => PostCommentModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      groupId: json['groupId']?.toString() ?? '',
      groupTitle: json['groupTitle'] ?? '',
      groupSlug: json['groupSlug'] ?? '',
    );
  }
}

class PostPage extends StatefulWidget {
  final ValueChanged<String>? onSearchChanged;
  final String userId;
  final String userName;

  const PostPage({
    super.key,
    this.onSearchChanged,
    required this.userId,
    required this.userName,
  });

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  List<GroupPostModel> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    try {
      final data = await ApiService.fetchPosts();
      if (!mounted) return;

      setState(() {
        posts = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 78),
        child: FloatingActionButton(
          onPressed: () async {
            final posted = await showNewPostOptionsSheet(
              context,
              userId: widget.userId,
              userName: widget.userName,
            );

            if (posted == true) {
              await loadPosts();

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Review posted successfully")),
              );
            }
          },
          backgroundColor: const Color(0xFF5B2333),
          elevation: 3,
          child: SvgPicture.asset(
            'assets/icons/addpost.svg',
            width: 22,
            height: 22,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : posts.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 8, bottom: 120),
                          itemCount: posts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return PostCard(
                              post: posts[index],
                              onDelete: () async {
                                await loadPosts();
                              },
                              onRefresh: () async {
                                await loadPosts();
                              },
                              currentUserId: widget.userId,
                              currentUserName: widget.userName,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          const Spacer(),
          Text(
            "Skinova.",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5B2333),
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.notifications_none_rounded,
            size: 28,
            color: Color(0xFF202124),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            readOnly: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchPostsScreen(
                    userId: widget.userId,
                    userName: widget.userName,
                  ),
                ),
              );
            },
            decoration: InputDecoration(
              hintText: "Search posts or people",
              hintStyle: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFFB2B2B2),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFFB2B2B2),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          )),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 42,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              "No posts yet",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A2A2A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Be the first one to share something in this group.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF9A9A9A),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final GroupPostModel post;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;
  final String currentUserId;
  final String currentUserName;

  const PostCard({
    required this.post,
    required this.onDelete,
    required this.onRefresh,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(
            post: post,
            onDelete: onDelete,
            currentUserId: currentUserId,
          ),
          const SizedBox(height: 10),
          if (post.postType.toLowerCase() == "update") ...[
            Row(
              children: [
                Icon(
                  Icons.watch_later_outlined,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  "Posted to ",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFA0A0A0),
                  ),
                ),
                Text(
                  post.groupTitle.isNotEmpty ? post.groupTitle : "General",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF5B2333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  " · ${_PostHeader(post: post, onDelete: onDelete, currentUserId: currentUserId)._formatPostTime(post.createdAt)}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFA0A0A0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (post.content.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  post.content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF2A2A2A),
                    height: 1.5,
                  ),
                ),
              ),
            if (post.productName.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sell_outlined, color: Color(0xFF444444)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        post.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2A2A2A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (post.productName.isNotEmpty) const SizedBox(height: 14),
            if (post.productImage.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    post.productImage,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF1F1F1),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
            if (post.productImage.isNotEmpty) const SizedBox(height: 14),
          ],
          if (post.postType.toLowerCase() == "question") ...[
            Row(
              children: [
                Icon(
                  Icons.watch_later_outlined,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  "Posted to ",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFA0A0A0),
                  ),
                ),
                Text(
                  post.groupTitle.isNotEmpty ? post.groupTitle : "General",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF5B2333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  " · ${_PostHeader(post: post, onDelete: onDelete, currentUserId: currentUserId)._formatPostTime(post.createdAt)}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFA0A0A0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (post.content.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  post.content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF2A2A2A),
                    height: 1.5,
                  ),
                ),
              ),
            if (post.productName.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sell_outlined, color: Color(0xFF444444)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        post.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2A2A2A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (post.productName.isNotEmpty) const SizedBox(height: 14),
            if (post.productImage.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    post.productImage,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF1F1F1),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
            if (post.productImage.isNotEmpty) const SizedBox(height: 14),
          ],
          if (post.postType.toLowerCase() == "review") ...[
            if (post.rating > 0) ...[
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < post.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFF7C300),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (post.productName.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(44),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sell_outlined, color: Color(0xFF444444)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        post.productName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2A2A2A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (post.productName.isNotEmpty) const SizedBox(height: 14),
            if (post.productImage.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    post.productImage,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF1F1F1),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
            if (post.productImage.isNotEmpty) const SizedBox(height: 14),
          ],
          if (post.content.trim().isNotEmpty &&
              post.postType.toLowerCase() != "question" &&
              post.postType.toLowerCase() != "update") ...[
            Builder(
              builder: (context) {
                final isLong = post.content.length > 3;
                final preview =
                    isLong ? post.content.substring(0, 3).trim() : post.content;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF2A2A2A),
                          height: 1.55,
                        ),
                        children: [
                          TextSpan(text: preview),
                          if (isLong)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PostDetailsScreen(
                                        post: post,
                                        currentUserId: currentUserId,
                                        currentUserName: currentUserName,
                                      ),
                                    ),
                                  );
                                  onRefresh();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    "...see more",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFF6B6B6B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          if (post.images.isNotEmpty) _PostImages(images: post.images),
          if (post.images.isNotEmpty) const SizedBox(height: 10),
          if (post.images.length > 1) _buildSliderDots(),
          const SizedBox(height: 12),
          _PostActions(
            post: post,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
            onRefresh: onRefresh,
          )
        ],
      ),
    );
  }

  Widget _buildSliderDots() {
    Widget dot(bool active) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: active ? 7 : 5,
        height: active ? 7 : 5,
        decoration: BoxDecoration(
          color: active
              ? Color.fromARGB(255, 234, 167, 139)
              : const Color(0xFFD8D8D8),
          shape: BoxShape.circle,
        ),
      );
    }

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot(true),
          dot(false),
          dot(false),
          dot(false),
        ],
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  final GroupPostModel post;
  final VoidCallback onDelete;
  final String currentUserId;

  const _PostHeader({
    required this.post,
    required this.onDelete,
    required this.currentUserId,
  });
  String _formatPostTime(DateTime? createdAt) {
    if (createdAt == null) return "Just now";

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) return "now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";

    return "${createdAt.day}/${createdAt.month}/${createdAt.year}";
  }

  Color _getPostTypeColor(String postType) {
    switch (postType.toLowerCase()) {
      case "question":
        return const Color(0xFFF3D86B); // أصفر
      case "review":
        return const Color(0xFF6BA4D9); // أزرق
      case "update":
        return const Color(0xFF8BC48A); // أخضر
      default:
        return const Color(0xFFB0B0B0);
    }
  }

  Color _getPostTypeTextColor(String postType) {
    switch (postType.toLowerCase()) {
      case "question":
        return const Color(0xFF5A4A00); // بني غامق
      case "review":
        return Colors.white;
      case "update":
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  void _showEditPostDialog(BuildContext context) {
    final TextEditingController controller =
        TextEditingController(text: post.content);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Post"),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "Edit your question",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final newContent = controller.text.trim();
                if (newContent.isEmpty) return;

                final success = await ApiService.editPost(
                  postId: post.id,
                  content: newContent,
                );

                if (!context.mounted) return;

                Navigator.pop(context);

                if (success) {
                  onDelete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Post updated")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to update post")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = post.userAvatar.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF1F1F1),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasAvatar
              ? Image.network(
                  post.userAvatar,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackAvatar(post.userName),
                )
              : _fallbackAvatar(post.userName),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A2A2A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getPostTypeColor(post.postType),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      post.postType.isNotEmpty
                          ? post.postType[0].toUpperCase() +
                              post.postType.substring(1)
                          : "Update",
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: _getPostTypeTextColor(post.postType),
                      ),
                    ),
                  ),
                ],
              ),
              if (post.postType.toLowerCase() != "question") ...[
                const SizedBox(height: 2),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    Icon(
                      Icons.public_rounded,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    Text(
                      " · ${_formatPostTime(post.createdAt)}${post.isEdited ? " · Edited" : ""}",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFFA0A0A0),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            final isMyPost = post.userId == currentUserId;

            showModalBottomSheet(
              context: context,
              builder: (_) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMyPost) ...[
                          if (post.postType.toLowerCase() == "question")
                            ListTile(
                              title: const Text("Edit Post"),
                              onTap: () {
                                Navigator.pop(context);
                                _showEditPostDialog(context);
                              },
                            ),
                          ListTile(
                            title: const Text(
                              "Delete Post",
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () async {
                              Navigator.pop(context);

                              final success =
                                  await ApiService.deletePost(post.id);

                              if (!context.mounted) return;

                              if (success) {
                                onDelete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Post deleted")),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Failed to delete post"),
                                  ),
                                );
                              }
                            },
                          ),
                        ] else ...[
                          ListTile(
                            title: const Text("Save Post"),
                            onTap: () async {
                              Navigator.pop(context);

                              final result = await ApiService.toggleSavePost(
                                userId: currentUserId,
                                postId: post.id,
                              );

                              if (!context.mounted) return;

                              if (result["statusCode"] == 200) {
                                final isSaved =
                                    result["data"]["isSaved"] ?? false;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isSaved
                                          ? "Post saved successfully"
                                          : "Post removed from saved",
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Failed to save post")),
                                );
                              }
                            },
                          ),
                        ],
                        ListTile(
                          title: const Text("Cancel"),
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: const Icon(
            Icons.more_horiz_rounded,
            color: Color(0xFF7C7C7C),
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _fallbackAvatar(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "U";

    return Container(
      color: const Color(0xFFF1F1F1),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8F8F8F),
        ),
      ),
    );
  }
}

class _PostImages extends StatelessWidget {
  final List<String> images;

  const _PostImages({
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1.08,
          child: Image.network(
            images.first,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imageFallback(),
          ),
        ),
      );
    }

    if (images.length == 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 320,
          child: Row(
            children: [
              Expanded(
                child: Image.network(
                  images[0],
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => _imageFallback(),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Image.network(
                  images[1],
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => _imageFallback(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 320,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: images.length > 4 ? 4 : images.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemBuilder: (context, index) {
            return Image.network(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imageFallback(),
            );
          },
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFF1F1F1),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFFB0B0B0),
      ),
    );
  }
}

class _PostActions extends StatefulWidget {
  final GroupPostModel post;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback onRefresh;

  const _PostActions({
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    required this.onRefresh,
  });

  @override
  State<_PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends State<_PostActions> {
  late List<String> likes;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    likes = List<String>.from(widget.post.likes);
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = likes.contains(widget.currentUserId);

    Widget action({
      required IconData icon,
      required String text,
      required VoidCallback? onTap,
      Color iconColor = const Color(0xFF9A9A9A),
      Color textColor = const Color(0xFF9A9A9A),
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: textColor,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        action(
          icon:
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          text: "Like ${likes.isNotEmpty ? "(${likes.length})" : ""}",
          iconColor: isLiked ? Colors.red : const Color(0xFF9A9A9A),
          textColor: isLiked ? Colors.red : const Color(0xFF9A9A9A),
          onTap: isLoading
              ? null
              : () async {
                  setState(() {
                    isLoading = true;
                  });

                  final result = await ApiService.toggleLike(
                    postId: widget.post.id,
                    userId: widget.currentUserId,
                  );

                  if (result["statusCode"] == 200) {
                    final updatedLikes =
                        List<String>.from(result["data"]["likes"] ?? []);

                    setState(() {
                      likes = updatedLikes;
                    });
                  }

                  setState(() {
                    isLoading = false;
                  });
                },
        ),
        const SizedBox(width: 28),
        action(
          icon: Icons.chat_bubble_outline_rounded,
          text: widget.post.comments.isNotEmpty
              ? "${widget.post.comments.length} ${widget.post.comments.length == 1 ? "Comment" : "Comments"}"
              : "Comment",
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailsScreen(
                  post: widget.post,
                  currentUserId: widget.currentUserId,
                  currentUserName: widget.currentUserName,
                  openCommentField: true,
                ),
              ),
            );

            widget.onRefresh();
          },
        ),
      ],
    );
  }
}

Future<bool?> showNewPostOptionsSheet(
  BuildContext context, {
  required String userId,
  required String userName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return _NewPostOptionsSheet(
        userId: userId,
        userName: userName,
      );
    },
  );
}

class _NewPostOptionsSheet extends StatelessWidget {
  final String userId;
  final String userName;

  const _NewPostOptionsSheet({
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    Widget optionCard({
      required String title,
      required Future<void> Function() onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2A2A2A),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E3E3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 34,
                      color: Color(0xFF8D8D8D),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "New Post",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2A2A2A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
              const SizedBox(height: 14),
              optionCard(
                title: "Review",
                onTap: () async {
                  final posted = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SelectReviewProductScreen(
                        userId: userId,
                        userName: userName,
                      ),
                    ),
                  );

                  if (posted == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
              const SizedBox(height: 14),
              optionCard(
                title: "Question",
                onTap: () async {
                  final posted = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestionPostScreen(
                        userId: userId,
                        userName: userName,
                      ),
                    ),
                  );

                  if (posted == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
              const SizedBox(height: 14),
              optionCard(
                title: "Update",
                onTap: () async {
                  final posted = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UpdatePostScreen(
                        userId: userId,
                        userName: userName,
                      ),
                    ),
                  );

                  if (posted == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
