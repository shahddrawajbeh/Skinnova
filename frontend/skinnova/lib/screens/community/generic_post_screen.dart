import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../api_service.dart';
import 'community_theme.dart';

/// Generalized composer for the new FAB post types (Tip / Share Routine /
/// Before & After). Posts directly via [ApiService.addGenericPost] with no
/// group picker — these always land in the main feed.
class GenericPostScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String postType;
  final int minImages;

  const GenericPostScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.postType,
    this.minImages = 0,
  });

  @override
  State<GenericPostScreen> createState() => _GenericPostScreenState();
}

class _GenericPostScreenState extends State<GenericPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const int maxChars = 1000;
  final List<String> _uploadedImageUrls = [];
  bool _isUploadingImage = false;
  bool _isPosting = false;

  String get _content => _contentController.text.trim();

  String get _title => CommunityColors.postTypeLabel(widget.postType);

  String get _hint {
    switch (widget.postType) {
      case 'tip':
        return "Share a quick skincare tip...";
      case 'routine':
        return "Walk us through your routine, step by step...";
      case 'before_after':
        return "Tell everyone about your transformation...";
      default:
        return "What's on your mind?";
    }
  }

  bool get _canPost =>
      _content.isNotEmpty &&
      _uploadedImageUrls.length >= widget.minImages &&
      !_isPosting &&
      !_isUploadingImage;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final imageUrl = await ApiService.uploadPostImage(File(pickedFile.path));

      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
        if (imageUrl != null) _uploadedImageUrls.add(imageUrl);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to pick image")),
      );
    }
  }

  void _removeImage(int index) {
    setState(() => _uploadedImageUrls.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_canPost) return;
    setState(() => _isPosting = true);

    final result = await ApiService.addGenericPost(
      userId: widget.userId,
      userName: widget.userName,
      userAvatar: "",
      content: _content,
      postType: widget.postType,
      images: _uploadedImageUrls,
    );

    if (!mounted) return;

    if (result["statusCode"] == 201 || result["statusCode"] == 200) {
      Navigator.pop(context, true);
    } else {
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create post")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = maxChars - _contentController.text.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close_rounded,
            color: Color(0xFF9E9E9E),
            size: 28,
          ),
        ),
        centerTitle: true,
        title: Text(
          _title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2A2A2A),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: TextButton(
              onPressed: _canPost ? _submit : null,
              style: TextButton.styleFrom(
                backgroundColor: _canPost
                    ? CommunityColors.wine
                    : const Color(0xFFF2F2F2),
                foregroundColor:
                    _canPost ? Colors.white : const Color(0xFFBDBDBD),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      "Post",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.minImages > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: CommunityColors.lightSoftPink,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: CommunityColors.wine,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Add at least ${widget.minImages} photos to share your before & after.",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: CommunityColors.wine,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                constraints: const BoxConstraints(minHeight: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFE8E8E8),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _contentController,
                  maxLength: maxChars,
                  maxLines: null,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF2A2A2A),
                  ),
                  decoration: InputDecoration(
                    hintText: _hint,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFFB0B0B0),
                    ),
                    border: InputBorder.none,
                    counterText: "",
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "$remaining characters remaining",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFFB0B0B0),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Photos",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2A2A2A),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (int i = 0; i < _uploadedImageUrls.length; i++)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _uploadedImageUrls[i],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  GestureDetector(
                    onTap: _isUploadingImage ? null : _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _isUploadingImage
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Color(0xFF8D8D8D),
                              size: 28,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
