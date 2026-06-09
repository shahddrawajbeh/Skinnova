import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});
  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  String _adminId = '';

  @override
  void initState() {
    super.initState();
    _loadAdminId();
  }

  Future<void> _loadAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _adminId = prefs.getString('userId') ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Container(
          color: AdminTheme.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Admin Notifications", style: AdminTheme.title(20)),
                    const SizedBox(height: 2),
                    Text(
                      "Track important system alerts, reports, support messages, and store activity.",
                      style: AdminTheme.sub(13),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: AdminTheme.line),
            ],
          ),
        ),
        Expanded(
          child: _AdminInboxTab(adminId: _adminId),
        ),
      ],
    );
    if (Scaffold.maybeOf(context) != null) return content;
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AdminTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: AdminTheme.title(15, w: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AdminTheme.line),
        ),
      ),
      body: content,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Admin Inbox Tab
// ══════════════════════════════════════════════════════════════════════════════

class _AdminInboxTab extends StatefulWidget {
  final String adminId;
  const _AdminInboxTab({required this.adminId});

  @override
  State<_AdminInboxTab> createState() => _AdminInboxTabState();
}

class _AdminInboxTabState extends State<_AdminInboxTab> {
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.adminId.isNotEmpty) _load();
  }

  @override
  void didUpdateWidget(covariant _AdminInboxTab old) {
    super.didUpdateWidget(old);
    if (old.adminId != widget.adminId && widget.adminId.isNotEmpty) _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.fetchNotifications(widget.adminId);
      if (!mounted) return;
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to load notifications";
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    await ApiService.markAllNotificationsRead(widget.adminId);
    if (!mounted) return;
    setState(() {
      for (final n in _notifications) {
        n['isRead'] = true;
      }
    });
  }

  Future<void> _markRead(String id, int index) async {
    if (_notifications[index]['isRead'] == true) return;
    await ApiService.markNotificationRead(id);
    if (!mounted) return;
    setState(() => _notifications[index]['isRead'] = true);
  }

  // ── Type → icon / color ──────────────────────────────────────────────────

  IconData _iconFor(String type) {
    switch (type) {
      case 'new_store_request':
        return Icons.store_outlined;
      case 'store_approved':
      case 'store_rejected':
        return Icons.store_rounded;
      case 'new_ad_request':
      case 'ad_approved':
      case 'ad_rejected':
        return Icons.campaign_outlined;
      case 'new_order':
        return Icons.shopping_bag_outlined;
      case 'review_submitted':
      case 'review_pending':
        return Icons.star_outline_rounded;
      case 'support_contact':
        return Icons.mail_outline_rounded;
      case 'support_bug':
        return Icons.bug_report_outlined;
      case 'store_report':
        return Icons.flag_outlined;
      case 'post_like':
        return Icons.favorite_border_rounded;
      case 'post_comment':
        return Icons.chat_bubble_outline_rounded;
      case 'new_follower':
      case 'store_new_follower':
        return Icons.person_add_alt_outlined;
      case 'promo':
        return Icons.local_offer_outlined;
      case 'skin_scan_reminder':
        return Icons.camera_alt_outlined;
      case 'routine_step_reminder':
        return Icons.spa_outlined;
      case 'skincare_tip':
        return Icons.lightbulb_outline_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'new_store_request':
      case 'new_ad_request':
        return const Color(0xFFD97706);
      case 'store_approved':
      case 'ad_approved':
        return const Color(0xFF2E7D52);
      case 'store_rejected':
      case 'ad_rejected':
        return Colors.red.shade600;
      case 'new_order':
        return const Color(0xFF2563EB);
      case 'review_submitted':
      case 'review_pending':
        return const Color(0xFFB45309);
      case 'support_contact':
        return const Color(0xFF0891B2);
      case 'support_bug':
        return Colors.red.shade500;
      case 'store_report':
        return Colors.red.shade600;
      case 'post_like':
        return Colors.pink.shade400;
      case 'post_comment':
        return const Color(0xFF7C3AED);
      case 'promo':
        return const Color(0xFF059669);
      case 'skin_scan_reminder':
        return const Color(0xFF2563EB);
      case 'routine_step_reminder':
        return const Color(0xFF2E7D52);
      case 'skincare_tip':
        return const Color(0xFFB45309);
      default:
        return AdminTheme.wine;
    }
  }

  String _labelFor(String type) {
    const map = {
      'new_store_request': 'Store Request',
      'store_approved': 'Store Approved',
      'store_rejected': 'Store Rejected',
      'new_ad_request': 'Ad Request',
      'ad_approved': 'Ad Approved',
      'ad_rejected': 'Ad Rejected',
      'new_order': 'New Order',
      'order_status_changed': 'Order Update',
      'review_submitted': 'Review',
      'review_pending': 'Pending Review',
      'support_contact': 'Contact',
      'support_bug': 'Bug Report',
      'store_report': 'Store Report',
      'post_like': 'Like',
      'post_comment': 'Comment',
      'new_follower': 'Follower',
      'store_new_follower': 'Store Follow',
      'promo': 'Promo',
      'admin': 'Admin',
      'general': 'General',
      'skin_scan_reminder': 'Scan Reminder',
      'routine_step_reminder': 'Routine Reminder',
      'skincare_tip': 'Skincare Tip',
    };
    return map[type] ?? type;
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
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['isRead'] != true).length;

    return Container(
      color: AdminTheme.bg,
      child: Column(
        children: [
          // Sub-header
          Container(
            color: AdminTheme.card,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  _isLoading
                      ? 'Loading...'
                      : '${_notifications.length} notification${_notifications.length == 1 ? '' : 's'}',
                  style: AdminTheme.sub(13),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AdminTheme.wine,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$unread unread',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
                const Spacer(),
                if (unread > 0)
                  TextButton.icon(
                    onPressed: _markAllRead,
                    icon: const Icon(Icons.done_all_rounded,
                        size: 16, color: AdminTheme.wine),
                    label: Text("Mark all read",
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AdminTheme.wine,
                            fontWeight: FontWeight.w500)),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6)),
                  ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded,
                      size: 18, color: AdminTheme.grey),
                  tooltip: "Refresh",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AdminTheme.line),

          // Body
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (widget.adminId.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(
              color: AdminTheme.wine, strokeWidth: 2));
    }
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AdminTheme.wine, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(_error!,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.red.shade400)),
            const SizedBox(height: 12),
            TextButton(
                onPressed: _load,
                child: Text("Retry",
                    style: GoogleFonts.poppins(
                        color: AdminTheme.wine, fontSize: 14))),
          ],
        ),
      );
    }
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AdminTheme.wine.withOpacity(0.07),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 36, color: AdminTheme.wine),
            ),
            const SizedBox(height: 16),
            Text("No notifications yet",
                style: AdminTheme.title(16, w: FontWeight.w600)),
            const SizedBox(height: 6),
            Text("Admin alerts will appear here.", style: AdminTheme.sub(13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.wine,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        itemCount: _notifications.length,
        itemBuilder: (_, i) {
          final n = _notifications[i];
          return _buildCard(n, i);
        },
      ),
    );
  }

  Widget _buildCard(dynamic n, int index) {
    final id = n['_id']?.toString() ?? '';
    final title = n['title']?.toString() ?? '';
    final body = n['body']?.toString() ?? '';
    final type = n['type']?.toString() ?? 'general';
    final isRead = n['isRead'] == true;
    final createdAt = n['createdAt']?.toString() ?? '';

    final color = _colorFor(type);
    final icon = _iconFor(type);
    final label = _labelFor(type);

    return GestureDetector(
      onTap: () => _markRead(id, index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AdminTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead ? AdminTheme.line : AdminTheme.wine.withOpacity(0.25),
            width: isRead ? 1 : 1.2,
          ),
          boxShadow: isRead
              ? null
              : [
                  BoxShadow(
                      color: AdminTheme.wine.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Type chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(label,
                              style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                        ),
                        const Spacer(),
                        Text(_formatDate(createdAt), style: AdminTheme.sub(11)),
                        if (!isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AdminTheme.wine,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                        color: AdminTheme.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, color: AdminTheme.grey, height: 1.45),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Send Notification Tab (preserved from original)
// ══════════════════════════════════════════════════════════════════════════════
