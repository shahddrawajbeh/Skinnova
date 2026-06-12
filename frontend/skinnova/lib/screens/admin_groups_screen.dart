import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import 'admin_group_members_screen.dart';
import 'admin_group_posts_by_group_screen.dart';
import 'group_details_screen.dart';

class AdminGroupsScreen extends StatefulWidget {
  const AdminGroupsScreen({super.key});
  @override
  State<AdminGroupsScreen> createState() => _AdminGroupsScreenState();
}

class _AdminGroupsScreenState extends State<AdminGroupsScreen> {
  bool _loading = true;
  List _groups = [];
  int _total = 0;
  String _adminId = '';
  String _adminName = '';
  final _searchCtrl = TextEditingController();
  String _typeFilter = '';

  static const List<String> _groupTypes = [
    '',
    'skin_types',
    'skin_colors',
    'product_categories',
    'skin_concerns',
    'skin_tones',
    'skin_type',
    'medications',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminId = prefs.getString('userId') ?? '';
    _adminName = prefs.getString('userName') ?? 'Admin';
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.adminGetGroups(_adminId,
          search: _searchCtrl.text.trim(), groupType: _typeFilter);
      if (!mounted) return;
      setState(() {
        _groups = data['groups'] as List? ?? [];
        _total = data['total'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ── Edit / Create dialog (membersCount removed) ───────────────────────────
  void _showEditDialog([Map? group]) {
    final titleCtrl = TextEditingController(text: group?['title'] ?? '');
    final slugCtrl = TextEditingController(text: group?['slug'] ?? '');
    final descCtrl = TextEditingController(text: group?['description'] ?? '');
    final categoryCtrl =
        TextEditingController(text: group?['categoryKey'] ?? '');
    final coverCtrl = TextEditingController(text: group?['coverImage'] ?? '');
    final profileCtrl =
        TextEditingController(text: group?['profileImage'] ?? '');
    String groupType = group?['groupType'] ?? 'skin_concerns';
    bool uploadingCover = false;
    bool uploadingProfile = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          Future<void> pickAndUpload(
              TextEditingController ctrl, bool isCover) async {
            final picked = await ImagePicker()
                .pickImage(source: ImageSource.gallery, imageQuality: 85);
            if (picked == null) return;
            setS(() {
              if (isCover) {
                uploadingCover = true;
              } else {
                uploadingProfile = true;
              }
            });
            try {
              final url = await ApiService.adminUploadGroupImage(
                  _adminId, File(picked.path));
              if (url != null) {
                setS(() => ctrl.text = url);
              } else {
                _showSnack("Image upload failed", error: true);
              }
            } catch (_) {
              _showSnack("Image upload failed", error: true);
            } finally {
              setS(() {
                if (isCover) {
                  uploadingCover = false;
                } else {
                  uploadingProfile = false;
                }
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(group == null ? "Add Group" : "Edit Group",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AdminTheme.black)),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _field("Title *", titleCtrl),
                  const SizedBox(height: 10),
                  _field("Slug *", slugCtrl, hint: "e.g. acne"),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: groupType,
                    decoration: _inputDec("Group Type"),
                    items: _groupTypes
                        .skip(1)
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t,
                                style: GoogleFonts.poppins(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setS(() => groupType = v!),
                  ),
                  const SizedBox(height: 10),
                  _field("Category Key", categoryCtrl, hint: "e.g. acne"),
                  const SizedBox(height: 10),
                  _field("Description", descCtrl, maxLines: 3),
                  const SizedBox(height: 10),
                  _imagePickerField(
                    "Cover Image",
                    coverCtrl,
                    isUploading: uploadingCover,
                    onPick: () => pickAndUpload(coverCtrl, true),
                  ),
                  const SizedBox(height: 14),
                  _imagePickerField(
                    "Profile Image",
                    profileCtrl,
                    isUploading: uploadingProfile,
                    onPick: () => pickAndUpload(profileCtrl, false),
                  ),
                ]),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Cancel",
                      style: GoogleFonts.poppins(color: AdminTheme.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.wine,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    // membersCount intentionally excluded from payload
                    final data = {
                      'title': titleCtrl.text.trim(),
                      'slug': slugCtrl.text.trim().toLowerCase(),
                      'description': descCtrl.text.trim(),
                      'categoryKey': categoryCtrl.text.trim().toLowerCase(),
                      'coverImage': coverCtrl.text.trim(),
                      'profileImage': profileCtrl.text.trim(),
                      'groupType': groupType,
                    };
                    if (group == null) {
                      await ApiService.adminCreateGroup(_adminId, data);
                      _showSnack("Group created");
                    } else {
                      await ApiService.adminUpdateGroup(
                          _adminId, group['_id'], data);
                      _showSnack("Group updated");
                    }
                    _load();
                  } catch (e) {
                    _showSnack(e.toString(), error: true);
                  }
                },
                child: Text("Save",
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Image URL field with thumbnail preview + gallery upload button ────────
  Widget _imagePickerField(
    String label,
    TextEditingController ctrl, {
    required bool isUploading,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(label, ctrl, hint: "https://... or assets/images/..."),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ctrl.text.trim().isNotEmpty
                  ? _buildImage(ctrl.text.trim(), width: 56, height: 56)
                  : _groupPlaceholderSized(56, 56),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: isUploading ? null : onPick,
              icon: isUploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AdminTheme.wine),
                    )
                  : const Icon(Icons.upload_rounded,
                      size: 16, color: AdminTheme.wine),
              label: Text(isUploading ? "Uploading..." : "Upload Image",
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, color: AdminTheme.wine)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AdminTheme.wine),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── View Details dialog ───────────────────────────────────────────────────
  void _showDetailsDialog(Map g) {
    final coverPath = (g['coverImage'] ?? '').toString();
    final profilePath = (g['profileImage'] ?? '').toString();
    final previewPath = coverPath.isNotEmpty ? coverPath : profilePath;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cover image banner
              if (previewPath.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: _buildImage(previewPath,
                      height: 130, width: double.infinity),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile image + title row
                    Row(children: [
                      if (profilePath.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child:
                              _buildImage(profilePath, height: 44, width: 44),
                        ),
                      if (profilePath.isNotEmpty) const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g['title'] ?? '',
                                  style: AdminTheme.title(15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(g['slug'] ?? '',
                                  style: AdminTheme.sub(12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ]),
                      ),
                      _activeDot(g['isActive'] != false),
                    ]),
                    const SizedBox(height: 14),
                    const Divider(color: AdminTheme.line, height: 1),
                    const SizedBox(height: 12),
                    _detailRow("Type", g['groupType'] ?? 'N/A'),
                    _detailRow(
                        "Category Key",
                        g['categoryKey']?.isNotEmpty == true
                            ? g['categoryKey']
                            : 'N/A'),
                    _detailRow("Members", "${g['membersCount'] ?? 0}"),
                    _detailRow("Active", g['isActive'] != false ? 'Yes' : 'No'),
                    if ((g['description'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text("Description",
                          style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: AdminTheme.grey,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(g['description'],
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AdminTheme.black,
                              height: 1.5)),
                    ],
                    if (g['createdAt'] != null) ...[
                      const SizedBox(height: 8),
                      _detailRow(
                          "Created", _formatDate(g['createdAt'].toString())),
                    ],
                    if (g['updatedAt'] != null)
                      _detailRow(
                          "Updated", _formatDate(g['updatedAt'].toString())),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close",
                  style: GoogleFonts.poppins(color: AdminTheme.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.wine,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(ctx);
              _showEditDialog(g);
            },
            child: Text("Edit",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 96,
            child: Text("$label:",
                style:
                    GoogleFonts.poppins(fontSize: 12, color: AdminTheme.grey)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AdminTheme.black,
                    fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AdminTheme.wine))
              : _groups.isEmpty
                  ? _emptyState()
                  : _buildList(),
        ),
      ],
    );
  }

  Widget _topBar() => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        color: AdminTheme.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text("Groups", style: AdminTheme.title(20)),
              const SizedBox(width: 10),
              _badge(_total),
              const Spacer(),
              _wineBtn("Add Group", Icons.add, () => _showEditDialog()),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _load(),
                  decoration: _inputDec("Search groups...").copyWith(
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: AdminTheme.grey)),
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _typeFilter.isEmpty ? null : _typeFilter,
                  hint: Text("All Types",
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AdminTheme.grey)),
                  borderRadius: BorderRadius.circular(12),
                  items: _groupTypes
                      .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.isEmpty ? "All Types" : t,
                              style: GoogleFonts.poppins(fontSize: 13))))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _typeFilter = v ?? '');
                    _load();
                  },
                ),
              ),
            ]),
          ],
        ),
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _groups.length,
        itemBuilder: (_, i) => _buildRow(_groups[i] as Map),
      );

  Widget _buildRow(Map g) {
    final isActive = g['isActive'] != false;
    final coverPath = (g['coverImage'] ?? '').toString();
    final profilePath = (g['profileImage'] ?? '').toString();
    final imagePath = coverPath.isNotEmpty ? coverPath : profilePath;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AdminTheme.cardDec(),
      child: Row(
        children: [
          // Smart image: handles network URLs, asset paths, fallback
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imagePath.isNotEmpty
                ? _buildImage(imagePath, height: 48, width: 48)
                : _groupPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g['title'] ?? '',
                  style: AdminTheme.title(13.5, w: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(
                "${g['slug'] ?? ''} • ${g['groupType'] ?? ''}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AdminTheme.sub(11.5),
              ),
              Text(
                "Category: ${g['categoryKey']?.isNotEmpty == true ? g['categoryKey'] : 'N/A'} • ${g['membersCount'] ?? 0} members",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    GoogleFonts.poppins(fontSize: 11, color: AdminTheme.wine),
              ),
            ]),
          ),
          _activeDot(isActive),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 18, color: AdminTheme.grey),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) async {
              if (v == 'details') _showDetailsDialog(g);
              if (v == 'preview') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetailsScreen(
                      groupSlug: g['slug'] ?? '',
                      userId: _adminId,
                      userName: _adminName,
                    ),
                  ),
                );
              }
              if (v == 'posts') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminGroupPostsByGroupScreen(
                      groupId: g['_id'].toString(),
                      groupTitle: g['title'] ?? '',
                      groupSlug: g['slug'] ?? '',
                    ),
                  ),
                );
              }
              if (v == 'members') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminGroupMembersScreen(
                      groupId: g['_id'].toString(),
                      groupTitle: g['title'] ?? '',
                    ),
                  ),
                );
              }
              if (v == 'edit') _showEditDialog(g);
              if (v == 'toggle') {
                await ApiService.adminToggleGroupActive(_adminId, g['_id']);
                _showSnack(isActive ? "Group deactivated" : "Group activated");
                _load();
              }
              if (v == 'delete') {
                if (await _confirm(
                    "Delete this group? This cannot be undone.")) {
                  await ApiService.adminDeleteGroup(_adminId, g['_id']);
                  _showSnack("Group deleted");
                  _load();
                }
              }
            },
            itemBuilder: (_) => [
              _popItem('details', 'View Details', Icons.info_outline_rounded),
              _popItem('preview', 'Preview as User', Icons.visibility_outlined),
              _popItem('posts', 'View Posts', Icons.article_outlined),
              _popItem('members', 'View Members', Icons.group_outlined),
              const PopupMenuDivider(),
              _popItem('edit', 'Edit', Icons.edit_outlined),
              _popItem('toggle', isActive ? 'Deactivate' : 'Activate',
                  isActive ? Icons.block_outlined : Icons.check_circle_outline),
              _popItem('delete', 'Delete', Icons.delete_outline, danger: true),
            ],
          ),
        ],
      ),
    );
  }

  // ── Smart image widget: network URL vs local asset vs placeholder ─────────
  Widget _buildImage(String path, {double? width, double? height}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _groupPlaceholderSized(width, height),
      );
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _groupPlaceholderSized(width, height),
    );
  }

  Widget _groupPlaceholder() => _groupPlaceholderSized(48, 48);

  Widget _groupPlaceholderSized(double? w, double? h) => Container(
        width: w,
        height: h,
        color: AdminTheme.wineMuted,
        child: const Icon(Icons.spa_outlined, color: AdminTheme.wine, size: 22),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────
  PopupMenuItem<String> _popItem(String v, String l, IconData i,
          {bool danger = false}) =>
      PopupMenuItem(
        value: v,
        child: Row(children: [
          Icon(i,
              size: 16, color: danger ? Colors.red.shade400 : AdminTheme.grey),
          const SizedBox(width: 8),
          Text(l,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: danger ? Colors.red.shade400 : AdminTheme.black)),
        ]),
      );

  Widget _badge(int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
            color: AdminTheme.wineMuted,
            borderRadius: BorderRadius.circular(20)),
        child: Text("$n",
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: AdminTheme.wine,
                fontWeight: FontWeight.w600)),
      );

  Widget _activeDot(bool a) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
            color: a ? Colors.green.shade400 : Colors.red.shade300,
            shape: BoxShape.circle),
      );

  Widget _wineBtn(String label, IconData icon, VoidCallback onTap) =>
      ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17, color: Colors.white),
        label: Text(label,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.wine,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
      );

  Widget _emptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.spa_outlined,
            size: 60, color: AdminTheme.grey.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text("No groups found", style: AdminTheme.sub(15)),
        const SizedBox(height: 8),
        _wineBtn("Add First Group", Icons.add, () => _showEditDialog()),
      ]));

  InputDecoration _inputDec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  TextField _field(String label, TextEditingController ctrl,
          {String? hint, int maxLines = 1}) =>
      TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: _inputDec(label, hint: hint),
          style: GoogleFonts.poppins(fontSize: 13));

  Future<bool> _confirm(String msg) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Confirm",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: AdminTheme.black)),
          content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text("Cancel",
                    style: GoogleFonts.poppins(color: AdminTheme.grey))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text("Confirm",
                    style: GoogleFonts.poppins(color: Colors.white))),
          ],
        ),
      ) ??
      false;

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
