import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import 'product_usage_reminder_screen.dart';

class MyProductRemindersScreen extends StatefulWidget {
  final String userId;
  const MyProductRemindersScreen({super.key, required this.userId});

  @override
  State<MyProductRemindersScreen> createState() =>
      _MyProductRemindersScreenState();
}

class _MyProductRemindersScreenState extends State<MyProductRemindersScreen> {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reminders = [];
  final Set<String> _togglingIds = {};
  final Set<String> _deletingIds = {};

  static const List<String> _dayNames = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getProductUsageReminders(widget.userId);
      if (!mounted) return;
      setState(() {
        _reminders = list.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggle(String reminderId) async {
    setState(() => _togglingIds.add(reminderId));
    final ok =
        await ApiService.toggleProductUsageReminder(reminderId, widget.userId);
    if (!mounted) return;
    setState(() => _togglingIds.remove(reminderId));
    if (ok) await _load();
  }

  Future<void> _delete(String reminderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Reminder',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: darkText)),
        content: Text('Remove this product usage reminder?',
            style: GoogleFonts.poppins(fontSize: 14, color: grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: grey, fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _deletingIds.add(reminderId));
    final ok =
        await ApiService.deleteProductUsageReminder(reminderId, widget.userId);
    if (!mounted) return;
    setState(() => _deletingIds.remove(reminderId));
    if (ok) await _load();
  }

  void _openEdit(Map<String, dynamic> reminder) {
    final times =
        (reminder['reminderTimes'] as List?)?.cast<Map<String, dynamic>>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductUsageReminderScreen(
          userId: widget.userId,
          productId: reminder['productId']?.toString() ?? '',
          productName: reminder['productNameSnapshot'] ?? '',
          brand: reminder['brandSnapshot'] ?? '',
          imageUrl: reminder['productImageSnapshot'] ?? '',
          directionsOfUse: reminder['directionsOfUseSnapshot'] ?? '',
          existingReminderId: reminder['_id']?.toString(),
          existingTimes: times,
          existingFrequencyType: reminder['frequencyType']?.toString(),
          existingIsActive: reminder['isActive'] == true,
        ),
      ),
    ).then((_) => _load());
  }

  // ── Formatting ────────────────────────────────────────────────────────────

  String _scheduleText(List<dynamic> times) {
    if (times.isEmpty) return 'No schedule set';
    final slots = times.where((t) => (t['enabled'] ?? true) == true).toList();
    if (slots.isEmpty) return 'All times disabled';
    return slots.map((t) {
      final time = t['time']?.toString() ?? '08:00';
      final day = t['dayOfWeek'];
      final fmtTime = _fmt12h(time);
      return day != null ? '${_dayNames[day as int]} $fmtTime' : fmtTime;
    }).join(' · ');
  }

  String _fmt12h(String time24) {
    try {
      final parts = time24.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final period = h < 12 ? 'AM' : 'PM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$h12:$m $period';
    } catch (_) {
      return time24;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: whiteSmoke, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: darkText),
          ),
        ),
        title: Text('My Product Reminders',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w600, color: darkText)),
        centerTitle: true,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: line, height: 1)),
      );

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: wine));
    }
    if (_error != null) {
      return _buildErrorState();
    }
    if (_reminders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: wine,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _reminders.length,
        itemBuilder: (_, i) => _buildReminderCard(_reminders[i]),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final id = reminder['_id']?.toString() ?? '';
    final name = reminder['productNameSnapshot'] ?? 'Unknown Product';
    final brand = reminder['brandSnapshot'] ?? '';
    final imageUrl = reminder['productImageSnapshot'] ?? '';
    final isActive = reminder['isActive'] == true;
    final times = (reminder['reminderTimes'] as List?) ?? [];
    final isToggling = _togglingIds.contains(id);
    final isDeleting = _deletingIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isActive ? line : line.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.55,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: darkText),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        if (brand.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(brand,
                              style: GoogleFonts.poppins(
                                  fontSize: 11.5, color: grey)),
                        ],
                      ],
                    ),
                  ),
                  // Active toggle
                  if (isToggling)
                    const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: wine))
                  else
                    Transform.scale(
                      scale: 0.82,
                      child: Switch(
                        value: isActive,
                        onChanged: (_) => _toggle(id),
                        activeColor: wine,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: line),
              const SizedBox(height: 10),

              // Schedule
              Row(
                children: [
                  const Icon(Icons.alarm_rounded, size: 14, color: wine),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_scheduleText(times),
                        style:
                            GoogleFonts.poppins(fontSize: 12, color: darkText)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  // Edit
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openEdit(reminder),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: wine,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text('Edit',
                            style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Delete
                  Expanded(
                    child: GestureDetector(
                      onTap: isDeleting ? null : () => _delete(id),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.25)),
                        ),
                        alignment: Alignment.center,
                        child: isDeleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.red))
                            : Text('Delete',
                                style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
            color: const Color(0xFFF2E8EA),
            borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.spa_outlined, color: wine, size: 24),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: wine.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.alarm_outlined, size: 34, color: wine),
              ),
              const SizedBox(height: 18),
              Text('No Reminders Yet',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: darkText)),
              const SizedBox(height: 8),
              Text(
                'Set reminders from your Purchase History\nto never forget to use your products.',
                style: GoogleFonts.poppins(fontSize: 12.5, color: grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildErrorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: wine),
              const SizedBox(height: 12),
              Text('Failed to load reminders',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkText)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                      color: wine, borderRadius: BorderRadius.circular(12)),
                  child: Text('Try Again',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
}
