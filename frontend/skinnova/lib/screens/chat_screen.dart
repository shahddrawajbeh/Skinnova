import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../services/chat_socket_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String userId;
  final String userName;
  final String storeId;
  final String storeName;
  final String storeLogoUrl;
  final String responseTime;
  final String sellerId;
  final Map<String, dynamic>? productContext;

  // Seller-mode params
  final String currentUserId;
  final String currentUserType; // 'user' or 'seller'
  final String customerName;
  final String customerAvatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.userId,
    required this.userName,
    required this.storeId,
    required this.storeName,
    required this.storeLogoUrl,
    required this.responseTime,
    required this.sellerId,
    this.productContext,
    this.currentUserId = '',
    this.currentUserType = 'user',
    this.customerName = '',
    this.customerAvatarUrl = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color softPink = Color(0xFFF8E8EC);
  static const Color userBubble = Color(0xFF5B2333);
  static const Color storeBubble = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFFFFFFF);
  static const Color lineColor = Color(0xFFEEEEEE);

  // ── Data ──────────────────────────────────────────────────────────────────
  // Messages stored newest-first for ListView(reverse:true)
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isStoreTyping = false;
  bool _showQuickReplies = false;
  List<dynamic> _storeProducts = [];

  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  // ── Socket ────────────────────────────────────────────────────────────────
  final ChatSocketService _socket = ChatSocketService();

  // ── Typing debounce ────────────────────────────────────────────────────────
  Timer? _typingTimer;
  bool _userIsTyping = false;

  // ── Typing dots animation ──────────────────────────────────────────────────
  late AnimationController _dotCtrl;

  // ── Quick replies ──────────────────────────────────────────────────────────
  static const List<String> _quickReplies = [
    "Track my order 📦",
    "Product recommendation 💆",
    "Skin concern help 🌿",
    "Delivery question 🚚",
  ];

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
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _initChat();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _dotCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    _socket.off('new_message');
    _socket.off('user_typing');
    _socket.off('user_stop_typing');
    _socket.off('messages_seen');
    _socket.leaveConversation(widget.conversationId);
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> _initChat() async {
    _socket.connect(ApiService.baseUrl);
    _socket.joinConversation(widget.conversationId);

    _socket.on('new_message', (data) {
      if (!mounted) return;
      final msg = Map<String, dynamic>.from(data as Map);
      if (msg['senderType'] != widget.currentUserType) {
        setState(() {
          _messages.insert(0, msg);
          _showQuickReplies = false;
        });
        ApiService.markChatSeen(
          conversationId: widget.conversationId,
          viewerType: widget.currentUserType,
        );
        _socket.emitSeen(widget.conversationId);
      }
    });

    _socket.on('user_typing', (_) {
      if (mounted) setState(() => _isStoreTyping = true);
    });

    _socket.on('user_stop_typing', (_) {
      if (mounted) setState(() => _isStoreTyping = false);
    });

    _socket.on('messages_seen', (data) {
      if (!mounted) return;
      setState(() {
        for (final msg in _messages) {
          if (msg['senderType'] == widget.currentUserType) msg['isSeen'] = true;
        }
      });
    });

    await _loadMessages();

    await ApiService.markChatSeen(
      conversationId: widget.conversationId,
      viewerType: widget.currentUserType,
    );
    _socket.emitSeen(widget.conversationId);
  }

  Future<void> _loadMessages() async {
    final result = await ApiService.getChatMessages(widget.conversationId);
    if (!mounted) return;

    final rawList = (result['messages'] as List<dynamic>? ?? []);
    final msgs = rawList
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList()
        .reversed // API returns oldest-first; we need newest-first
        .toList();

    final hasUserMsg = msgs.any((m) => m['senderType'] == 'user');

    setState(() {
      _messages.clear();
      _messages.addAll(msgs);
      _showQuickReplies =
          widget.currentUserType == 'user' && !hasUserMsg && msgs.isNotEmpty;
      _isLoading = false;
    });

    // Pre-fill input if opened from product
    if (widget.productContext != null && msgs.length <= 1) {
      final pName = widget.productContext!['name'] ?? '';
      if (pName.isNotEmpty) {
        _inputCtrl.text = "I'm interested in $pName";
        _inputFocus.requestFocus();
      }
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────────
  Future<void> _sendText() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    await _doSend(text: text, type: 'text');
  }

  Future<void> _sendProduct(Map<String, dynamic> product) async {
    if (_isSending) return;
    final snap = {
      'name': product['productId']?['name'] ?? product['name'] ?? '',
      'imageUrl':
          product['productId']?['imageUrl'] ?? product['imageUrl'] ?? '',
      'price': (product['price'] ?? 0).toDouble(),
      'currency': product['currency'] ?? 'ILS',
      'storeProductId': (product['_id'] ?? '').toString(),
    };
    await _doSend(type: 'product', productSnapshot: snap);
  }

  Future<void> _doSend({
    String text = '',
    String type = 'text',
    Map<String, dynamic>? productSnapshot,
  }) async {
    _stopTyping();
    _inputCtrl.clear();
    _inputFocus.unfocus();
    HapticFeedback.lightImpact();

    final effectiveId =
        widget.currentUserId.isNotEmpty ? widget.currentUserId : widget.userId;
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = {
      '_id': tempId,
      'senderId': effectiveId,
      'senderType': widget.currentUserType,
      'messageType': type,
      'text': type == 'product' ? '📦 Shared a product' : text,
      'productSnapshot': productSnapshot,
      'isSeen': false,
      'createdAt': DateTime.now().toIso8601String(),
      '_sending': true,
    };

    setState(() {
      _messages.insert(0, optimistic);
      _showQuickReplies = false;
      _isSending = true;
    });

    final result = await ApiService.sendChatMessage(
      conversationId: widget.conversationId,
      senderId: effectiveId,
      senderType: widget.currentUserType,
      messageType: type,
      text: type == 'product' ? '📦 Shared a product' : text,
      productSnapshot: productSnapshot,
    );

    if (!mounted) return;

    if (result['_id'] != null) {
      final real = Map<String, dynamic>.from(result);
      setState(() {
        final idx = _messages.indexWhere((m) => m['_id'] == tempId);
        if (idx >= 0) _messages[idx] = real;
        _isSending = false;
      });
      _socket.emitMessage({...real, 'conversationId': widget.conversationId});
    } else {
      setState(() {
        _messages.removeWhere((m) => m['_id'] == tempId);
        _isSending = false;
      });
    }
  }

  // ── Typing ────────────────────────────────────────────────────────────────
  void _onInputChanged(String value) {
    final effectiveId =
        widget.currentUserId.isNotEmpty ? widget.currentUserId : widget.userId;
    if (value.isNotEmpty && !_userIsTyping) {
      _userIsTyping = true;
      _socket.emitTyping(widget.conversationId, effectiveId);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    final effectiveId =
        widget.currentUserId.isNotEmpty ? widget.currentUserId : widget.userId;
    if (_userIsTyping) {
      _userIsTyping = false;
      _socket.emitStopTyping(widget.conversationId, effectiveId);
    }
    _typingTimer?.cancel();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _dateLabel(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dt.year, dt.month, dt.day);
      final diff = today.difference(msgDay).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  bool _shouldShowDateBefore(int index) {
    if (index >= _messages.length - 1) return true;
    final a = DateTime.tryParse(_messages[index]['createdAt'] ?? '');
    final b = DateTime.tryParse(_messages[index + 1]['createdAt'] ?? '');
    if (a == null || b == null) return false;
    return a.day != b.day || a.month != b.month || a.year != b.year;
  }

  Future<void> _loadStoreProducts() async {
    if (_storeProducts.isNotEmpty) return;
    try {
      final result = await ApiService.fetchProductsByStore(widget.storeId);
      if (mounted) setState(() => _storeProducts = result);
    } catch (_) {
      // Product attach is optional; silently skip on error
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
            _buildAppBar(),
            Expanded(
              child: _isLoading ? _buildLoadingSkeleton() : _buildMessageList(),
            ),
            if (_isStoreTyping) _buildTypingBar(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    final isSeller = widget.currentUserType == 'seller';
    final avatarUrl = isSeller ? widget.customerAvatarUrl : widget.storeLogoUrl;
    final displayName = isSeller ? widget.customerName : widget.storeName;
    final letter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: lineColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: softPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: wine,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [wine.withOpacity(0.8), const Color(0xFF8E4B5D)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(letter,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: wine,
                                        fontSize: 16)),
                              ),
                            )
                          : Center(
                              child: Text(letter,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: wine,
                                      fontSize: 16)),
                            ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSeller)
                  Text(
                    'Customer · ${widget.storeName}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Usually replies within ${widget.responseTime}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Menu
          PopupMenuButton<String>(
            onSelected: (_) {},
            icon:
                const Icon(Icons.more_vert_rounded, color: darkText, size: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (_) => isSeller
                ? [_popupItem('Mark as resolved', Icons.check_circle_outline)]
                : [
                    _popupItem('Report conversation', Icons.flag_outlined),
                    _popupItem('Block store', Icons.block_rounded),
                  ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItem(String label, IconData icon) {
    return PopupMenuItem(
      value: label,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 13, color: darkText)),
        ],
      ),
    );
  }

  // ── Message List ──────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    if (_messages.isEmpty) return _buildEmptyState();

    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      itemCount: _messages.length + (_showQuickReplies ? 1 : 0),
      itemBuilder: (_, index) {
        // Quick replies appear at index 0 (bottom) above the last messages
        if (_showQuickReplies && index == 0) {
          return _buildQuickReplies();
        }
        final msgIndex = _showQuickReplies ? index - 1 : index;
        final msg = _messages[msgIndex];
        final showDate = _shouldShowDateBefore(msgIndex);

        return Column(
          children: [
            if (showDate) _buildDateSeparator(msg['createdAt']),
            _buildMessageItem(msg, msgIndex),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(String? iso) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: lineColor)),
          const SizedBox(width: 12),
          Text(
            _dateLabel(iso),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: lineColor)),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg, int index) {
    final senderType = msg['senderType'] as String? ?? 'user';
    final isUser = senderType == widget.currentUserType;
    final isSending = msg['_sending'] == true;

    Widget bubble;
    switch (msg['messageType']) {
      case 'product':
        bubble = _buildProductCard(msg, isUser: isUser);
        break;
      default:
        bubble = _buildTextBubble(msg, isUser: isUser);
    }

    // Show avatar on seller messages
    Widget content = isUser
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(child: bubble),
              const SizedBox(width: 4),
              _buildSeenIndicator(msg, isSending: isSending),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStoreAvatar(),
              const SizedBox(width: 6),
              Flexible(child: bubble),
            ],
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: content,
    );
  }

  Widget _buildTextBubble(Map<String, dynamic> msg, {required bool isUser}) {
    final text = msg['text'] as String? ?? '';
    final time = _formatTime(msg['createdAt'] as String?);

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? userBubble : storeBubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: isUser
                    ? wine.withOpacity(0.18)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: isUser ? Colors.white : darkText,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> msg, {required bool isUser}) {
    final snap = msg['productSnapshot'] as Map? ?? {};
    final name = snap['name'] as String? ?? 'Product';
    final imgUrl = snap['imageUrl'] as String? ?? '';
    final price = (snap['price'] as num?)?.toDouble() ?? 0;
    final currency = snap['currency'] as String? ?? 'ILS';
    final priceStr = currency == 'ILS'
        ? '₪${price.toStringAsFixed(0)}'
        : '$currency ${price.toStringAsFixed(0)}';
    final time = _formatTime(msg['createdAt'] as String?);

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          width: 230,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            border: Border.all(color: wine.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  height: 110,
                  width: double.infinity,
                  color: softPink,
                  child: imgUrl.isNotEmpty
                      ? Image.network(imgUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.spa_outlined,
                              color: wine,
                              size: 28))
                      : const Icon(Icons.spa_outlined, color: wine, size: 36),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (price > 0)
                      Text(
                        priceStr,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: wine,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: wine.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'View Product',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: wine,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(time,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.black38)),
      ],
    );
  }

  Widget _buildStoreAvatar() {
    final isSeller = widget.currentUserType == 'seller';
    final avatarUrl = isSeller ? widget.customerAvatarUrl : widget.storeLogoUrl;
    final name = isSeller ? widget.customerName : widget.storeName;
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
            colors: [wine.withOpacity(0.8), const Color(0xFF8E4B5D)]),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Container(
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: ClipOval(
            child: avatarUrl.isNotEmpty
                ? Image.network(avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                        child: Text(letter,
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: wine,
                                fontWeight: FontWeight.w600))))
                : Center(
                    child: Text(letter,
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: wine,
                            fontWeight: FontWeight.w600))),
          ),
        ),
      ),
    );
  }

  Widget _buildSeenIndicator(Map<String, dynamic> msg,
      {required bool isSending}) {
    if (isSending) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 4),
        child: Icon(Icons.schedule_rounded, size: 12, color: Colors.black26),
      );
    }
    final isSeen = msg['isSeen'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Icon(
        isSeen ? Icons.done_all_rounded : Icons.done_rounded,
        size: 14,
        color: isSeen ? wine : Colors.black26,
      ),
    );
  }

  // ── Quick Replies ─────────────────────────────────────────────────────────
  Widget _buildQuickReplies() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick replies',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickReplies.map((reply) {
              return GestureDetector(
                onTap: () => _doSend(text: reply),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: wine.withOpacity(0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    reply,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: wine,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Typing Indicator ──────────────────────────────────────────────────────
  Widget _buildTypingBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _buildStoreAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _typingDot(0),
                const SizedBox(width: 4),
                _typingDot(1),
                const SizedBox(width: 4),
                _typingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingDot(int index) {
    return AnimatedBuilder(
      animation: _dotCtrl,
      builder: (_, __) {
        final phase = (_dotCtrl.value * 3 - index).clamp(0.0, 1.0);
        final bounce = Curves.easeInOut
            .transform(phase < 0.5 ? phase * 2 : (1 - phase) * 2);
        return Transform.translate(
          offset: Offset(0, -4 * bounce),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3 + bounce * 0.3),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // ── Input Bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: warmCream,
        border: Border(top: BorderSide(color: lineColor, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach product button
          GestureDetector(
            onTap: _showProductAttachSheet,
            child: Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(bottom: 1),
              decoration: BoxDecoration(
                color: softPink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.spa_outlined, color: wine, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: lineColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      focusNode: _inputFocus,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: _onInputChanged,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: darkText,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.currentUserType == 'seller'
                            ? 'Reply to ${widget.customerName}...'
                            : 'Message ${widget.storeName}...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.fromLTRB(16, 12, 8, 12),
                        isDense: true,
                      ),
                      cursorColor: wine,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _inputCtrl,
            builder: (_, val, __) {
              final hasText = val.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: hasText ? _sendText : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasText ? wine : Colors.black12,
                    shape: BoxShape.circle,
                    boxShadow: hasText
                        ? [
                            BoxShadow(
                              color: wine.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: hasText ? Colors.white : Colors.white54,
                    size: 18,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Product Attach Sheet ───────────────────────────────────────────────────
  Future<void> _showProductAttachSheet() async {
    await _loadStoreProducts();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: warmCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 14),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Text(
                      'Share a Product',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: darkText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_storeProducts.length} items',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _storeProducts.isEmpty
                    ? Center(
                        child: Text('No products available',
                            style: GoogleFonts.poppins(
                                color: Colors.black38, fontSize: 13)),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _storeProducts.length,
                        itemBuilder: (_, i) {
                          final item = _storeProducts[i];
                          final product = item['productId'] ?? {};
                          final name = product['name'] as String? ?? 'Product';
                          final imgUrl = product['imageUrl'] as String? ?? '';
                          final price =
                              (item['price'] as num?)?.toDouble() ?? 0;
                          final currency = item['currency'] as String? ?? 'ILS';
                          final priceStr = currency == 'ILS'
                              ? '₪${price.toStringAsFixed(0)}'
                              : '$currency ${price.toStringAsFixed(0)}';

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _sendProduct(Map<String, dynamic>.from(item));
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: wine.withOpacity(0.07)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: softPink,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: imgUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              imgUrl,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.spa_outlined,
                                                color: wine,
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.spa_outlined,
                                            color: wine),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: darkText,
                                          ),
                                        ),
                                        if (price > 0)
                                          Text(
                                            priceStr,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: wine,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: softPink,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Share',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: wine,
                                      ),
                                    ),
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
              'Start the conversation',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask about products, delivery, or skin concerns. ${widget.storeName} is here to help.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.black45, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading Skeleton ──────────────────────────────────────────────────────
  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerRow(isUser: false, width: 200),
          const SizedBox(height: 16),
          _shimmerRow(isUser: true, width: 160),
          const SizedBox(height: 16),
          _shimmerRow(isUser: false, width: 240),
          const SizedBox(height: 16),
          _shimmerRow(isUser: true, width: 180),
        ],
      ),
    );
  }

  Widget _shimmerRow({required bool isUser, required double width}) {
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) ...[
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: Color(0xFFE0E0E0), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Container(
          height: 40,
          width: width,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
    );
  }
}
