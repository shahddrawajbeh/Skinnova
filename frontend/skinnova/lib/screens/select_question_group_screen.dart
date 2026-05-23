// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../api_service.dart';
// import '../group_model.dart';
// import '../product_model.dart';

// class SelectQuestionGroupScreen extends StatefulWidget {
//   final String userId;
//   final String userName;
//   final String questionText;
//   //final ProductModel selectedProduct;
//   final String groupType;
//   final ProductModel? selectedProduct;
//   final String uploadedImageUrl;
//   final String screenTitle;
//   final String postType;

//   const SelectQuestionGroupScreen({
//     super.key,
//     required this.userId,
//     required this.userName,
//     required this.questionText,
//     required this.selectedProduct,
//     required this.groupType,
//     required this.screenTitle,
//     required this.postType,
//     required this.uploadedImageUrl,
//   });

//   @override
//   State<SelectQuestionGroupScreen> createState() =>
//       _SelectQuestionGroupScreenState();
// }

// class _SelectQuestionGroupScreenState extends State<SelectQuestionGroupScreen> {
//   List<GroupModel> groups = [];
//   List<GroupModel> filteredGroups = [];
//   bool isLoading = true;
//   final TextEditingController searchController = TextEditingController();
//   String? selectedGroupId;

//   @override
//   void initState() {
//     super.initState();
//     loadGroups();
//     searchController.addListener(_filterGroups);
//   }

//   Future<void> loadGroups() async {
//     try {
//       final data = await ApiService.fetchGroupsByType(widget.groupType);

//       if (!mounted) return;

//       setState(() {
//         groups = data;
//         filteredGroups = data;
//         isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void _filterGroups() {
//     final query = searchController.text.trim().toLowerCase();

//     setState(() {
//       filteredGroups = groups.where((group) {
//         return group.title.toLowerCase().contains(query) ||
//             group.categoryKey.toLowerCase().contains(query);
//       }).toList();
//     });
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }

//   Widget _buildGroupImage(GroupModel group) {
//     if (group.coverImage.isEmpty) {
//       return Container(
//         color: const Color(0xFFF1F1F1),
//         child: const Icon(
//           Icons.image_outlined,
//           color: Color(0xFFB0B0B0),
//         ),
//       );
//     }

//     if (group.coverImage.startsWith("http")) {
//       return Image.network(
//         group.coverImage,
//         fit: BoxFit.cover,
//         errorBuilder: (_, __, ___) {
//           return Container(
//             color: const Color(0xFFF1F1F1),
//             child: const Icon(
//               Icons.image_outlined,
//               color: Color(0xFFB0B0B0),
//             ),
//           );
//         },
//       );
//     }

//     return Image.asset(
//       group.coverImage,
//       fit: BoxFit.cover,
//       errorBuilder: (_, __, ___) {
//         return Container(
//           color: const Color(0xFFF1F1F1),
//           child: const Icon(
//             Icons.image_outlined,
//             color: Color(0xFFB0B0B0),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const Color textDark = Color(0xFF202124);
//     const Color subText = Color(0xFF8E8E8E);
//     const Color accentBlue = Color(0xFF5B2333);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: const Icon(
//                       Icons.chevron_left,
//                       size: 30,
//                       color: textDark,
//                     ),
//                   ),
//                   Expanded(
//                     child: Center(
//                       child: Text(
//                         widget.screenTitle,
//                         style: GoogleFonts.poppins(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w500,
//                           color: textDark,
//                         ),
//                       ),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: selectedGroupId == null
//                         ? null
//                         : () async {
//                             final selectedGroup = groups.firstWhere(
//                               (g) => g.id == selectedGroupId,
//                             );

//                             final result = widget.postType == "update"
//                                 ? await ApiService.addUpdatePost(
//                                     userId: widget.userId,
//                                     userName: widget.userName,
//                                     userAvatar: "",
//                                     content: widget.questionText,
//                                     productId: widget.selectedProduct.id,
//                                     productName: widget.selectedProduct.name,
//                                     productImage:
//                                         widget.selectedProduct.imageUrl,
//                                     groupId: selectedGroup.id,
//                                     groupTitle: selectedGroup.title,
//                                     groupSlug: selectedGroup.slug,
//                                   )
//                                 : await ApiService.addQuestionPost(
//                                     userId: widget.userId,
//                                     userName: widget.userName,
//                                     userAvatar: "",
//                                     content: widget.questionText,
//                                     productId: widget.selectedProduct.id,
//                                     productName: widget.selectedProduct.name,
//                                     productImage:
//                                         widget.selectedProduct.imageUrl,
//                                     groupId: selectedGroup.id,
//                                     groupTitle: selectedGroup.title,
//                                     groupSlug: selectedGroup.slug,
//                                   );

//                             if (!mounted) return;

//                             if (result["statusCode"] == 201) {
//                               Navigator.pop(context, true);
//                             } else {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text(
//                                     widget.postType == "update"
//                                         ? "Failed to post update"
//                                         : "Failed to post question",
//                                   ),
//                                 ),
//                               );
//                             }
//                           },
//                     child: Icon(
//                       Icons.check_rounded,
//                       size: 30,
//                       color: selectedGroupId == null
//                           ? Colors.grey.shade300
//                           : accentBlue,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const Divider(height: 1),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
//               child: Container(
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF5F5F5),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: TextField(
//                   controller: searchController,
//                   decoration: InputDecoration(
//                     hintText: "Search for a group...",
//                     hintStyle: GoogleFonts.poppins(
//                       fontSize: 13.5,
//                       color: const Color(0xFFB5B5B5),
//                     ),
//                     prefixIcon: const Icon(
//                       Icons.search_rounded,
//                       color: Color(0xFFB5B5B5),
//                     ),
//                     border: InputBorder.none,
//                   ),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : filteredGroups.isEmpty
//                       ? Center(
//                           child: Text(
//                             "No groups found",
//                             style: GoogleFonts.poppins(
//                               fontSize: 14,
//                               color: subText,
//                             ),
//                           ),
//                         )
//                       : ListView.separated(
//                           padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
//                           itemCount: filteredGroups.length,
//                           separatorBuilder: (_, __) =>
//                               const SizedBox(height: 14),
//                           itemBuilder: (context, index) {
//                             final group = filteredGroups[index];
//                             final isSelected = selectedGroupId == group.id;
//                             return GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   selectedGroupId = group.id;
//                                 });
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 16, vertical: 8),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFFF8F7F6),
//                                   borderRadius: BorderRadius.circular(10),
//                                   border: Border.all(
//                                     color: isSelected
//                                         ? accentBlue
//                                         : const Color(0xFFF0F0F0),
//                                     width: isSelected ? 2 : 1,
//                                   ),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     ClipRRect(
//                                       borderRadius: BorderRadius.circular(999),
//                                       child: SizedBox(
//                                         width: 64,
//                                         height: 64,
//                                         child: _buildGroupImage(group),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 16),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           Text(
//                                             group.title,
//                                             style: GoogleFonts.poppins(
//                                               fontSize: 15,
//                                               fontWeight: FontWeight.w600,
//                                               color: textDark,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     const SizedBox(width: 10),
//                                     if (isSelected)
//                                       const Icon(
//                                         Icons.check_circle_rounded,
//                                         color: accentBlue,
//                                         size: 24,
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../group_model.dart';
import '../product_model.dart';

class SelectQuestionGroupScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String questionText;
  final ProductModel? selectedProduct;
  final String groupType;
  final String screenTitle;
  final String postType;
  final String uploadedImageUrl;

  const SelectQuestionGroupScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.questionText,
    required this.selectedProduct,
    required this.groupType,
    required this.screenTitle,
    required this.postType,
    required this.uploadedImageUrl,
  });

  @override
  State<SelectQuestionGroupScreen> createState() =>
      _SelectQuestionGroupScreenState();
}

class _SelectQuestionGroupScreenState extends State<SelectQuestionGroupScreen> {
  List<GroupModel> groups = [];
  List<GroupModel> filteredGroups = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();
  String? selectedGroupId;

  @override
  void initState() {
    super.initState();
    loadGroups();
    searchController.addListener(_filterGroups);
  }

  Future<void> loadGroups() async {
    try {
      final data = await ApiService.fetchGroupsByType(widget.groupType);

      if (!mounted) return;

      setState(() {
        groups = data;
        filteredGroups = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterGroups() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      filteredGroups = groups.where((group) {
        return group.title.toLowerCase().contains(query) ||
            group.categoryKey.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget _buildGroupImage(GroupModel group) {
    if (group.coverImage.isEmpty) {
      return Container(
        color: const Color(0xFFF1F1F1),
        child: const Icon(
          Icons.image_outlined,
          color: Color(0xFFB0B0B0),
        ),
      );
    }

    if (group.coverImage.startsWith("http")) {
      return Image.network(
        group.coverImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            color: const Color(0xFFF1F1F1),
            child: const Icon(
              Icons.image_outlined,
              color: Color(0xFFB0B0B0),
            ),
          );
        },
      );
    }

    return Image.asset(
      group.coverImage,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFFF1F1F1),
          child: const Icon(
            Icons.image_outlined,
            color: Color(0xFFB0B0B0),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF202124);
    const Color subText = Color(0xFF8E8E8E);
    const Color accentBlue = Color(0xFF5B2333);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.chevron_left,
                      size: 30,
                      color: textDark,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.screenTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: selectedGroupId == null
                        ? null
                        : () async {
                            final selectedGroup = groups.firstWhere(
                              (g) => g.id == selectedGroupId,
                            );

                            final result = widget.postType == "update"
                                ? await ApiService.addUpdatePost(
                                    userId: widget.userId,
                                    userName: widget.userName,
                                    userAvatar: "",
                                    content: widget.questionText,
                                    productId: widget.selectedProduct?.id ?? "",
                                    productName:
                                        widget.selectedProduct?.name ?? "",
                                    productImage: widget
                                            .uploadedImageUrl.isNotEmpty
                                        ? widget.uploadedImageUrl
                                        : (widget.selectedProduct?.imageUrl ??
                                            ""),
                                    groupId: selectedGroup.id,
                                    groupTitle: selectedGroup.title,
                                    groupSlug: selectedGroup.slug,
                                  )
                                : await ApiService.addQuestionPost(
                                    userId: widget.userId,
                                    userName: widget.userName,
                                    userAvatar: "",
                                    content: widget.questionText,
                                    productId: widget.selectedProduct?.id ?? "",
                                    productName:
                                        widget.selectedProduct?.name ?? "",
                                    productImage: widget
                                            .uploadedImageUrl.isNotEmpty
                                        ? widget.uploadedImageUrl
                                        : (widget.selectedProduct?.imageUrl ??
                                            ""),
                                    groupId: selectedGroup.id,
                                    groupTitle: selectedGroup.title,
                                    groupSlug: selectedGroup.slug,
                                  );

                            if (!mounted) return;

                            if (result["statusCode"] == 201) {
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    widget.postType == "update"
                                        ? "Failed to post update"
                                        : "Failed to post question",
                                  ),
                                ),
                              );
                            }
                          },
                    child: Icon(
                      Icons.check_rounded,
                      size: 30,
                      color: selectedGroupId == null
                          ? Colors.grey.shade300
                          : accentBlue,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search for a group...",
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: const Color(0xFFB5B5B5),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFFB5B5B5),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredGroups.isEmpty
                      ? Center(
                          child: Text(
                            "No groups found",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: subText,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          itemCount: filteredGroups.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final group = filteredGroups[index];
                            final isSelected = selectedGroupId == group.id;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedGroupId = group.id;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F7F6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? accentBlue
                                        : const Color(0xFFF0F0F0),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: SizedBox(
                                        width: 64,
                                        height: 64,
                                        child: _buildGroupImage(group),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            group.title,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: accentBlue,
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
