import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import '_report_helpers.dart';

class AdminReportLoginScreen extends StatefulWidget {
  final String adminId;
  const AdminReportLoginScreen({super.key, required this.adminId});
  @override
  State<AdminReportLoginScreen> createState() => _State();
}

class _State extends State<AdminReportLoginScreen> {
  bool _loading = true;
  List _records = [];
  Map<String, dynamic> _summary = {};
  int _total = 0;
  int _page = 1;
  String _search = '';
  DateTimeRange? _dateRange;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({int page = 1}) async {
    setState(() { _loading = true; _page = page; });
    try {
      final data = await ApiService.adminReportLoginActivity(
        widget.adminId, search: _search,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
        page: page,
      );
      if (mounted) setState(() {
        _records = List.from(data['records'] ?? []);
        _total   = data['total'] ?? 0;
        _summary = Map.from(data['summary'] ?? {});
      });
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Failed to load'); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _exportCsv() async {
    try {
      ReportHelpers.snack(context, 'Generating CSV…');
      final csv = await ApiService.adminReportExportCsv(
        widget.adminId, 'login-activity', search: _search,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
      );
      final file = File('${Directory.systemTemp.path}/login_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Login Activity Report');
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Export failed'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: ReportHelpers.appBar(context, 'Login Activity Report'),
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
        if (!_loading) ReportHelpers.pagination(
          page: _page, total: _total, limit: 50,
          onPrev: _page > 1 ? () => _load(page: _page - 1) : null,
          onNext: (_page * 50) < _total ? () => _load(page: _page + 1) : null,
        ),
      ]),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        ReportHelpers.summaryCard('Total Logins', '${_summary['totalLogins'] ?? 0}'),
        const SizedBox(width: 10),
        ReportHelpers.summaryCard('Avg Session', '${_summary['avgSessionMinutes'] ?? 0} min'),
        const SizedBox(width: 10),
        ReportHelpers.summaryCard('Peak Hour', _summary['peakHour'] ?? 'N/A', color: AdminTheme.wine),
      ]),
    );
  }

  Widget _buildTable() {
    if (_records.isEmpty) return ReportHelpers.emptyState('No login records found');
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
            columnSpacing: 20,
            dividerThickness: 0.5,
            columns: const [
              DataColumn(label: Text('User')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Login Time')),
              DataColumn(label: Text('Logout Time')),
              DataColumn(label: Text('Duration')),
              DataColumn(label: Text('Device')),
              DataColumn(label: Text('Platform')),
              DataColumn(label: Text('IP Address')),
            ],
            rows: _records.map((r) {
              final userId = r['userId'];
              final name  = (userId is Map ? userId['fullName'] : null) ?? '—';
              final email = (userId is Map ? userId['email']    : null) ?? '—';
              final dur = r['sessionDuration'];
              final durStr = dur != null
                  ? '${((dur as num) / 60).round()} min'
                  : 'Active';
              return DataRow(cells: [
                DataCell(Text(name, style: ReportHelpers.cellStyle(bold: true))),
                DataCell(Text(email)),
                DataCell(Text(ReportHelpers.fmtDateTime(r['loginTime']))),
                DataCell(Text(r['logoutTime'] != null
                    ? ReportHelpers.fmtDateTime(r['logoutTime'])
                    : 'Active')),
                DataCell(Text(durStr)),
                DataCell(Text(r['device'] ?? '—')),
                DataCell(Text(r['platform'] ?? '—')),
                DataCell(Text(r['ipAddress'] ?? '—')),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
