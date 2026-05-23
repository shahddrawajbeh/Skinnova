// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../api_service.dart';

// class CheckoutScreen extends StatefulWidget {
//   final String userId;
//   final double subtotal;

//   const CheckoutScreen({
//     super.key,
//     required this.userId,
//     required this.subtotal,
//   });

//   @override
//   State<CheckoutScreen> createState() => _CheckoutScreenState();
// }

// class _CheckoutScreenState extends State<CheckoutScreen> {
//   static const Color bgColor = Colors.black;
//   static const Color cardColor = Colors.white;
//   static const Color softRose = Color(0xFFCCBDB9);
//   static const Color deepRose = Color(0xFF5B2333);
//   static const Color textDark = Color(0xFF111111);
//   static const Color lineColor = Color(0xFFF1ECEA);

//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController cityController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController noteController = TextEditingController();

//   final TextEditingController cardNameController = TextEditingController();
//   final TextEditingController cardNumberController = TextEditingController();
//   final TextEditingController expiryController = TextEditingController();
//   final TextEditingController cvvController = TextEditingController();

//   String selectedPaymentMethod = 'cod';

//   double get deliveryFee => 2.99;
//   double get total => widget.subtotal + deliveryFee;

//   @override
//   void dispose() {
//     fullNameController.dispose();
//     phoneController.dispose();
//     cityController.dispose();
//     addressController.dispose();
//     noteController.dispose();
//     cardNameController.dispose();
//     cardNumberController.dispose();
//     expiryController.dispose();
//     cvvController.dispose();
//     super.dispose();
//   }

//   void _showPrettySnackBar(String message) {
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: deepRose,
//         elevation: 0,
//         margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(18),
//         ),
//         duration: const Duration(seconds: 2),
//         content: Row(
//           children: [
//             const Icon(
//               Icons.check_circle_outline_rounded,
//               color: Colors.white,
//               size: 20,
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 message,
//                 style: GoogleFonts.poppins(
//                   color: Colors.white,
//                   fontSize: 13.5,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _confirmOrder() async {
//     if (fullNameController.text.trim().isEmpty ||
//         phoneController.text.trim().isEmpty ||
//         cityController.text.trim().isEmpty ||
//         addressController.text.trim().isEmpty) {
//       _showPrettySnackBar("Please fill in all delivery details");
//       return;
//     }

//     if (selectedPaymentMethod == 'card') {
//       if (cardNameController.text.trim().isEmpty ||
//           cardNumberController.text.trim().isEmpty ||
//           expiryController.text.trim().isEmpty ||
//           cvvController.text.trim().isEmpty) {
//         _showPrettySnackBar("Please fill in all card details");
//         return;
//       }
//     }

//     try {
//       final result = await ApiService.createOrder(
//         userId: widget.userId,
//         fullName: fullNameController.text.trim(),
//         phoneNumber: phoneController.text.trim(),
//         city: cityController.text.trim(),
//         streetAddress: addressController.text.trim(),
//         note: noteController.text.trim(),
//         paymentMethod: selectedPaymentMethod,
//         subtotal: widget.subtotal,
//         deliveryFee: deliveryFee,
//         total: total,
//       );

//       if (result["statusCode"] == 201) {
//         if (!mounted) return;
//         _showPrettySnackBar(
//           selectedPaymentMethod == 'cod'
//               ? "Order confirmed successfully"
//               : "Payment submitted successfully",
//         );
//         Navigator.pop(context, result["data"]["orders"]);
//       } else {
//         _showPrettySnackBar("Failed to create order");
//       }
//     } catch (e) {
//       _showPrettySnackBar("Error creating order");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bgColor,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Container(
//                       width: 46,
//                       height: 46,
//                       decoration: BoxDecoration(
//                         color: cardColor,
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(color: lineColor),
//                       ),
//                       child: const Icon(
//                         Icons.arrow_back_ios_new_rounded,
//                         size: 18,
//                         color: deepRose,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 14),
//                   Expanded(
//                     child: Text(
//                       "Checkout",
//                       style: GoogleFonts.marcellus(
//                         fontSize: 28,
//                         color: deepRose,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 18),
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _sectionTitle("Delivery Information"),
//                     const SizedBox(height: 12),
//                     _buildInfoCard(
//                       child: Column(
//                         children: [
//                           _buildTextField(
//                             controller: fullNameController,
//                             hint: "Full Name",
//                             icon: Icons.person_outline_rounded,
//                           ),
//                           const SizedBox(height: 12),
//                           _buildTextField(
//                             controller: phoneController,
//                             hint: "Phone Number",
//                             icon: Icons.phone_outlined,
//                             keyboardType: TextInputType.phone,
//                           ),
//                           const SizedBox(height: 12),
//                           _buildTextField(
//                             controller: cityController,
//                             hint: "City",
//                             icon: Icons.location_city_outlined,
//                           ),
//                           const SizedBox(height: 12),
//                           _buildTextField(
//                             controller: addressController,
//                             hint: "Street Address",
//                             icon: Icons.location_on_outlined,
//                             maxLines: 2,
//                           ),
//                           const SizedBox(height: 12),
//                           _buildTextField(
//                             controller: noteController,
//                             hint: "Note (Optional)",
//                             icon: Icons.edit_note_rounded,
//                             maxLines: 2,
//                           ),
//                           const SizedBox(height: 14),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _smallActionButton(
//                                   title: "Use current location",
//                                   icon: Icons.my_location_rounded,
//                                   onTap: () {
//                                     _showPrettySnackBar(
//                                       "Location feature can be added next",
//                                     );
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: _smallActionButton(
//                                   title: "Pick on map",
//                                   icon: Icons.map_outlined,
//                                   onTap: () {
//                                     _showPrettySnackBar(
//                                       "Map picker can be added next",
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 22),
//                     _sectionTitle("Payment Method"),
//                     const SizedBox(height: 12),
//                     _paymentOptionCard(
//                       title: "Cash on Delivery",
//                       subtitle: "Pay when your order arrives",
//                       icon: Icons.local_shipping_outlined,
//                       value: 'cod',
//                     ),
//                     const SizedBox(height: 12),
//                     _paymentOptionCard(
//                       title: "Credit / Debit Card",
//                       subtitle: "Pay securely using your card",
//                       icon: Icons.credit_card_outlined,
//                       value: 'card',
//                     ),
//                     const SizedBox(height: 22),
//                     if (selectedPaymentMethod == 'card') ...[
//                       _sectionTitle("Card Details"),
//                       const SizedBox(height: 12),
//                       _buildInfoCard(
//                         child: Column(
//                           children: [
//                             _buildTextField(
//                               controller: cardNameController,
//                               hint: "Card Holder Name",
//                               icon: Icons.badge_outlined,
//                             ),
//                             const SizedBox(height: 12),
//                             _buildTextField(
//                               controller: cardNumberController,
//                               hint: "Card Number",
//                               icon: Icons.credit_card_rounded,
//                               keyboardType: TextInputType.number,
//                             ),
//                             const SizedBox(height: 12),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: _buildTextField(
//                                     controller: expiryController,
//                                     hint: "MM/YY",
//                                     icon: Icons.date_range_outlined,
//                                     keyboardType: TextInputType.datetime,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: _buildTextField(
//                                     controller: cvvController,
//                                     hint: "CVV",
//                                     icon: Icons.lock_outline_rounded,
//                                     keyboardType: TextInputType.number,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 22),
//                     ],
//                     _sectionTitle("Order Summary"),
//                     const SizedBox(height: 12),
//                     _buildSummaryCard(),
//                     const SizedBox(height: 24),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 58,
//                       child: ElevatedButton(
//                         onPressed: _confirmOrder,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: deepRose,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(22),
//                           ),
//                         ),
//                         child: Text(
//                           selectedPaymentMethod == 'cod'
//                               ? "Confirm Order"
//                               : "Pay Now",
//                           style: GoogleFonts.poppins(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _sectionTitle(String title) {
//     return Text(
//       title,
//       style: GoogleFonts.poppins(
//         fontSize: 17,
//         fontWeight: FontWeight.w600,
//         color: textDark,
//       ),
//     );
//   }

//   Widget _buildInfoCard({required Widget child}) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: lineColor),
//         boxShadow: [
//           BoxShadow(
//             color: deepRose.withOpacity(0.03),
//             blurRadius: 18,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     TextInputType keyboardType = TextInputType.text,
//     int maxLines = 1,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       maxLines: maxLines,
//       style: GoogleFonts.poppins(
//         fontSize: 13.5,
//         color: textDark,
//       ),
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: GoogleFonts.poppins(
//           color: softRose,
//           fontSize: 13.5,
//         ),
//         prefixIcon: Icon(
//           icon,
//           color: deepRose,
//           size: 20,
//         ),
//         filled: true,
//         fillColor: const Color(0xFFFFFFFF),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 16,
//         ),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(18),
//           borderSide: const BorderSide(color: lineColor),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(18),
//           borderSide: const BorderSide(color: lineColor),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(18),
//           borderSide: const BorderSide(color: deepRose),
//         ),
//       ),
//     );
//   }

//   Widget _smallActionButton({
//     required String title,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 48,
//         decoration: BoxDecoration(
//           color: const Color(0xFFFFFFFF),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: lineColor),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               color: deepRose,
//               size: 18,
//             ),
//             const SizedBox(width: 8),
//             Flexible(
//               child: Text(
//                 title,
//                 overflow: TextOverflow.ellipsis,
//                 style: GoogleFonts.poppins(
//                   fontSize: 12.5,
//                   fontWeight: FontWeight.w500,
//                   color: deepRose,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _paymentOptionCard({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required String value,
//   }) {
//     final bool isSelected = selectedPaymentMethod == value;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selectedPaymentMethod = value;
//         });
//       },
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: cardColor,
//           borderRadius: BorderRadius.circular(22),
//           border: Border.all(
//             color: isSelected ? deepRose : lineColor,
//             width: isSelected ? 1.5 : 1,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: deepRose.withOpacity(0.03),
//               blurRadius: 18,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFFFFF),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Icon(
//                 icon,
//                 color: deepRose,
//                 size: 21,
//               ),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: GoogleFonts.poppins(
//                       fontSize: 14.5,
//                       fontWeight: FontWeight.w600,
//                       color: textDark,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     subtitle,
//                     style: GoogleFonts.poppins(
//                       fontSize: 12.5,
//                       color: softRose,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Radio<String>(
//               value: value,
//               groupValue: selectedPaymentMethod,
//               activeColor: deepRose,
//               onChanged: (val) {
//                 setState(() {
//                   selectedPaymentMethod = val!;
//                 });
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryCard() {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: lineColor),
//         boxShadow: [
//           BoxShadow(
//             color: deepRose.withOpacity(0.03),
//             blurRadius: 18,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           _summaryRow("Subtotal", widget.subtotal),
//           const SizedBox(height: 10),
//           _summaryRow("Delivery", deliveryFee),
//           const SizedBox(height: 12),
//           Divider(color: lineColor, thickness: 1),
//           const SizedBox(height: 12),
//           _summaryRow("Total", total, isBold: true),
//         ],
//       ),
//     );
//   }

//   Widget _summaryRow(String title, double amount, {bool isBold = false}) {
//     return Row(
//       children: [
//         Text(
//           title,
//           style: GoogleFonts.poppins(
//             fontSize: isBold ? 15 : 13.5,
//             fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
//             color: isBold ? deepRose : softRose,
//           ),
//         ),
//         const Spacer(),
//         Text(
//           "\$${amount.toStringAsFixed(2)}",
//           style: GoogleFonts.poppins(
//             fontSize: isBold ? 16 : 14,
//             fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
//             color: textDark,
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
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
  static const Color bgColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color wine = Color(0xFF5B2333);
  static const Color textDark = Color(0xFF111111);
  static const Color textSoft = Color(0xFF777777);
  static const Color lineColor = Color(0xFFE8E8E8);
  static const Color fieldBg = Color(0xFFFAFAFA);

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  final TextEditingController cardNameController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  String selectedPaymentMethod = 'cod';

  double get deliveryFee => 2.99;
  double get total => widget.subtotal + deliveryFee;

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    cityController.dispose();
    addressController.dispose();
    noteController.dispose();
    cardNameController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  void _showPrettySnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: wine,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 2),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    if (fullNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty) {
      _showPrettySnackBar("Please fill in all delivery details");
      return;
    }

    if (selectedPaymentMethod == 'card') {
      if (cardNameController.text.trim().isEmpty ||
          cardNumberController.text.trim().isEmpty ||
          expiryController.text.trim().isEmpty ||
          cvvController.text.trim().isEmpty) {
        _showPrettySnackBar("Please fill in all card details");
        return;
      }
    }

    try {
      final result = await ApiService.createOrder(
        userId: widget.userId,
        fullName: fullNameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        city: cityController.text.trim(),
        streetAddress: addressController.text.trim(),
        note: noteController.text.trim(),
        paymentMethod: selectedPaymentMethod,
        subtotal: widget.subtotal,
        deliveryFee: deliveryFee,
        total: total,
      );

      if (result["statusCode"] == 201) {
        if (!mounted) return;

        _showPrettySnackBar("Order confirmed successfully");
        Navigator.pop(context, result["data"]["orders"]);
      } else {
        _showPrettySnackBar("Failed to create order");
      }
    } catch (e) {
      _showPrettySnackBar("Error creating order");
    }
  }

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
                    _sectionTitle("Delivery Information"),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: fullNameController,
                            hint: "Full Name",
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: phoneController,
                            hint: "Phone Number",
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: cityController,
                            hint: "City",
                            icon: Icons.location_city_outlined,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: addressController,
                            hint: "Street Address",
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: noteController,
                            hint: "Note (Optional)",
                            icon: Icons.edit_note_rounded,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle("Payment Method"),
                    const SizedBox(height: 12),
                    _paymentOptionCard(
                      title: "Cash on Delivery",
                      subtitle: "Pay when your order arrives",
                      icon: Icons.local_shipping_outlined,
                      value: 'cod',
                    ),
                    const SizedBox(height: 12),
                    _paymentOptionCard(
                      title: "Credit / Debit Card",
                      subtitle: "Pay securely using your card",
                      icon: Icons.credit_card_outlined,
                      value: 'card',
                    ),
                    if (selectedPaymentMethod == 'card') ...[
                      const SizedBox(height: 24),
                      _sectionTitle("Card Details"),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: cardNameController,
                              hint: "Card Holder Name",
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: cardNumberController,
                              hint: "Card Number",
                              icon: Icons.credit_card_rounded,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: expiryController,
                                    hint: "MM/YY",
                                    icon: Icons.date_range_outlined,
                                    keyboardType: TextInputType.datetime,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: cvvController,
                                    hint: "CVV",
                                    icon: Icons.lock_outline_rounded,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _sectionTitle("Order Summary"),
                    const SizedBox(height: 12),
                    _buildSummaryCard(),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _confirmOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: wine,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          selectedPaymentMethod == 'cod'
                              ? "Confirm Order"
                              : "Pay Now",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
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
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 17,
                color: wine,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            "Checkout",
            style: GoogleFonts.poppins(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        fontSize: 13.5,
        color: textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: textSoft,
          fontSize: 13.5,
        ),
        prefixIcon: Icon(
          icon,
          color: wine,
          size: 20,
        ),
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: wine,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _paymentOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final bool isSelected = selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? wine : lineColor,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? wine : Colors.black54,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: textSoft,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: selectedPaymentMethod,
              activeColor: wine,
              onChanged: (val) {
                setState(() {
                  selectedPaymentMethod = val!;
                });
              },
            ),
          ],
        ),
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
          _summaryRow("Delivery", deliveryFee),
          const SizedBox(height: 14),
          const Divider(color: lineColor, thickness: 1),
          const SizedBox(height: 14),
          _summaryRow("Total", total, isBold: true),
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
