import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../group_model.dart';
import '../product_model.dart';
import 'product_details_screen.dart';
import '../app_user_model.dart';
import 'post_page.dart';
import 'question_post_screen.dart';
import 'public_profile_screen.dart';
import '../medication_model.dart';
import 'medication_details_screen.dart';
import 'community/community_theme.dart';
import 'community/post_card.dart';
import 'community/join_button.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupSlug;
  final String userId;
  final String userName;

  const GroupDetailsScreen({
    super.key,
    required this.groupSlug,
    required this.userId,
    required this.userName,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  GroupModel? group;
  List<ProductModel> products = [];
  bool isLoading = true;

  bool isJoined = false;
  bool isJoining = false;
  List<AppUserModel> people = [];
  bool peopleLoading = true;
  int selectedGroupTab = 0; // 0 = People, 1 = Discussion
  List<GroupPostModel> discussionPosts = [];
  bool discussionLoading = true;
  List<MedicationModel> medications = [];
  bool medicationsLoading = true;
  Set<String> followedUserIds = {};
  List<GroupMemberModel> members = [];
  bool membersLoading = true;

  @override
  void initState() {
    super.initState();
    loadGroupData();
  }

  Future<void> loadGroupData() async {
    try {
      final loadedGroup = await ApiService.fetchGroupBySlug(widget.groupSlug);

      List<ProductModel> loadedProducts = [];
      List<AppUserModel> loadedPeople = [];
      final currentUser = await ApiService.fetchUserProfile(widget.userId);

      if (loadedGroup.groupType == "product_categories") {
        loadedProducts = await ApiService.fetchGroupProducts(widget.groupSlug);
        discussionPosts = await ApiService.fetchProductCategoryDiscussionPosts(
            widget.groupSlug);
        discussionLoading = false;
      } else if (loadedGroup.groupType == "medications") {
        loadedProducts = await ApiService.fetchProductsByConcern(
          loadedGroup.categoryKey,
        );

        loadedPeople = await ApiService.fetchGroupPeople(widget.groupSlug);

        discussionPosts = await ApiService.fetchMedicationDiscussionPosts(
          widget.groupSlug,
        );

        medications = await ApiService.fetchMedicationsByCondition(
          loadedGroup.title,
        );

        discussionLoading = false;
        medicationsLoading = false;
      } else {
        loadedPeople = await ApiService.fetchGroupPeople(widget.groupSlug);
        discussionPosts = await ApiService.fetchPostsByGroup(widget.groupSlug);
        discussionLoading = false;
      }
      final joined = await ApiService.fetchJoinStatus(
        slug: widget.groupSlug,
        userId: widget.userId,
      );

      if (!mounted) return;

      setState(() {
        group = loadedGroup;
        products = loadedProducts;
        people = loadedPeople;
        isJoined = joined;
        followedUserIds = currentUser?.following.map((u) => u.id).toSet() ?? {};
        isLoading = false;
        peopleLoading = false;
      });

      _loadMembers();
    } catch (e) {
      debugPrint("GROUP DETAILS ERROR: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
        peopleLoading = false;
      });
    }
  }

  Future<void> _loadMembers() async {
    try {
      final loadedMembers = await ApiService.fetchGroupMembers(
        widget.groupSlug,
        widget.userId,
      );

      if (!mounted) return;

      setState(() {
        members = loadedMembers;
        membersLoading = false;
        for (final m in loadedMembers) {
          if (m.isFollowedByMe) followedUserIds.add(m.id);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => membersLoading = false);
    }
  }

  Future<void> _joinGroup() async {
    if (isJoined || isJoining) return;

    setState(() {
      isJoining = true;
    });

    try {
      await ApiService.joinGroup(
        slug: widget.groupSlug,
        userId: widget.userId,
      );

      if (!mounted) return;

      setState(() {
        isJoined = true;
        if (group != null) {
          group = GroupModel(
            id: group!.id,
            title: group!.title,
            slug: group!.slug,
            coverImage: group!.coverImage,
            profileImage: group!.profileImage,
            description: group!.description,
            categoryKey: group!.categoryKey,
            membersCount: group!.membersCount + 1,
            isActive: group!.isActive,
            groupType: group!.groupType,
          );
        }
      });

      _showPrettySnackBar(
        message: "Joined successfully",
        icon: Icons.check_rounded,
      );
    } catch (e) {
      _showPrettySnackBar(
        message: "Failed to join group",
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isJoining = false;
      });
    }
  }

  Future<void> _leaveGroup() async {
    if (!isJoined || isJoining) return;

    setState(() {
      isJoining = true;
    });

    try {
      await ApiService.leaveGroup(
        slug: widget.groupSlug,
        userId: widget.userId,
      );

      if (!mounted) return;

      setState(() {
        isJoined = false;
        if (group != null && group!.membersCount > 0) {
          group = GroupModel(
            id: group!.id,
            title: group!.title,
            slug: group!.slug,
            coverImage: group!.coverImage,
            profileImage: group!.profileImage,
            description: group!.description,
            categoryKey: group!.categoryKey,
            membersCount: group!.membersCount - 1,
            isActive: group!.isActive,
            groupType: group!.groupType,
          );
        }
      });

      _showPrettySnackBar(
        message: "Left group successfully",
        icon: Icons.logout_rounded,
      );
    } catch (e) {
      _showPrettySnackBar(
        message: "Failed to leave group",
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isJoining = false;
      });
    }
  }

  void _showPrettySnackBar({
    required String message,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF202124),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (group == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Group not found")),
      );
    }
    final bool isMedicationGroup = group!.groupType == "medications";
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Group",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF202124),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    //if (!isMedicationGroup)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: isMedicationGroup
                              ? Container(color: Colors.white)
                              : GroupCoverImage(
                                  imageUrl: group!.coverImage,
                                  seed: group!.slug.isNotEmpty
                                      ? group!.slug
                                      : group!.title,
                                  height: 180,
                                  width: double.infinity,
                                ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: JoinButton(
                            isJoined: isJoined,
                            isLoading: isJoining,
                            onJoin: _joinGroup,
                            onLeave: _leaveGroup,
                          ),
                        ),
                        Positioned(
                          bottom: -50,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: GroupAvatar(
                                imageUrl: group!.profileImage,
                                seed: group!.slug.isNotEmpty
                                    ? group!.slug
                                    : group!.title,
                                size: 102,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMedicationGroup ? 18 : 70),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            group!.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF202124),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${group!.membersCount} members",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (group!.description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              group!.description,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // _buildProductsList(),
                    group!.groupType == "product_categories"
                        ? _buildProductsAndDiscussionTabs()
                        : group!.groupType == "medications"
                            ? _buildMedicationGroupTabs()
                            : group!.groupType == "skin_tones"
                                ? _buildPeopleOnlySection()
                                : _buildPeopleAndDiscussionTabs(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationGroupTabs() {
    final tabs = [
      "Products",
      "Members",
      "Discussion",
      "Medications",
      "Media",
      "Pinned",
    ];

    return Column(
      children: [
        _buildTabBar(tabs),
        const SizedBox(height: 18),
        if (selectedGroupTab == 0)
          _buildProductsList()
        else if (selectedGroupTab == 1)
          _buildMembersTab()
        else if (selectedGroupTab == 2)
          _buildDiscussionPlaceholder()
        else if (selectedGroupTab == 3)
          _buildMedicationsList()
        else if (selectedGroupTab == 4)
          _buildMediaTab()
        else
          _buildPinnedTab(),
      ],
    );
  }

  Widget _buildMedicationsList() {
    if (medicationsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (medications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "No medications found",
          style: GoogleFonts.poppins(fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: medications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final med = medications[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicationDetailsScreen(medication: med),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDEDED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Sold as: ${med.soldAs.join(", ")}",
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  med.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "See more",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsAndDiscussionTabs() {
    final tabs = ["Products", "Discussion", "Media", "Pinned"];

    return Column(
      children: [
        _buildTabBar(tabs),
        const SizedBox(height: 18),
        if (selectedGroupTab == 0)
          _buildProductsList()
        else if (selectedGroupTab == 1)
          _buildDiscussionPlaceholder()
        else if (selectedGroupTab == 2)
          _buildMediaTab()
        else
          _buildPinnedTab(),
      ],
    );
  }

  Widget _buildPeopleOnlySection() {
    return Column(
      children: [
        Text(
          "People",
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5B2333),
          ),
        ),
        const SizedBox(height: 18),
        _buildPeopleList(),
      ],
    );
  }

  Widget _buildPeopleAndDiscussionTabs() {
    final tabs = ["Members", "Discussion", "Media", "Pinned"];

    return Column(
      children: [
        _buildTabBar(tabs),
        const SizedBox(height: 18),
        if (selectedGroupTab == 0)
          _buildMembersTab()
        else if (selectedGroupTab == 1)
          _buildDiscussionPlaceholder()
        else if (selectedGroupTab == 2)
          _buildMediaTab()
        else
          _buildPinnedTab(),
      ],
    );
  }

  Widget _buildTabBar(List<String> tabs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(tabs.length, (index) {
        final selected = selectedGroupTab == index;

        return GestureDetector(
          onTap: () => setState(() => selectedGroupTab = index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tabs[index],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? const Color(0xFF202124) : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 38,
                height: 2,
                color:
                    selected ? const Color(0xFF202124) : Colors.transparent,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPeopleList() {
    return peopleLoading
        ? const Center(child: CircularProgressIndicator())
        : people.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "No people found",
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: people.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final user = people[index];

                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PublicProfileScreen(
                            viewedUserId: user.id,
                            currentUserId: widget.userId,
                          ),
                        ),
                      );

                      await loadGroupData();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: user.profileImage.isNotEmpty
                                ? NetworkImage(user.profileImage)
                                : null,
                            child: user.profileImage.isEmpty
                                ? Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName[0].toUpperCase()
                                        : "U",
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          user.id == widget.userId
                              ? const SizedBox()
                              : GestureDetector(
                                  onTap: () async {
                                    final alreadyFollowing =
                                        followedUserIds.contains(user.id);

                                    final success = alreadyFollowing
                                        ? await ApiService.unfollowUser(
                                            targetUserId: user.id,
                                            currentUserId: widget.userId,
                                          )
                                        : await ApiService.followUser(
                                            targetUserId: user.id,
                                            currentUserId: widget.userId,
                                          );

                                    if (success) {
                                      setState(() {
                                        if (alreadyFollowing) {
                                          followedUserIds.remove(user.id);
                                        } else {
                                          followedUserIds.add(user.id);
                                        }
                                      });

                                      _showPrettySnackBar(
                                        message: alreadyFollowing
                                            ? "Unfollowed successfully"
                                            : "Followed successfully",
                                        icon: Icons.check_rounded,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: followedUserIds.contains(user.id)
                                          ? Colors.white
                                          : const Color(0xFF5B2333),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: followedUserIds.contains(user.id)
                                            ? const Color(0xFFE0E0E0)
                                            : const Color(0xFF5B2333),
                                      ),
                                    ),
                                    child: Text(
                                      followedUserIds.contains(user.id)
                                          ? "Following"
                                          : "Follow",
                                      style: GoogleFonts.poppins(
                                        color: followedUserIds.contains(user.id)
                                            ? const Color(0xFF202124)
                                            : Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  );
                },
              );
  }

  Widget _buildMembersTab() {
    if (membersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "No members yet",
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final member = members[index];

        return FadeSlideIn(
          delay: Duration(milliseconds: 50 * index),
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicProfileScreen(
                    viewedUserId: member.id,
                    currentUserId: widget.userId,
                  ),
                ),
              );

              await loadGroupData();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: member.profileImage.isNotEmpty
                        ? NetworkImage(member.profileImage)
                        : null,
                    child: member.profileImage.isEmpty
                        ? Text(
                            member.fullName.isNotEmpty
                                ? member.fullName[0].toUpperCase()
                                : "U",
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.fullName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (member.isMutual) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: CommunityColors.lightSoftPink,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Mutual",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: CommunityColors.wine,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Joined ${PostCardHeader.formatPostTime(member.joinedAt)}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  member.id == widget.userId
                      ? const SizedBox()
                      : GestureDetector(
                          onTap: () async {
                            final alreadyFollowing =
                                followedUserIds.contains(member.id);

                            final success = alreadyFollowing
                                ? await ApiService.unfollowUser(
                                    targetUserId: member.id,
                                    currentUserId: widget.userId,
                                  )
                                : await ApiService.followUser(
                                    targetUserId: member.id,
                                    currentUserId: widget.userId,
                                  );

                            if (success) {
                              setState(() {
                                if (alreadyFollowing) {
                                  followedUserIds.remove(member.id);
                                } else {
                                  followedUserIds.add(member.id);
                                }
                              });

                              _showPrettySnackBar(
                                message: alreadyFollowing
                                    ? "Unfollowed successfully"
                                    : "Followed successfully",
                                icon: Icons.check_rounded,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: followedUserIds.contains(member.id)
                                  ? Colors.white
                                  : CommunityColors.wine,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: followedUserIds.contains(member.id)
                                    ? const Color(0xFFE0E0E0)
                                    : CommunityColors.wine,
                              ),
                            ),
                            child: Text(
                              followedUserIds.contains(member.id)
                                  ? "Following"
                                  : "Follow",
                              style: GoogleFonts.poppins(
                                color: followedUserIds.contains(member.id)
                                    ? const Color(0xFF202124)
                                    : Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaTab() {
    if (discussionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final images = discussionPosts.expand((p) => p.images).toList();

    if (images.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "No media yet",
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _MediaViewerScreen(
                images: images,
                initialIndex: index,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF1F1F1),
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Color(0xFFB0B0B0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinnedTab() {
    if (discussionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pinnedPosts = discussionPosts.where((p) => p.isPinned).toList();

    if (pinnedPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          "No pinned posts yet",
          style: GoogleFonts.poppins(fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: pinnedPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return PostCard(
          post: pinnedPosts[index],
          currentUserId: widget.userId,
          currentUserName: widget.userName,
          onDelete: loadGroupData,
          onRefresh: loadGroupData,
        );
      },
    );
  }

  // Widget _buildDiscussionPlaceholder() {
  //   return discussionLoading
  //       ? const Center(child: CircularProgressIndicator())
  //       : discussionPosts.isEmpty
  //           ? Padding(
  //               padding: const EdgeInsets.all(24),
  //               child: Text(
  //                 "No discussions yet",
  //                 style: GoogleFonts.poppins(fontSize: 15),
  //               ),
  //             )
  //           : ListView.separated(
  //               shrinkWrap: true,
  //               physics: const NeverScrollableScrollPhysics(),
  //               padding: const EdgeInsets.only(bottom: 20),
  //               itemCount: discussionPosts.length,
  //               separatorBuilder: (_, __) => const SizedBox(height: 8),
  //               itemBuilder: (context, index) {
  //                 return PostCard(
  //                   post: discussionPosts[index],
  //                   currentUserId: widget.userId,
  //                   currentUserName: widget.userName,
  //                   onDelete: loadGroupData,
  //                   onRefresh: loadGroupData,
  //                 );
  //               },
  //             );
  // }
  Widget _buildDiscussionPlaceholder() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () async {
              final posted = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => QuestionPostScreen(
                    userId: widget.userId,
                    userName: widget.userName,
                    fixedGroup: group!,
                  ),
                ),
              );

              if (posted == true) {
                await loadGroupData();
              }
            },
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Text(
                  "Add Post +",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        discussionLoading
            ? const Center(child: CircularProgressIndicator())
            : discussionPosts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      "No discussions yet",
                      style: GoogleFonts.poppins(fontSize: 15),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: discussionPosts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return PostCard(
                        post: discussionPosts[index],
                        currentUserId: widget.userId,
                        currentUserName: widget.userName,
                        onDelete: loadGroupData,
                        onRefresh: loadGroupData,
                      );
                    },
                  ),
      ],
    );
  }

  Widget _buildProductsList() {
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "No products found",
          style: GoogleFonts.poppins(fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final product = products[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(
                  product: product,
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported_outlined),
                        ),
                      )
                    : const Icon(Icons.image_not_supported_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF444444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MediaViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _MediaViewerScreen({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<_MediaViewerScreen> {
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
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
