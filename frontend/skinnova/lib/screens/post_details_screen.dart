import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'post_page.dart';
import '../api_service.dart';
import 'package:flutter/services.dart';

class PostDetailsScreen extends StatefulWidget {
  final GroupPostModel post;
  final String currentUserId;
  final String currentUserName;
  final bool openCommentField;

  const PostDetailsScreen({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    this.openCommentField = false,
  });

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController commentController = TextEditingController();

  bool isLiked = false;
  late GroupPostModel post;
  final FocusNode commentFocusNode = FocusNode();
  String? replyingToCommentId;
  String replyingToUserName = "";
  Color _getPostTypeColor(String postType) {
    switch (postType.toLowerCase()) {
      case "question":
        return const Color(0xFFF3D86B);
      case "review":
        return const Color(0xFF6BA4D9);
      case "update":
        return const Color(0xFF8BC48A);
      default:
        return const Color(0xFFB0B0B0);
    }
  }

  Color _getPostTypeTextColor(String postType) {
    switch (postType.toLowerCase()) {
      case "question":
        return const Color(0xFF5A4A00);
      case "review":
        return Colors.white;
      case "update":
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  @override
  void initState() {
    super.initState();
    post = widget.post;
    if (widget.openCommentField) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(commentFocusNode);
      });
    }
    _refreshPost();
  }

  void _showEditPostDialog() {
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
              //  onPressed: () => Navigator.pop(context),
              onPressed: () => Navigator.pop(context, true),
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

                if (!mounted) return;

                Navigator.pop(context);

                if (success) {
                  await _refreshPost();
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

  void _showEditCommentDialog(PostCommentModel comment) {
    final TextEditingController controller =
        TextEditingController(text: comment.comment);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Comment"),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Edit your comment",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              //onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final newComment = controller.text.trim();
                if (newComment.isEmpty) return;

                final success = await ApiService.editComment(
                  postId: post.id,
                  commentId: comment.id,
                  comment: newComment,
                );

                if (!mounted) return;

                Navigator.pop(context);

                if (success) {
                  await _refreshPost();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Comment updated")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to update comment")),
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

  Future<void> _refreshPost() async {
    try {
      final posts = await ApiService.fetchPosts();

      final updatedPost = posts.firstWhere(
        (p) => p.id == widget.post.id,
        orElse: () => widget.post,
      );

      if (!mounted) return;

      setState(() {
        post = updatedPost;
      });
    } catch (e) {}
  }

  @override
  void dispose() {
    commentFocusNode.dispose();
    commentController.dispose();
    super.dispose();
  }

  String _formatPostTime(DateTime? createdAt) {
    if (createdAt == null) return "Just now";

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) return "now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";

    return "${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}";
  }

  String _monthName(int month) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month];
  }

  Widget _buildAvatar({
    required String userName,
    required String userAvatar,
    double radius = 22,
  }) {
    final hasAvatar = userAvatar.trim().isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFF1F1F1),
      backgroundImage: hasAvatar ? NetworkImage(userAvatar) : null,
      child: !hasAvatar
          ? Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : "U",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8F8F8F),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoBox(String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2A2A2A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF2A2A2A),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _togglePostLike() async {
    final result = await ApiService.toggleLike(
      postId: post.id,
      userId: widget.currentUserId,
    );

    if (result["statusCode"] == 200) {
      setState(() {
        post = GroupPostModel(
          id: post.id,
          userId: post.userId,
          userName: post.userName,
          userAvatar: post.userAvatar,
          tag: post.tag,
          postType: post.postType,
          content: post.content,
          images: post.images,
          timeText: post.timeText,
          isEdited: post.isEdited,
          createdAt: post.createdAt,
          rating: post.rating,
          productName: post.productName,
          productImage: post.productImage,
          repurchase: post.repurchase,
          improvedSkin: post.improvedSkin,
          wasGift: post.wasGift,
          adverseReaction: post.adverseReaction,
          texture: post.texture,
          usageWeeks: post.usageWeeks,
          likes: List<String>.from(result["data"]["likes"] ?? []),
          comments: post.comments,
          groupId: post.groupId,
          groupTitle: post.groupTitle,
          groupSlug: post.groupSlug,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //final post = widget.post;
    final sortedComments = List<PostCommentModel>.from(post.comments)
      ..sort((a, b) => b.likes.length.compareTo(a.likes.length));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          //onPressed: () => Navigator.pop(context),
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        title: Text(
          "Post",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(
                        userName: post.userName,
                        userAvatar: post.userAvatar,
                        radius: 22,
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
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: const Color(0xFF2A2A2A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPostTypeColor(post.postType),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    post.postType.isNotEmpty
                                        ? post.postType[0].toUpperCase() +
                                            post.postType.substring(1)
                                        : "Review",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          _getPostTypeTextColor(post.postType),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "·",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFB0B0B0),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatPostTime(post.createdAt),
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF9A9A9A),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "·",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFB0B0B0),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final isMyPost = post.userId == widget.currentUserId;

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
                                        if (post.postType.toLowerCase() ==
                                            "question")
                                          ListTile(
                                            title: const Text("Edit Post"),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _showEditPostDialog();
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
                                                await ApiService.deletePost(
                                                    post.id);

                                            if (!mounted) return;

                                            if (success) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content:
                                                        Text("Post deleted")),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      "Failed to delete post"),
                                                ),
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
                  ),
                  const SizedBox(height: 16),
                  if (post.rating > 0)
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < post.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF7C300),
                          size: 30,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  if (post.content.isNotEmpty)
                    Text(
                      post.content,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF2A2A2A),
                        height: 1.6,
                      ),
                    ),
                  const SizedBox(height: 22),
                  _buildInfoBox(
                    "Would you repurchase this item?",
                    post.repurchase == null
                        ? ""
                        : (post.repurchase! ? "Yes" : "No"),
                  ),
                  _buildInfoBox(
                    "Was there a visible improvement to your skin?",
                    post.improvedSkin == null
                        ? ""
                        : (post.improvedSkin! ? "Yes" : "No"),
                  ),
                  _buildInfoBox(
                    "Was this item a gift?",
                    post.wasGift == null ? "" : (post.wasGift! ? "Yes" : "No"),
                  ),
                  _buildInfoBox(
                    "Did your skin have an adverse reaction?",
                    post.adverseReaction == null
                        ? ""
                        : (post.adverseReaction! ? "Yes" : "No"),
                  ),
                  _buildInfoBox(
                    "Describe the texture of this product:",
                    post.texture,
                  ),
                  _buildInfoBox(
                    "How many weeks have you used this product for?",
                    post.usageWeeks,
                  ),
                  if (post.productName.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sell_outlined,
                            color: Color(0xFF444444),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              post.productName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF2A2A2A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  if (post.productImage.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        post.productImage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          height: 220,
                          color: const Color(0xFFF1F1F1),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Builder(
                    builder: (context) {
                      final isLiked = post.likes.contains(widget.currentUserId);

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: _togglePostLike,
                                child: Row(
                                  children: [
                                    Icon(
                                      isLiked
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: isLiked
                                          ? Colors.red
                                          : const Color(0xFF8E8E8E),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${post.likes.length} ${post.likes.length == 1 ? "Like" : "Likes"}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isLiked
                                            ? Colors.red
                                            : const Color(0xFF8E8E8E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color(0xFFE9E9E9),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                  ...sortedComments.map((comment) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatar(
                            userName: comment.userName,
                            userAvatar: comment.userAvatar,
                            radius: 20,
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
                                        comment.userName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF2A2A2A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatPostTime(comment.createdAt),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF9A9A9A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (comment.replyToUserName.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      "Replying to ${comment.replyToUserName}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF5B2333),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                Text(
                                  comment.comment,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: const Color(0xFF2A2A2A),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          replyingToCommentId = comment.id;
                                          replyingToUserName = comment.userName;
                                        });

                                        FocusScope.of(context)
                                            .requestFocus(commentFocusNode);
                                      },
                                      child: Text(
                                        "Reply",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: const Color(0xFF5B2333),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            comment.likes.isNotEmpty
                                ? "${comment.likes.length}"
                                : "",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF9A9A9A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final result = await ApiService.toggleCommentLike(
                                postId: post.id,
                                commentId: comment.id,
                                userId: widget.currentUserId,
                              );

                              if (result["statusCode"] == 200) {
                                await _refreshPost();
                              }
                            },
                            child: Icon(
                              comment.likes.contains(widget.currentUserId)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color:
                                  comment.likes.contains(widget.currentUserId)
                                      ? Colors.red
                                      : const Color(0xFF9A9A9A),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              final isMyComment =
                                  comment.userId == widget.currentUserId;

                              showModalBottomSheet(
                                context: context,
                                builder: (_) {
                                  return SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isMyComment) ...[
                                            ListTile(
                                              title: const Text("Edit Comment"),
                                              onTap: () async {
                                                Navigator.pop(context);
                                                _showEditCommentDialog(comment);
                                              },
                                            ),
                                            ListTile(
                                              title: const Text(
                                                "Delete Comment",
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                              onTap: () async {
                                                Navigator.pop(context);

                                                final success = await ApiService
                                                    .deleteComment(
                                                  postId: post.id,
                                                  commentId: comment.id,
                                                );

                                                if (!mounted) return;

                                                if (success) {
                                                  await _refreshPost();
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            "Comment deleted")),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          "Failed to delete comment"),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ] else ...[
                                            ListTile(
                                              title: const Text("Copy Comment"),
                                              onTap: () async {
                                                Navigator.pop(context);

                                                await Clipboard.setData(
                                                  ClipboardData(
                                                      text: comment.comment),
                                                );

                                                if (!mounted) return;

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          "Comment copied")),
                                                );
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
                              color: Color(0xFF9A9A9A),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEAEAEA)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (replyingToCommentId != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4F3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Replying to $replyingToUserName",
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: const Color(0xFF5B2333),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              replyingToCommentId = null;
                              replyingToUserName = "";
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF5B2333),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE7E7E7)),
                        ),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          controller: commentController,
                          focusNode: commentFocusNode,
                          decoration: InputDecoration(
                            hintText: "Leave a comment...",
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFFB0B0B0),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        if (commentController.text.trim().isEmpty) return;

                        final userProfile = await ApiService.fetchUserProfile(
                          widget.currentUserId,
                        );

                        final result = await ApiService.addComment(
                          postId: post.id,
                          userId: widget.currentUserId,
                          userName: widget.currentUserName,
                          userAvatar: userProfile?.profileImage ?? "",
                          comment: commentController.text.trim(),
                          parentCommentId: replyingToCommentId,
                          replyToUserName: replyingToUserName,
                        );

                        if (result["statusCode"] == 201) {
                          setState(() {
                            post = GroupPostModel(
                              id: post.id,
                              userId: post.userId,
                              userName: post.userName,
                              userAvatar: post.userAvatar,
                              tag: post.tag,
                              postType: post.postType,
                              content: post.content,
                              images: post.images,
                              timeText: post.timeText,
                              isEdited: post.isEdited,
                              createdAt: post.createdAt,
                              rating: post.rating,
                              productName: post.productName,
                              productImage: post.productImage,
                              repurchase: post.repurchase,
                              improvedSkin: post.improvedSkin,
                              wasGift: post.wasGift,
                              adverseReaction: post.adverseReaction,
                              texture: post.texture,
                              usageWeeks: post.usageWeeks,
                              likes: post.likes,
                              groupId: post.groupId,
                              groupTitle: post.groupTitle,
                              groupSlug: post.groupSlug,
                              comments: (result["data"]["comments"] as List)
                                  .map(
                                    (e) => PostCommentModel.fromJson(
                                      Map<String, dynamic>.from(e),
                                    ),
                                  )
                                  .toList(),
                            );
                          });

                          commentController.clear();

                          setState(() {
                            replyingToCommentId = null;
                            replyingToUserName = "";
                          });
                        }
                      },
                      child: Text(
                        "Post",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5B2333),
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
}
