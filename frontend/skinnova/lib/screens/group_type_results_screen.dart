import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'group_details_screen.dart';
import '../group_model.dart';

class GroupTypeResultsScreen extends StatefulWidget {
  final String title;
  final String groupType;
  final String userId;
  final String userName;

  const GroupTypeResultsScreen({
    super.key,
    required this.title,
    required this.groupType,
    required this.userId,
    required this.userName,
  });

  @override
  State<GroupTypeResultsScreen> createState() => _GroupTypeResultsScreenState();
}

class _GroupTypeResultsScreenState extends State<GroupTypeResultsScreen> {
  List<GroupModel> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  Future<void> loadGroups() async {
    final data = await ApiService.fetchGroupsByType(widget.groupType);
    if (!mounted) return;

    setState(() {
      groups = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                        itemCount: groups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return _AnimatedGroupCard(
                            group: group,
                            groupType: widget.groupType,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GroupDetailsScreen(
                                    groupSlug: group.slug,
                                    userId: widget.userId,
                                    userName: widget.userName,
                                  ),
                                ),
                              );

                              await loadGroups();
                            },
                          );

                          // return GestureDetector(
                          //   onTap: () async {
                          //     await Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (_) => GroupDetailsScreen(
                          //           groupSlug: group.slug,
                          //           userId: widget.userId,
                          //           userName: widget.userName,
                          //         ),
                          //       ),
                          //     );

                          //     await loadGroups();
                          //   },
                          //   child: Container(
                          //     padding: const EdgeInsets.symmetric(
                          //         horizontal: 18, vertical: 18),
                          //     decoration: BoxDecoration(
                          //       color: Colors.white,
                          //       borderRadius: BorderRadius.circular(22),
                          //       border:
                          //           Border.all(color: const Color(0xFFEDE7E7)),
                          //       boxShadow: [
                          //         BoxShadow(
                          //           color: Colors.black.withOpacity(0.04),
                          //           blurRadius: 14,
                          //           offset: const Offset(0, 7),
                          //         ),
                          //       ],
                          //     ),
                          //     child: Row(
                          //       children: [
                          //         Expanded(
                          //           child: Text(
                          //             group.title,
                          //             style: GoogleFonts.poppins(
                          //               fontSize: 16,
                          //               fontWeight: FontWeight.w600,
                          //               color: const Color(0xFF202124),
                          //             ),
                          //           ),
                          //         ),
                          //         Text(
                          //           "${group.membersCount} members",
                          //           style: GoogleFonts.poppins(
                          //             fontSize: 12,
                          //             color: const Color(0xFF9A9A9A),
                          //             fontWeight: FontWeight.w400,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // );
                        },
                      )),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          ),
          const SizedBox(width: 14),
          Text(
            widget.title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedGroupCard extends StatelessWidget {
  final GroupModel group;
  final String groupType;
  final VoidCallback onTap;

  const _AnimatedGroupCard({
    required this.group,
    required this.groupType,
    required this.onTap,
  });

  Color _cardColor(String title) {
    final colors = [
      Color(0xFFF7EDEE),
      Color(0xFFEFF3EE),
      Color(0xFFF6F0E8),
      Color(0xFFEDEFF7),
      Color(0xFFF3EEF7),
      Color(0xFFEFF6F5),
    ];

    return colors[title.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 112,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _cardColor(group.title),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Text(
            group.title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF202124),
            ),
          ),
        ),
      ),
    );
  }
}
