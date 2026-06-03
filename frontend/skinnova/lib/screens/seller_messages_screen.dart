import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../services/chat_socket_service.dart';
import 'chat_screen.dart';

class SellerMessagesScreen extends StatefulWidget {
  const SellerMessagesScreen({super.key});

  @override
  State<SellerMessagesScreen> createState() => _SellerMessagesScreenState();
}

class _SellerMessagesScreenState extends State<SellerMessagesScreen> {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color softPink = Color(0xFFF8E8EC);
  static const Color lineColor = Color(0xFFEEEEEE);

  // ── State ─────────────────────────────────────────────────────────────────
  String _sellerId = '';
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filter = 'all';
  int _totalUnread = 0;

  // ── Controllers ───────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  final ChatSocketService _socket = ChatSocketService();

  static const List<String> _months = [
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
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _socket.off('conversation_updated');
    if (_sellerId.isNotEmpty) _socket.leaveSellerRoom(_sellerId);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final sellerId = prefs.getString('userId') ?? '';
    if (!mounted) return;
    setState(() => _sellerId = sellerId);

    _socket.connect(ApiService.baseUrl);
    _socket.joinSellerRoom(sellerId);

    _socket.on('conversation_updated', (data) {
      if (!mounted) return;
      final update = Map<String, dynamic>.from(data as Map);
      final convId = update['conversationId']?.toString() ?? '';
      setState(() {
        final idx = _conversations.indexWhere((c) => c['_id'] == convId);
        if (idx >= 0) {
          _conversations[idx]['lastMessage'] = update['lastMessage'];
          _conversations[idx]['lastMessageTime'] = update['lastMessageTime'];
          _conversations[idx]['sellerUnreadCount'] =
              update['sellerUnreadCount'] ?? 0;
          _conversations.sort((a, b) {
            final tA =
                DateTime.tryParse(a['lastMessageTime']?.toString() ?? '') ??
                    DateTime(2000);
            final tB =
                DateTime.tryParse(b['lastMessageTime']?.toString() ?? '') ??
                    DateTime(2000);
            return tB.compareTo(tA);
          });
          _totalUnread = _conversations.fold(
              0, (s, c) => s + (c['sellerUnreadCount'] as int? ?? 0));
        }
      });
    });

    await _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (_sellerId.isEmpty) return;
    final list = await ApiService.fetchSellerConversations(_sellerId);
    if (!mounted) return;
    final convs = list.map((c) => Map<String, dynamic>.from(c as Map)).toList();
    final total =
        convs.fold(0, (s, c) => s + (c['sellerUnreadCount'] as int? ?? 0));
    setState(() {
      _conversations = convs;
      _totalUnread = total;
      _isLoading = false;
    });
  }

  // ── Filtering ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_conversations);
    if (_filter == 'unread') {
      list =
          list.where((c) => (c['sellerUnreadCount'] as int? ?? 0) > 0).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        final user = c['userId'] as Map? ?? {};
        final name = (user['fullName'] as String? ?? '').toLowerCase();
        final store = c['storeId'] as Map? ?? {};
        final sn = (store['storeName'] as String? ?? '').toLowerCase();
        final last = (c['lastMessage'] as String? ?? '').toLowerCase();
        return name.contains(q) || sn.contains(q) || last.contains(q);
      }).toList();
    }
    return list;
  }

  // ── Time label ────────────────────────────────────────────────────────────
  String _timeLabel(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dt.year, dt.month, dt.day);
      final diff = today.difference(msgDay).inDays;
      if (diff == 0) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      if (diff == 1) return 'Yesterday';
      if (diff < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dt.weekday - 1];
      }
      return '${dt.day} ${_months[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: _isLoading
                  ? _buildSkeleton()
                  : _filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildConversationList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: softPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: wine, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                if (_totalUnread > 0)
                  Text(
                    '$_totalUnread unread',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: wine, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadConversations,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: softPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh_rounded, color: wine, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: softBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lineColor),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, color: Colors.black38, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.poppins(fontSize: 13.5, color: darkText),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13.5, color: Colors.black38),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: wine,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.close_rounded,
                      color: Colors.black38, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Filter Chips ──────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          _chip('all', 'All'),
          const SizedBox(width: 8),
          _chip('unread', 'Unread', badge: _totalUnread),
        ],
      ),
    );
  }

  Widget _chip(String value, String label, {int badge = 0}) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? wine : softBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: active ? wine : lineColor, width: active ? 0 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : Colors.black54,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? Colors.white24 : wine,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$badge',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Conversation List ─────────────────────────────────────────────────────
  Widget _buildConversationList() {
    final list = _filtered;
    return RefreshIndicator(
      color: wine,
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildConvTile(list[i]),
      ),
    );
  }

  Widget _buildConvTile(Map<String, dynamic> conv) {
    final user = conv['userId'] as Map? ?? {};
    final store = conv['storeId'] as Map? ?? {};
    final customerName = user['fullName'] as String? ?? 'Customer';
    final customerAvatar = user['profileImage'] as String? ?? '';
    final storeName = store['storeName'] as String? ?? '';
    final lastMsg = conv['lastMessage'] as String? ?? '';
    final timeStr = _timeLabel(conv['lastMessageTime'] as String?);
    final unread = conv['sellerUnreadCount'] as int? ?? 0;
    final convId = conv['_id'] as String? ?? '';
    final letter =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: convId,
              userId: (user['_id'] ?? '').toString(),
              userName: customerName,
              storeId: (store['_id'] ?? '').toString(),
              storeName: storeName,
              storeLogoUrl: store['logoUrl'] as String? ?? '',
              responseTime: '1 hour',
              sellerId: _sellerId,
              currentUserId: _sellerId,
              currentUserType: 'seller',
              customerName: customerName,
              customerAvatarUrl: customerAvatar,
            ),
          ),
        );
        // Reset unread count locally on return
        if (mounted) {
          setState(() {
            final idx = _conversations.indexWhere((c) => c['_id'] == convId);
            if (idx >= 0) {
              _conversations[idx]['sellerUnreadCount'] = 0;
              _totalUnread = _conversations.fold(
                  0, (s, c) => s + (c['sellerUnreadCount'] as int? ?? 0));
            }
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unread > 0 ? wine.withOpacity(0.15) : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [wine.withOpacity(0.75), const Color(0xFF8E4B5D)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: ClipOval(
                    child: customerAvatar.isNotEmpty
                        ? Image.network(
                            customerAvatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(letter,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: wine,
                                      fontWeight: FontWeight.w600)),
                            ),
                          )
                        : Center(
                            child: Text(letter,
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: wine,
                                    fontWeight: FontWeight.w600)),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customerName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight:
                                unread > 0 ? FontWeight.w700 : FontWeight.w500,
                            color: darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: unread > 0 ? wine : Colors.black38,
                          fontWeight:
                              unread > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (storeName.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: softPink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            storeName,
                            style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                color: wine,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          lastMsg.isNotEmpty ? lastMsg : 'No messages yet',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: unread > 0 ? darkText : Colors.black45,
                            fontWeight: unread > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: wine,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: Text(
                              '$unread',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
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
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 38, color: wine),
            ),
            const SizedBox(height: 20),
            Text(
              _filter == 'unread' ? 'All caught up!' : 'No messages yet',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600, color: darkText),
            ),
            const SizedBox(height: 8),
            Text(
              _filter == 'unread'
                  ? 'You have no unread messages from customers.'
                  : 'When customers start a conversation, it will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.black45, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skeleton ──────────────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: List.generate(
            6,
            (_) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8E8E8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 13,
                              width: 120,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFE8E8E8),
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 11,
                              width: 180,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                  ),
                )),
      ),
    );
  }
}
