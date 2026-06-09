import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';
import '_report_helpers.dart';

class AdminReportCustomScreen extends StatefulWidget {
  final String adminId;
  const AdminReportCustomScreen({super.key, required this.adminId});
  @override
  State<AdminReportCustomScreen> createState() => _State();
}

class _State extends State<AdminReportCustomScreen> {
  int _step = 0;

  // Step 1
  String _entity = 'users';

  // Step 2 - available columns per entity
  static const Map<String, List<Map<String, String>>> _allCols = {
    'users': [
      {'key': 'fullName', 'label': 'Name'},
      {'key': 'email', 'label': 'Email'},
      {'key': 'phone', 'label': 'Phone'},
      {'key': 'createdAt', 'label': 'Join Date'},
      {'key': 'city', 'label': 'City'},
      {'key': 'isActive', 'label': 'Status'},
    ],
    'stores': [
      {'key': 'storeName', 'label': 'Store Name'},
      {'key': 'city', 'label': 'City'},
      {'key': 'rating', 'label': 'Rating'},
      {'key': 'isApproved', 'label': 'Approved'},
      {'key': 'createdAt', 'label': 'Join Date'},
    ],
    'orders': [
      {'key': 'fullName', 'label': 'Customer'},
      {'key': 'total', 'label': 'Total'},
      {'key': 'status', 'label': 'Status'},
      {'key': 'paymentMethod', 'label': 'Payment'},
      {'key': 'createdAt', 'label': 'Date'},
    ],
    'products': [
      {'key': 'name', 'label': 'Name'},
      {'key': 'brand', 'label': 'Brand'},
      {'key': 'rating', 'label': 'Rating'},
      {'key': 'isPublished', 'label': 'Published'},
      {'key': 'createdAt', 'label': 'Date'},
    ],
  };

  List<String> _selectedCols = [];

  // Step 3
  String _filterStatus = '';
  String _filterSearch = '';
  DateTimeRange? _dateRange;
  final _searchCtrl = TextEditingController();

  // Step 4
  String _sortField = 'createdAt';
  String _sortOrder = 'desc';

  // Step 5
  bool _loading = false;
  bool _generated = false;
  List _data = [];
  int _total = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _cols => _allCols[_entity] ?? [];

  void _toggleCol(String key) {
    setState(() {
      if (_selectedCols.contains(key)) {
        _selectedCols.remove(key);
      } else {
        _selectedCols.add(key);
      }
    });
  }

  Future<void> _generate() async {
    if (_selectedCols.isEmpty) {
      ReportHelpers.snack(context, 'Please select at least one column');
      return;
    }
    setState(() { _loading = true; _generated = false; });
    try {
      final body = {
        'entity': _entity,
        'columns': _selectedCols,
        'filters': {
          if (_filterStatus.isNotEmpty) 'status': _filterStatus,
          if (_filterSearch.isNotEmpty) 'search': _filterSearch,
          if (_dateRange != null) 'from': ReportHelpers.fmtDate(_dateRange!.start),
          if (_dateRange != null) 'to': ReportHelpers.fmtDate(_dateRange!.end),
        },
        'sortField': _sortField,
        'sortOrder': _sortOrder,
        'page': 1,
        'limit': 100,
      };
      final r = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/admin/reports/custom'),
        headers: {
          'x-admin-id': widget.adminId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      final decoded = jsonDecode(r.body);
      if (mounted) setState(() {
        _data  = List.from(decoded['data'] ?? []);
        _total = decoded['total'] ?? 0;
        _generated = true;
        _step  = 4;
      });
    } catch (_) {
      if (mounted) ReportHelpers.snack(context, 'Failed to generate report');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _exportCsv() async {
    if (_data.isEmpty) return;
    try {
      final rows = _data.map((row) {
        return _selectedCols.map((k) {
          final v = row[k];
          return '"${v?.toString().replaceAll('"', '""') ?? ''}"';
        }).join(',');
      }).toList();
      final header = _selectedCols.map((k) {
        return _cols.firstWhere((c) => c['key'] == k, orElse: () => {'label': k})['label'] ?? k;
      }).map((l) => '"$l"').join(',');
      final csv = '$header\n${rows.join('\n')}';
      final file = File('${Directory.systemTemp.path}/custom_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Custom Report');
    } catch (_) {
      if (mounted) ReportHelpers.snack(context, 'Export failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: ReportHelpers.appBar(context, 'Custom Report Builder'),
      body: Column(children: [
        _buildStepIndicator(),
        Expanded(
          child: _generated && _step == 4
              ? _buildResults()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    if (_step == 0) _buildStep1(),
                    if (_step == 1) _buildStep2(),
                    if (_step == 2) _buildStep3(),
                    if (_step == 3) _buildStep4(),
                  ]),
                ),
        ),
        _buildNavButtons(),
      ]),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Entity', 'Columns', 'Filters', 'Sort', 'Results'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final active = _step >= e.key;
          final current = _step == e.key || (_step == 4 && e.key == 4);
          return Expanded(
            child: Row(children: [
              Expanded(child: Column(children: [
                Container(
                  width: 28, height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? AdminTheme.wine : AdminTheme.soft,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: active ? AdminTheme.wine : AdminTheme.line),
                  ),
                  child: Text('${e.key + 1}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AdminTheme.grey)),
                ),
                const SizedBox(height: 4),
                Text(e.value,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                        color: active ? AdminTheme.wine : AdminTheme.grey)),
              ])),
              if (e.key < steps.length - 1)
                Container(height: 1, width: 20, color: AdminTheme.line),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep1() {
    const entities = {
      'users': ('Users', Icons.people_outline_rounded),
      'stores': ('Stores', Icons.store_outlined),
      'orders': ('Orders', Icons.receipt_long_outlined),
      'products': ('Products', Icons.inventory_2_outlined),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Choose Entity', style: AdminTheme.title(15, w: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Select the data source for your report.', style: AdminTheme.sub(13)),
      const SizedBox(height: 20),
      Wrap(
        spacing: 12, runSpacing: 12,
        children: entities.entries.map((e) {
          final sel = _entity == e.key;
          return GestureDetector(
            onTap: () => setState(() {
              _entity = e.key;
              _selectedCols = [];
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 150, height: 100,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sel ? AdminTheme.wine : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? AdminTheme.wine : AdminTheme.line),
                boxShadow: sel ? [BoxShadow(color: AdminTheme.wine.withOpacity(0.15),
                    blurRadius: 10, offset: const Offset(0, 4))] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(e.value.$2, size: 28,
                      color: sel ? Colors.white : AdminTheme.wine),
                  const SizedBox(height: 8),
                  Text(e.value.$1,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w500,
                          color: sel ? Colors.white : AdminTheme.black)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Choose Columns', style: AdminTheme.title(15, w: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Select which columns to include in the report.', style: AdminTheme.sub(13)),
      const SizedBox(height: 20),
      Container(
        decoration: AdminTheme.cardDec(),
        child: Column(
          children: _cols.map((col) {
            final sel = _selectedCols.contains(col['key']!);
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              leading: Checkbox(
                value: sel,
                onChanged: (_) => _toggleCol(col['key']!),
                activeColor: AdminTheme.wine,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              title: Text(col['label']!,
                  style: ReportHelpers.cellStyle(bold: sel)),
              onTap: () => _toggleCol(col['key']!),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        GestureDetector(
          onTap: () => setState(() => _selectedCols = _cols.map((c) => c['key']!).toList()),
          child: Text('Select All',
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: AdminTheme.wine,
                  decoration: TextDecoration.underline)),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => setState(() => _selectedCols = []),
          child: Text('Clear',
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: AdminTheme.grey,
                  decoration: TextDecoration.underline)),
        ),
      ]),
    ]);
  }

  Widget _buildStep3() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Choose Filters', style: AdminTheme.title(15, w: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Narrow down the data with optional filters.', style: AdminTheme.sub(13)),
      const SizedBox(height: 20),
      _labeledSection('Date Range', GestureDetector(
        onTap: () async {
          final r = await showDateRangePicker(context: context,
            firstDate: DateTime(2024), lastDate: DateTime.now(),
            builder: ReportHelpers.datePickerTheme);
          if (r != null) setState(() => _dateRange = r);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _dateRange != null ? AdminTheme.wineMuted : AdminTheme.soft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _dateRange != null ? AdminTheme.wine : AdminTheme.line),
          ),
          child: Row(children: [
            Icon(Icons.date_range_rounded, size: 16,
                color: _dateRange != null ? AdminTheme.wine : AdminTheme.grey),
            const SizedBox(width: 8),
            Text(_dateRange != null
                ? '${ReportHelpers.fmtDisplay(_dateRange!.start.toIso8601String())} – ${ReportHelpers.fmtDisplay(_dateRange!.end.toIso8601String())}'
                : 'Pick date range',
                style: AdminTheme.sub(13)),
          ]),
        ),
      )),
      const SizedBox(height: 14),
      _labeledSection('Search', SizedBox(
        height: 42,
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => _filterSearch = v,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search by name, email…',
            hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: AdminTheme.grey),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AdminTheme.grey),
            filled: true, fillColor: AdminTheme.soft,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
      )),
      const SizedBox(height: 14),
      _labeledSection('Status', Wrap(
        spacing: 8,
        children: [
          for (final s in ['', 'active', 'inactive', 'pending', 'delivered', 'cancelled'])
            GestureDetector(
              onTap: () => setState(() => _filterStatus = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _filterStatus == s ? AdminTheme.wine : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _filterStatus == s ? AdminTheme.wine : AdminTheme.line),
                ),
                child: Text(s.isEmpty ? 'All' : s,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _filterStatus == s ? Colors.white : AdminTheme.black)),
              ),
            ),
        ],
      )),
    ]);
  }

  Widget _buildStep4() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Sorting', style: AdminTheme.title(15, w: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Choose how to sort the report results.', style: AdminTheme.sub(13)),
      const SizedBox(height: 20),
      _labeledSection('Sort Field', ReportHelpers.sortDropdown(
        value: _sortField,
        options: Map.fromEntries(
          (_allCols[_entity] ?? []).map((c) => MapEntry(c['key']!, c['label']!)),
        ),
        onChanged: (v) => setState(() => _sortField = v ?? 'createdAt'),
      )),
      const SizedBox(height: 14),
      _labeledSection('Sort Order', Row(children: [
        for (final o in [('asc', 'Ascending', Icons.arrow_upward_rounded),
                         ('desc', 'Descending', Icons.arrow_downward_rounded)])
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _sortOrder = o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _sortOrder == o.$1 ? AdminTheme.wine : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _sortOrder == o.$1 ? AdminTheme.wine : AdminTheme.line),
                ),
                child: Row(children: [
                  Icon(o.$3, size: 15,
                      color: _sortOrder == o.$1 ? Colors.white : AdminTheme.grey),
                  const SizedBox(width: 6),
                  Text(o.$2,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _sortOrder == o.$1 ? Colors.white : AdminTheme.black,
                          fontWeight: _sortOrder == o.$1 ? FontWeight.w600 : FontWeight.w400)),
                ]),
              ),
            ),
          ),
      ])),
    ]);
  }

  Widget _buildResults() {
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Text('$_total results',
              style: AdminTheme.sub(12)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() { _generated = false; _step = 0; }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AdminTheme.soft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminTheme.line),
              ),
              child: Text('New Report', style: AdminTheme.sub(12)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _exportCsv,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AdminTheme.wineMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminTheme.wine.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.download_rounded, size: 13, color: AdminTheme.wine),
                const SizedBox(width: 5),
                Text('Export CSV',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AdminTheme.wine,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ]),
      ),
      Expanded(
        child: _data.isEmpty
            ? ReportHelpers.emptyState('No data matches your filters')
            : SingleChildScrollView(
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
                      columns: _selectedCols.map((key) {
                        final label = _cols.firstWhere(
                          (c) => c['key'] == key, orElse: () => {'label': key})['label'] ?? key;
                        return DataColumn(label: Text(label));
                      }).toList(),
                      rows: _data.map((row) {
                        return DataRow(
                          cells: _selectedCols.map((key) {
                            final v = row[key];
                            String display;
                            if (v == null) {
                              display = '—';
                            } else if (v is bool) {
                              display = v ? 'Yes' : 'No';
                            } else if (key.contains('At') || key.contains('Time')) {
                              display = ReportHelpers.fmtDisplay(v.toString());
                            } else {
                              display = v.toString();
                            }
                            return DataCell(Text(display));
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
      ),
    ]);
  }

  Widget _buildNavButtons() {
    if (_generated && _step == 4) return const SizedBox();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Row(children: [
        if (_step > 0)
          OutlinedButton(
            onPressed: () => setState(() => _step--),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminTheme.wine,
              side: const BorderSide(color: AdminTheme.wine),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Back', style: GoogleFonts.poppins(fontSize: 13)),
          ),
        const Spacer(),
        if (_step < 3)
          ElevatedButton(
            onPressed: () => setState(() => _step++),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.wine,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Next', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        if (_step == 3)
          ElevatedButton.icon(
            onPressed: _loading ? null : _generate,
            icon: _loading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text('Generate Report',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.wine,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
      ]),
    );
  }

  Widget _labeledSection(String label, Widget child) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AdminTheme.grey)),
      const SizedBox(height: 6),
      child,
    ]);
  }
}
