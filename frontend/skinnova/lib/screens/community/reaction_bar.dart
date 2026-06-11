import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api_service.dart';
import '../post_page.dart';
import 'community_theme.dart';

/// Tap to toggle the default "helpful" reaction; long-press to pick
/// from the full set of reactions ([kReactions]).
class ReactionBar extends StatefulWidget {
  final GroupPostModel post;
  final String currentUserId;
  final ValueChanged<List<PostReaction>> onChanged;

  const ReactionBar({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onChanged,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar>
    with SingleTickerProviderStateMixin {
  late List<PostReaction> reactions;
  bool isLoading = false;
  final List<OverlayEntry> _overlayEntries = [];
  late final AnimationController _popController;
  late final Animation<double> _popScale;

  @override
  void initState() {
    super.initState();
    reactions = List<PostReaction>.from(widget.post.reactions);

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _popController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _removeOverlay();
    _popController.dispose();
    super.dispose();
  }

  String? get _myReaction {
    for (final r in reactions) {
      if (r.userId == widget.currentUserId) return r.type;
    }
    return null;
  }

  Future<void> _toggle(String type) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    final result = await ApiService.toggleReaction(
      postId: widget.post.id,
      userId: widget.currentUserId,
      type: type,
    );

    if (result["statusCode"] == 200) {
      final updated = (result["data"]["reactions"] as List? ?? [])
          .map((e) => PostReaction.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (mounted) {
        setState(() => reactions = updated);
        _popController.forward(from: 0);
      }
      widget.onChanged(updated);
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _removeOverlay() {
    for (final entry in _overlayEntries) {
      entry.remove();
    }
    _overlayEntries.clear();
  }

  void _showPicker(BuildContext context, Offset globalPosition) {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    const pickerWidth = 180.0;

    final left = (globalPosition.dx - pickerWidth / 2)
        .clamp(8.0, screenSize.width - pickerWidth - 8.0);
    final top = (globalPosition.dy - 70).clamp(8.0, screenSize.height - 80.0);

    final scrim = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _removeOverlay,
        ),
      ),
    );

    final picker = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        child: _ReactionPicker(
          onSelect: (type) {
            _removeOverlay();
            _toggle(type);
          },
        ),
      ),
    );

    _overlayEntries.addAll([scrim, picker]);
    overlay.insert(scrim);
    overlay.insert(picker);
  }

  @override
  Widget build(BuildContext context) {
    final myType = _myReaction;
    final myReaction = reactionByType(myType);
    final total = reactions.length;

    return GestureDetector(
      onTap: isLoading ? null : () => _toggle('helpful'),
      onLongPressStart: (details) =>
          _showPicker(context, details.globalPosition),
      child: ScaleTransition(
        scale: _popScale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: myReaction != null
                ? CommunityColors.lightSoftPink
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                myReaction?.emoji ?? '🤍',
                style: const TextStyle(fontSize: 17),
              ),
              const SizedBox(width: 6),
              Text(
                total > 0 ? "$total" : "React",
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight:
                      myReaction != null ? FontWeight.w600 : FontWeight.w400,
                  color: myReaction != null
                      ? CommunityColors.wine
                      : const Color(0xFF9A9A9A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionPicker extends StatefulWidget {
  final ValueChanged<String> onSelect;

  const _ReactionPicker({required this.onSelect});

  @override
  State<_ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<_ReactionPicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(kReactions.length, (i) {
            final reaction = kReactions[i];
            final start = i * 0.12;
            final animation = CurvedAnimation(
              parent: _controller,
              curve: Interval(start, (start + 0.6).clamp(0.0, 1.0),
                  curve: Curves.elasticOut),
            );

            return ScaleTransition(
              scale: animation,
              child: GestureDetector(
                onTap: () => widget.onSelect(reaction.type),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reaction.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                      Text(
                        reaction.label,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF9A9A9A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
