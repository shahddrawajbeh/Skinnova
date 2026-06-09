import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String userId;
  final double subtotal;

  const CheckoutScreen({
    super.key,
    required this.userId,
    required this.subtotal,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // ── Palette (matches CartScreen / OrderTrackingScreen) ────────────────────
  static const Color bgColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color wine = Color(0xFF5B2333);
  static const Color textDark = Color(0xFF111111);
  static const Color textSoft = Color(0xFF777777);
  static const Color lineColor = Color(0xFFE8E8E8);
  static const Color fieldBg = Color(0xFFFAFAFA);

  // ── Delivery controllers ──────────────────────────────────────────────────
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // ── Card demo controllers ─────────────────────────────────────────────────
  final _cardNameCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _cardExpiryCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();

  // ── PalPay demo controllers ───────────────────────────────────────────────
  final _palPayPhoneCtrl = TextEditingController();
  final _palPayNameCtrl = TextEditingController();
  final _palPayCodeCtrl = TextEditingController();

  // ── Reflect demo controllers ──────────────────────────────────────────────
  final _reflectPhoneCtrl = TextEditingController();
  final _reflectNameCtrl = TextEditingController();
  final _reflectCodeCtrl = TextEditingController();

  String _selectedMethod = 'cod';
  bool _isLoading = false;

  double get _deliveryFee => 2.99;
  double get _total => widget.subtotal + _deliveryFee;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    _palPayPhoneCtrl.dispose();
    _palPayNameCtrl.dispose();
    _palPayCodeCtrl.dispose();
    _reflectPhoneCtrl.dispose();
    _reflectNameCtrl.dispose();
    _reflectCodeCtrl.dispose();
    super.dispose();
  }

  // ── Snackbar (matches CartScreen style) ───────────────────────────────────
  void _snack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: wine,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        content: Text(
          msg,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Validation helpers ────────────────────────────────────────────────────
  bool _isDeliveryValid() {
    if (_fullNameCtrl.text.trim().isEmpty) { _snack("Enter your full name"); return false; }
    if (_phoneCtrl.text.trim().isEmpty) { _snack("Enter your phone number"); return false; }
    if (_cityCtrl.text.trim().isEmpty) { _snack("Enter your city"); return false; }
    if (_addressCtrl.text.trim().isEmpty) { _snack("Enter your street address"); return false; }
    return true;
  }

  bool _isCardValid() {
    if (_cardNameCtrl.text.trim().isEmpty) { _snack("Enter the cardholder name"); return false; }
    final digits = _cardNumberCtrl.text.replaceAll(' ', '');
    if (!RegExp(r'^\d{16}$').hasMatch(digits)) {
      _snack("Card number must be exactly 16 digits");
      return false;
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(_cardExpiryCtrl.text.trim())) {
      _snack("Expiry must be in MM/YY format");
      return false;
    }
    final month = int.tryParse(_cardExpiryCtrl.text.substring(0, 2)) ?? 0;
    if (month < 1 || month > 12) { _snack("Expiry month must be between 01 and 12"); return false; }
    if (!RegExp(r'^\d{3}$').hasMatch(_cardCvvCtrl.text.trim())) {
      _snack("CVV must be exactly 3 digits");
      return false;
    }
    return true;
  }

  bool _isPalPayValid() {
    final p = _palPayPhoneCtrl.text.trim();
    if (!RegExp(r'^05\d{8}$').hasMatch(p)) {
      _snack("PalPay phone must be 10 digits starting with 05");
      return false;
    }
    if (_palPayNameCtrl.text.trim().isEmpty) { _snack("Enter the PalPay account holder name"); return false; }
    if (!RegExp(r'^\d{4}$').hasMatch(_palPayCodeCtrl.text.trim())) {
      _snack("PalPay confirmation code must be 4 digits");
      return false;
    }
    return true;
  }

  bool _isReflectValid() {
    final p = _reflectPhoneCtrl.text.trim();
    if (!RegExp(r'^05\d{8}$').hasMatch(p)) {
      _snack("Reflect phone must be 10 digits starting with 05");
      return false;
    }
    if (_reflectNameCtrl.text.trim().isEmpty) { _snack("Enter the Reflect account name"); return false; }
    if (!RegExp(r'^\d{4}$').hasMatch(_reflectCodeCtrl.text.trim())) {
      _snack("Reflect confirmation code must be 4 digits");
      return false;
    }
    return true;
  }

  // ── Main submit ────────────────────────────────────────────────────────────
  Future<void> _confirmOrder() async {
    if (!_isDeliveryValid()) return;

    bool paymentValid = false;
    String paymentStatus = 'pending';
    String? cardLast4;

    switch (_selectedMethod) {
      case 'cod':
        paymentValid = true;
        paymentStatus = 'pending';
        break;
      case 'card':
        paymentValid = _isCardValid();
        if (paymentValid) {
          paymentStatus = 'demo_paid';
          final digits = _cardNumberCtrl.text.replaceAll(' ', '');
          cardLast4 = digits.substring(digits.length - 4);
        }
        break;
      case 'palpay':
        paymentValid = _isPalPayValid();
        if (paymentValid) paymentStatus = 'demo_paid';
        break;
      case 'reflect':
        paymentValid = _isReflectValid();
        if (paymentValid) paymentStatus = 'demo_paid';
        break;
      case 'apple_pay':
        paymentValid = true;
        paymentStatus = 'demo_paid';
        break;
    }

    if (!paymentValid) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.createOrder(
        userId: widget.userId,
        fullName: _fullNameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        streetAddress: _addressCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        paymentMethod: _selectedMethod,
        paymentStatus: paymentStatus,
        cardLast4: cardLast4,
        subtotal: widget.subtotal,
        deliveryFee: _deliveryFee,
        total: _total,
      );

      if (!mounted) return;

      if (result["statusCode"] == 201) {
        Navigator.pop(context, result["data"]["orders"]);
      } else {
        final msg = result["data"]["message"] ?? "Failed to create order";
        _snack(msg);
      }
    } catch (_) {
      _snack("Error creating order. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Delivery ───────────────────────────────────────────
                    _sectionTitle("Delivery Information"),
                    const SizedBox(height: 12),
                    _infoCard(
                      child: Column(
                        children: [
                          _textField(ctrl: _fullNameCtrl, hint: "Full Name", icon: Icons.person_outline_rounded),
                          const SizedBox(height: 12),
                          _textField(ctrl: _phoneCtrl, hint: "Phone Number", icon: Icons.phone_outlined, type: TextInputType.phone),
                          const SizedBox(height: 12),
                          _textField(ctrl: _cityCtrl, hint: "City", icon: Icons.location_city_outlined),
                          const SizedBox(height: 12),
                          _textField(ctrl: _addressCtrl, hint: "Street Address", icon: Icons.location_on_outlined, maxLines: 2),
                          const SizedBox(height: 12),
                          _textField(ctrl: _noteCtrl, hint: "Note (Optional)", icon: Icons.edit_note_rounded, maxLines: 2),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Payment method ─────────────────────────────────────
                    _sectionTitle("Payment Method"),
                    const SizedBox(height: 12),
                    _methodCard(value: 'cod',       icon: Icons.local_shipping_outlined,         title: "Cash on Delivery",  subtitle: "Pay when your order arrives"),
                    const SizedBox(height: 10),
                    _methodCard(value: 'card',      icon: Icons.credit_card_outlined,            title: "Credit / Debit Card", subtitle: "Pay securely with your card"),
                    const SizedBox(height: 10),
                    _methodCard(value: 'palpay',    icon: Icons.account_balance_wallet_outlined, title: "PalPay",              subtitle: "Local digital wallet"),
                    const SizedBox(height: 10),
                    _methodCard(value: 'reflect',   icon: Icons.swap_horiz_rounded,              title: "Reflect",             subtitle: "Instant bank transfer"),
                    const SizedBox(height: 10),
                    _methodCard(value: 'apple_pay', icon: Icons.phone_iphone_rounded,            title: "Apple Pay",           subtitle: "Fast and secure payment"),

                    // ── Conditional payment fields ─────────────────────────
                    if (_selectedMethod == 'card') ...[
                      const SizedBox(height: 24),
                      _sectionTitle("Card Details"),
                      const SizedBox(height: 12),
                      _infoCard(
                        child: Column(
                          children: [
                            _textField(ctrl: _cardNameCtrl, hint: "Cardholder Name", icon: Icons.badge_outlined),
                            const SizedBox(height: 12),
                            _textField(
                              ctrl: _cardNumberCtrl,
                              hint: "Card Number (16 digits)",
                              icon: Icons.credit_card_rounded,
                              type: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _textField(
                                    ctrl: _cardExpiryCtrl,
                                    hint: "MM/YY",
                                    icon: Icons.date_range_outlined,
                                    type: TextInputType.datetime,
                                    inputFormatters: [_ExpiryFormatter()],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _textField(
                                    ctrl: _cardCvvCtrl,
                                    hint: "CVV",
                                    icon: Icons.lock_outline_rounded,
                                    type: TextInputType.number,
                                    obscure: true,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_selectedMethod == 'palpay') ...[
                      const SizedBox(height: 24),
                      _sectionTitle("PalPay Details"),
                      const SizedBox(height: 12),
                      _infoCard(
                        child: Column(
                          children: [
                            _textField(ctrl: _palPayPhoneCtrl, hint: "Phone Number (05xxxxxxxx)", icon: Icons.phone_android_rounded, type: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
                            const SizedBox(height: 12),
                            _textField(ctrl: _palPayNameCtrl, hint: "Account Holder Name", icon: Icons.person_outline_rounded),
                            const SizedBox(height: 12),
                            _textField(ctrl: _palPayCodeCtrl, hint: "Confirmation Code (4 digits)", icon: Icons.dialpad_rounded, type: TextInputType.number, obscure: true, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)]),
                          ],
                        ),
                      ),
                    ],

                    if (_selectedMethod == 'reflect') ...[
                      const SizedBox(height: 24),
                      _sectionTitle("Reflect Details"),
                      const SizedBox(height: 12),
                      _infoCard(
                        child: Column(
                          children: [
                            _textField(ctrl: _reflectPhoneCtrl, hint: "Phone Number (05xxxxxxxx)", icon: Icons.phone_android_rounded, type: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
                            const SizedBox(height: 12),
                            _textField(ctrl: _reflectNameCtrl, hint: "Account Name", icon: Icons.person_outline_rounded),
                            const SizedBox(height: 12),
                            _textField(ctrl: _reflectCodeCtrl, hint: "Confirmation Code (4 digits)", icon: Icons.dialpad_rounded, type: TextInputType.number, obscure: true, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)]),
                          ],
                        ),
                      ),
                    ],

                    if (_selectedMethod == 'apple_pay') ...[
                      const SizedBox(height: 20),
                      _buildApplePayCard(),
                    ],

                    const SizedBox(height: 24),

                    // ── Order summary ──────────────────────────────────────
                    _sectionTitle("Order Summary"),
                    const SizedBox(height: 12),
                    _buildSummaryCard(),

                    const SizedBox(height: 26),

                    // ── Submit button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _confirmOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: wine,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: wine.withOpacity(0.55),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _selectedMethod == 'cod' ? "Confirm Order" : "Pay Now",
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
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

  // ─────────────────────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: wine),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            "Checkout",
            style: GoogleFonts.poppins(fontSize: 25, fontWeight: FontWeight.w600, color: textDark),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
    );
  }

  Widget _infoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: lineColor),
      ),
      child: child,
    );
  }

  Widget _textField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    bool obscure = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      obscureText: obscure,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 13.5, color: textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: textSoft, fontSize: 13.5),
        prefixIcon: Icon(icon, color: wine, size: 20),
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: lineColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: lineColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: wine, width: 1.3)),
      ),
    );
  }

  Widget _methodCard({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool selected = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? wine : lineColor, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? wine.withOpacity(0.1) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: selected ? wine : textSoft, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w600, color: textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12.5, color: textSoft)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedMethod,
              activeColor: wine,
              onChanged: (v) => setState(() => _selectedMethod = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplePayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                "Apple Pay",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              "Pay with Apple Pay",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1C1C1E)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Confirm your payment with Face ID or Touch ID.",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: lineColor),
      ),
      child: Column(
        children: [
          _summaryRow("Subtotal", widget.subtotal),
          const SizedBox(height: 10),
          _summaryRow("Delivery", _deliveryFee),
          const SizedBox(height: 14),
          const Divider(color: lineColor, thickness: 1),
          const SizedBox(height: 14),
          _summaryRow("Total", _total, isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, double amount, {bool isBold = false}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 15 : 13.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? wine : textSoft,
          ),
        ),
        const Spacer(),
        Text(
          "${amount.toStringAsFixed(2)} ILS",
          style: GoogleFonts.poppins(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isBold ? wine : textDark,
          ),
        ),
      ],
    );
  }
}

// ── Formatter: auto-inserts "/" after 2 digits for MM/YY ──────────────────
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) return oldValue;
    var result = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 2) result += '/';
      result += digits[i];
    }
    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
