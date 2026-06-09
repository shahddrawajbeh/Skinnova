import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import '_report_helpers.dart';

class AdminReportRevenueScreen extends StatefulWidget {
  final String adminId;
  const AdminReportRevenueScreen({super.key, required this.adminId});
  @override
  State<AdminReportRevenueScreen> createState() => _State();
}

class _State extends State<AdminReportRevenueScreen> {
  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List _stores = [];
  DateTimeRange? _dateRange;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.adminReportRevenue(
        widget.adminId,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
      );
      if (mounted) setState(() {
        _summary = Map.from(data['summary'] ?? {});
        _stores  = List.from(data['stores']  ?? []);
      });
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Failed to load'); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _exportCsv() async {
    try {
      ReportHelpers.snack(context, 'Generating CSV…');
      final csv = await ApiService.adminReportExportCsv(
        widget.adminId, 'revenue',
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
      );
      final file = File('${Directory.systemTemp.path}/revenue_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Revenue Report');
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Export failed'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: ReportHelpers.appBar(context, 'Revenue Report'),
      body: Column(children: [
        _buildFilterBar(),
        Expanded(
          child: _loading
              ? ReportHelpers.loader()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildSummaryGrid(),
                    const SizedBox(height: 20),
                    _buildStoreTable(),
                  ]),
                ),
        ),
      ]),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(children: [
        const Spacer(),
        GestureDetector(
          onTap: () async {
            final r = await showDateRangePicker(context: context,
              firstDate: DateTime(2024), lastDate: DateTime.now(),
              builder: ReportHelpers.datePickerTheme);
            if (r != null) { _dateRange = r; _load(); }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _dateRange != null ? AdminTheme.wineMuted : AdminTheme.soft,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _dateRange != null ? AdminTheme.wine : AdminTheme.line),
            ),
            child: Row(children: [
              Icon(Icons.date_range_rounded, size: 15,
                  color: _dateRange != null ? AdminTheme.wine : AdminTheme.grey),
              const SizedBox(width: 6),
              Text(_dateRange != null
                  ? '${ReportHelpers.fmtDisplay(_dateRange!.start.toIso8601String())} – ${ReportHelpers.fmtDisplay(_dateRange!.end.toIso8601String())}'
                  : 'Date Range',
                  style: AdminTheme.sub(12)),
            ]),
          ),
        ),
        if (_dateRange != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () { _dateRange = null; _load(); },
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AdminTheme.soft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminTheme.line),
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: AdminTheme.grey),
            ),
          ),
        ],
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _exportCsv,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AdminTheme.wineMuted,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AdminTheme.wine.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.download_rounded, size: 14, color: AdminTheme.wine),
              const SizedBox(width: 5),
              Text('Export CSV', style: GoogleFonts.poppins(
                  fontSize: 12, color: AdminTheme.wine, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _load,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AdminTheme.soft,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AdminTheme.line),
            ),
            child: const Icon(Icons.refresh_rounded, size: 17, color: AdminTheme.grey),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final fromStr = _dateRange != null
        ? ReportHelpers.fmtDisplay(_dateRange!.start.toIso8601String())
        : 'All time';
    final toStr = _dateRange != null
        ? ReportHelpers.fmtDisplay(_dateRange!.end.toIso8601String())
        : ReportHelpers.fmtDisplay(now.toIso8601String());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AdminTheme.cardDec(shadow: true),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Revenue Report',
                  style: AdminTheme.title(16, w: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Period: $fromStr – $toStr',
                  style: AdminTheme.sub(12.5)),
              const SizedBox(height: 2),
              Text('Generated: ${ReportHelpers.fmtDateTime(now.toIso8601String())}',
                  style: AdminTheme.sub(11.5)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AdminTheme.wineMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Official Report',
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: AdminTheme.wine)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    final rev  = (_summary['totalRevenue']  ?? 0.0) as num;
    final avg  = (_summary['avgOrderValue'] ?? 0.0) as num;
    final items = [
      ('Total Revenue', 'ILS ${rev.toStringAsFixed(2)}', AdminTheme.wine),
      ('Total Orders', '${_summary['totalOrders'] ?? 0}', AdminTheme.black),
      ('Delivered', '${_summary['delivered'] ?? 0}', Colors.green.shade600),
      ('Cancelled', '${_summary['cancelled'] ?? 0}', Colors.red.shade400),
      ('Avg Order Value', 'ILS ${avg.toStringAsFixed(2)}', Colors.blue.shade500),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((t) {
        return Container(
          width: 170,
          padding: const EdgeInsets.all(16),
          decoration: AdminTheme.cardDec(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.$3 == AdminTheme.wine ? '⬤ ' : '', style: TextStyle(color: t.$3, fontSize: 8)),
            Text(t.$2,
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w700, color: t.$3)),
            const SizedBox(height: 2),
            Text(t.$1, style: AdminTheme.sub(11.5)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildStoreTable() {
    if (_stores.isEmpty) return const SizedBox();
    return Container(
      decoration: AdminTheme.cardDec(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text('Revenue by Store',
              style: AdminTheme.title(13.5, w: FontWeight.w600)),
        ),
        const Divider(height: 0, color: AdminTheme.line),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(AdminTheme.soft),
            headingTextStyle: ReportHelpers.headStyle(),
            dataTextStyle: ReportHelpers.cellStyle(),
            columnSpacing: 28,
            dividerThickness: 0.5,
            columns: const [
              DataColumn(label: Text('Store')),
              DataColumn(label: Text('Orders'), numeric: true),
              DataColumn(label: Text('Revenue (ILS)'), numeric: true),
              DataColumn(label: Text('Cancelled'), numeric: true),
              DataColumn(label: Text('Net Revenue (ILS)'), numeric: true),
            ],
            rows: _stores.map((s) {
              final rev = (s['revenue'] ?? 0.0) as num;
              final net = (s['netRevenue'] ?? 0.0) as num;
              return DataRow(cells: [
                DataCell(Text(s['storeName'] ?? '—',
                    style: ReportHelpers.cellStyle(bold: true))),
                DataCell(Text('${s['orders'] ?? 0}')),
                DataCell(Text(rev.toStringAsFixed(2))),
                DataCell(Text('${s['cancelled'] ?? 0}')),
                DataCell(Text(net.toStringAsFixed(2))),
              ]);
            }).toList(),
          ),
        ),
      ]),
    );
  }
}
