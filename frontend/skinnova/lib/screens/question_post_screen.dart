import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../product_model.dart';
import 'select_question_product_screen.dart';
import 'select_group_type_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../group_model.dart';

class QuestionPostScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final GroupModel? fixedGroup;

  const QuestionPostScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.fixedGroup,
  });

  @override
  State<QuestionPostScreen> createState() => _QuestionPostScreenState();
}

class _QuestionPostScreenState extends State<QuestionPostScreen> {
  final TextEditingController questionController = TextEditingController();

  static const int maxChars = 1000;
  ProductModel? selectedProduct;
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  String uploadedImageUrl = "";

  String get questionText => questionController.text.trim();
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        selectedImage = File(pickedFile.path);
      });

      final imageUrl = await ApiService.uploadPostImage(File(pickedFile.path));

      if (imageUrl != null) {
        setState(() {
          uploadedImageUrl = imageUrl;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to pick image")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    questionController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = maxChars - questionController.text.length;
    final canPost = questionText.isNotEmpty;

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
          "Question",
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
              onPressed: canPost
                  ? () async {
                      if (widget.fixedGroup != null) {
                        await ApiService.addQuestionPost(
                          userId: widget.userId,
                          userName: widget.userName,
                          userAvatar: "",
                          content: questionController.text.trim(),
                          productId: selectedProduct?.id ?? "",
                          productName: selectedProduct?.name ?? "",
                          productImage: uploadedImageUrl.isNotEmpty
                              ? uploadedImageUrl
                              : selectedProduct?.imageUrl ?? "",
                          groupId: widget.fixedGroup!.id,
                          groupTitle: widget.fixedGroup!.title,
                          groupSlug: widget.fixedGroup!.slug,
                        );

                        if (mounted) {
                          Navigator.pop(context, true);
                        }
                      } else {
                        final posted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectGroupTypeScreen(
                              userId: widget.userId,
                              userName: widget.userName,
                              questionText: questionController.text.trim(),
                              selectedProduct: selectedProduct,
                              postType: "question",
                              uploadedImageUrl: uploadedImageUrl,
                            ),
                          ),
                        );

                        if (posted == true && mounted) {
                          Navigator.pop(context, true);
                        }
                      }
                    }
                  : null,
              style: TextButton.styleFrom(
                backgroundColor:
                    canPost ? const Color(0xFF5B2333) : const Color(0xFFF2F2F2),
                foregroundColor:
                    canPost ? Colors.white : const Color(0xFFBDBDBD),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
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
                  controller: questionController,
                  maxLength: maxChars,
                  maxLines: null,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF2A2A2A),
                  ),
                  decoration: InputDecoration(
                    hintText: "Ask your question...",
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
              const SizedBox(height: 16),
              if (selectedProduct != null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sell_outlined,
                        color: Color(0xFF3A3A3A),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedProduct!.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2A2A2A),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedProduct = null;
                          });
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF7A7A7A),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              if (selectedImage != null) ...[
                const SizedBox(height: 14),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        selectedImage!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImage = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              Text(
                "Attach",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2A2A2A),
                ),
              ),
              const SizedBox(height: 16),
              _buildAttachCard(
                icon: Icons.sell_outlined,
                title: "Product",
                onTap: () async {
                  final product = await Navigator.push<ProductModel>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelectQuestionProductScreen(),
                    ),
                  );

                  if (product != null) {
                    setState(() {
                      selectedProduct = product;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              _buildAttachCard(
                icon: Icons.image_outlined,
                title: "Photo from gallery",
                onTap: _pickImageFromGallery,
              ),
              const SizedBox(height: 14),
              _buildAttachCard(
                icon: Icons.photo_camera_outlined,
                title: "Take photo",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Camera later")),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: const Color(0xFF3A3A3A),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2A2A2A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
