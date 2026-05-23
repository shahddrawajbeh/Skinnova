import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShopAiChatPage extends StatefulWidget {
  const ShopAiChatPage({super.key});

  @override
  State<ShopAiChatPage> createState() => _ShopAiChatPageState();
}

class _ShopAiChatPageState extends State<ShopAiChatPage> {
  static const Color wine = Color(0xFF5B2333);
  static const Color softBg = Color(0xFFF7F4F3);

  final TextEditingController _controller = TextEditingController();

  final List<Map<String, String>> messages = [
    {
      "role": "ai",
      "text":
          "Hi, I’m Skinova AI. Ask me what to buy based on your skin type, concern, or product needs."
    },
  ];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({
        "role": "user",
        "text": text,
      });

      messages.add({
        "role": "ai",
        "text":
            "Based on what you said, I can help suggest suitable skincare products from Skinova. Soon this will be connected to your real AI backend.",
      });
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: softBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: wine),
        centerTitle: true,
        title: Text(
          "Ask Skinova AI",
          style: GoogleFonts.poppins(
            color: wine,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message["role"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? wine : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                    ),
                    child: Text(
                      message["text"] ?? "",
                      style: GoogleFonts.poppins(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: softBg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Ask about products...",
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: wine,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
