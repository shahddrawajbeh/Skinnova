import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'post_page.dart';
import 'post_details_screen.dart';

class PublicUserPostsScreen extends StatelessWidget {
  final List<GroupPostModel> posts;
  final String currentUserId;
  final String currentUserName;

  const PublicUserPostsScreen({
    super.key,
    required this.posts,
    required this.currentUserId,
    required this.currentUserName,
  });

  static const Color textDark = Color(0xFF202124);
  static const Color lightBorder = Color(0xFFF7F4F3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: posts.isEmpty
                  ? Center(
                      child: Text(
                        "No posts to show yet.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _postCard(context, posts[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                "Posts",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _postCard(BuildContext context, GroupPostModel post) {
    final image =
        post.images.isNotEmpty ? post.images.first : post.productImage;

    return GestureDetector(
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
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: lightBorder, width: 1.3),
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
                height: 1.4,
                color: textDark,
              ),
            ),
            const SizedBox(height: 14),
            if (image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  image,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.favorite_border_rounded,
                    size: 20, color: Colors.grey),
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
}
