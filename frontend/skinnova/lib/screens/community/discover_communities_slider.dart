import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api_service.dart';
import '../../group_model.dart';
import '../group_details_screen.dart';
import 'community_theme.dart';
import 'join_button.dart';

/// "Discover Communities" rail — suggested groups the user hasn't joined
/// yet, each with a cover image and an inline [JoinButton].
class DiscoverCommunitiesSlider extends StatefulWidget {
  final List<GroupModel> groups;
  final String userId;
  final String userName;

  const DiscoverCommunitiesSlider({
    super.key,
    required this.groups,
    required this.userId,
    required this.userName,
  });

  @override
  State<DiscoverCommunitiesSlider> createState() =>
      _DiscoverCommunitiesSliderState();
}

class _DiscoverCommunitiesSliderState
    extends State<DiscoverCommunitiesSlider> {
  final Set<String> _joinedIds = {};
  final Set<String> _loadingIds = {};

  Future<void> _join(GroupModel group) async {
    if (_loadingIds.contains(group.id)) return;
    setState(() => _loadingIds.add(group.id));
    try {
      await ApiService.joinGroup(slug: group.slug, userId: widget.userId);
      if (mounted) setState(() => _joinedIds.add(group.id));
    } finally {
      if (mounted) setState(() => _loadingIds.remove(group.id));
    }
  }

  Future<void> _leave(GroupModel group) async {
    if (_loadingIds.contains(group.id)) return;
    setState(() => _loadingIds.add(group.id));
    try {
      await ApiService.leaveGroup(slug: group.slug, userId: widget.userId);
      if (mounted) setState(() => _joinedIds.remove(group.id));
    } finally {
      if (mounted) setState(() => _loadingIds.remove(group.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            "Discover Communities",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF202124),
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final group = widget.groups[index];
              final isJoined = _joinedIds.contains(group.id);
              final isLoading = _loadingIds.contains(group.id);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailsScreen(
                        groupSlug: group.slug,
                        userId: widget.userId,
                        userName: widget.userName,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFEAEAEA),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      group.coverImage.isNotEmpty
                          ? Image.network(
                              group.coverImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: CommunityColors.lightSoftPink,
                              ),
                            )
                          : Container(color: CommunityColors.lightSoftPink),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.65),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${group.membersCount} members",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            JoinButton(
                              isJoined: isJoined,
                              isLoading: isLoading,
                              onJoin: () => _join(group),
                              onLeave: () => _leave(group),
                            ),
                          ],
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
