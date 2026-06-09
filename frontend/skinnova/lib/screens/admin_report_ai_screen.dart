import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import '_report_helpers.dart';

class AdminReportAiScreen extends StatefulWidget {
  final String adminId;
  const AdminReportAiScreen({super.key, required this.adminId});
  @override
  State<AdminReportAiScreen> createState() => _State();
}

class _State extends State<AdminReportAiScreen> {
  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List _concerns = [];
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.adminReportAI(
        widget.adminId,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end) : null,
      );
      if (mounted) {
        setState(() {
          _summary = Map.from(data['summary'] ?? {});
          _concerns = List.from(data['concerns'] ?? []);
        });
      }
    } catch (_) {
      if (mounted) ReportHelpers.snack(context, 'Failed to load');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _exportCsv() async {
    try {
      ReportHelpers.snack(context, 'Generating CSV…');
      final csv = await ApiService.adminReportExportCsv(
        widget.adminId, 'ai',
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end) : null,
      );
      final file = File(
          '${Directory.systemTemp.path}/ai_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'AI Report');
    } catch (_) {
      if (mounted) ReportHelpers.snack(context, 'Export failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: ReportHelpers.appBar(context, 'AI Analysis Report'),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _loading
                ? ReportHelpers.loader()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummary(),
                        const SizedBox(height: 20),
                        _buildConcernsTable(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          const Spacer(),
          GestureDetector(
            onTap: () async {
              final r = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                builder: ReportHelpers.datePickerTheme,
              );
              if (r != null) {
                _dateRange = r;
                _load();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _dateRange != null ? AdminTheme.wineMuted : AdminTheme.soft,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: _dateRange != null ? AdminTheme.wine : AdminTheme.line),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range_rounded,
                      size: 15,
                      color: _dateRange != null ? AdminTheme.wine : AdminTheme.grey),
                  const SizedBox(width: 6),
                  Text(
                    _dateRange != null
                        ? '${ReportHelpers.fmtDisplay(_dateRange!.start.toIso8601String())} – ${ReportHelpers.fmtDisplay(_dateRange!.end.toIso8601String())}'
                        : 'Date Range',
                    style: AdminTheme.sub(12),
                  ),
                ],
              ),
            ),
          ),
          if (_dateRange != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _dateRange = null;
                _load();
              },
              child: Container(
                width: 32,
                height: 32,
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
              child: Row(
                children: [
                  const Icon(Icons.download_rounded, size: 14, color: AdminTheme.wine),
                  const SizedBox(width: 5),
                  Text('Export CSV',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AdminTheme.wine,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _load,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AdminTheme.soft,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AdminTheme.line),
              ),
              child: const Icon(Icons.refresh_rounded, size: 17, color: AdminTheme.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        ReportHelpers.summaryCard('Total Scans', '${_summary['totalScans'] ?? 0}'),
        const SizedBox(width: 10),
        ReportHelpers.summaryCard('Routines Generated',
            '${_summary['totalRoutines'] ?? 0}',
            color: AdminTheme.wine),
        const SizedBox(width: 10),
        ReportHelpers.summaryCard('Avg Skin Score',
            '${_summary['avgSkinScore'] ?? '0.0'}',
            color: Colors.green.shade600),
      ],
    );
  }

  Widget _buildConcernsTable() {
    return Container(
      decoration: AdminTheme.cardDec(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text('Top 10 Most Common Skin Concerns',
                style: AdminTheme.title(13.5, w: FontWeight.w600)),
          ),
          const Divider(height: 0, color: AdminTheme.line),
          if (_concerns.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: ReportHelpers.emptyState('No scan data available'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AdminTheme.soft),
                headingTextStyle: ReportHelpers.headStyle(),
                dataTextStyle: ReportHelpers.cellStyle(),
                columnSpacing: 28,
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(label: Text('Skin Concern')),
                  DataColumn(label: Text('Occurrences'), numeric: true),
                  DataColumn(label: Text('Avg Severity'), numeric: true),
                  DataColumn(label: Text('% of Users'), numeric: true),
                ],
                rows: _concerns.asMap().entries.map((e) {
                  final c = e.value;
                  final rank = e.key + 1;
                  return DataRow(
                    cells: [
                      DataCell(Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: rank <= 3
                                  ? AdminTheme.wineMuted
                                  : AdminTheme.soft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('$rank',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: rank <= 3
                                        ? AdminTheme.wine
                                        : AdminTheme.grey)),
                          ),
                          const SizedBox(width: 8),
                          Text(c['concern'] ?? '—',
                              style: ReportHelpers.cellStyle(bold: true)),
                        ],
                      )),
                      DataCell(Text('${c['occurrences'] ?? 0}')),
                      DataCell(Text('${c['avgSeverity'] ?? '0.0'}')),
                      DataCell(Text('${c['percentage'] ?? '0.0'}%')),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
