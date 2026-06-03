import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class AdminSupportCenterScreen extends StatefulWidget {
  const AdminSupportCenterScreen({super.key});

  @override
  State<AdminSupportCenterScreen> createState() =>
      _AdminSupportCenterScreenState();
}

class _AdminSupportCenterScreenState extends State<AdminSupportCenterScreen>
    with SingleTickerProviderStateMixin {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFFF5F5F3);
  static const Color wine = Color(0xFF5B2333);
  static const Color black = Color(0xFF202020);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFE8E8E8);
  static const Color card = Colors.white;

  late TabController _tabCtrl;
  final List<String> _tabs = ["All", "Contact", "Bug Reports"];
  final List<String?> _typeFilters = [null, "contact", "bug"];

  String? _statusFilter;
  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final typeFilter = _typeFilters[_tabCtrl.index];
    final result = await ApiService.fetchUserSupportMessages(
      type: typeFilter,
      status: _statusFilter,
    );
    if (!mounted) return;
    setState(() {
      _messages = (result['messages'] as List?) ?? [];
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(String id, String status) async {
    final ok = await ApiService.updateUserSupportMessageStatus(id, status);
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update status")),
      );
    }
  }

  Future<void> _showNoteDialog(Map<String, dynamic> msg) async {
    final noteCtrl =
        TextEditingController(text: msg['adminNote']?.toString() ?? '');
    String selectedStatus = msg['status']?.toString() ?? 'open';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Update Message",
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Status",
                  style: GoogleFonts.poppins(fontSize: 12, color: grey)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: "open", child: Text("Open")),
                  DropdownMenuItem(
                      value: "in_progress", child: Text("In Progress")),
                  DropdownMenuItem(value: "resolved", child: Text("Resolved")),
                  DropdownMenuItem(
                      value: "dismissed", child: Text("Dismissed")),
                ],
                onChanged: (v) =>
                    setDialogState(() => selectedStatus = v ?? selectedStatus),
              ),
              const SizedBox(height: 14),
              Text("Admin Note (optional)",
                  style: GoogleFonts.poppins(fontSize: 12, color: grey)),
              const SizedBox(height: 6),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Add an internal note...",
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: grey),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: GoogleFonts.poppins(fontSize: 13, color: black),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text("Cancel",
                  style: GoogleFonts.poppins(fontSize: 13, color: grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: wine,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("Save",
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      await ApiService.updateUserSupportMessageStatus(
        msg['_id'].toString(),
        selectedStatus,
        adminNote: noteCtrl.text.trim(),
      );
      _load();
    }
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Message",
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: black)),
        content: Text(
            "This message will be permanently deleted. This cannot be undone.",
            style: GoogleFonts.poppins(fontSize: 13, color: grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel",
                style: GoogleFonts.poppins(fontSize: 13, color: grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Delete",
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ApiService.deleteUserSupportMessage(id);
      _load();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFFD97706);
      case 'in_progress':
        return const Color(0xFF2563EB);
      case 'resolved':
        return const Color(0xFF2E7D52);
      case 'dismissed':
        return grey;
      default:
        return grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'dismissed':
        return 'Dismissed';
      default:
        return status;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          _buildStatusFilterRow(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final openCount = _messages.where((m) => m['status'] == 'open').length;
    return Container(
      color: card,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Support Center",
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: black)),
                const SizedBox(height: 2),
                Text(
                  _isLoading
                      ? "Loading..."
                      : "$openCount open message${openCount == 1 ? '' : 's'}",
                  style: GoogleFonts.poppins(fontSize: 12.5, color: grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: wine),
            tooltip: "Refresh",
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: card,
      child: Column(
        children: [
          Container(height: 1, color: line),
          TabBar(
            controller: _tabCtrl,
            labelColor: wine,
            unselectedLabelColor: grey,
            indicatorColor: wine,
            indicatorWeight: 2.5,
            labelStyle:
                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterRow() {
    final statuses = [null, 'open', 'in_progress', 'resolved', 'dismissed'];
    final labels = ['All', 'Open', 'In Progress', 'Resolved', 'Dismissed'];
    return Container(
      color: const Color(0xFFFAF8F7),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(statuses.length, (i) {
            final selected = _statusFilter == statuses[i];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _statusFilter = statuses[i]);
                  _load();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? wine : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? wine : line, width: selected ? 0 : 1),
                  ),
                  child: Text(
                    labels[i],
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : grey,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: wine, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.red)));
    }
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: wine.withOpacity(0.07),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.support_agent_rounded,
                  size: 36, color: wine),
            ),
            const SizedBox(height: 16),
            Text("No messages found",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: black)),
            const SizedBox(height: 6),
            Text("Support messages will appear here.",
                style: GoogleFonts.poppins(fontSize: 13, color: grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: wine,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        itemCount: _messages.length,
        itemBuilder: (_, i) => _buildCard(_messages[i]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> msg) {
    final type = msg['type']?.toString() ?? 'contact';
    final subject = msg['subject']?.toString() ?? '';
    final message = msg['message']?.toString() ?? '';
    final userName = msg['userName']?.toString() ?? '';
    final email = msg['email']?.toString() ?? '';
    final status = msg['status']?.toString() ?? 'open';
    final adminNote = msg['adminNote']?.toString() ?? '';
    final createdAt = msg['createdAt']?.toString() ?? '';
    final id = msg['_id']?.toString() ?? '';

    final isBug = type == 'bug';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBug ? Colors.red.shade50 : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBug
                            ? Icons.bug_report_outlined
                            : Icons.mail_outline_rounded,
                        size: 13,
                        color: isBug
                            ? Colors.red.shade600
                            : const Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isBug ? "Bug Report" : "Contact",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isBug
                              ? Colors.red.shade600
                              : const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Status chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // More options
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) async {
                    if (v == 'note') {
                      _showNoteDialog(msg);
                    } else if (v == 'delete') {
                      _confirmDelete(id);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'note',
                      child: Row(children: [
                        const Icon(Icons.edit_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text("Update / Add Note",
                            style: GoogleFonts.poppins(fontSize: 13)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 16, color: Colors.red.shade500),
                        const SizedBox(width: 8),
                        Text("Delete",
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.red.shade500)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Subject ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              subject,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600, color: black),
            ),
          ),

          // ── Message ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              message,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: grey, height: 1.5),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Admin note ────────────────────────────────────────────────────
          if (adminNote.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      adminNote,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF92400E),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1, color: line),

          // ── Footer ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    userName.isEmpty ? "Anonymous" : userName,
                    style: GoogleFonts.poppins(fontSize: 12, color: grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.mail_outline_rounded, size: 14, color: grey),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      email,
                      style: GoogleFonts.poppins(fontSize: 12, color: grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  _formatDate(createdAt),
                  style: GoogleFonts.poppins(fontSize: 11, color: grey),
                ),
              ],
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────────
          if (status == 'open' || status == 'in_progress')
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  if (status == 'open')
                    _actionBtn(
                      label: "In Progress",
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFF2563EB),
                      onTap: () => _updateStatus(id, 'in_progress'),
                    ),
                  if (status == 'open') const SizedBox(width: 8),
                  _actionBtn(
                    label: "Resolve",
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF2E7D52),
                    onTap: () => _updateStatus(id, 'resolved'),
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    label: "Dismiss",
                    icon: Icons.cancel_outlined,
                    color: grey,
                    onTap: () => _updateStatus(id, 'dismissed'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
