import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminGroupPostsScreen extends StatefulWidget {
  const AdminGroupPostsScreen({super.key});
  @override
  State<AdminGroupPostsScreen> createState() => _AdminGroupPostsScreenState();
}

class _AdminGroupPostsScreenState extends State<AdminGroupPostsScreen> {
  bool _loading = true;
  List _posts = [];
  int _total = 0;
  String _adminId = '';
  final _searchCtrl = TextEditingController();
  String _typeFilter = '';
  String _statusFilter = '';

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
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.adminGetGroupPosts(
        _adminId,
        search: _searchCtrl.text.trim(),
        postType: _typeFilter,
        approvalStatus: _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _posts = data['posts'] as List? ?? [];
        _total = data['total'] ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showDetails(Map post) {
    final likes = (post['likes'] as List?)?.length ?? 0;
    final comments = (post['comments'] as List?)?.length ?? 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Post Details",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AdminTheme.black)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _detail("Author", post['userName'] ?? ''),
                _detail("Type", post['postType'] ?? ''),
                _detail("Tag", post['tag'] ?? ''),
                if ((post['groupTitle'] ?? '').toString().isNotEmpty)
                  _detail("Group", post['groupTitle']),
                if ((post['productName'] ?? '').toString().isNotEmpty)
                  _detail("Product", post['productName']),
                _detail("Rating", post['rating']?.toString() ?? '0'),
                _detail("Likes", "$likes"),
                _detail("Comments", "$comments"),
                _detail("Hidden", post['isHidden'] == true ? 'Yes' : 'No'),
                _detail("Status", post['approvalStatus'] ?? 'approved'),
                const SizedBox(height: 10),
                Text("Content:",
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AdminTheme.grey)),
                const SizedBox(height: 4),
                Text(post['content'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AdminTheme.black)),
              ])),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close",
                  style: GoogleFonts.poppins(color: AdminTheme.grey))),
        ],
      ),
    );
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
              : _posts.isEmpty
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
              Text("Group Posts", style: AdminTheme.title(20)),
              const SizedBox(width: 10),
              _badge(_total),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _load(),
                decoration: _inputDec("Search posts...").copyWith(
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: AdminTheme.grey)),
                style: GoogleFonts.poppins(fontSize: 13),
              )),
              const SizedBox(width: 10),
              _dropDown(
                  _typeFilter, ['', 'review', 'question', 'update'], 'Type',
                  (v) {
                setState(() => _typeFilter = v);
                _load();
              }),
              const SizedBox(width: 10),
              _dropDown(_statusFilter, ['', 'pending', 'approved', 'rejected'],
                  'Status', (v) {
                setState(() => _statusFilter = v);
                _load();
              }),
            ]),
          ],
        ),
      );

  Widget _dropDown(String value, List<String> options, String hint,
      void Function(String) onChanged) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value.isEmpty ? null : value,
        hint: Text(hint,
            style: GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey)),
        borderRadius: BorderRadius.circular(12),
        items: options
            .map((o) => DropdownMenuItem(
                value: o,
                child: Text(o.isEmpty ? "All" : o,
                    style: GoogleFonts.poppins(fontSize: 13))))
            .toList(),
        onChanged: (v) => onChanged(v ?? ''),
      ),
    );
  }

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _posts.length,
        itemBuilder: (_, i) => _buildRow(_posts[i] as Map),
      );

  Widget _buildRow(Map p) {
    final isHidden = p['isHidden'] == true;
    final status = p['approvalStatus'] ?? 'approved';
    final likes = (p['likes'] as List?)?.length ?? 0;
    final comments = (p['comments'] as List?)?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration:
          AdminTheme.cardDec(color: isHidden ? const Color(0xFFFDF5F5) : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(p['userName'] ?? '',
                    style: AdminTheme.title(13.5, w: FontWeight.w500)),
                Row(children: [
                  _typeBadge(p['postType'] ?? 'review'),
                  const SizedBox(width: 6),
                  _statusBadge(status),
                  if (isHidden) ...[
                    const SizedBox(width: 6),
                    _hiddenBadge(),
                  ],
                ]),
              ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 18, color: AdminTheme.grey),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) async {
              if (v == 'details') _showDetails(p);
              if (v == 'hide') {
                await ApiService.adminToggleGroupPostHidden(_adminId, p['_id']);
                _showSnack(isHidden ? "Post shown" : "Post hidden");
                _load();
              }
              if (v == 'approve') {
                await ApiService.adminSetGroupPostStatus(
                    _adminId, p['_id'], 'approved');
                _showSnack("Post approved");
                _load();
              }
              if (v == 'reject') {
                await ApiService.adminSetGroupPostStatus(
                    _adminId, p['_id'], 'rejected');
                _showSnack("Post rejected");
                _load();
              }
              if (v == 'delete') {
                if (await _confirm("Delete this post permanently?")) {
                  await ApiService.adminDeleteGroupPost(_adminId, p['_id']);
                  _showSnack("Post deleted");
                  _load();
                }
              }
            },
            itemBuilder: (_) => [
              _popItem('details', 'View Details', Icons.info_outline),
              _popItem(
                  'hide',
                  isHidden ? 'Show Post' : 'Hide Post',
                  isHidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
              if (status != 'approved')
                _popItem('approve', 'Approve', Icons.check_circle_outline),
              if (status != 'rejected')
                _popItem('reject', 'Reject', Icons.cancel_outlined),
              _popItem('delete', 'Delete', Icons.delete_outline, danger: true),
            ],
          ),
        ]),
        if ((p['content'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(p['content'],
              style: AdminTheme.sub(12.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Row(children: [
          if ((p['groupTitle'] ?? '').toString().isNotEmpty)
            Text(p['groupTitle'],
                style:
                    GoogleFonts.poppins(fontSize: 11, color: AdminTheme.wine)),
          const Spacer(),
          Icon(Icons.favorite_border_rounded, size: 13, color: AdminTheme.grey),
          const SizedBox(width: 3),
          Text("$likes", style: AdminTheme.sub(12)),
          const SizedBox(width: 10),
          Icon(Icons.comment_outlined, size: 13, color: AdminTheme.grey),
          const SizedBox(width: 3),
          Text("$comments", style: AdminTheme.sub(12)),
          if ((p['rating'] as num? ?? 0) > 0) ...[
            const SizedBox(width: 10),
            Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade600),
            const SizedBox(width: 2),
            Text("${p['rating']}", style: AdminTheme.sub(12)),
          ],
        ]),
      ]),
    );
  }

  // ── helpers ──
  Widget _typeBadge(String type) {
    Color c = type == 'review'
        ? AdminTheme.wine
        : type == 'question'
            ? Colors.blue.shade400
            : Colors.orange.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(type,
          style: GoogleFonts.poppins(
              fontSize: 10, color: c, fontWeight: FontWeight.w600)),
    );
  }

  Widget _statusBadge(String status) {
    Color c = status == 'approved'
        ? Colors.green.shade500
        : status == 'rejected'
            ? Colors.red.shade400
            : Colors.orange.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(status,
          style: GoogleFonts.poppins(
              fontSize: 10, color: c, fontWeight: FontWeight.w600)),
    );
  }

  Widget _hiddenBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8)),
        child: Text("hidden",
            style: GoogleFonts.poppins(
                fontSize: 10,
                color: AdminTheme.grey,
                fontWeight: FontWeight.w600)),
      );

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 80, child: Text("$label:", style: AdminTheme.sub(12))),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AdminTheme.black,
                      fontWeight: FontWeight.w500))),
        ]),
      );

  PopupMenuItem<String> _popItem(String v, String l, IconData i,
          {bool danger = false}) =>
      PopupMenuItem(
          value: v,
          child: Row(children: [
            Icon(i,
                size: 16,
                color: danger ? Colors.red.shade400 : AdminTheme.grey),
            const SizedBox(width: 8),
            Text(l,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: danger ? Colors.red.shade400 : AdminTheme.black)),
          ]));

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

  Widget _emptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.article_outlined,
            size: 60, color: AdminTheme.grey.withOpacity(0.3)),
        const SizedBox(height: 12),
        Text("No posts found", style: AdminTheme.sub(15)),
      ]));

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Future<bool> _confirm(String msg) async =>
      await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
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
              )) ??
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
