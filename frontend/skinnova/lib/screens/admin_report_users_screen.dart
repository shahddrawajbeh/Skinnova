import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import '_report_helpers.dart';

class AdminReportUsersScreen extends StatefulWidget {
  final String adminId;
  const AdminReportUsersScreen({super.key, required this.adminId});
  @override
  State<AdminReportUsersScreen> createState() => _State();
}

class _State extends State<AdminReportUsersScreen> {
  bool _loading = true;
  List _users = [];
  Map<String, dynamic> _summary = {};
  int _total = 0;
  int _page = 1;

  String _status = '';
  String _sort = 'newest';
  String _search = '';
  DateTimeRange? _dateRange;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() { _loading = true; _page = page; });
    try {
      final data = await ApiService.adminReportUsers(
        widget.adminId,
        status: _status,
        sort: _sort,
        search: _search,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
        page: page,
      );
      if (mounted) {
        setState(() {
          _users   = List.from(data['users'] ?? []);
          _total   = data['total'] ?? 0;
          _summary = Map.from(data['summary'] ?? {});
        });
      }
    } catch (e) {
      if (mounted) ReportHelpers.snack(context, 'Failed to load report');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _exportCsv() async {
    try {
      ReportHelpers.snack(context, 'Generating CSV…');
      final csv = await ApiService.adminReportExportCsv(
        widget.adminId, 'users',
        status: _status, search: _search,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
      );
      final file = File('${Directory.systemTemp.path}/user_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'User Report');
    } catch (_) {
      if (mounted) ReportHelpers.snack(context, 'Export failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: ReportHelpers.appBar(context, 'User Report'),
      body: Column(
        children: [
          ReportHelpers.filterBar(
            context,
            searchCtrl: _searchCtrl,
            onSearch: (v) { _search = v; _load(); },
            dateRange: _dateRange,
            onDatePick: () async {
              final r = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                builder: (ctx, child) => ReportHelpers.datePickerTheme(ctx, child),
              );
              if (r != null) { _dateRange = r; _load(); }
            },
            onClearDate: _dateRange != null ? () { _dateRange = null; _load(); } : null,
            onExportCsv: _exportCsv,
            onRefresh: () => _load(),
            filterChips: ReportHelpers.chips(
              options: {
                '': 'All', 'active': 'Active', 'inactive': 'Inactive',
                'new': 'New (30d)', 'withOrders': 'Has Orders',
              },
              selected: _status,
              onSelect: (v) { _status = v; _load(); },
            ),
            sortWidget: ReportHelpers.sortDropdown(
              value: _sort,
              options: {
                'newest': 'Newest',
                'oldest': 'Oldest',
                'mostOrders': 'Most Orders',
                'mostPurchases': 'Most Purchases',
                'mostScans': 'Most AI Scans',
              },
              onChanged: (v) { _sort = v!; _load(); },
            ),
          ),
          if (!_loading) _buildSummary(),
          Expanded(child: _loading ? ReportHelpers.loader() : _buildTable()),
          if (!_loading)
            ReportHelpers.pagination(
              page: _page, total: _total, limit: 50,
              onPrev: _page > 1 ? () => _load(page: _page - 1) : null,
              onNext: (_page * 50) < _total ? () => _load(page: _page + 1) : null,
            ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          ReportHelpers.summaryCard('Total', '${_summary['totalUsers'] ?? 0}'),
          const SizedBox(width: 10),
          ReportHelpers.summaryCard('Active', '${_summary['activeUsers'] ?? 0}', color: Colors.green.shade600),
          const SizedBox(width: 10),
          ReportHelpers.summaryCard('Inactive', '${_summary['inactiveUsers'] ?? 0}', color: Colors.red.shade400),
          const SizedBox(width: 10),
          ReportHelpers.summaryCard('New (30d)', '${_summary['newUsers'] ?? 0}', color: AdminTheme.wine),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_users.isEmpty) return ReportHelpers.emptyState('No users found');
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
              DataColumn(label: Text('User')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Joined')),
              DataColumn(label: Text('Orders'), numeric: true),
              DataColumn(label: Text('AI Scans'), numeric: true),
              DataColumn(label: Text('Spent (ILS)'), numeric: true),
              DataColumn(label: Text('Status')),
            ],
            rows: _users.map((u) {
              final name = u['fullName'] ?? '';
              final email = u['email'] ?? '';
              final joined = ReportHelpers.fmtDisplay(u['createdAt']);
              final orders = u['ordersCount'] ?? 0;
              final scans = u['aiScanCount'] ?? 0;
              final spent = (u['totalSpent'] ?? 0.0).toStringAsFixed(0);
              final active = u['isActive'] != false;
              return DataRow(cells: [
                DataCell(Text(name, style: ReportHelpers.cellStyle(bold: true))),
                DataCell(Text(email)),
                DataCell(Text(joined)),
                DataCell(Text('$orders')),
                DataCell(Text('$scans')),
                DataCell(Text(spent)),
                DataCell(ReportHelpers.statusBadge(
                  active ? 'Active' : 'Inactive',
                  active ? Colors.green.shade600 : Colors.red.shade400,
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
