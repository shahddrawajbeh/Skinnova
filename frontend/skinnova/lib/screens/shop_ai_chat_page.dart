import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'store_profile_screen.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

class _AiProduct {
  final String storeProductId;
  final String productId;
  final String storeId;
  final String name;
  final String brand;
  final String storeName;
  final String imageUrl;
  final String reason;
  final double price;
  final String currency;
  final int stockCount;

  _AiProduct.fromJson(Map<String, dynamic> j)
      : storeProductId = j["storeProductId"]?.toString() ?? "",
        productId = j["productId"]?.toString() ?? "",
        storeId = j["storeId"]?.toString() ?? "",
        name = j["name"]?.toString() ?? "",
        brand = j["brand"]?.toString() ?? "",
        storeName = j["storeName"]?.toString() ?? "",
        imageUrl = j["imageUrl"]?.toString() ?? "",
        reason = j["reason"]?.toString() ?? "",
        price = double.tryParse(j["price"]?.toString() ?? "0") ?? 0,
        currency = j["currency"]?.toString() ?? "ILS",
        stockCount = int.tryParse(j["stockCount"]?.toString() ?? "0") ?? 0;
}

class _AiResult {
  final String title;
  final String summary;
  final String verdict;
  final List<String> warnings;
  final List<String> tips;
  final List<_AiProduct> products;
  final List<String> morningRoutine;
  final List<String> eveningRoutine;

  _AiResult.fromJson(Map<String, dynamic> j)
      : title = j["title"]?.toString() ?? "",
        summary = j["summary"]?.toString() ?? "",
        verdict = j["verdict"]?.toString() ?? "",
        warnings =
            List<String>.from((j["warnings"] ?? []).map((e) => e.toString())),
        tips = List<String>.from((j["tips"] ?? []).map((e) => e.toString())),
        products = ((j["products"] ?? []) as List)
            .map((e) => _AiProduct.fromJson(e as Map<String, dynamic>))
            .toList(),
        morningRoutine = List<String>.from(
            ((j["routine"] ?? {})["morning"] ?? []).map((e) => e.toString())),
        eveningRoutine = List<String>.from(
            ((j["routine"] ?? {})["evening"] ?? []).map((e) => e.toString()));
}

enum _MsgType { user, ai, loading, error }

class _Msg {
  final _MsgType type;
  final String? text;
  final _AiResult? result;
  final String? errorText;
  final VoidCallback? onRetry;

  _Msg.user(String t)
      : type = _MsgType.user,
        text = t,
        result = null,
        errorText = null,
        onRetry = null;

  _Msg.ai(_AiResult r)
      : type = _MsgType.ai,
        text = null,
        result = r,
        errorText = null,
        onRetry = null;

  _Msg.loading()
      : type = _MsgType.loading,
        text = null,
        result = null,
        errorText = null,
        onRetry = null;

  _Msg.error(String msg, VoidCallback retry)
      : type = _MsgType.error,
        text = null,
        result = null,
        errorText = msg,
        onRetry = retry;
}

// ─── Mode config ──────────────────────────────────────────────────────────────

const _kModes = [
  {
    "id": "detective",
    "label": "Product Detective",
    "icon": Icons.science_outlined,
    "description": "Analyze ingredients & products",
  },
  {
    "id": "coach",
    "label": "Skin Coach",
    "icon": Icons.spa_outlined,
    "description": "Ask skincare questions",
  },
  {
    "id": "shopper",
    "label": "Smart Shopper",
    "icon": Icons.shopping_bag_outlined,
    "description": "Find real products in the app",
  },
];

const _kStarters = {
  "detective": [
    "Analyze: niacinamide, salicylic acid, fragrance, alcohol",
    "Is this ingredient list safe for oily skin?",
    "Is retinol pore-clogging?",
    "What does hyaluronic acid do for dry skin?",
  ],
  "coach": [
    "Can I use niacinamide with adapalene?",
    "Why is my skin oily in the T-zone?",
    "Build me a simple AM/PM routine",
    "How do I treat acne without drying my skin?",
  ],
  "shopper": [
    "Find sunscreen for oily skin",
    "Recommend a moisturizer for dry skin",
    "Build me a morning skincare routine",
    "What Korean products do you carry?",
  ],
};

// ─── Main widget ──────────────────────────────────────────────────────────────

class ShopAiChatPage extends StatefulWidget {
  final String userId;
  final String userName;

  const ShopAiChatPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ShopAiChatPage> createState() => _ShopAiChatPageState();
}

class _ShopAiChatPageState extends State<ShopAiChatPage>
    with TickerProviderStateMixin {
  // ─── Palette ──────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color softPink = Color(0xFFF8E8EC);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color gold = Color(0xFFD4AF37);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color dustyRose = Color(0xFFE8AABA);

  // ─── State ────────────────────────────────────────────────────────────────
  int _selectedMode = 0;
  final List<_Msg> _messages = [];
  bool _isLoading = false;
  String? _lastMessage;

  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Animation controller for loading dots
  late final AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get _currentModeId => _kModes[_selectedMode]["id"] as String;

  Future<void> _send(String message) async {
    if (message.trim().isEmpty || _isLoading) return;
    _ctrl.clear();
    _focusNode.unfocus();
    _lastMessage = message.trim();

    setState(() {
      _messages.add(_Msg.user(message.trim()));
      _messages.add(_Msg.loading());
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await ApiService.sendShopAiChat(
        userId: widget.userId,
        mode: _currentModeId,
        message: message.trim(),
      );

      if (!mounted) return;

      // Remove the loading bubble
      setState(() {
        _messages.removeWhere((m) => m.type == _MsgType.loading);
        _isLoading = false;
      });

      final data = response["data"] as Map<String, dynamic>;
      final statusCode = response["statusCode"] as int;

      if (statusCode == 200 && data["success"] == true) {
        final result =
            _AiResult.fromJson(data["result"] as Map<String, dynamic>);
        setState(() => _messages.add(_Msg.ai(result)));
      } else {
        final errMsg = data["message"]?.toString() ??
            "Something went wrong. Please try again.";
        setState(() => _messages.add(_Msg.error(errMsg, () => _retry())));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.type == _MsgType.loading);
        _isLoading = false;
        _messages.add(_Msg.error(
          "Network error. Check your connection and try again.",
          () => _retry(),
        ));
      });
    }

    _scrollToBottom();
  }

  void _retry() {
    if (_lastMessage != null) {
      // Remove the error message and re-send
      setState(() => _messages.removeWhere((m) => m.type == _MsgType.error));
      _send(_lastMessage!);
    }
  }

  Future<void> _openStore(String storeId) async {
    try {
      final store = await ApiService.fetchStoreById(storeId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoreProfileScreen(
            store: store,
            userId: widget.userId,
            userName: widget.userName,
          ),
        ),
      );
    } catch (_) {
      // Store load failed silently — don't crash the chat
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: warmCream,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _modeBar(),
          const Divider(height: 1, color: Color(0x10000000)),
          Expanded(
            child: _messages.isEmpty ? _emptyState() : _chatList(),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: warmCream,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: wine.withOpacity(0.09),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: wine, size: 16),
        ),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            "Skinova  AI",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: deepPlum,
            ),
          ),
          Text(
            "Powered by AI",
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: wine.withOpacity(0.55),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        if (_messages.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() {
              _messages.clear();
              _isLoading = false;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: softPink,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "Clear",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: wine,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Mode picker chips ────────────────────────────────────────────────────

  Widget _modeBar() {
    return Container(
      color: warmCream,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: List.generate(_kModes.length, (i) {
          final mode = _kModes[i];
          final selected = _selectedMode == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMode = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                margin: EdgeInsets.only(right: i < _kModes.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [wine, Color(0xFF8E4B5D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? wine.withOpacity(0.28)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: selected ? 18 : 8,
                      offset: Offset(0, selected ? 6 : 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mode["icon"] as IconData,
                      size: 17,
                      color: selected ? Colors.white : wine.withOpacity(0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (mode["label"] as String).split(' ').first,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : darkText,
                      ),
                    ),
                    Text(
                      (mode["label"] as String).split(' ').skip(1).join(' '),
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white.withOpacity(0.82)
                            : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Empty / welcome state ────────────────────────────────────────────────

  Widget _emptyState() {
    final mode = _kModes[_selectedMode];
    final starters = _kStarters[_currentModeId] ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        // AI intro card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0A10), deepPlum, wine],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.4, 1.0],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: wine.withOpacity(0.32),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative glow
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [gold.withOpacity(0.12), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: gold.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: gold.withOpacity(0.35), width: 0.8),
                        ),
                        child: Text(
                          (mode["label"] as String).toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Hello! I'm\nSkinova  AI",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mode["description"] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.70),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Starter prompts
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: wine,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              "Try asking...",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...starters.map((prompt) => _starterCard(prompt)),
      ],
    );
  }

  Widget _starterCard(String prompt) {
    return GestureDetector(
      onTap: () => _send(prompt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: wine.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: dustyRose.withOpacity(0.14),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: softPink,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.auto_awesome_rounded, color: wine, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                prompt,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: darkText,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  // ─── Chat list ────────────────────────────────────────────────────────────

  Widget _chatList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        switch (msg.type) {
          case _MsgType.user:
            return _userBubble(msg.text!);
          case _MsgType.ai:
            return _aiResponseCard(msg.result!);
          case _MsgType.loading:
            return _loadingBubble();
          case _MsgType.error:
            return _errorBubble(msg.errorText!, msg.onRetry!);
        }
      },
    );
  }

  // ─── User message bubble ──────────────────────────────────────────────────

  Widget _userBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [wine, Color(0xFF8E4B5D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: wine.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.white,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  // ─── Loading animation (3 pulsing dots) ──────────────────────────────────

  Widget _loadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: dustyRose.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _dotCtrl,
          builder: (_, __) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                // Offset each dot's animation by 200ms
                final offset = i * 0.333;
                final t = (_dotCtrl.value + offset) % 1.0;
                // Sine wave: 0→1→0 over one cycle
                final scale = 0.6 + 0.4 * (0.5 - (t - 0.5).abs()) * 2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 7,
                  height: 7 * scale,
                  decoration: BoxDecoration(
                    color: wine.withOpacity(0.4 + 0.4 * scale),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  // ─── Error bubble ─────────────────────────────────────────────────────────

  Widget _errorBubble(String message, VoidCallback onRetry) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F4),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: wine.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 16, color: wine.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  "Something went wrong",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: wine,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: Colors.black54,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: wine,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded,
                        size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      "Try again",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AI response card ─────────────────────────────────────────────────────

  Widget _aiResponseCard(_AiResult r) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI avatar label
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [deepPlum, wine],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: wine.withOpacity(0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      size: 13, color: Colors.white),
                ),
                const SizedBox(width: 7),
                Text(
                  "Skinova Beauty AI",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: wine,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: dustyRose.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  if (r.title.isNotEmpty) ...[
                    Text(
                      r.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: deepPlum,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            wine.withOpacity(0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Summary
                  if (r.summary.isNotEmpty)
                    Text(
                      r.summary,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: darkText.withOpacity(0.85),
                        height: 1.6,
                      ),
                    ),
                  // Verdict badge
                  if (r.verdict.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _verdictChip(r.verdict),
                  ],
                  // Warnings
                  if (r.warnings.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _sectionLabel("⚠️  Warnings", Colors.orange.shade700),
                    const SizedBox(height: 7),
                    ...r.warnings.map((w) => _warningRow(w)),
                  ],
                  // Tips
                  if (r.tips.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _sectionLabel("💡  Tips", wine),
                    const SizedBox(height: 7),
                    ...r.tips.map((t) => _tipRow(t)),
                  ],
                  // Products
                  if (r.products.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionLabel("🛍️  Recommended Products", deepPlum),
                    const SizedBox(height: 10),
                    ...r.products.map((p) => _productCard(p)),
                  ],
                  // Routine
                  if (r.morningRoutine.isNotEmpty ||
                      r.eveningRoutine.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _routineSection(r.morningRoutine, r.eveningRoutine),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verdictChip(String verdict) {
    // Color the chip based on keywords in the verdict
    final lower = verdict.toLowerCase();
    Color bg, fg;
    IconData icon;
    if (lower.contains("not recommend") ||
        lower.contains("avoid") ||
        lower.contains("caution") ||
        lower.contains("warning")) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
      icon = Icons.warning_amber_rounded;
    } else if (lower.contains("safe") ||
        lower.contains("good") ||
        lower.contains("suitable") ||
        lower.contains("recommend")) {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
      icon = Icons.check_circle_outline_rounded;
    } else {
      bg = softPink;
      fg = wine;
      icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              verdict,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _warningRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: wine.withOpacity(0.65),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Product card ─────────────────────────────────────────────────────────

  Widget _productCard(_AiProduct p) {
    return GestureDetector(
      onTap: p.storeId.isNotEmpty ? () => _openStore(p.storeId) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: warmCream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: wine.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: dustyRose.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image or fallback
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 58,
                height: 58,
                color: softPink,
                child: p.imageUrl.isNotEmpty
                    ? Image.network(
                        p.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.spa_outlined,
                          color: wine,
                          size: 24,
                        ),
                      )
                    : const Icon(Icons.spa_outlined, color: wine, size: 24),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.brand.isNotEmpty)
                    Text(
                      p.brand.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: wine.withOpacity(0.65),
                        letterSpacing: 0.7,
                      ),
                    ),
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                      height: 1.25,
                    ),
                  ),
                  if (p.storeName.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined,
                            size: 11, color: Colors.black38),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            p.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (p.price > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      p.currency == "ILS"
                          ? "₪${p.price.toStringAsFixed(0)}"
                          : "${p.currency} ${p.price.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: wine,
                      ),
                    ),
                  ],
                  if (p.reason.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      p.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: wine.withOpacity(0.75),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (p.storeId.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 6, top: 2),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: Colors.black26),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Routine section ──────────────────────────────────────────────────────

  Widget _routineSection(List<String> morning, List<String> evening) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("🌅  Suggested Routine", deepPlum),
        const SizedBox(height: 10),
        if (morning.isNotEmpty) ...[
          _routineBlock("Morning", morning, const Color(0xFFFFF8E1)),
        ],
        if (evening.isNotEmpty) ...[
          if (morning.isNotEmpty) const SizedBox(height: 10),
          _routineBlock("Evening", evening, const Color(0xFFEDE7F6)),
        ],
      ],
    );
  }

  Widget _routineBlock(String label, List<String> steps, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: darkText,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 7),
          ...steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3, right: 8),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: wine.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${e.key + 1}",
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: wine,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: darkText.withOpacity(0.75),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─── Input bar ────────────────────────────────────────────────────────────

  Widget _inputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          14, 10, 14, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: warmCream,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: wine.withOpacity(0.09)),
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (v) => _send(v),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: darkText,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  hintText: _isLoading
                      ? "AI is thinking..."
                      : _currentModeId == "detective"
                          ? "Paste ingredients or product name..."
                          : _currentModeId == "coach"
                              ? "Ask a skincare question..."
                              : "What are you looking for?",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black26,
                  ),
                ),
                cursorColor: wine,
                cursorWidth: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading ? null : () => _send(_ctrl.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(
                        colors: [wine, Color(0xFF8E4B5D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _isLoading ? Colors.black12 : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: wine.withOpacity(0.30),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Icon(
                _isLoading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                color: _isLoading ? Colors.black26 : Colors.white,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
