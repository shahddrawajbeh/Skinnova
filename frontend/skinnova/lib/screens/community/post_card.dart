import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api_service.dart';
import '../post_page.dart';
import '../post_details_screen.dart';
import '../product_details_screen.dart';
import 'community_theme.dart';
import 'reaction_bar.dart';

/// Redesigned post card used by the community feed and group pages.
class PostCard extends StatelessWidget {
  final GroupPostModel post;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;
  final String currentUserId;
  final String currentUserName;

  const PostCard({
    super.key,
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
          PostCardHeader(
            post: post,
            onDelete: onDelete,
            currentUserId: currentUserId,
          ),
          const SizedBox(height: 12),
          if (post.postType.toLowerCase() == "review" && post.rating > 0) ...[
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < post.rating.round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFF7C300),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (post.content.trim().isNotEmpty) ...[
            _PostContent(
              post: post,
              currentUserId: currentUserId,
              currentUserName: currentUserName,
              onRefresh: onRefresh,
            ),
            const SizedBox(height: 12),
          ],
          if (post.productName.isNotEmpty) ...[
            AttachedProductCard(
              post: post,
              currentUserId: currentUserId,
              currentUserName: currentUserName,
            ),
            const SizedBox(height: 12),
          ],
          if (post.images.isNotEmpty) ...[
            PostImageGallery(
              images: post.images,
              heroTagPrefix: 'post-${post.id}',
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              ReactionBar(
                post: post,
                currentUserId: currentUserId,
                onChanged: (_) {},
              ),
              const SizedBox(width: 20),
              Expanded(
                child: CommentsSaveRow(
                  post: post,
                  currentUserId: currentUserId,
                  currentUserName: currentUserName,
                  onRefresh: onRefresh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostContent extends StatelessWidget {
  final GroupPostModel post;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback onRefresh;

  const _PostContent({
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    const previewLength = 180;
    final isLong = post.content.length > previewLength;
    final preview =
        isLong ? post.content.substring(0, previewLength).trim() : post.content;

    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          color: const Color(0xFF2A2A2A),
          height: 1.55,
        ),
        children: [
          TextSpan(text: isLong ? "$preview..." : preview),
          if (isLong)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
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
                    " see more",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: CommunityColors.wine,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Header row shared by [PostCard] and [PostDetailsScreen]: avatar, name,
/// post-type badge, optional group chip, time text and the overflow menu.
class PostCardHeader extends StatelessWidget {
  final GroupPostModel post;
  final VoidCallback onDelete;
  final String currentUserId;

  const PostCardHeader({
    super.key,
    required this.post,
    required this.onDelete,
    required this.currentUserId,
  });

  static String formatPostTime(DateTime? createdAt) {
    if (createdAt == null) return "Just now";

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) return "now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";

    return "${createdAt.day}/${createdAt.month}/${createdAt.year}";
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
                      color: CommunityColors.bgFor(post.postType),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      CommunityColors.postTypeLabel(post.postType),
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: CommunityColors.fgFor(post.postType),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
                children: [
                  if (post.groupTitle.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CommunityColors.lightSoftPink,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "📍 ${post.groupTitle}",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: CommunityColors.wine,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public_rounded,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      Text(
                        " · ${formatPostTime(post.createdAt)}${post.isEdited ? " · Edited" : ""}",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFFA0A0A0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

/// Compact card for the product attached to a post (review/question/update/etc).
class AttachedProductCard extends StatelessWidget {
  final GroupPostModel post;
  final String currentUserId;
  final String currentUserName;

  const AttachedProductCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
  });

  Future<void> _open(BuildContext context) async {
    if (post.productId.isEmpty) return;

    try {
      final product = await ApiService.fetchProductById(post.productId);
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(
            product: product,
            userId: currentUserId,
            userName: currentUserName,
          ),
        ),
      );
    } catch (_) {}
  }

  Widget _fallbackThumb() {
    return Container(
      color: const Color(0xFFE9E4E1),
      alignment: Alignment.center,
      child: const Icon(
        Icons.spa_outlined,
        color: Color(0xFFB0B0B0),
        size: 22,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = post.productId.isNotEmpty;

    return GestureDetector(
      onTap: hasLink ? () => _open(context) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
                child: post.productImage.isNotEmpty
                    ? Image.network(
                        post.productImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackThumb(),
                      )
                    : _fallbackThumb(),
              ),
            ),
            const SizedBox(width: 12),
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
            if (hasLink) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: CommunityColors.wine,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "Open Product",
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single-image, two-image and grid layouts with a swipeable, zoomable
/// full-screen viewer.
class PostImageGallery extends StatefulWidget {
  final List<String> images;
  final String heroTagPrefix;

  const PostImageGallery({
    super.key,
    required this.images,
    required this.heroTagPrefix,
  });

  @override
  State<PostImageGallery> createState() => _PostImageGalleryState();
}

class _PostImageGalleryState extends State<PostImageGallery> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _controller.addListener(() {
      final next = _controller.page?.round() ?? 0;
      if (next != _page && mounted) {
        setState(() => _page = next);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenGallery(
          images: widget.images,
          initialIndex: index,
          heroTagPrefix: widget.heroTagPrefix,
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

  Widget _image(String url, int index) {
    return Hero(
      tag: '${widget.heroTagPrefix}-$index',
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    if (widget.images.length == 1) {
      return GestureDetector(
        onTap: () => _openViewer(0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1.08,
            child: _image(widget.images.first, 0),
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 320,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openViewer(index),
                  child: _image(widget.images[index], index),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 7 : 5,
              height: active ? 7 : 5,
              decoration: BoxDecoration(
                color:
                    active ? CommunityColors.wine : const Color(0xFFD8D8D8),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroTagPrefix;

  const _FullScreenGallery({
    required this.images,
    required this.heroTagPrefix,
    this.initialIndex = 0,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Hero(
                    tag: '${widget.heroTagPrefix}-$index',
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small comment-count + save/bookmark row shown under the reaction bar.
class CommentsSaveRow extends StatelessWidget {
  final GroupPostModel post;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback onRefresh;

  const CommentsSaveRow({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailsScreen(
                  post: post,
                  currentUserId: currentUserId,
                  currentUserName: currentUserName,
                  openCommentField: true,
                ),
              ),
            );

            onRefresh();
          },
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: Color(0xFF9A9A9A),
              ),
              const SizedBox(width: 4),
              Text(
                post.comments.isNotEmpty
                    ? "${post.comments.length} ${post.comments.length == 1 ? "Comment" : "Comments"}"
                    : "Comment",
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: const Color(0xFF9A9A9A),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            final result = await ApiService.toggleSavePost(
              userId: currentUserId,
              postId: post.id,
            );

            if (!context.mounted) return;

            if (result["statusCode"] == 200) {
              final isSaved = result["data"]["isSaved"] ?? false;

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
                const SnackBar(content: Text("Failed to save post")),
              );
            }
          },
          child: const Icon(
            Icons.bookmark_border_rounded,
            size: 19,
            color: Color(0xFF9A9A9A),
          ),
        ),
      ],
    );
  }
}
