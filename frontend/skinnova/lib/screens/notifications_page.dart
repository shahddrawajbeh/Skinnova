import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class NotificationsPage extends StatefulWidget {
  final String userId;

  const NotificationsPage({super.key, required this.userId});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color lineColor = Color(0xFFEEEEEE);
  static const Color unreadDot = Color(0xFF5B2333);

  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndMarkRead();
  }

  Future<void> _loadAndMarkRead() async {
    setState(() => _isLoading = true);

    final data = await ApiService.fetchNotifications(widget.userId);
    if (!mounted) return;

    setState(() {
      _notifications = data;
      _isLoading = false;
    });

    // Mark all as read silently after displaying
    if (data.any((n) => n["isRead"] == false)) {
      await ApiService.markAllNotificationsRead(widget.userId);
      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          n["isRead"] = true;
        }
      });
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case "new_product":
      case "followed_store_new_product":
        return Icons.shopping_bag_outlined;
      case "restock":
        return Icons.inventory_2_outlined;
      case "skin_scan_reminder":
        return Icons.camera_alt_outlined;
      case "routine_step_reminder":
        return Icons.spa_outlined;
      case "skincare_tip":
        return Icons.lightbulb_outline_rounded;
      case "new_order":
      case "order_status_changed":
        return Icons.receipt_long_outlined;
      case "store_approved":
      case "store_rejected":
      case "new_store_request":
        return Icons.store_outlined;
      case "ad_approved":
      case "ad_rejected":
        return Icons.campaign_outlined;
      case "post_like":
        return Icons.favorite_border_rounded;
      case "post_comment":
        return Icons.chat_bubble_outline_rounded;
      case "new_follower":
      case "store_new_follower":
        return Icons.person_add_alt_outlined;
      case "review_submitted":
        return Icons.star_outline_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconBgForType(String type) {
    switch (type) {
      case "new_product":
      case "followed_store_new_product":
        return const Color(0xFFF0E8EC);
      case "restock":
        return const Color(0xFFE8F0F0);
      case "skin_scan_reminder":
        return const Color(0xFFE8F0FC);
      case "routine_step_reminder":
        return const Color(0xFFEDF7F2);
      case "skincare_tip":
        return const Color(0xFFFEF9E7);
      default:
        return const Color(0xFFF0EEE8);
    }
  }

  Color _iconColorForType(String type) {
    switch (type) {
      case "new_product":
      case "followed_store_new_product":
        return wine;
      case "restock":
        return const Color(0xFF2E7D6A);
      case "skin_scan_reminder":
        return const Color(0xFF2563EB);
      case "routine_step_reminder":
        return const Color(0xFF2E7D52);
      case "skincare_tip":
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF7A5C2E);
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      if (diff.inDays < 7) return "${diff.inDays}d ago";

      final months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      return "${dt.day} ${months[dt.month - 1]}";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: wine,
                        strokeWidth: 2,
                      ),
                    )
                  : _notifications.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _loadAndMarkRead,
                          color: wine,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                            itemCount: _notifications.length,
                            itemBuilder: (_, i) =>
                                _buildCard(_notifications[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: lineColor),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 17,
                color: wine,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Notifications",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              if (_notifications.isNotEmpty)
                Text(
                  "${_notifications.length} update${_notifications.length == 1 ? '' : 's'}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF999999),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic notification) {
    final type = (notification["type"] ?? "general").toString();
    final title = (notification["title"] ?? "").toString();
    final body = (notification["body"] ?? "").toString();
    final isRead = notification["isRead"] == true;
    final createdAt = (notification["createdAt"] ?? "").toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead ? lineColor : wine.withOpacity(0.2),
            width: isRead ? 1 : 1.2,
          ),
          boxShadow: isRead
              ? []
              : [
                  BoxShadow(
                    color: wine.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBgForType(type),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                _iconForType(type),
                color: _iconColorForType(type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unread dot
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            color: unreadDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xFF777777),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFFBBBBBB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: wine.withOpacity(0.07),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 38,
                color: wine,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No notifications yet",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Updates from stores you follow will appear here.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF999999),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
