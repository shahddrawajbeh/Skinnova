import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../group_details_screen.dart';
import 'community_models.dart';
import 'community_theme.dart';

/// "Friends are active in" rail — hidden entirely when there is no
/// recent activity from people the current user follows.
class FriendsActiveSlider extends StatelessWidget {
  final List<FriendActivityModel> items;
  final String userId;
  final String userName;

  const FriendsActiveSlider({
    super.key,
    required this.items,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            "Friends are active in",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF202124),
            ),
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailsScreen(
                        groupSlug: item.groupSlug,
                        userId: userId,
                        userName: userName,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CommunityColors.lightBackground,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFEAEAEA),
                        backgroundImage: item.friendAvatar.isNotEmpty
                            ? NetworkImage(item.friendAvatar)
                            : null,
                        child: item.friendAvatar.isEmpty
                            ? Text(
                                item.friendName.isNotEmpty
                                    ? item.friendName[0].toUpperCase()
                                    : "U",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: item.friendName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF202124),
                                    ),
                                  ),
                                  TextSpan(
                                    text: " joined",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      color: const Color(0xFF6B6B6B),
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.groupTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: CommunityColors.wine,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.newPostsCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: CommunityColors.wine,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "+${item.newPostsCount}",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
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
            },
          ),
        ),
      ],
    );
  }
}
