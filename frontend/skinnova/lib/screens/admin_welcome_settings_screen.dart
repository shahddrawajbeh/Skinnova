import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminWelcomeSettingsScreen extends StatefulWidget {
  const AdminWelcomeSettingsScreen({super.key});

  @override
  State<AdminWelcomeSettingsScreen> createState() =>
      _AdminWelcomeSettingsScreenState();
}

class _AdminWelcomeSettingsScreenState
    extends State<AdminWelcomeSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  String _adminId = '';

  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _btnTextCtrl = TextEditingController();
  final _mediaUrlCtrl = TextEditingController();
  String _mediaType = 'video';
  bool _isActive = true;

  // Preview video controller
  VideoPlayerController? _previewVideoCtrl;
  bool _previewVideoReady = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _btnTextCtrl.dispose();
    _mediaUrlCtrl.dispose();
    _previewVideoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminId = prefs.getString('userId') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.adminGetWelcomeSettings(_adminId);
      if (!mounted) return;
      setState(() {
        _titleCtrl.text = data['title'] ?? 'Welcome to Skinova';
        _subtitleCtrl.text = data['subtitle'] ?? '';
        _btnTextCtrl.text = data['buttonText'] ?? 'Get Started';
        _mediaType = data['mediaType'] ?? 'video';
        _mediaUrlCtrl.text = data['mediaUrl'] ?? '';
        _isActive = data['isActive'] != false;
        _loading = false;
      });
      _initPreviewVideo();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _initPreviewVideo() {
    _previewVideoCtrl?.dispose();
    _previewVideoCtrl = null;
    _previewVideoReady = false;

    final url = _mediaUrlCtrl.text.trim();
    if (_mediaType != 'video' || url.isEmpty) return;

    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    _previewVideoCtrl = ctrl;
    ctrl.initialize().then((_) {
      if (!mounted) return;
      ctrl.setLooping(true);
      ctrl.setVolume(0);
      ctrl.play();
      setState(() => _previewVideoReady = true);
    }).catchError((_) {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.adminUpdateWelcomeSettings(_adminId, {
        'title': _titleCtrl.text.trim(),
        'subtitle': _subtitleCtrl.text.trim(),
        'buttonText': _btnTextCtrl.text.trim(),
        'mediaType': _mediaType,
        'mediaUrl': _mediaUrlCtrl.text.trim(),
        'isActive': _isActive,
      });
      if (!mounted) return;
      _showSnack('Welcome screen settings saved!');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to save: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadMedia() async {
    final picker = ImagePicker();
    XFile? picked;

    if (_mediaType == 'image') {
      picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    } else {
      picked = await picker.pickVideo(source: ImageSource.gallery);
    }
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final result =
          await ApiService.adminUploadWelcomeMedia(_adminId, File(picked.path));
      if (!mounted) return;
      setState(() {
        _mediaUrlCtrl.text = result['mediaUrl'] ?? '';
        _mediaType = result['mediaType'] ?? _mediaType;
      });
      _initPreviewVideo();
      _showSnack('Media uploaded!');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Upload failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AdminTheme.wine));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome Screen', style: AdminTheme.title(20)),
          const SizedBox(height: 4),
          Text('Control what users see on first launch.',
              style: AdminTheme.sub(13)),
          const SizedBox(height: 24),

          // ── Live preview ─────────────────────────────────────────────────────
          _buildPreview(),

          const SizedBox(height: 20),

          // ── Media section ────────────────────────────────────────────────────
          _card('Background Media', [
            Row(children: [
              Expanded(
                child: _segmentBtn(
                  label: 'Video',
                  icon: Icons.videocam_outlined,
                  selected: _mediaType == 'video',
                  onTap: () {
                    setState(() => _mediaType = 'video');
                    _initPreviewVideo();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _segmentBtn(
                  label: 'Image',
                  icon: Icons.image_outlined,
                  selected: _mediaType == 'image',
                  onTap: () {
                    setState(() {
                      _mediaType = 'image';
                      _previewVideoCtrl?.dispose();
                      _previewVideoCtrl = null;
                      _previewVideoReady = false;
                    });
                  },
                ),
              ),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _mediaUrlCtrl,
              decoration: _inputDec(
                'Media URL',
                hint: _mediaType == 'video'
                    ? 'https://example.com/video.mp4'
                    : 'https://example.com/image.jpg',
                suffix: IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      size: 18, color: AdminTheme.wine),
                  tooltip: 'Reload preview',
                  onPressed: _initPreviewVideo,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 13),
              onSubmitted: (_) => _initPreviewVideo(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : _uploadMedia,
                icon: _uploading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            color: AdminTheme.wine, strokeWidth: 2))
                    : Icon(
                        _mediaType == 'video'
                            ? Icons.video_file_outlined
                            : Icons.add_photo_alternate_outlined,
                        size: 18,
                        color: AdminTheme.wine),
                label: Text(
                  _uploading
                      ? 'Uploading…'
                      : 'Upload ${_mediaType == "video" ? "Video" : "Image"}',
                  style: GoogleFonts.poppins(
                      color: AdminTheme.wine,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AdminTheme.wine),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Text content ─────────────────────────────────────────────────────
          _card('Screen Content', [
            _f('Title', _titleCtrl, hint: 'Welcome to Skinova'),
            const SizedBox(height: 12),
            _f('Subtitle', _subtitleCtrl,
                maxLines: 3, hint: 'Your ultimate companion…'),
            const SizedBox(height: 12),
            _f('Button Text', _btnTextCtrl, hint: 'Get Started'),
          ]),

          const SizedBox(height: 16),

          // ── Visibility ───────────────────────────────────────────────────────
          _card('Visibility', [
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Use custom welcome screen',
                        style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AdminTheme.black)),
                    Text(
                      _isActive
                          ? 'Custom content is shown to users'
                          : 'Default hardcoded content is shown',
                      style: AdminTheme.sub(12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isActive,
                activeColor: AdminTheme.wine,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ]),
          ]),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.wine,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Save Changes',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview widget ───────────────────────────────────────────────────────────
  Widget _buildPreview() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminTheme.line),
        color: Colors.black,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(fit: StackFit.expand, children: [
        // Background
        _buildPreviewBackground(),
        // Wine overlay gradients (matches actual WelcomeScreen)
        Container(color: const Color(0xFF5B2333).withOpacity(0.10)),
        _linearGrad([
          const Color(0xFF5B2333).withOpacity(0.30),
          const Color(0xFF5B2333).withOpacity(0.10),
          Colors.transparent,
          Colors.transparent,
        ], [
          0.0,
          0.18,
          0.40,
          1.0
        ]),
        _linearGrad([
          Colors.transparent,
          Colors.transparent,
          Colors.black.withOpacity(0.12),
          const Color(0xFF5B2333).withOpacity(0.72),
          const Color(0xFF5B2333).withOpacity(0.94),
        ], [
          0.0,
          0.42,
          0.62,
          0.82,
          1.0
        ]),
        // Text overlay
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _titleCtrl.text.isNotEmpty
                    ? _titleCtrl.text
                    : 'Welcome to Skinova',
                textAlign: TextAlign.center,
                style: GoogleFonts.marcellus(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF7F4F3),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4F3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _btnTextCtrl.text.isNotEmpty
                      ? _btnTextCtrl.text
                      : 'Get Started',
                  style: GoogleFonts.marcellus(
                    fontSize: 14,
                    color: const Color(0xFF5B2333),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Label
        Positioned(
          top: 10,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Preview',
                style:
                    GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
          ),
        ),
      ]),
    );
  }

  Widget _buildPreviewBackground() {
    final url = _mediaUrlCtrl.text.trim();

    if (_mediaType == 'image' && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackBg(),
      );
    }

    if (_mediaType == 'video') {
      if (_previewVideoReady && _previewVideoCtrl != null) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _previewVideoCtrl!.value.size.width,
            height: _previewVideoCtrl!.value.size.height,
            child: VideoPlayer(_previewVideoCtrl!),
          ),
        );
      }
      if (url.isNotEmpty) {
        // Still loading
        return const Center(
          child:
              CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
        );
      }
    }

    return _fallbackBg();
  }

  Widget _fallbackBg() => Container(
        color: const Color(0xFF3D1723),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              _mediaType == 'video'
                  ? Icons.videocam_outlined
                  : Icons.image_outlined,
              color: Colors.white30,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              _mediaType == 'video' ? 'No video URL set' : 'No image URL set',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
            ),
          ]),
        ),
      );

  Widget _linearGrad(List<Color> colors, List<double> stops) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
            stops: stops,
          ),
        ),
      );

  // ── Helper widgets ───────────────────────────────────────────────────────────
  Widget _card(String title, List<Widget> children) => Container(
        padding: const EdgeInsets.all(20),
        decoration: AdminTheme.cardDec(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AdminTheme.title(14)),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );

  Widget _segmentBtn({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AdminTheme.wine : AdminTheme.soft,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: selected ? AdminTheme.wine : AdminTheme.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18, color: selected ? Colors.white : AdminTheme.grey),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AdminTheme.black,
                  )),
            ],
          ),
        ),
      );

  InputDecoration _inputDec(String label, {String? hint, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey),
        hintStyle: GoogleFonts.poppins(
            fontSize: 12.5, color: AdminTheme.grey.withOpacity(0.6)),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  TextField _f(String label, TextEditingController ctrl,
          {String? hint, int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: _inputDec(label, hint: hint),
        style: GoogleFonts.poppins(fontSize: 13),
        onChanged: (_) => setState(() {}), // refresh preview text
      );

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? Colors.red.shade400 : AdminTheme.wine,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
