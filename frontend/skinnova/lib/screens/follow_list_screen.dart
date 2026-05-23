import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../user_model.dart';
import 'public_profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final String title;
  final String profileUserId;
  final String currentUserId;

  const FollowListScreen({
    super.key,
    required this.title,
    required this.profileUserId,
    required this.currentUserId,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  bool isLoading = true;
  List<FollowUserModel> users = [];
  bool hasChanged = false;

  @override
  void initState() {
    super.initState();
    loadFollowUsers();
  }

  Future<void> loadFollowUsers() async {
    final profileUser = await ApiService.fetchUserProfile(widget.profileUserId);

    if (!mounted) return;

    setState(() {
      if (widget.title == "Followers") {
        users = profileUser?.followers ?? [];
      } else {
        users = profileUser?.following ?? [];
      }

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, hasChanged);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF202124),
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF202124)),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : users.isEmpty
                ? Center(
                    child: Text(
                      "No users yet",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = users[index];

                      return GestureDetector(
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PublicProfileScreen(
                                viewedUserId: user.id,
                                currentUserId: widget.currentUserId,
                              ),
                            ),
                          );

                          if (updated == true) {
                            hasChanged = true;
                            await loadFollowUsers();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFF0F0F0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
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
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
