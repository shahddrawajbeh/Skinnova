import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class ScanHistoryScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ScanHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  bool isLoading = true;
  List<dynamic> scans = [];

  @override
  void initState() {
    super.initState();
    loadScans();
  }

  Future<void> deleteScan(int index) async {
    final scan = scans[index];
    final scanId = scan["_id"];

    final success = await ApiService.deleteScanHistory(scanId);

    if (!mounted) return;

    if (success) {
      setState(() {
        scans.removeAt(index);
      });

      _showDeleteSuccessSheet();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete scan")),
      );
    }
  }

  Future<void> loadScans() async {
    try {
      final result = await ApiService.fetchScanHistory(widget.userId);

      if (!mounted) return;

      setState(() {
        scans = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDeleteSuccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFCFAF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),
              const Icon(
                Icons.delete_outline_rounded,
                size: 46,
                color: Color(0xFF5B2333),
              ),
              const SizedBox(height: 14),
              Text(
                "Scan removed",
                style: GoogleFonts.marcellus(
                  fontSize: 22,
                  color: Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This scan has been deleted from your history.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B2333),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Done",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fullImageUrl(String imageUrl) {
    if (imageUrl.startsWith("http")) return imageUrl;
    return "${ApiService.baseUrl}$imageUrl";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Scan History",
          style: GoogleFonts.poppins(
            color: const Color(0xFF202124),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF202124)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : scans.isEmpty
              ? Center(
                  child: Text(
                    "No scans yet",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: scans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final scan = scans[index];
                    final bool matched = scan["matched"] == true;
                    final product = scan["productId"];
                    final productImageUrl = matched && product != null
                        ? product["imageUrl"] ?? ""
                        : "";
                    return Dismissible(
                      key: ValueKey(scan["_id"]),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        return false;
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 22),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () {
                            deleteScan(index);
                          },
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F7F6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: productImageUrl.isNotEmpty
                                  ? Image.network(
                                      productImageUrl.startsWith("http")
                                          ? productImageUrl
                                          : _fullImageUrl(productImageUrl),
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image_not_supported),
                                    )
                                  : const Icon(Icons.search_off_rounded),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    matched
                                        ? "${scan["productBrand"] ?? ""} ${scan["productName"] ?? ""}"
                                        : "Product not found",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF202124),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    matched
                                        ? "Matched successfully"
                                        : "Not in database yet",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              matched
                                  ? Icons.check_circle_rounded
                                  : Icons.search_off_rounded,
                              color: matched
                                  ? Colors.green
                                  : const Color(0xFF5B2333),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
