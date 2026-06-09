import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import '_report_helpers.dart';

class AdminReportOrdersScreen extends StatefulWidget {
  final String adminId;
  const AdminReportOrdersScreen({super.key, required this.adminId});
  @override
  State<AdminReportOrdersScreen> createState() => _State();
}

class _State extends State<AdminReportOrdersScreen> {
  bool _loading = true;
  List _orders = [];
  Map<String, dynamic> _summary = {};
  int _total = 0;
  int _page = 1;
  String _status = '';
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
      final data = await ApiService.adminReportOrders(
        widget.adminId, status: _status, search: _search,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
        page: page,
      );
      if (mounted) setState(() {
        _orders  = List.from(data['orders'] ?? []);
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
        widget.adminId, 'orders', status: _status, search: _search,
        from: _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.start) : null,
        to:   _dateRange != null ? ReportHelpers.fmtDate(_dateRange!.end)   : null,
      );
      final file = File('${Directory.systemTemp.path}/order_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Order Report');
    } catch (_) { if (mounted) ReportHelpers.snack(context, 'Export failed'); }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'delivered': return Colors.green.shade600;
      case 'cancelled': return Colors.red.shade400;
      case 'pending':   return Colors.orange.shade600;
      case 'processing': return Colors.blue.shade500;
      case 'out_for_delivery': return Colors.teal.shade500;
      default: return AdminTheme.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: ReportHelpers.appBar(context, 'Order Report'),
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
              '': 'All', 'pending': 'Pending', 'processing': 'Processing',
              'out_for_delivery': 'On the Way', 'delivered': 'Delivered',
              'cancelled': 'Cancelled',
            },
            selected: _status,
            onSelect: (v) { _status = v; _load(); },
          ),
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
    final avg = (_summary['avgOrderValue'] ?? 0.0) as num;
    final rev = (_summary['totalRevenue'] ?? 0.0) as num;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        ReportHelpers.summaryCard('Total', '${_summary['totalOrders'] ?? 0}'),
        const SizedBox(width: 10),
        ReportHelpers.summaryCard('Delivered', '${_summary['delivered'] ?? 0}', color: Colors.green.shade600),
        const SizedBox(width: 10),
        ReportHelpers.summaryCard('Cancelled', '${_summary['cancelled'] ?? 0}', color: Colors.red.shade400),
        const SizedBox(width: 10),
        ReportHelpers.summaryCard('Avg Value', 'ILS ${avg.toStringAsFixed(0)}'),
        const SizedBox(width: 10),
        ReportHelpers.summaryCard('Revenue', 'ILS ${rev.toStringAsFixed(0)}', color: AdminTheme.wine),
      ]),
    );
  }

  Widget _buildTable() {
    if (_orders.isEmpty) return ReportHelpers.emptyState('No orders found');
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
              DataColumn(label: Text('Order ID')),
              DataColumn(label: Text('Customer')),
              DataColumn(label: Text('Store')),
              DataColumn(label: Text('Items'), numeric: true),
              DataColumn(label: Text('Total (ILS)'), numeric: true),
              DataColumn(label: Text('Payment')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Date')),
            ],
            rows: _orders.map((o) {
              final id = (o['_id'] ?? '').toString();
              final shortId = id.length >= 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();
              final customer = (o['userId'] is Map ? o['userId']['fullName'] : o['fullName']) ?? '—';
              final store = (o['storeId'] is Map ? o['storeId']['storeName'] : '—') ?? '—';
              final items = (o['items'] as List?)?.length ?? 0;
              final total = (o['total'] ?? 0.0) as num;
              final status = o['status'] ?? '';
              final payment = o['paymentMethod'] ?? '—';
              return DataRow(cells: [
                DataCell(Text('#$shortId', style: ReportHelpers.cellStyle(bold: true))),
                DataCell(Text(customer)),
                DataCell(Text(store)),
                DataCell(Text('$items')),
                DataCell(Text(total.toStringAsFixed(0))),
                DataCell(Text(payment.toString().replaceAll('_', ' '))),
                DataCell(ReportHelpers.statusBadge(status, _statusColor(status))),
                DataCell(Text(ReportHelpers.fmtDisplay(o['createdAt']))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
