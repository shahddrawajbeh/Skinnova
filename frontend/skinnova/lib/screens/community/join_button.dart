import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'community_theme.dart';

/// A pill button that morphs between "Join" and "Joined" states, used by
/// [DiscoverCommunitiesSlider] and the group details header.
class JoinButton extends StatelessWidget {
  final bool isJoined;
  final bool isLoading;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const JoinButton({
    super.key,
    required this.isJoined,
    required this.isLoading,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : (isJoined ? onLeave : onJoin),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isJoined ? const Color(0xFF202124) : CommunityColors.wine,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isJoined ? Icons.check_rounded : Icons.add_rounded,
                key: ValueKey(isJoined),
                color: Colors.white,
                size: 15,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isLoading
                  ? (isJoined ? "Leaving..." : "Joining...")
                  : (isJoined ? "Joined" : "Join"),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
