import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class SellerHelpSupportScreen extends StatefulWidget {
  const SellerHelpSupportScreen({super.key});

  @override
  State<SellerHelpSupportScreen> createState() =>
      _SellerHelpSupportScreenState();
}

class _SellerHelpSupportScreenState extends State<SellerHelpSupportScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color deepPlum = Color(0xFF2E1520);
  static const Color softBg = Color(0xFFF7F4F3);
  static const Color warmCream = Color(0xFFFBF8F5);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _category = 'other';
  bool _isSending = false;
  String _userId = '';
  String _storeId = '';

  final Set<int> _expandedFaqs = {};

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How do I add products to my store?',
      'a':
          'Go to the Products tab in the bottom navigation, then tap "Add" in the top right corner. Select a product from the catalog, set your price and stock count.',
    },
    {
      'q': 'How are orders processed?',
      'a':
          'When a customer places an order, you receive a notification and it appears in the Orders tab. Confirm the order, prepare it, mark it as "Out for Delivery", then "Delivered" when complete.',
    },
    {
      'q': 'How does store verification work?',
      'a':
          'Store verification is granted by the Skinova admin team. Once verified, your store displays a verified badge which builds customer trust and improves visibility.',
    },
    {
      'q': 'When will I get paid?',
      'a':
          'Payments are processed according to the Skinova payment schedule. Contact support for details about payout timelines and methods available in your region.',
    },
    {
      'q': 'Can I change my delivery fees?',
      'a':
          'Yes! Go to More → Store Settings. There you can update your standard delivery fee, express delivery fee, and the minimum order amount for free delivery.',
    },
    {
      'q': 'How do customer reviews work?',
      'a':
          'Customers can leave a review after their order is delivered. Reviews go through admin approval before being published. You can view all approved reviews in More → Store Reviews.',
    },
  ];

  static const List<Map<String, String>> _categories = [
    {'value': 'order', 'label': 'Order Issue'},
    {'value': 'payment', 'label': 'Payment'},
    {'value': 'technical', 'label': 'Technical Problem'},
    {'value': 'account', 'label': 'Account'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadIds();
  }

  Future<void> _loadIds() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId') ?? '';
      _storeId = prefs.getString('storeId') ?? '';
    });
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in subject and message.')),
      );
      return;
    }
    setState(() => _isSending = true);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await ApiService.sendSellerSupportMessage({
      'sellerId': _userId,
      'storeId': _storeId.isNotEmpty ? _storeId : null,
      'subject': _subjectCtrl.text.trim(),
      'message': _messageCtrl.text.trim(),
      'category': _category,
    });

    if (!mounted) return;
    setState(() => _isSending = false);

    if (ok) {
      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() => _category = 'other');
      messenger.showSnackBar(
        const SnackBar(
          content:
              Text('Support ticket submitted! We\'ll get back to you soon.'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to submit. Please try again.')),
      );
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
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: deepPlum,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFaqSection(),
            const SizedBox(height: 24),
            _buildContactForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: wine.withOpacity(0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.quiz_outlined, color: wine, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: List.generate(_faqs.length, (i) {
              final faq = _faqs[i];
              final isExpanded = _expandedFaqs.contains(i);
              final isLast = i == _faqs.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedFaqs.remove(i);
                        } else {
                          _expandedFaqs.add(i);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              faq['q']!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: darkText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: grey,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Text(
                        faq['a']!,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: grey,
                          height: 1.6,
                        ),
                      ),
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, color: line, indent: 16, endIndent: 16),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.support_agent_rounded,
                  color: Color(0xFF2196F3), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Contact Support',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600, color: grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: grey),
                    style: GoogleFonts.poppins(fontSize: 13, color: darkText),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                              value: c['value'],
                              child: Text(c['label']!),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v ?? 'other'),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Subject',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600, color: grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subjectCtrl,
                style: GoogleFonts.poppins(fontSize: 14, color: darkText),
                decoration: _inputDecoration('Brief summary of your issue'),
              ),
              const SizedBox(height: 14),
              Text(
                'Message',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600, color: grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageCtrl,
                maxLines: 5,
                style: GoogleFonts.poppins(fontSize: 14, color: darkText),
                decoration: _inputDecoration(
                    'Describe your issue in detail. Include order IDs or product names if relevant.'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Send Message',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.poppins(fontSize: 13, color: grey.withOpacity(0.7)),
      filled: true,
      fillColor: softBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: wine, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
