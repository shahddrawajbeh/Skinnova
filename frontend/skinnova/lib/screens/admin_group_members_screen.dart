import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

/// Shows all members who joined a specific group (admin view).
class AdminGroupMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupTitle;

  const AdminGroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupTitle,
  });

  @override
  State<AdminGroupMembersScreen> createState() =>
      _AdminGroupMembersScreenState();
}

class _AdminGroupMembersScreenState extends State<AdminGroupMembersScreen> {
  bool _loading = true;
  List _members = [];
  int _total = 0;
  int _storedCount = 0;
  String _adminId = '';
  final _searchCtrl = TextEditingController();
  List _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilter);
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
      final data =
          await ApiService.adminGetGroupMembers(_adminId, widget.groupId);
      if (!mounted) return;
      final members = data['members'] as List? ?? [];
      setState(() {
        _members = members;
        _total = data['total'] ?? members.length;
        _storedCount = data['storedMembersCount'] ?? 0;
        _filtered = members;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _members);
      return;
    }
    setState(() {
      _filtered = _members.where((m) {
        final user = (m['user'] as Map?) ?? {};
        final name = (user['fullName'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    });
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
            Text("Group Members",
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
          : Column(children: [
              _buildHeader(),
              Expanded(
                child: _filtered.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AdminTheme.wine,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _buildMemberCard(_filtered[i] as Map),
                        ),
                      ),
              ),
            ]),
    );
  }

  Widget _buildHeader() => Container(
        color: AdminTheme.card,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(children: [
          // Stats row
          Row(children: [
            _statChip("Total Joined", "$_total", Colors.green.shade600),
            const SizedBox(width: 10),
          ]),
          const SizedBox(height: 10),
          // Search
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: "Search by name or email...",
              hintStyle:
                  GoogleFonts.poppins(fontSize: 13, color: AdminTheme.grey),
              prefixIcon:
                  const Icon(Icons.search, size: 18, color: AdminTheme.grey),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          size: 16, color: AdminTheme.grey),
                      onPressed: () {
                        _searchCtrl.clear();
                        _applyFilter();
                      },
                    )
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ]),
      );

  Widget _statChip(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ]),
      );

  Widget _buildMemberCard(Map member) {
    final user = (member['user'] as Map?) ?? {};
    final fullName = (user['fullName'] ?? 'Unknown').toString();
    final email = (user['email'] ?? '').toString();
    final avatar = (user['profileImage'] ?? '').toString();
    final joinedAt = _formatDate(member['joinedAt']?.toString() ?? '');
    final hasAvatar = avatar.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AdminTheme.cardDec(),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: AdminTheme.wineMuted,
          backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
          child: !hasAvatar
              ? Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.wine,
                      fontSize: 15),
                )
              : null,
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fullName,
                style: AdminTheme.title(13.5, w: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (email.isNotEmpty)
              Text(email,
                  style: AdminTheme.sub(12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ]),
        ),
        // Joined date
        if (joinedAt.isNotEmpty)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("Joined", style: AdminTheme.sub(10.5)),
            Text(joinedAt,
                style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AdminTheme.wine,
                    fontWeight: FontWeight.w500)),
          ]),
      ]),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.group_outlined,
              size: 64, color: AdminTheme.grey.withOpacity(0.3)),
          const SizedBox(height: 14),
          Text(
            _searchCtrl.text.isNotEmpty
                ? "No members match \"${_searchCtrl.text}\""
                : "No members yet",
            style: AdminTheme.sub(15),
          ),
          const SizedBox(height: 6),
          if (_searchCtrl.text.isEmpty)
            Text("Users who join \"${widget.groupTitle}\" will appear here.",
                textAlign: TextAlign.center, style: AdminTheme.sub(13)),
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
}
