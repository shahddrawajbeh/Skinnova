import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_tracking_screen.dart';
import 'my_orders_screen.dart';
import 'rate_stores_screen.dart';

/// Confirmation screen shown right after an order is placed from Checkout,
/// before the user is asked to rate the stores they bought from.
class OrderSuccessScreen extends StatelessWidget {
  static const Color bgColor = Colors.white;
  static const Color wine = Color(0xFF5B2333);
  static const Color textDark = Color(0xFF111111);
  static const Color textSoft = Color(0xFF777777);
  static const Color lineColor = Color(0xFFE8E8E8);

  final String userId;
  final List<dynamic> orders;

  const OrderSuccessScreen({
    super.key,
    required this.userId,
    required this.orders,
  });

  void _goToTracking(BuildContext context) {
    if (orders.length == 1) {
      final order = orders.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            orderId: (order["_id"] ?? "").toString(),
            initialOrder: order is Map<String, dynamic> ? order : null,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MyOrdersScreen(userId: userId)),
      );
    }
  }

  void _continue(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RateStoresScreen(userId: userId, orders: orders),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderCount = orders.length;
    final total = orders.fold<double>(0, (sum, o) {
      final t = o is Map ? o["total"] : null;
      return sum + (t is num ? t.toDouble() : 0);
    });

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: wine.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: wine,
                  size: 52,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Order Placed!",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                orderCount == 1
                    ? "Your order has been placed successfully and is now pending confirmation."
                    : "Your $orderCount orders have been placed successfully and are now pending confirmation.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: textSoft,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: lineColor),
                ),
                child: Column(
                  children: [
                    _summaryRow(
                      orderCount == 1 ? "Order" : "Orders placed",
                      "$orderCount",
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: lineColor, thickness: 1),
                    const SizedBox(height: 10),
                    _summaryRow(
                      "Total",
                      "${total.toStringAsFixed(2)} ILS",
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _goToTracking(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: wine,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    "Track Order",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _continue(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: wine,
                    side: const BorderSide(color: wine, width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    "Continue",
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
    );
  }

  Widget _summaryRow(String title, String value, {bool isBold = false}) {
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
          value,
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
