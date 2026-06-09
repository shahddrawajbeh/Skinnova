import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import '_report_helpers.dart';

class AdminReportStoresScreen extends StatefulWidget {
  final String adminId;
  const AdminReportStoresScreen({super.key, required this.adminId});
  @override
  State<AdminReportStoresScreen> createState() => _State();
}

class _State extends State<AdminReportStoresScreen> {
  bool _loading = true;
  List _stores = [];
  int _total = 0;
  int _page = 1;
  String _filter = 'all';
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
      final data = await ApiService.adminReportStores(
        widget.adminId,
        filter: _filter, search: _search,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
        page: page,
      );
      if (mounted) setState(() {
        _stores = List.from(data['stores'] ?? []);
        _total  = data['total'] ?? 0;
      });
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Failed to load'); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _exportCsv() async {
    try {
      ReportHelpers.snack(context, 'Generating CSV…');
      final csv = await ApiService.adminReportExportCsv(
        widget.adminId, 'stores', filter: _filter, search: _search,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
      );
      final file = File('${Directory.systemTemp.path}/store_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Store Report');
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Export failed'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: ReportHelpers.appBar(context, 'Store Report'),
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
          filterChips: ReportHelpers.chips(
            options: { 'all': 'All', 'topRevenue': 'Top Revenue',
              'mostOrders': 'Most Orders', 'highestRating': 'Highest Rating',
              'newest': 'Newest' },
            selected: _filter,
            onSelect: (v) { _filter = v; _load(); },
          ),
        ),
        Expanded(child: _loading ? ReportHelpers.loader() : _buildTable()),
        if (!_loading) ReportHelpers.pagination(
          page: _page, total: _total, limit: 50,
          onPrev: _page > 1 ? () => _load(page: _page - 1) : null,
          onNext: (_page * 50) < _total ? () => _load(page: _page + 1) : null,
        ),
      ]),
    );
  }

  Widget _buildTable() {
    if (_stores.isEmpty) return ReportHelpers.emptyState('No stores found');
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
              DataColumn(label: Text('Store')),
              DataColumn(label: Text('Owner')),
              DataColumn(label: Text('Joined')),
              DataColumn(label: Text('Revenue (ILS)'), numeric: true),
              DataColumn(label: Text('Orders'), numeric: true),
              DataColumn(label: Text('Products'), numeric: true),
              DataColumn(label: Text('Rating'), numeric: true),
              DataColumn(label: Text('Approved')),
            ],
            rows: _stores.map((s) {
              final rev = (s['revenue'] ?? 0.0);
              final approved = s['isApproved'] == true;
              return DataRow(cells: [
                DataCell(Text(s['storeName'] ?? '', style: ReportHelpers.cellStyle(bold: true))),
                DataCell(Text(s['owner'] ?? '—')),
                DataCell(Text(ReportHelpers.fmtDisplay(s['createdAt']))),
                DataCell(Text(rev is num ? rev.toStringAsFixed(0) : '$rev')),
                DataCell(Text('${s['ordersCount'] ?? 0}')),
                DataCell(Text('${s['productsCount'] ?? 0}')),
                DataCell(Text(s['rating'] != null ? (s['rating'] as num).toStringAsFixed(1) : '—')),
                DataCell(ReportHelpers.statusBadge(
                  approved ? 'Yes' : 'No',
                  approved ? Colors.green.shade600 : Colors.orange.shade600,
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
