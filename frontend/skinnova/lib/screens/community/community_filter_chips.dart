import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'community_theme.dart';

/// Sticky horizontal row of feed-filter pill chips.
class CommunityFilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const CommunityFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const List<Map<String, String>> filters = [
    {'key': 'all', 'label': 'All'},
    {'key': 'myGroups', 'label': 'My Groups'},
    {'key': 'following', 'label': 'Following'},
    {'key': 'question', 'label': 'Questions'},
    {'key': 'tip', 'label': 'Tips'},
    {'key': 'review', 'label': 'Reviews'},
    {'key': 'routine', 'label': 'Routine'},
    {'key': 'before_after', 'label': 'Before & After'},
    {'key': 'trending', 'label': 'Trending'},
    {'key': 'latest', 'label': 'Latest'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selected == filter['key'];

          return GestureDetector(
            onTap: () => onSelected(filter['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? CommunityColors.wine
                    : CommunityColors.lightBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : const Color(0xFF6B6B6B),
                ),
                child: Text(filter['label']!),
              ),
            ),
          );
        },
      ),
    );
  }
}
