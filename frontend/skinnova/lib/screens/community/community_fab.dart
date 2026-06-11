import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../question_post_screen.dart';
import '../select_review_product_screen.dart';
import '../update_post_screen.dart';
import 'community_theme.dart';
import 'generic_post_screen.dart';

class _FabOption {
  final IconData icon;
  final String label;
  final Color color;
  final Future<void> Function() onTap;

  const _FabOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Expandable "create post" FAB. Tapping the main button reveals 6
/// staggered mini-options behind a dismissible scrim; tapping again (or
/// the scrim) collapses it.
class CommunityFab extends StatefulWidget {
  final String userId;
  final String userName;
  final VoidCallback onPosted;

  const CommunityFab({
    super.key,
    required this.userId,
    required this.userName,
    required this.onPosted,
  });

  @override
  State<CommunityFab> createState() => _CommunityFabState();
}

class _CommunityFabState extends State<CommunityFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOpen = false;
  final List<OverlayEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    for (final entry in _entries) {
      entry.remove();
    }
    _entries.clear();
  }

  Future<void> _openScreen(Widget screen) async {
    _close();
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (posted == true) widget.onPosted();
  }

  List<_FabOption> get _options => [
        _FabOption(
          icon: Icons.help_outline_rounded,
          label: "Ask Question",
          color: CommunityColors.bgFor('question'),
          onTap: () => _openScreen(QuestionPostScreen(
            userId: widget.userId,
            userName: widget.userName,
          )),
        ),
        _FabOption(
          icon: Icons.rate_review_outlined,
          label: "Review Product",
          color: CommunityColors.bgFor('review'),
          onTap: () => _openScreen(SelectReviewProductScreen(
            userId: widget.userId,
            userName: widget.userName,
          )),
        ),
        _FabOption(
          icon: Icons.spa_outlined,
          label: "Share Routine",
          color: CommunityColors.bgFor('routine'),
          onTap: () => _openScreen(GenericPostScreen(
            userId: widget.userId,
            userName: widget.userName,
            postType: "routine",
          )),
        ),
        _FabOption(
          icon: Icons.lightbulb_outline_rounded,
          label: "Tip",
          color: CommunityColors.bgFor('tip'),
          onTap: () => _openScreen(GenericPostScreen(
            userId: widget.userId,
            userName: widget.userName,
            postType: "tip",
          )),
        ),
        _FabOption(
          icon: Icons.compare_rounded,
          label: "Before & After",
          color: CommunityColors.bgFor('before_after'),
          onTap: () => _openScreen(GenericPostScreen(
            userId: widget.userId,
            userName: widget.userName,
            postType: "before_after",
            minImages: 2,
          )),
        ),
        _FabOption(
          icon: Icons.image_outlined,
          label: "Photo",
          color: CommunityColors.bgFor('update'),
          onTap: () => _openScreen(UpdatePostScreen(
            userId: widget.userId,
            userName: widget.userName,
          )),
        ),
      ];

  void _toggle() => _isOpen ? _close() : _open();

  void _open() {
    setState(() => _isOpen = true);
    _controller.forward();

    final overlay = Overlay.of(context);
    final options = _options;

    final scrim = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _close,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Container(
              color: Colors.black.withOpacity(0.35 * _controller.value),
            ),
          ),
        ),
      ),
    );

    final menu = OverlayEntry(
      builder: (_) => Positioned(
        right: 16,
        bottom: 166,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(options.length, (i) {
            final reverseIndex = options.length - 1 - i;
            final start = reverseIndex * 0.08;
            final animation = CurvedAnimation(
              parent: _controller,
              curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
                  curve: Curves.easeOutBack),
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ScaleTransition(
                scale: animation,
                alignment: Alignment.bottomRight,
                child: FadeTransition(
                  opacity: animation,
                  child: _MiniFabOption(option: options[i]),
                ),
              ),
            );
          }),
        ),
      ),
    );

    _entries.addAll([scrim, menu]);
    overlay.insert(scrim);
    overlay.insert(menu);
  }

  void _close() {
    _controller.reverse().whenCompleteOrCancel(_removeOverlay);
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _toggle,
      backgroundColor: CommunityColors.wine,
      elevation: 3,
      child: AnimatedRotation(
        turns: _isOpen ? 0.125 : 0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _MiniFabOption extends StatelessWidget {
  final _FabOption option;

  const _MiniFabOption({required this.option});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: option.onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              option.label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2A2A2A),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: option.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              option.icon,
              color: option.color.computeLuminance() > 0.5
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
