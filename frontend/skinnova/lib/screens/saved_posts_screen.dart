import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'post_page.dart';
import 'post_details_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const SavedPostsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<GroupPostModel> savedPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSavedPosts();
  }

  Future<void> _removeSavedPost(String postId) async {
    final result = await ApiService.toggleSavePost(
      userId: widget.userId,
      postId: postId,
    );

    if (!mounted) return;

    if (result["statusCode"] == 200) {
      setState(() {
        savedPosts.removeWhere((post) => post.id == postId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Removed from saved posts"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to remove post"),
        ),
      );
    }
  }

  Future<void> loadSavedPosts() async {
    try {
      final data = await ApiService.fetchSavedPosts(widget.userId);

      if (!mounted) return;

      setState(() {
        savedPosts = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildAvatar({
    required String userName,
    required String userAvatar,
    double radius = 20,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          "Saved Posts",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : savedPosts.isEmpty
              ? Center(
                  child: Text(
                    "No saved posts yet",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF777777),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: savedPosts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final post = savedPosts[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailsScreen(
                              post: post,
                              currentUserId: widget.userId,
                              currentUserName: widget.userName,
                            ),
                          ),
                        ).then((_) => loadSavedPosts());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildAvatar(
                                  userName: post.userName,
                                  userAvatar: post.userAvatar,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    post.userName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: const Color(0xFF2A2A2A),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _removeSavedPost(post.id),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F7F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.bookmark_rounded,
                                      color: Color(0xFF202124),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (post.productName.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  post.productName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF2A2A2A),
                                  ),
                                ),
                              ),
                            if (post.productName.isNotEmpty)
                              const SizedBox(height: 12),
                            if (post.content.isNotEmpty)
                              Text(
                                post.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF444444),
                                  height: 1.5,
                                ),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              "${post.likes.length} Likes • ${post.comments.length} Comments",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF9A9A9A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
