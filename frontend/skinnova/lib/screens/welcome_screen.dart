import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../api_service.dart';
import 'auth_popup.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color wine = Color(0xFF5B2333);

  // ── Remote settings ───────────────────────────────────────────────────────
  bool _settingsLoaded = false;
  bool _isActive = false; // false until we know the setting is active
  String _title = 'Welcome to Skinova';
  String _subtitle =
      'Your ultimate companion for your skincare journey. Achieve healthier skin with personalized routines and progress tracking.';
  String _buttonText = 'Get Started';
  String _mediaType = 'video'; // "video" | "image"
  String _mediaUrl = '';

  // ── Video players ─────────────────────────────────────────────────────────
  VideoPlayerController? _videoController; // local asset fallback
  VideoPlayerController? _netVideoController; // remote network video
  bool _localReady = false;
  bool _netReady = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ── Fetch welcome settings then decide which media to use ─────────────────
  Future<void> _loadSettings() async {
    try {
      final data = await ApiService.getWelcomeSettings();
      if (!mounted) return;

      final active = data['isActive'] == true;
      final url = (data['mediaUrl'] ?? '').toString().trim();
      final type = (data['mediaType'] ?? 'video').toString();

      if (active) {
        setState(() {
          _isActive = true;
          _title = (data['title'] ?? _title).toString();
          _subtitle = (data['subtitle'] ?? _subtitle).toString();
          _buttonText = (data['buttonText'] ?? _buttonText).toString();
          _mediaType = type;
          _mediaUrl = url;
          _settingsLoaded = true;
        });

        if (type == 'video' && url.isNotEmpty) {
          await _initNetworkVideo(url);
        } else if (type == 'image' && url.isNotEmpty) {
          // Image — no controller needed
          setState(() => _settingsLoaded = true);
        } else {
          // No valid remote media → fall back to local asset
          await _initLocalVideo();
        }
      } else {
        // isActive == false → use local defaults
        setState(() => _settingsLoaded = true);
        await _initLocalVideo();
      }
    } catch (_) {
      // Network error → fall back to local defaults silently
      if (!mounted) return;
      setState(() => _settingsLoaded = true);
      await _initLocalVideo();
    }
  }

  Future<void> _initLocalVideo() async {
    if (!mounted) return;
    try {
      final ctrl = VideoPlayerController.asset('assets/videos/video1.mp4');
      _videoController = ctrl;
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      await ctrl.setLooping(true);
      await ctrl.setVolume(0.0);
      await ctrl.play();
      if (mounted) setState(() => _localReady = true);
    } catch (_) {
      // Asset missing or error — show nothing but don't crash
    }
  }

  Future<void> _initNetworkVideo(String url) async {
    if (!mounted) return;
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      _netVideoController = ctrl;
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      await ctrl.setLooping(true);
      await ctrl.setVolume(0.0);
      await ctrl.play();
      if (mounted) setState(() => _netReady = true);
    } catch (_) {
      // Network video failed → fall back to local
      _netVideoController?.dispose();
      _netVideoController = null;
      await _initLocalVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _netVideoController?.dispose();
    super.dispose();
  }

  void _openAuthPopup() {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Auth',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.22),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const AuthPopup();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  // ── Choose what to show as background ────────────────────────────────────
  Widget _buildBackground() {
    // Remote image
    if (_isActive && _mediaType == 'image' && _mediaUrl.isNotEmpty) {
      return Image.network(
        _mediaUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _fallbackBackground(),
      );
    }

    // Remote network video
    if (_isActive &&
        _mediaType == 'video' &&
        _netReady &&
        _netVideoController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _netVideoController!.value.size.width,
          height: _netVideoController!.value.size.height,
          child: VideoPlayer(_netVideoController!),
        ),
      );
    }

    // Local asset video (fallback or default)
    if (_localReady && _videoController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    // Still loading
    return _fallbackBackground();
  }

  Widget _fallbackBackground() => Container(
        color: whiteSmoke,
        child: const Center(child: CircularProgressIndicator()),
      );

  @override
  Widget build(BuildContext context) {
    final bool mediaReady = _settingsLoaded &&
        (_isActive
            ? (_mediaType == 'image'
                ? _mediaUrl.isNotEmpty
                : (_netReady || _localReady))
            : _localReady);

    return Scaffold(
      backgroundColor: whiteSmoke,
      body: Stack(
        children: [
          // ── Background ────────────────────────────────────────────────────
          Positioned.fill(
            child: mediaReady ? _buildBackground() : _fallbackBackground(),
          ),

          // ── Wine overlay tint ─────────────────────────────────────────────
          Positioned.fill(
            child: Container(color: wine.withOpacity(0.10)),
          ),

          // ── Top gradient (top → transparent) ─────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    wine.withOpacity(0.30),
                    wine.withOpacity(0.10),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.18, 0.40, 1.0],
                ),
              ),
            ),
          ),

          // ── Bottom gradient (transparent → wine) ─────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.12),
                    wine.withOpacity(0.72),
                    wine.withOpacity(0.94),
                  ],
                  stops: const [0.0, 0.42, 0.62, 0.82, 1.0],
                ),
              ),
            ),
          ),

          // ── Text content + button ─────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.marcellus(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: whiteSmoke,
                      height: 1.15,
                      letterSpacing: -0.4,
                      shadows: [
                        Shadow(
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                          color: Colors.black.withOpacity(0.25),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: whiteSmoke.withOpacity(0.95),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _openAuthPopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: whiteSmoke,
                        foregroundColor: wine,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        _buttonText,
                        style: GoogleFonts.marcellus(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
