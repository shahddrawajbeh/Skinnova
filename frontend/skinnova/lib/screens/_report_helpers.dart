import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard.dart';

/// Shared utilities for all admin report screens.
class ReportHelpers {
  // ── Date formatting ──────────────────────────────────────────────────────────

  static String fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String fmtDisplay(dynamic raw) {
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '—';
    }
  }

  static String fmtDateTime(dynamic raw) {
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return '—';
    }
  }

  // ── AppBar ───────────────────────────────────────────────────────────────────

  static AppBar appBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AdminTheme.black,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AdminTheme.black)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AdminTheme.line),
      ),
    );
  }

  // ── Filter bar ───────────────────────────────────────────────────────────────

  static Widget filterBar(
    BuildContext context, {
    required TextEditingController searchCtrl,
    required ValueChanged<String> onSearch,
    required VoidCallback? onExportCsv,
    required VoidCallback? onRefresh,
    DateTimeRange? dateRange,
    VoidCallback? onDatePick,
    VoidCallback? onClearDate,
    List<Widget> filterChips = const [],
    Widget? sortWidget,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: searchCtrl,
                    onSubmitted: onSearch,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search…',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 12.5, color: AdminTheme.grey),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: AdminTheme.grey),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  size: 16, color: AdminTheme.grey),
                              onPressed: () {
                                searchCtrl.clear();
                                onSearch('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AdminTheme.soft,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AdminTheme.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AdminTheme.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AdminTheme.wine),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Date range
              if (onDatePick != null)
                _iconBtn(
                  icon: Icons.date_range_rounded,
                  tooltip: dateRange != null
                      ? '${fmtDisplay(dateRange.start.toIso8601String())} – ${fmtDisplay(dateRange.end.toIso8601String())}'
                      : 'Date Range',
                  active: dateRange != null,
                  onTap: onDatePick,
                ),
              if (onClearDate != null) ...[
                const SizedBox(width: 4),
                _iconBtn(
                  icon: Icons.close_rounded,
                  tooltip: 'Clear date',
                  onTap: onClearDate,
                ),
              ],
              const SizedBox(width: 8),
              if (sortWidget != null) sortWidget,
              const SizedBox(width: 8),
              if (onExportCsv != null)
                _textBtn(
                  icon: Icons.download_rounded,
                  label: 'Export CSV',
                  onTap: onExportCsv,
                ),
              const SizedBox(width: 8),
              if (onRefresh != null)
                _iconBtn(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onTap: onRefresh,
                ),
            ],
          ),
          if (filterChips.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: filterChips),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    String tooltip = '',
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: active ? AdminTheme.wineMuted : AdminTheme.soft,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: active ? AdminTheme.wine : AdminTheme.line),
          ),
          child: Icon(icon,
              size: 17,
              color: active ? AdminTheme.wine : AdminTheme.grey),
        ),
      ),
    );
  }

  static Widget _textBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AdminTheme.wineMuted,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AdminTheme.wine.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AdminTheme.wine),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AdminTheme.wine,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── Filter chips ─────────────────────────────────────────────────────────────

  static List<Widget> chips({
    required Map<String, String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return options.entries.map((e) {
      final sel = selected == e.key;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => onSelect(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: sel ? AdminTheme.wine : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: sel ? AdminTheme.wine : AdminTheme.line),
            ),
            child: Text(e.value,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? Colors.white : AdminTheme.black)),
          ),
        ),
      );
    }).toList();
  }

  // ── Sort dropdown ────────────────────────────────────────────────────────────

  static Widget sortDropdown({
    required String value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AdminTheme.soft,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AdminTheme.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: GoogleFonts.poppins(fontSize: 12, color: AdminTheme.black),
          icon: const Icon(Icons.expand_more_rounded,
              size: 16, color: AdminTheme.grey),
          onChanged: onChanged,
          items: options.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ── Table text styles ────────────────────────────────────────────────────────

  static TextStyle headStyle() => GoogleFonts.poppins(
      fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.black);

  static TextStyle cellStyle({bool bold = false}) => GoogleFonts.poppins(
      fontSize: 12.5,
      fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
      color: AdminTheme.black);

  // ── Status badge ─────────────────────────────────────────────────────────────

  static Widget statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ── Summary card ─────────────────────────────────────────────────────────────

  static Widget summaryCard(String label, String value,
      {Color color = AdminTheme.black}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminTheme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AdminTheme.grey)),
          ],
        ),
      ),
    );
  }

  // ── Pagination ───────────────────────────────────────────────────────────────

  static Widget pagination({
    required int page,
    required int total,
    required int limit,
    VoidCallback? onPrev,
    VoidCallback? onNext,
  }) {
    final start = (page - 1) * limit + 1;
    final end = (page * limit).clamp(0, total);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text('$start–$end of $total',
              style: GoogleFonts.poppins(fontSize: 12, color: AdminTheme.grey)),
          const Spacer(),
          _pgBtn(Icons.chevron_left_rounded, onPrev),
          const SizedBox(width: 4),
          Text('$page',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AdminTheme.black)),
          const SizedBox(width: 4),
          _pgBtn(Icons.chevron_right_rounded, onNext),
        ],
      ),
    );
  }

  static Widget _pgBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? AdminTheme.wineMuted : AdminTheme.soft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminTheme.line),
        ),
        child: Icon(icon,
            size: 18,
            color: onTap != null ? AdminTheme.wine : AdminTheme.grey),
      ),
    );
  }

  // ── Loader / Empty ───────────────────────────────────────────────────────────

  static Widget loader() => const Center(
        child: CircularProgressIndicator(color: AdminTheme.wine),
      );

  static Widget emptyState(String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: AdminTheme.grey.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(msg,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AdminTheme.grey)),
          ],
        ),
      );

  // ── Snackbar ─────────────────────────────────────────────────────────────────

  static void snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: AdminTheme.wine,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Date picker theme ────────────────────────────────────────────────────────

  static Widget datePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AdminTheme.wine,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: AdminTheme.black,
        ),
      ),
      child: child!,
    );
  }

  // ── Date preset chips ────────────────────────────────────────────────────────

  /// Returns a row of preset chips. Calls [onSelect] with a [DateTimeRange].
  /// Pass [activePreset] as the currently selected label ('' = none).
  static Widget datePresetChips({
    required ValueChanged<DateTimeRange?> onSelect,
    String activePreset = '',
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final presets = {
      'Today': DateTimeRange(start: today, end: today),
      'Yesterday': DateTimeRange(
          start: today.subtract(const Duration(days: 1)),
          end: today.subtract(const Duration(days: 1))),
      'Last 7d': DateTimeRange(
          start: today.subtract(const Duration(days: 6)), end: today),
      'Last 30d': DateTimeRange(
          start: today.subtract(const Duration(days: 29)), end: today),
      'This Month': DateTimeRange(
          start: DateTime(now.year, now.month, 1), end: today),
      'This Year': DateTimeRange(
          start: DateTime(now.year, 1, 1), end: today),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...presets.entries.map((e) {
            final selected = activePreset == e.key;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onSelect(e.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected ? AdminTheme.wine : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected
                            ? AdminTheme.wine
                            : AdminTheme.line),
                  ),
                  child: Text(e.key,
                      style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? Colors.white
                              : AdminTheme.black)),
                ),
              ),
            );
          }),
          // Clear preset chip
          if (activePreset.isNotEmpty)
            GestureDetector(
              onTap: () => onSelect(null),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AdminTheme.soft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AdminTheme.line),
                ),
                child: Row(children: [
                  const Icon(Icons.close_rounded,
                      size: 12, color: AdminTheme.grey),
                  const SizedBox(width: 4),
                  Text('Clear',
                      style: GoogleFonts.poppins(
                          fontSize: 11.5, color: AdminTheme.grey)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ── Skeleton table ───────────────────────────────────────────────────────────

  /// Shows N shimmer rows to use while data is loading.
  static Widget skeletonTable({int rows = 7, int cols = 5}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.line),
        ),
        child: Column(
          children: [
            // Header row
            Container(
              height: 42,
              decoration: const BoxDecoration(
                color: AdminTheme.soft,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(cols, (i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 12),
                      child: _SkeletonBar(width: 60 + (i * 8.0)),
                    ),
                  );
                }),
              ),
            ),
            ...List.generate(rows, (r) {
              final isLast = r == rows - 1;
              return Column(
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: List.generate(cols, (c) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 14),
                            child: _SkeletonBar(
                                width: 40.0 +
                                    (c * 12.0) +
                                    (r * 4.0) % 30),
                          ),
                        );
                      }),
                    ),
                  ),
                  if (!isLast)
                    Container(height: 0.5, color: AdminTheme.line),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Smart status badge ────────────────────────────────────────────────────────

  /// Auto-picks a color from the status string.
  static Widget smartStatusBadge(String status) {
    Color c;
    final s = status.toLowerCase();
    if (s == 'active' || s == 'approved' || s == 'delivered' || s == 'paid') {
      c = AdminTheme.success;
    } else if (s == 'pending' || s == 'processing' || s == 'partial') {
      c = AdminTheme.warning;
    } else if (s == 'inactive' || s == 'rejected' || s == 'cancelled' ||
        s == 'failed') {
      c = AdminTheme.danger;
    } else if (s == 'out_for_delivery' || s == 'shipped') {
      c = AdminTheme.info;
    } else if (s == 'admin' || s == 'seller') {
      c = AdminTheme.wine;
    } else {
      c = AdminTheme.grey;
    }
    return statusBadge(status.replaceAll('_', ' '), c);
  }
}

// ── Skeleton bar widget (stateful shimmer) ────────────────────────────────────
class _SkeletonBar extends StatefulWidget {
  final double width;
  const _SkeletonBar({required this.width});
  @override
  State<_SkeletonBar> createState() => _SkeletonBarState();
}

class _SkeletonBarState extends State<_SkeletonBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        height: 10,
        width: math.min(widget.width, double.infinity),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEEECE9),
              Color.lerp(const Color(0xFFEEECE9), const Color(0xFFDDD8D4),
                  _ctrl.value)!,
              const Color(0xFFEEECE9),
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
}
