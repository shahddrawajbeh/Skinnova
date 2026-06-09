import 'package:flutter/material.dart';
import '../models/skin_scan_history_model.dart';
import '../services/skin_scan_api_service.dart';
import '../widgets/skinova_theme.dart';
import 'skin_scan_details_screen.dart';

class SkinScanHistoryScreen extends StatefulWidget {
  final String userId;
  const SkinScanHistoryScreen({super.key, required this.userId});

  @override
  State<SkinScanHistoryScreen> createState() => _SkinScanHistoryScreenState();
}

class _SkinScanHistoryScreenState extends State<SkinScanHistoryScreen> {
  List<SkinScanModel> _scans = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final scans = await SkinScanApiService.getHistory(widget.userId);
      if (!mounted) return;
      setState(() {
        _scans = scans;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteScan(String scanId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: SkiNova.radiusLarge),
        title: Text('Delete Scan', style: SkiNova.heading3()),
        content:
            Text('Remove this scan from your history?', style: SkiNova.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: SkiNova.body(color: SkiNova.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Delete', style: SkiNova.body(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await SkinScanApiService.deleteScan(scanId);
    if (ok && mounted) {
      setState(() => _scans.removeWhere((s) => s.id == scanId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkiNova.offWhite,
      appBar: AppBar(
        backgroundColor: SkiNova.wine,
        foregroundColor: Colors.white,
        elevation: 0,
        title:
            Text('Scan History', style: SkiNova.heading3(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: SkiNova.wine));
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_scans.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: SkiNova.wine,
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        itemCount: _scans.length,
        itemBuilder: (_, i) => _ScanCard(
          scan: _scans[i],
          onViewDetails: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SkinScanDetailsScreen(scan: _scans[i]),
            ),
          ),
          onDelete: () => _deleteScan(_scans[i].id),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: SkiNova.wineMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.face_retouching_natural_rounded,
                  size: 36, color: SkiNova.wine),
            ),
            const SizedBox(height: 20),
            Text('No skin scans yet.',
                style: SkiNova.heading2(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Start your first AI skin analysis.',
              style: SkiNova.body(color: SkiNova.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SkiNova.wine,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                    borderRadius: SkiNova.radiusMedium),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: SkiNova.textSecondary),
            const SizedBox(height: 16),
            Text('Could not load scan history.',
                style: SkiNova.heading3(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Check your connection and try again.',
                style: SkiNova.body(color: SkiNova.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: SkiNova.wine,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                    borderRadius: SkiNova.radiusMedium),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan Card ─────────────────────────────────────────────────────────────────

class _ScanCard extends StatelessWidget {
  final SkinScanModel scan;
  final VoidCallback onViewDetails;
  final VoidCallback onDelete;

  const _ScanCard({
    required this.scan,
    required this.onViewDetails,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SkiNova.surface,
        borderRadius: SkiNova.radiusLarge,
        boxShadow: SkiNova.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + status header
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: _ScanImage(imageUrl: scan.imageUrl, height: 160),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _StatusBadge(status: scan.overallStatus),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: SkiNova.radiusCircle,
                  ),
                  child: Text(
                    _formatDate(scan.createdAt),
                    style: SkiNova.caption(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.troubleshoot_rounded,
                        size: 16, color: SkiNova.wine),
                    const SizedBox(width: 6),
                    Text(
                      '${scan.concernCount} concern${scan.concernCount == 1 ? '' : 's'} detected',
                      style:
                          SkiNova.body().copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (scan.topConcerns.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: scan.topConcerns.map((c) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: SkiNova.wineMuted,
                          borderRadius: SkiNova.radiusCircle,
                        ),
                        child: Text(c.name,
                            style: SkiNova.label(color: SkiNova.wine)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onViewDetails,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        gradient: SkiNova.wineGradient,
                        borderRadius: SkiNova.radiusMedium,
                      ),
                      child: Center(
                        child: Text('View Details',
                            style: SkiNova.body(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: SkiNova.radiusMedium,
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 18, color: Colors.red.shade400),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    final s = status.toLowerCase();
    if (s == 'good') return SkiNova.statusGood;
    if (s == 'moderate') return SkiNova.statusModerate;
    return SkiNova.statusNeedsCare;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: SkiNova.radiusCircle,
      ),
      child: Text(
        status.isEmpty ? 'Unknown' : status,
        style: SkiNova.label(color: Colors.white),
      ),
    );
  }
}

class _ScanImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  const _ScanImage({required this.imageUrl, required this.height});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        color: SkiNova.wineMuted,
        child: const Icon(Icons.face_retouching_natural_rounded,
            size: 48, color: SkiNova.wine),
      );
    }

    final fullUrl =
        imageUrl.startsWith('http') ? imageUrl : '${_baseUrl()}$imageUrl';

    return Image.network(
      fullUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: double.infinity,
        color: SkiNova.wineMuted,
        child: const Icon(Icons.face_retouching_natural_rounded,
            size: 48, color: SkiNova.wine),
      ),
    );
  }

  String _baseUrl() {
    // Matches ApiService.baseUrl without importing it here
    return 'http://10.0.2.2:5000';
  }
}
