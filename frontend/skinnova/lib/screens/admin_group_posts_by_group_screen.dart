import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

/// Shows all posts belonging to a specific group (admin view).
/// Navigated to from the AdminGroupsScreen "View Posts" action.
class AdminGroupPostsByGroupScreen extends StatefulWidget {
  final String groupId;
  final String groupTitle;
  final String groupSlug;

  const AdminGroupPostsByGroupScreen({
    super.key,
    required this.groupId,
    required this.groupTitle,
    required this.groupSlug,
  });

  @override
  State<AdminGroupPostsByGroupScreen> createState() =>
      _AdminGroupPostsByGroupScreenState();
}

class _AdminGroupPostsByGroupScreenState
    extends State<AdminGroupPostsByGroupScreen> {
  bool _loading = true;
  List _posts = [];
  String _adminId = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminId = prefs.getString('userId') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data =
          await ApiService.adminGetGroupPostsByGroup(_adminId, widget.groupId);
      if (!mounted) return;
      setState(() {
        _posts = data['posts'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await _showConfirm("Delete this post permanently?");
    if (!confirm) return;
    final ok = await ApiService.adminDeleteGroupPost(_adminId, postId);
    if (ok) {
      _showSnack("Post deleted");
      _load();
    } else {
      _showSnack("Failed to delete post", error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: AppBar(
        backgroundColor: AdminTheme.card,
        foregroundColor: AdminTheme.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Group Posts",
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.black)),
            Text(widget.groupTitle,
                style:
                    GoogleFonts.poppins(fontSize: 12, color: AdminTheme.grey)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AdminTheme.line, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminTheme.wine),
            onPressed: _load,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AdminTheme.wine))
          : _posts.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  color: AdminTheme.wine,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (_, i) => _buildPostCard(_posts[i] as Map),
                  ),
                ),
    );
  }

  Widget _buildPostCard(Map post) {
    final userName = post['userName'] ?? 'Unknown';
    final content = (post['content'] ?? '').toString();
    final productName = (post['productName'] ?? '').toString();
    final productImage = (post['productImage'] ?? '').toString();
    final postType = post['postType'] ?? 'review';
    final likes = (post['likes'] as List?)?.length ?? 0;
    final comments = (post['comments'] as List?)?.length ?? 0;
    final rating = (post['rating'] as num?)?.toInt() ?? 0;
    final isHidden = post['isHidden'] == true;
    final approvalStatus = post['approvalStatus'] ?? 'approved';
    final createdAt = _formatDate(post['createdAt']?.toString() ?? '');
    final userAvatar = (post['userAvatar'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration:
          AdminTheme.cardDec(color: isHidden ? const Color(0xFFFDF5F5) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AdminTheme.wineMuted,
                backgroundImage: userAvatar.startsWith('http')
                    ? NetworkImage(userAvatar)
                    : null,
                child: !userAvatar.startsWith('http')
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.wine,
                            fontSize: 13),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName,
                          style: AdminTheme.title(13.5, w: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(createdAt, style: AdminTheme.sub(11.5)),
                    ]),
              ),
              // Type badge
              _typeBadge(postType),
              const SizedBox(width: 6),
              // More actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 18, color: AdminTheme.grey),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (v) async {
                  if (v == 'hide') {
                    await ApiService.adminToggleGroupPostHidden(
                        _adminId, post['_id'].toString());
                    _showSnack(isHidden ? "Post shown" : "Post hidden");
                    _load();
                  }
                  if (v == 'approve') {
                    await ApiService.adminSetGroupPostStatus(
                        _adminId, post['_id'].toString(), 'approved');
                    _showSnack("Approved");
                    _load();
                  }
                  if (v == 'reject') {
                    await ApiService.adminSetGroupPostStatus(
                        _adminId, post['_id'].toString(), 'rejected');
                    _showSnack("Rejected");
                    _load();
                  }
                  if (v == 'delete') {
                    await _deletePost(post['_id'].toString());
                  }
                },
                itemBuilder: (_) => [
                  _menuItem(
                      'hide',
                      isHidden ? 'Show Post' : 'Hide Post',
                      isHidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                  if (approvalStatus != 'approved')
                    _menuItem('approve', 'Approve', Icons.check_circle_outline),
                  if (approvalStatus != 'rejected')
                    _menuItem('reject', 'Reject', Icons.cancel_outlined),
                  _menuItem('delete', 'Delete', Icons.delete_outline,
                      danger: true),
                ],
              ),
            ]),
          ),

          // ── Product row (if linked) ──
          if (productName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(children: [
                if (productImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      productImage,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                if (productImage.isNotEmpty) const SizedBox(width: 6),
                Expanded(
                  child: Text(productName,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AdminTheme.wine,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (rating > 0)
                  Row(children: [
                    Icon(Icons.star_rounded,
                        size: 13, color: Colors.amber.shade600),
                    Text(" $rating",
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AdminTheme.grey)),
                  ]),
              ]),
            ),

          // ── Content ──
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(content,
                  style: AdminTheme.sub(13),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis),
            ),

          // ── Images row ──
          if ((post['images'] as List?)?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: (post['images'] as List).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final imgUrl = (post['images'] as List)[i].toString();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(imgUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink()),
                    );
                  },
                ),
              ),
            ),

          // ── Footer: likes, comments, status badges ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(Icons.favorite_border_rounded,
                  size: 14, color: AdminTheme.grey),
              const SizedBox(width: 3),
              Text("$likes", style: AdminTheme.sub(12)),
              const SizedBox(width: 12),
              Icon(Icons.comment_outlined, size: 14, color: AdminTheme.grey),
              const SizedBox(width: 3),
              Text("$comments", style: AdminTheme.sub(12)),
              const Spacer(),
              if (isHidden) _pill("hidden", Colors.grey.shade500),
              if (approvalStatus == 'rejected')
                _pill("rejected", Colors.red.shade400),
              if (approvalStatus == 'pending')
                _pill("pending", Colors.orange.shade500),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String type) {
    Color c = type == 'review'
        ? AdminTheme.wine
        : type == 'question'
            ? Colors.blue.shade500
            : Colors.orange.shade500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(type,
          style: GoogleFonts.poppins(
              fontSize: 10.5, color: c, fontWeight: FontWeight.w600)),
    );
  }

  Widget _pill(String label, Color color) => Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10.5, color: color, fontWeight: FontWeight.w600)),
      );

  PopupMenuItem<String> _menuItem(String v, String l, IconData i,
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

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.article_outlined,
              size: 64, color: AdminTheme.grey.withOpacity(0.3)),
          const SizedBox(height: 14),
          Text("No posts in this group", style: AdminTheme.sub(15)),
          const SizedBox(height: 6),
          Text(
              "Posts written about or inside \"${widget.groupTitle}\" will appear here.",
              textAlign: TextAlign.center,
              style: AdminTheme.sub(13)),
        ]),
      );

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }

  Future<bool> _showConfirm(String msg) async =>
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
                child: Text("Delete",
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
