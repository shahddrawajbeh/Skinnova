import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class SellerNotificationsScreen extends StatefulWidget {
  const SellerNotificationsScreen({super.key});

  @override
  State<SellerNotificationsScreen> createState() =>
      _SellerNotificationsScreenState();
}

class _SellerNotificationsScreenState extends State<SellerNotificationsScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String _userId = '';
  final Set<String> _processingIds = {};

  int get _unreadCount =>
      _notifications.where((n) => n['isRead'] != true).length;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';
    await _load();
  }

  Future<void> _load() async {
    if (_userId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final items = await ApiService.fetchSellerNotifications(_userId);
      if (!mounted) return;
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(String id) async {
    setState(() => _processingIds.add(id));
    await ApiService.markNotificationRead(id);
    if (!mounted) return;
    setState(() {
      _processingIds.remove(id);
      final idx = _notifications.indexWhere((n) => n['_id'] == id);
      if (idx != -1) {
        final oldItem = Map<String, dynamic>.from(_notifications[idx]);
        _notifications[idx] = {
          ...oldItem,
          'isRead': true,
        };
      }
    });
  }

  Future<void> _markAllRead() async {
    if (_userId.isEmpty) return;
    await ApiService.markAllNotificationsRead(_userId);
    if (!mounted) return;
    setState(() {
      _notifications = _notifications.map((n) {
        final item = Map<String, dynamic>.from(n);
        return {
          ...item,
          'isRead': true,
        };
      }).toList();
    });
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'new_order':
        return const Color(0xFF2196F3);
      case 'review_submitted':
        return const Color(0xFFE65100);
      case 'new_product':
        return const Color(0xFF4CAF50);
      case 'restock':
        return const Color(0xFF00838F);
      default:
        return wine;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'new_order':
        return Icons.receipt_long_outlined;
      case 'review_submitted':
        return Icons.star_outline_rounded;
      case 'new_product':
        return Icons.inventory_2_outlined;
      case 'restock':
        return Icons.replay_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(d);
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
      return '${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: warmCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: deepPlum, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: deepPlum,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: wine.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_unreadCount',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: wine,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: wine,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: wine, size: 22),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: wine))
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: wine,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildItem(
                        Map<String, dynamic>.from(_notifications[i])),
                  ),
                ),
    );
  }

  Widget _buildItem(Map<String, dynamic> n) {
    final id = n['_id']?.toString() ?? '';
    final type = n['type']?.toString() ?? 'general';
    final title = n['title']?.toString() ?? '';
    final body = n['body']?.toString() ?? '';
    final isRead = n['isRead'] == true;
    final date = _formatDate(n['createdAt']?.toString());
    final color = _typeColor(type);
    final isProcessing = _processingIds.contains(id);

    return GestureDetector(
      onTap: isRead || isProcessing ? null : () => _markRead(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : wine.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? line : wine.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(isRead ? 0.08 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w700,
                            color: darkText,
                          ),
                        ),
                      ),
                      if (!isRead && !isProcessing)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: wine,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (isProcessing)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: wine),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isRead ? grey : darkText.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    date,
                    style: GoogleFonts.poppins(fontSize: 10, color: grey),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 64, color: grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New orders and reviews will appear here.',
            style: GoogleFonts.poppins(fontSize: 13, color: grey),
          ),
        ],
      ),
    );
  }
}
