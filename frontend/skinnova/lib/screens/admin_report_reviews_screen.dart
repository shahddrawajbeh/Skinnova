import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import '_report_helpers.dart';

class AdminReportReviewsScreen extends StatefulWidget {
  final String adminId;
  const AdminReportReviewsScreen({super.key, required this.adminId});
  @override
  State<AdminReportReviewsScreen> createState() => _State();
}

class _State extends State<AdminReportReviewsScreen> {
  bool _loading = true;
  List _stores = [];
  Map<String, dynamic> _summary = {};
  String _search = '';
  DateTimeRange? _dateRange;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.adminReportReviews(
        widget.adminId, search: _search,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
      );
      if (mounted) setState(() {
        _stores  = List.from(data['stores'] ?? []);
        _summary = Map.from(data['summary'] ?? {});
      });
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Failed to load'); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _exportCsv() async {
    try {
      ReportHelpers.snack(context, 'Generating CSV…');
      final csv = await ApiService.adminReportExportCsv(
        widget.adminId, 'reviews', search: _search,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
      );
      final file = File('${Directory.systemTemp.path}/review_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Review Report');
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Export failed'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: ReportHelpers.appBar(context, 'Review Report'),
      body: Column(children: [
        ReportHelpers.filterBar(context,
          searchCtrl: _searchCtrl,
          onSearch: (v) { _search = v; _load(); },
          dateRange: _dateRange,
          onDatePick: () async {
            final r = await showDateRangePicker(context: context,
              firstDate: DateTime(2024), lastDate: DateTime.now(),
              builder: ReportHelpers.datePickerTheme);
            if (r != null) { _dateRange = r; _load(); }
          },
          onClearDate: _dateRange != null ? () { _dateRange = null; _load(); } : null,
          onExportCsv: _exportCsv,
          onRefresh: () => _load(),
        ),
        if (!_loading) _buildSummary(),
        Expanded(child: _loading ? ReportHelpers.loader() : _buildTable()),
      ]),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        ReportHelpers.summaryCard('Total Reviews', '${_summary['totalReviews'] ?? 0}'),
        const SizedBox(width: 10),
        ReportHelpers.summaryCard('Highest Rated', '${_summary['highestRated'] ?? 0}', color: Colors.green.shade600),
        const SizedBox(width: 10),
        ReportHelpers.summaryCard('Lowest Rated', '${_summary['lowestRated'] ?? 0}', color: Colors.red.shade400),
      ]),
    );
  }

  Widget _buildTable() {
    if (_stores.isEmpty) return ReportHelpers.emptyState('No review data found');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: AdminTheme.cardDec(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(AdminTheme.soft),
            headingTextStyle: ReportHelpers.headStyle(),
            dataTextStyle: ReportHelpers.cellStyle(),
            columnSpacing: 28,
            dividerThickness: 0.5,
            columns: const [
              DataColumn(label: Text('Store')),
              DataColumn(label: Text('Reviews'), numeric: true),
              DataColumn(label: Text('Avg Rating'), numeric: true),
              DataColumn(label: Text('Positive')),
              DataColumn(label: Text('Negative')),
            ],
            rows: _stores.map((s) {
              final avg = s['avgRating'];
              final avgStr = avg != null ? (avg as num).toStringAsFixed(1) : '—';
              return DataRow(cells: [
                DataCell(Text(s['storeName'] ?? '—', style: ReportHelpers.cellStyle(bold: true))),
                DataCell(Text('${s['reviewCount'] ?? 0}')),
                DataCell(Text(avgStr)),
                DataCell(ReportHelpers.statusBadge(s['positivePct'] ?? '0%', Colors.green.shade600)),
                DataCell(ReportHelpers.statusBadge(s['negativePct'] ?? '0%', Colors.red.shade400)),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
