import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

/// Deterministic skincare-themed gradients + icons used as fallback
/// visuals for groups/communities/friends that have no uploaded image.
class GroupVisuals {
  static const List<List<Color>> gradients = [
    [Color(0xFFFCE4EC), Color(0xFFF48FB1)], // soft pink
    [Color(0xFFE0F7FA), Color(0xFF80DEEA)], // aqua
    [Color(0xFFFFF3E0), Color(0xFFFFCC80)], // peach
    [Color(0xFFF3E5F5), Color(0xFFCE93D8)], // lavender
    [Color(0xFFE8F5E9), Color(0xFFA5D6A7)], // mint
    [Color(0xFFFFF8E1), Color(0xFFFFD54F)], // cream gold
    [Color(0xFFEDE7F6), Color(0xFFB39DDB)], // periwinkle
    [Color(0xFFFBE9E7), Color(0xFFFFAB91)], // coral
  ];

  static const List<IconData> icons = [
    Icons.spa_rounded,
    Icons.water_drop_rounded,
    Icons.local_florist_rounded,
    Icons.face_retouching_natural_rounded,
    Icons.eco_rounded,
    Icons.favorite_rounded,
    Icons.bubble_chart_rounded,
    Icons.wb_sunny_rounded,
  ];

  static int _hash(String key) =>
      key.codeUnits.fold<int>(0, (sum, c) => sum + c);

  static List<Color> gradientFor(String seed) =>
      gradients[_hash(seed) % gradients.length];

  static IconData iconFor(String seed) =>
      icons[_hash(seed) % icons.length];
}

/// Circular avatar for a group/community/person. Shows [imageUrl] when
/// available; otherwise renders a skincare-themed gradient with either an
/// icon or [fallbackText] (e.g. initials), picked deterministically from
/// [seed] so the same entity always gets the same look.
class GroupAvatar extends StatelessWidget {
  final String imageUrl;
  final String seed;
  final double size;
  final String? fallbackText;

  const GroupAvatar({
    super.key,
    required this.imageUrl,
    required this.seed,
    this.size = 56,
    this.fallbackText,
  });

  Widget _fallback() {
    final colors = GroupVisuals.gradientFor(seed);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: fallbackText != null && fallbackText!.isNotEmpty
          ? Text(
              fallbackText!,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.36,
              ),
            )
          : Icon(
              GroupVisuals.iconFor(seed),
              color: Colors.white,
              size: size * 0.46,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _fallback();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl.isEmpty
            ? fallback
            : (imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallback,
                  )
                : Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallback,
                  )),
      ),
    );
  }
}

/// Rectangular cover image for a group/community card or header. Shows
/// [imageUrl] when available; otherwise a skincare-themed gradient with a
/// large centered icon, picked deterministically from [seed].
class GroupCoverImage extends StatelessWidget {
  final String imageUrl;
  final String seed;
  final double? height;
  final double? width;

  const GroupCoverImage({
    super.key,
    required this.imageUrl,
    required this.seed,
    this.height,
    this.width,
  });

  Widget _fallback() {
    final colors = GroupVisuals.gradientFor(seed);
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        GroupVisuals.iconFor(seed),
        color: Colors.white.withOpacity(0.85),
        size: (height ?? 120) * 0.4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _fallback();
    return imageUrl.startsWith('http')
        ? Image.network(
            imageUrl,
            height: height,
            width: width,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(),
          )
        : Image.asset(
            imageUrl,
            height: height,
            width: width,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(),
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
