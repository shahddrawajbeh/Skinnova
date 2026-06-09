import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import '_report_helpers.dart';

class AdminReportProductsScreen extends StatefulWidget {
  final String adminId;
  const AdminReportProductsScreen({super.key, required this.adminId});
  @override
  State<AdminReportProductsScreen> createState() => _State();
}

class _State extends State<AdminReportProductsScreen> {
  bool _loading = true;
  List _products = [];
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
      final data = await ApiService.adminReportProducts(
        widget.adminId, filter: _filter, search: _search,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
        page: page,
      );
      if (mounted) setState(() {
        _products = List.from(data['products'] ?? []);
        _total    = data['total'] ?? 0;
      });
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Failed to load'); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _exportCsv() async {
    try {
      ReportHelpers.snack(context, 'Generating CSV…');
      final csv = await ApiService.adminReportExportCsv(
        widget.adminId, 'products', filter: _filter, search: _search,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
      );
      final file = File('${Directory.systemTemp.path}/product_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Product Report');
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Export failed'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: ReportHelpers.appBar(context, 'Product Report'),
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
            options: {
              'all': 'All', 'bestSelling': 'Best Selling',
              'leastSelling': 'Least Selling',
              'highestRated': 'Highest Rated', 'lowestRated': 'Lowest Rated',
            },
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
    if (_products.isEmpty) return ReportHelpers.emptyState('No products found');
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
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Brand')),
              DataColumn(label: Text('Stores'), numeric: true),
              DataColumn(label: Text('Sold'), numeric: true),
              DataColumn(label: Text('Stock'), numeric: true),
              DataColumn(label: Text('Rating'), numeric: true),
              DataColumn(label: Text('Revenue (ILS)'), numeric: true),
            ],
            rows: _products.map((p) {
              final rev = (p['revenue'] ?? 0.0) as num;
              final rating = p['rating'];
              return DataRow(cells: [
                DataCell(Text(p['name'] ?? '—', style: ReportHelpers.cellStyle(bold: true))),
                DataCell(Text(p['brand'] ?? '—')),
                DataCell(Text('${p['storeCount'] ?? 0}')),
                DataCell(Text('${p['totalSold'] ?? 0}')),
                DataCell(Text('${p['totalStock'] ?? 0}')),
                DataCell(Text(rating != null ? (rating as num).toStringAsFixed(1) : '—')),
                DataCell(Text(rev.toStringAsFixed(0))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
