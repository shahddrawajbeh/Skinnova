import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../group_model.dart';
import '../group_details_screen.dart';
import 'community_theme.dart';

/// Horizontal "My Groups" rail shown at the top of the community feed,
/// with a green dot for groups that have new activity in the last 24h
/// and a trailing "Discover" shortcut.
class MyGroupsSlider extends StatelessWidget {
  final List<MyGroupModel> groups;
  final String userId;
  final String userName;
  final VoidCallback? onDiscoverTap;

  const MyGroupsSlider({
    super.key,
    required this.groups,
    required this.userId,
    required this.userName,
    this.onDiscoverTap,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            "My Groups",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF202124),
            ),
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: groups.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == groups.length) {
                return GestureDetector(
                  onTap: onDiscoverTap,
                  child: SizedBox(
                    width: 84,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: CommunityColors.lightBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CommunityColors.dustyRose,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.explore_rounded,
                            color: CommunityColors.wine,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Discover",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: CommunityColors.wine,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final group = groups[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailsScreen(
                        groupSlug: group.slug,
                        userId: userId,
                        userName: userName,
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  width: 84,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  CommunityColors.dustyRose,
                                  CommunityColors.wine,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: GroupAvatar(
                              imageUrl: group.profileImage,
                              seed: group.slug.isNotEmpty
                                  ? group.slug
                                  : group.title,
                              size: 55,
                            ),
                          ),
                          if (group.hasNewActivity)
                            Positioned(
                              top: 0,
                              right: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        group.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF202124),
                        ),
                      ),
                      Text(
                        "${group.membersCount} members",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
