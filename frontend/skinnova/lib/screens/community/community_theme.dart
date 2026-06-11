import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

export '../admin_widgets.dart' show FadeSlideIn;

/// Shared color tokens + helpers for the redesigned Community section.
class CommunityColors {
  static const wine = AppColors.wine;
  static const dustyRose = AppColors.dustyRose;
  static const lightSoftPink = AppColors.lightSoftPink;
  static const lightBackground = AppColors.lightBackground;

  static const Map<String, Color> postTypeBg = {
    'question': Color(0xFFF3D86B),
    'review': Color(0xFF6BA4D9),
    'update': Color(0xFF8BC48A),
    'tip': Color(0xFFB392E8),
    'routine': Color(0xFF7FD1C0),
    'before_after': Color(0xFFE8AABA),
  };

  static const Map<String, Color> postTypeFg = {
    'question': Color(0xFF5A4A00),
    'review': Colors.white,
    'update': Colors.white,
    'tip': Colors.white,
    'routine': Color(0xFF1F4F45),
    'before_after': Color(0xFF5B2333),
  };

  static Color bgFor(String postType) =>
      postTypeBg[postType.toLowerCase()] ?? const Color(0xFFB0B0B0);

  static Color fgFor(String postType) =>
      postTypeFg[postType.toLowerCase()] ?? Colors.white;

  static String postTypeLabel(String postType) {
    switch (postType.toLowerCase()) {
      case 'before_after':
        return 'Before & After';
      case 'question':
        return 'Question';
      case 'review':
        return 'Review';
      case 'update':
        return 'Update';
      case 'tip':
        return 'Tip';
      case 'routine':
        return 'Routine';
      default:
        return postType.isNotEmpty
            ? postType[0].toUpperCase() + postType.substring(1)
            : 'Update';
    }
  }
}

/// One reaction option shown in the reaction picker.
class ReactionDef {
  final String type;
  final String emoji;
  final String label;

  const ReactionDef({
    required this.type,
    required this.emoji,
    required this.label,
  });
}

const List<ReactionDef> kReactions = [
  ReactionDef(type: 'helpful', emoji: '❤️', label: 'Helpful'),
  ReactionDef(type: 'useful', emoji: '✨', label: 'Useful'),
  ReactionDef(type: 'loveIt', emoji: '🔥', label: 'Love it'),
];

ReactionDef? reactionByType(String? type) {
  if (type == null) return null;
  for (final r in kReactions) {
    if (r.type == type) return r;
  }
  return null;
}

/// A simple hand-rolled pulsing skeleton block (no shimmer package).
class PulsingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const PulsingSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<PulsingSkeleton> createState() => _PulsingSkeletonState();
}

class _PulsingSkeletonState extends State<PulsingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xFFE9E4E1),
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder mimicking the shape of a [PostCard].
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PulsingSkeleton(
                width: 38,
                height: 38,
                borderRadius: BorderRadius.all(Radius.circular(19)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    PulsingSkeleton(width: 120, height: 12),
                    SizedBox(height: 6),
                    PulsingSkeleton(width: 80, height: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const PulsingSkeleton(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          const PulsingSkeleton(width: 220, height: 14),
          const SizedBox(height: 14),
          PulsingSkeleton(
            width: double.infinity,
            height: 180,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }
}
