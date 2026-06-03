import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class AdminStoreReportsPage extends StatefulWidget {
  const AdminStoreReportsPage({super.key});

  @override
  State<AdminStoreReportsPage> createState() => _AdminStoreReportsPageState();
}

class _AdminStoreReportsPageState extends State<AdminStoreReportsPage>
    with SingleTickerProviderStateMixin {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFFF5F5F3);
  static const Color card = Colors.white;
  static const Color wine = Color(0xFF5B2333);
  static const Color black = Color(0xFF202020);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFE8E8E8);
  static const Color pendingColor = Color(0xFFD97706);
  static const Color reviewedColor = Color(0xFF2E7D52);
  static const Color dismissedColor = Color(0xFF777777);

  late TabController _tabCtrl;
  final List<String> _tabs = ["All", "Pending", "Reviewed", "Dismissed"];
  final List<String?> _statusFilters = [
    null,
    "pending",
    "reviewed",
    "dismissed"
  ];

  List<dynamic> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final status = _statusFilters[_tabCtrl.index];
    final result = await ApiService.fetchStoreReports(status: status);
    if (!mounted) return;
    setState(() {
      _reports = result;
      _isLoading = false;
    });
  }

  Future<void> _action(String reportId, bool isReview) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isReview ? "Mark as Reviewed" : "Dismiss Report",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isReview
                  ? "Add an optional note about what action was taken."
                  : "Add an optional note explaining why this is dismissed.",
              style:
                  GoogleFonts.poppins(fontSize: 13, color: grey, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: GoogleFonts.poppins(fontSize: 13, color: black),
              decoration: InputDecoration(
                hintText: "Admin note (optional)...",
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFFBBBBBB)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: black,
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Cancel", style: GoogleFonts.poppins(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isReview ? reviewedColor : wine,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isReview ? "Confirm" : "Dismiss",
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final note = noteCtrl.text.trim();
    bool success;
    if (isReview) {
      success = await ApiService.markStoreReportReviewed(
          reportId: reportId, adminNote: note);
    } else {
      success = await ApiService.markStoreReportDismissed(
          reportId: reportId, adminNote: note);
    }

    if (!mounted) return;
    if (success) {
      _showSnack(isReview ? "Report marked as reviewed." : "Report dismissed.");
      _load();
    } else {
      _showSnack("Action failed. Try again.");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: wine,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
        content: Text(
          msg,
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _reports.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: wine,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 14, 18, 28),
                                itemCount: _reports.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) =>
                                    _buildReportCard(_reports[i]),
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 17, color: wine),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Store Reports",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: black,
                ),
              ),
              Text(
                "Visible to admin only",
                style: GoogleFonts.poppins(fontSize: 12, color: grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDEB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: wine,
          borderRadius: BorderRadius.circular(11),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: grey,
        labelStyle:
            GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
        padding: const EdgeInsets.all(4),
      ),
    );
  }

  Widget _buildReportCard(dynamic report) {
    final reportId = (report["_id"] ?? "").toString();
    final storeName = (report["storeName"] ?? "Unknown Store").toString();
    final userName = (report["userName"] ?? "Customer").toString();
    final reason = (report["reason"] ?? "").toString();
    final details = (report["details"] ?? "").toString();
    final status = (report["status"] ?? "pending").toString();
    final adminNote = (report["adminNote"] ?? "").toString();
    final createdAt = report["createdAt"] != null
        ? _formatDate(report["createdAt"].toString())
        : "";

    final isPending = status == "pending";
    final isReviewed = status == "reviewed";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending ? pendingColor.withOpacity(0.3) : line,
          width: isPending ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: wine.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  storeName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: wine,
                  ),
                ),
              ),
              const Spacer(),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),

          // ── Reported by ──
          _infoRow(Icons.person_outline_rounded, "Reported by", userName),
          const SizedBox(height: 6),
          _infoRow(Icons.flag_outlined, "Reason", reason),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.notes_rounded, "Details", details),
          ],
          if (adminNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(
                Icons.admin_panel_settings_outlined, "Admin note", adminNote),
          ],
          const SizedBox(height: 8),
          Text(
            createdAt,
            style: GoogleFonts.poppins(
                fontSize: 11.5, color: const Color(0xFFBBBBBB)),
          ),

          // ── Action buttons (only for pending) ──
          if (isPending) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF0F0F0), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _action(reportId, false),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(
                      "Dismiss",
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dismissedColor,
                      side: BorderSide(color: dismissedColor.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _action(reportId, true),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      "Reviewed",
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: reviewedColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Re-open option for reviewed/dismissed ──
          if (!isPending) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                isReviewed ? "Marked as reviewed" : "Dismissed",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isReviewed ? reviewedColor : dismissedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case "reviewed":
        color = reviewedColor;
        label = "Reviewed";
        break;
      case "dismissed":
        color = dismissedColor;
        label = "Dismissed";
        break;
      default:
        color = pendingColor;
        label = "Pending";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: grey),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: GoogleFonts.poppins(
              fontSize: 12.5, color: grey, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 12.5, color: black),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: wine.withOpacity(0.07),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.flag_outlined, size: 32, color: wine),
            ),
            const SizedBox(height: 16),
            Text(
              "No reports here",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: black),
            ),
            const SizedBox(height: 6),
            Text(
              "Store reports submitted by users will appear here.",
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Failed to load reports",
              style: GoogleFonts.poppins(color: grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
                backgroundColor: wine,
                foregroundColor: Colors.white,
                elevation: 0),
            child: Text("Try Again", style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return raw;
    }
  }
}
