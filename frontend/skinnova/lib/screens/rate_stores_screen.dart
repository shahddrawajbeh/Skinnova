import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class RateStoresScreen extends StatefulWidget {
  final String userId;
  final List<dynamic> orders;

  const RateStoresScreen({
    super.key,
    required this.userId,
    required this.orders,
  });

  @override
  State<RateStoresScreen> createState() => _RateStoresScreenState();
}

class _RateStoresScreenState extends State<RateStoresScreen> {
  static const Color wine = Color(0xFF5B2333);
  static const Color bgColor = Color(0xFFF7F4F3);

  final Map<String, double> ratings = {};
  final Map<String, TextEditingController> comments = {};
  final Set<String> submittedOrders = {};

  @override
  void initState() {
    super.initState();

    for (final order in widget.orders) {
      final orderId = order["_id"].toString();
      ratings[orderId] = 0;
      comments[orderId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in comments.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submitRating(dynamic order) async {
    final orderId = order["_id"].toString();
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString("userName") ?? "";

    final result = await ApiService.rateStoreForOrder(
      orderId: orderId,
      userId: widget.userId,
      userName: userName,
      rating: ratings[orderId] ?? 0,
      comment: comments[orderId]?.text.trim() ?? "",
    );

    if (result["statusCode"] == 200) {
      setState(() {
        submittedOrders.add(orderId);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Thank you! Your review was submitted and is waiting for admin approval.",
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF5B2333),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["data"]["message"] ?? "Failed to rate store"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unratedOrders = widget.orders.where((order) {
      return order["storeRated"] != true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: wine,
        title: Text(
          "Rate Stores",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              "Skip",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: unratedOrders.isEmpty
          ? Center(
              child: Text(
                "No stores to rate",
                style: GoogleFonts.poppins(
                  color: wine,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: unratedOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final order = unratedOrders[index];
                final orderId = order["_id"].toString();
                final store = order["storeId"];
                final storeName =
                    store is Map ? store["storeName"] ?? "Store" : "Store";

                final isSubmitted = submittedOrders.contains(orderId);

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "How was your experience with $storeName?",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: List.generate(5, (starIndex) {
                          final value = starIndex + 1;
                          final currentRating = ratings[orderId] ?? 5;

                          return GestureDetector(
                            onTap: isSubmitted
                                ? null
                                : () {
                                    setState(() {
                                      ratings[orderId] = value.toDouble();
                                    });
                                  },
                            child: Icon(
                              value <= currentRating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: const Color(0xFFE2A84B),
                              size: 34,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: comments[orderId],
                        enabled: !isSubmitted,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Write a short review...",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                const BorderSide(color: Color(0xFFE8DDDA)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                const BorderSide(color: Color(0xFFE8DDDA)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: wine),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              isSubmitted ? null : () => submitRating(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: wine,
                            disabledBackgroundColor: Colors.grey.shade300,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isSubmitted ? "Rated" : "Submit Rating",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
