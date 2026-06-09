import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import '_report_helpers.dart';

class AdminReportNotificationsScreen extends StatefulWidget {
  final String adminId;
  const AdminReportNotificationsScreen({super.key, required this.adminId});
  @override
  State<AdminReportNotificationsScreen> createState() => _State();
}

class _State extends State<AdminReportNotificationsScreen> {
  bool _loading = true;
  List _notifications = [];
  Map<String, dynamic> _summary = {};
  DateTimeRange? _dateRange;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.adminReportNotifications(
        widget.adminId,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
      );
      if (mounted) setState(() {
        _notifications = List.from(data['notifications'] ?? []);
        _summary       = Map.from(data['summary'] ?? {});
      });
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Failed to load'); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _exportCsv() async {
    try {
      ReportHelpers.snack(context, 'Generating CSV…');
      final csv = await ApiService.adminReportExportCsv(
        widget.adminId, 'notifications',
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
      );
      final file = File('${Directory.systemTemp.path}/notification_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Notification Report');
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Export failed'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: ReportHelpers.appBar(context, 'Notification Report'),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            const Spacer(),
            if (_dateRange != null) ...[
              ReportHelpers.chips(
                options: {'clear': 'Clear Date'},
                selected: '',
                onSelect: (_) { _dateRange = null; _load(); },
              ).first,
              const SizedBox(width: 8),
            ],
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
                  Text('Export CSV', style: AdminTheme.sub(12).copyWith(color: AdminTheme.wine)),
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
        ReportHelpers.summaryCard('Total Sent', '${_summary['total'] ?? 0}'),
        const SizedBox(width: 10),
        ReportHelpers.summaryCard('Opened', '${_summary['opened'] ?? 0}', color: Colors.green.shade600),
        const SizedBox(width: 10),
        ReportHelpers.summaryCard('Avg Open Rate', _summary['avgOpenRate'] ?? '0%', color: AdminTheme.wine),
      ]),
    );
  }

  Widget _buildTable() {
    if (_notifications.isEmpty) return ReportHelpers.emptyState('No notifications found');
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
            columnSpacing: 24,
            dividerThickness: 0.5,
            columns: const [
              DataColumn(label: Text('Notification')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Recipients'), numeric: true),
              DataColumn(label: Text('Opened'), numeric: true),
              DataColumn(label: Text('Open Rate')),
              DataColumn(label: Text('Sent At')),
            ],
            rows: _notifications.map((n) {
              final rate = n['openRate'] ?? '0%';
              return DataRow(cells: [
                DataCell(Text(n['notification'] ?? '—',
                    style: ReportHelpers.cellStyle(bold: true),
                    overflow: TextOverflow.ellipsis)),
                DataCell(Text((n['type'] ?? '—').toString().replaceAll('_', ' '))),
                DataCell(Text('${n['recipients'] ?? 0}')),
                DataCell(Text('${n['opened'] ?? 0}')),
                DataCell(ReportHelpers.statusBadge(
                  rate.toString(),
                  (double.tryParse(rate.toString().replaceAll('%', '')) ?? 0) >= 50
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                )),
                DataCell(Text(n['createdAt'] ?? '—')),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
