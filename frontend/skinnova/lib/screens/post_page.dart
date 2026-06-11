import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'select_review_product_screen.dart';
import '../api_service.dart';
import '../group_model.dart';
import 'question_post_screen.dart';
import 'update_post_screen.dart';
import 'search_posts_screen.dart';
import 'community/community_theme.dart';
import 'community/community_models.dart';
import 'community/community_filter_chips.dart';
import 'community/my_groups_slider.dart';
import 'community/friends_active_slider.dart';
import 'community/discover_communities_slider.dart';
import 'community/community_fab.dart';
import 'community/post_card.dart';

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

class PostReaction {
  final String userId;
  final String type;

  const PostReaction({required this.userId, required this.type});

  factory PostReaction.fromJson(Map<String, dynamic> json) {
    return PostReaction(
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
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
  final String productId;
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
  final List<PostReaction> reactions;
  final bool isPinned;

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
    this.productId = "",
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
    this.reactions = const [],
    this.isPinned = false,
  });

  Map<String, int> get reactionCounts {
    final counts = <String, int>{};
    for (final r in reactions) {
      counts[r.type] = (counts[r.type] ?? 0) + 1;
    }
    return counts;
  }

  String? userReactionType(String userId) {
    for (final r in reactions) {
      if (r.userId == userId) return r.type;
    }
    return null;
  }

  int get totalReactions => reactions.length;

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
      productId: json['productId']?.toString() ?? '',
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
      reactions: (json['reactions'] as List? ?? [])
          .map((e) => PostReaction.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      isPinned: json['isPinned'] ?? false,
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
  List<MyGroupModel> myGroups = [];
  List<FriendActivityModel> friendsActivity = [];
  List<GroupModel> suggestedGroups = [];

  String selectedFilter = 'all';
  bool isFeedLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    loadFeed(reset: true);
    _loadSliders();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || isFeedLoading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadSliders() async {
    try {
      final results = await Future.wait([
        ApiService.fetchMyGroups(widget.userId),
        ApiService.fetchFriendsActivity(widget.userId),
        ApiService.fetchSuggestedGroups(widget.userId),
      ]);

      if (!mounted) return;

      setState(() {
        myGroups = results[0] as List<MyGroupModel>;
        friendsActivity = results[1] as List<FriendActivityModel>;
        suggestedGroups = results[2] as List<GroupModel>;
      });
    } catch (e) {
      // Sliders are optional embellishments — ignore failures.
    }
  }

  Future<void> loadFeed({bool reset = true}) async {
    if (reset) {
      setState(() {
        isFeedLoading = true;
        _page = 1;
        _hasMore = true;
      });
    }

    try {
      final data = await ApiService.fetchFeed(
        userId: widget.userId,
        filter: selectedFilter,
        page: 1,
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        posts = data;
        _hasMore = data.length == 10;
        isFeedLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isFeedLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final nextPage = _page + 1;

    try {
      final data = await ApiService.fetchFeed(
        userId: widget.userId,
        filter: selectedFilter,
        page: nextPage,
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        posts = [...posts, ...data];
        _page = nextPage;
        _hasMore = data.length == 10;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _onFilterSelected(String filter) {
    if (filter == selectedFilter) return;
    setState(() => selectedFilter = filter);
    loadFeed(reset: true);
  }

  void _scrollToDiscover() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.offset + 420)
          .clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 78),
        child: CommunityFab(
          userId: widget.userId,
          userName: widget.userName,
          onPosted: () => loadFeed(reset: true),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: CommunityColors.wine,
          onRefresh: () async {
            await Future.wait([loadFeed(reset: true), _loadSliders()]);
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(
                child: MyGroupsSlider(
                  groups: myGroups,
                  userId: widget.userId,
                  userName: widget.userName,
                  onDiscoverTap: _scrollToDiscover,
                ),
              ),
              SliverToBoxAdapter(
                child: FriendsActiveSlider(
                  items: friendsActivity,
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
              SliverToBoxAdapter(
                child: DiscoverCommunitiesSlider(
                  groups: suggestedGroups,
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterChipsHeaderDelegate(
                  selected: selectedFilter,
                  onSelected: _onFilterSelected,
                ),
              ),
              if (isFeedLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: PostCardSkeleton(),
                    ),
                    childCount: 3,
                  ),
                )
              else if (posts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == posts.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: _hasMore
                                ? const CircularProgressIndicator()
                                : const SizedBox.shrink(),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FadeSlideIn(
                          delay: Duration(milliseconds: 40 * (index % 8)),
                          child: PostCard(
                            post: posts[index],
                            onDelete: () => loadFeed(reset: true),
                            onRefresh: () => loadFeed(reset: true),
                            currentUserId: widget.userId,
                            currentUserName: widget.userName,
                          ),
                        ),
                      );
                    },
                    childCount: posts.length + 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Center(
        child: Text(
          "Community",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5B2333),
          ),
        ),
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

class _FilterChipsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String selected;
  final ValueChanged<String> onSelected;

  _FilterChipsHeaderDelegate({required this.selected, required this.onSelected});

  @override
  double get minExtent => 46;

  @override
  double get maxExtent => 46;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF8F8F8),
      alignment: Alignment.center,
      child: CommunityFilterChips(selected: selected, onSelected: onSelected),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterChipsHeaderDelegate oldDelegate) {
    return oldDelegate.selected != selected;
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
