import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'admin_dashboard.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool _loading = true;
  String? _error;
  String _adminId = '';
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _adminId = prefs.getString('userId') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.adminGetAnalyticsCharts(_adminId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AdminTheme.wine,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildContent(),
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    if (_loading) {
      return [
        const SizedBox(height: 100),
        const Center(child: CircularProgressIndicator(color: AdminTheme.wine)),
      ];
    }

    if (_error != null) {
      return [
        const SizedBox(height: 100),
        Center(
          child: Column(children: [
            const Icon(Icons.error_outline_rounded,
                color: AdminTheme.wine, size: 48),
            const SizedBox(height: 12),
            Text("Failed to load analytics", style: AdminTheme.title(15)),
            const SizedBox(height: 6),
            Text("Pull down to retry", style: AdminTheme.sub(12)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              child: Text("Retry",
                  style: GoogleFonts.poppins(
                      color: AdminTheme.wine, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ];
    }

    final revenue = (_data['monthlyRevenue'] as List?)?.cast<Map>() ?? [];
    final orders = (_data['monthlyOrders'] as List?)?.cast<Map>() ?? [];
    final products = (_data['bestSellingProducts'] as List?)?.cast<Map>() ?? [];
    final users = (_data['monthlyUsers'] as List?)?.cast<Map>() ?? [];
    final stores = (_data['storeSales'] as List?)?.cast<Map>() ?? [];

    return [
      Text("Analytics Overview", style: AdminTheme.title(22)),
      const SizedBox(height: 4),
      Text("Business insights for ${DateTime.now().year}",
          style: AdminTheme.sub(13)),
      const SizedBox(height: 28),

      // Monthly Revenue
      _ChartCard(
        title: "Monthly Revenue",
        subtitle: "Revenue from delivered orders",
        badge: _formatCurrencyTotal(revenue),
        child: _buildLineChart(revenue, AdminTheme.wine, isCurrency: true),
      ),
      const SizedBox(height: 16),

      // Monthly Orders
      _ChartCard(
        title: "Monthly Orders",
        subtitle: "All orders placed each month",
        badge: "${_sumValues(orders).toInt()} total",
        child: _buildBarChart(orders, const Color(0xFF3D7CB5)),
      ),
      const SizedBox(height: 16),

      // Best-Selling Products
      _ChartCard(
        title: "Best-Selling Products",
        subtitle: "Ranked by total quantity sold",
        badge: "${products.length} products",
        child: _buildHorizontalBars(products, AdminTheme.wine),
      ),
      const SizedBox(height: 16),

      // Monthly New Users
      _ChartCard(
        title: "New Users Per Month",
        subtitle: "User registrations this year",
        badge: "${_sumValues(users).toInt()} new users",
        child: _buildLineChart(users, const Color(0xFF2E7D52)),
      ),
      const SizedBox(height: 16),

      // Store Sales Comparison
      _ChartCard(
        title: "Store Sales Comparison",
        subtitle: "Total revenue per store (all time)",
        badge: "${stores.length} stores",
        child: _buildHorizontalBars(stores, const Color(0xFF3D7CB5),
            isCurrency: true),
      ),
      const SizedBox(height: 8),
    ];
  }

  // ── Helper: sum values ──────────────────────────────────────────────────────

  double _sumValues(List<Map> data) => data.fold(
      0.0, (sum, item) => sum + ((item['value'] as num?)?.toDouble() ?? 0));

  String _formatCurrencyTotal(List<Map> data) {
    final total = _sumValues(data);
    if (total >= 1000000) {
      return "₪${(total / 1000000).toStringAsFixed(1)}M";
    } else if (total >= 1000) {
      return "₪${(total / 1000).toStringAsFixed(1)}K";
    }
    return "₪${total.toStringAsFixed(0)}";
  }

  // ── Line Chart ──────────────────────────────────────────────────────────────

  Widget _buildLineChart(List<Map> data, Color color,
      {bool isCurrency = false}) {
    if (data.isEmpty) return _emptyChart();

    final spots = data.asMap().entries.map((e) {
      final y = (e.value['value'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), y);
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final chartMax = maxY > 0 ? maxY * 1.25 : 5.0;
    final interval = chartMax / 4;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 11,
          minY: 0,
          maxY: chartMax,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.08),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  const labels = [
                    "J",
                    "F",
                    "M",
                    "A",
                    "M",
                    "J",
                    "J",
                    "A",
                    "S",
                    "O",
                    "N",
                    "D"
                  ];
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(labels[idx],
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: AdminTheme.grey)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  final label = isCurrency
                      ? (value >= 1000
                          ? "₪${(value / 1000).toStringAsFixed(0)}K"
                          : "₪${value.toStringAsFixed(0)}")
                      : value.toInt().toString();
                  return Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 9, color: AdminTheme.grey));
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AdminTheme.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // ── Bar Chart ───────────────────────────────────────────────────────────────

  Widget _buildBarChart(List<Map> data, Color color) {
    if (data.isEmpty) return _emptyChart();

    final maxY = data
        .map((e) => (e['value'] as num?)?.toDouble() ?? 0)
        .reduce((a, b) => a > b ? a : b);
    final chartMax = maxY > 0 ? maxY * 1.25 : 5.0;
    final interval = chartMax / 4;

    final barGroups = data.asMap().entries.map((e) {
      final value = (e.value['value'] as num?)?.toDouble() ?? 0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: value,
            color: color,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: chartMax,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = [
                    "J",
                    "F",
                    "M",
                    "A",
                    "M",
                    "J",
                    "J",
                    "A",
                    "S",
                    "O",
                    "N",
                    "D"
                  ];
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(labels[idx],
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: AdminTheme.grey)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(value.toInt().toString(),
                      style: GoogleFonts.poppins(
                          fontSize: 9, color: AdminTheme.grey));
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AdminTheme.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
        ),
      ),
    );
  }

  // ── Horizontal Progress Bars ────────────────────────────────────────────────

  Widget _buildHorizontalBars(List<Map> data, Color color,
      {bool isCurrency = false}) {
    if (data.isEmpty) return _emptyChart();

    final maxVal = data
        .map((e) => (e['value'] as num?)?.toDouble() ?? 0)
        .reduce((a, b) => a > b ? a : b);

    if (maxVal == 0) return _emptyChart();

    return Column(
      children: data.map((item) {
        final name = (item['name'] ?? '').toString();
        final value = (item['value'] as num?)?.toDouble() ?? 0;
        final ratio = (value / maxVal).clamp(0.0, 1.0);
        final displayValue = isCurrency
            ? (value >= 1000
                ? "₪${(value / 1000).toStringAsFixed(1)}K"
                : "₪${value.toStringAsFixed(0)}")
            : value.toInt().toString();
        final displayName =
            name.length > 14 ? '${name.substring(0, 14)}…' : name;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  displayName,
                  style: GoogleFonts.poppins(
                      fontSize: 11.5, color: AdminTheme.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 9,
                    backgroundColor: AdminTheme.line,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 60,
                child: Text(
                  displayValue,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.black),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _emptyChart() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Column(children: [
            Icon(Icons.bar_chart_outlined,
                size: 32, color: AdminTheme.grey.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text("No data available yet", style: AdminTheme.sub(12.5)),
          ]),
        ),
      );
}

// ── Reusable Chart Card ───────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AdminTheme.cardDec(shadow: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AdminTheme.title(14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AdminTheme.sub(11.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminTheme.wineMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AdminTheme.wine,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
