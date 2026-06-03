import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

class ProductUsageReminderScreen extends StatefulWidget {
  final String userId;
  final String productId;
  final String productName;
  final String brand;
  final String imageUrl;
  final String directionsOfUse;
  final String? existingReminderId;
  final List<Map<String, dynamic>>? existingTimes;
  final String? existingFrequencyType;
  final bool existingIsActive;

  const ProductUsageReminderScreen({
    super.key,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.brand,
    required this.imageUrl,
    required this.directionsOfUse,
    this.existingReminderId,
    this.existingTimes,
    this.existingFrequencyType,
    this.existingIsActive = true,
  });

  @override
  State<ProductUsageReminderScreen> createState() =>
      _ProductUsageReminderScreenState();
}

class _ProductUsageReminderScreenState
    extends State<ProductUsageReminderScreen> {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color wine = Color(0xFF5B2333);
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color darkText = Color(0xFF202124);
  static const Color grey = Color(0xFF7A7A7A);
  static const Color line = Color(0xFFEEECE9);

  bool _saving = false;
  late List<_TimeSlot> _slots;

  static const List<String> _dayNames = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];

  @override
  void initState() {
    super.initState();
    _slots = _buildInitialSlots();
  }

  // ── Build initial slots from existing data or suggestion ──────────────────

  List<_TimeSlot> _buildInitialSlots() {
    if (widget.existingTimes != null && widget.existingTimes!.isNotEmpty) {
      return widget.existingTimes!.map((t) {
        final parts = (t['time'] ?? '08:00').toString().split(':');
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        return _TimeSlot(
          time: TimeOfDay(hour: hour, minute: minute),
          dayOfWeek: t['dayOfWeek'] as int?,
          enabled: t['enabled'] != false,
        );
      }).toList();
    }
    return _suggestSlots(widget.directionsOfUse);
  }

  List<_TimeSlot> _suggestSlots(String text) {
    final lower = text.toLowerCase();

    // Every 2 hours
    if (lower.contains('every 2 hour') ||
        lower.contains('every two hour') ||
        lower.contains('reapply every 2') ||
        lower.contains('every 2-3 hour')) {
      return [
        _TimeSlot(time: const TimeOfDay(hour: 9, minute: 0)),
        _TimeSlot(time: const TimeOfDay(hour: 11, minute: 0)),
        _TimeSlot(time: const TimeOfDay(hour: 13, minute: 0)),
        _TimeSlot(time: const TimeOfDay(hour: 15, minute: 0)),
      ];
    }

    // Twice daily / Morning and evening
    if (lower.contains('twice daily') ||
        lower.contains('two times daily') ||
        lower.contains('twice a day') ||
        lower.contains('2 times daily') ||
        lower.contains('morning and evening') ||
        lower.contains('morning and night')) {
      return [
        _TimeSlot(time: const TimeOfDay(hour: 8, minute: 0)),
        _TimeSlot(time: const TimeOfDay(hour: 20, minute: 0)),
      ];
    }

    // Morning + night/evening combo
    if ((lower.contains('morning') &&
        (lower.contains('night') || lower.contains('evening')))) {
      return [
        _TimeSlot(time: const TimeOfDay(hour: 8, minute: 0)),
        _TimeSlot(time: const TimeOfDay(hour: 21, minute: 0)),
      ];
    }

    // Morning only
    if (lower.contains('morning') ||
        lower.contains(' am ') ||
        lower.contains('every morning')) {
      return [_TimeSlot(time: const TimeOfDay(hour: 8, minute: 0))];
    }

    // Night / Evening only
    if (lower.contains('night') ||
        lower.contains('nightly') ||
        lower.contains('before bed') ||
        lower.contains('bedtime') ||
        lower.contains('evening')) {
      return [_TimeSlot(time: const TimeOfDay(hour: 21, minute: 0))];
    }

    // Weekly patterns
    if (lower.contains('per week') ||
        lower.contains('a week') ||
        lower.contains('weekly') ||
        lower.contains('2-3 times') ||
        lower.contains('twice a week') ||
        lower.contains('3 times a week')) {
      return [
        _TimeSlot(
            time: const TimeOfDay(hour: 20, minute: 0), dayOfWeek: 1), // Mon
        _TimeSlot(
            time: const TimeOfDay(hour: 20, minute: 0), dayOfWeek: 3), // Wed
        _TimeSlot(
            time: const TimeOfDay(hour: 20, minute: 0), dayOfWeek: 5), // Fri
      ];
    }

    // Once daily / daily
    if (lower.contains('once daily') ||
        lower.contains('daily') ||
        lower.contains('once a day') ||
        lower.contains('every day')) {
      return [_TimeSlot(time: const TimeOfDay(hour: 8, minute: 0))];
    }

    // Default
    return [_TimeSlot(time: const TimeOfDay(hour: 8, minute: 0))];
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _scheduleLabel() {
    if (_slots.isEmpty) return 'No times set';
    final hasWeekly = _slots.any((s) => s.dayOfWeek != null);
    if (hasWeekly) {
      return _slots
          .map((s) =>
              '${s.dayOfWeek != null ? _dayNames[s.dayOfWeek!] : 'Daily'} ${_fmt12h(s.time)}')
          .join(', ');
    }
    return _slots.map((s) => _fmt12h(s.time)).join(' & ');
  }

  String _fmt12h(TimeOfDay t) {
    final period = t.hour < 12 ? 'AM' : 'PM';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  String _inferFrequencyType() {
    final hasWeekly = _slots.any((s) => s.dayOfWeek != null);
    if (hasWeekly) return 'weekly';
    if (_slots.length == 2) return 'twice_daily';
    if (_slots.length == 1) return 'daily';
    return 'custom';
  }

  // ── Time picker ───────────────────────────────────────────────────────────

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _slots[index].time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: wine,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: darkText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _slots[index] = _slots[index].copyWith(time: picked));
    }
  }

  // ── Day picker ────────────────────────────────────────────────────────────

  Future<void> _pickDay(int index) async {
    final current = _slots[index].dayOfWeek;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                      color: line, borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 16),
            Text('Select day',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: darkText)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _dayChipOption(null, 'Every Day', current, index),
                for (int d = 0; d < 7; d++)
                  _dayChipOption(d, _dayNames[d], current, index),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayChipOption(
      int? value, String label, int? currentDay, int slotIndex) {
    final selected = value == currentDay;
    return GestureDetector(
      onTap: () {
        setState(() => _slots[slotIndex] = _slots[slotIndex]
            .copyWith(dayOfWeek: value, clearDay: value == null));
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? wine : whiteSmoke,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? wine : line),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : darkText)),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_slots.isEmpty) {
      _showSnack('Add at least one reminder time.');
      return;
    }

    setState(() => _saving = true);

    final times = _slots
        .map((s) => {
              'time': _formatTime(s.time),
              'dayOfWeek': s.dayOfWeek,
              'enabled': s.enabled,
            })
        .toList();

    final payload = {
      'userId': widget.userId,
      'productId': widget.productId,
      'productNameSnapshot': widget.productName,
      'productImageSnapshot': widget.imageUrl,
      'brandSnapshot': widget.brand,
      'directionsOfUseSnapshot': widget.directionsOfUse,
      'reminderTimes': times,
      'frequencyType': _inferFrequencyType(),
    };

    try {
      Map<String, dynamic> result;
      if (widget.existingReminderId != null) {
        result = await ApiService.updateProductUsageReminder(
          widget.existingReminderId!,
          widget.userId,
          {'reminderTimes': times, 'frequencyType': _inferFrequencyType()},
        );
      } else {
        result = await ApiService.createProductUsageReminder(payload);
        // If 409 (duplicate), update the existing one
        if (result['statusCode'] == 409) {
          final existingId = result['data']['reminderId']?.toString() ?? '';
          if (existingId.isNotEmpty) {
            result = await ApiService.updateProductUsageReminder(
              existingId,
              widget.userId,
              {'reminderTimes': times, 'frequencyType': _inferFrequencyType()},
            );
          }
        }
      }

      if (!mounted) return;
      setState(() => _saving = false);

      if (result['statusCode'] == 200 || result['statusCode'] == 201) {
        _showSnack('Reminder saved!');
        Navigator.pop(context, true);
      } else {
        _showSnack('Failed to save reminder. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Error: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReminderId != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: whiteSmoke, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: darkText),
          ),
        ),
        title: Text(
          isEditing ? 'Edit Reminder' : 'Set Usage Reminder',
          style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w600, color: darkText),
        ),
        centerTitle: true,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: line, height: 1)),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: _saving
            ? const Center(child: CircularProgressIndicator(color: wine))
            : GestureDetector(
                onTap: _save,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                      color: wine, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text('Save Reminder',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductCard(),
            if (widget.directionsOfUse.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDirectionsCard(),
            ],
            const SizedBox(height: 16),
            _buildScheduleCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Product card ──────────────────────────────────────────────────────────

  Widget _buildProductCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: whiteSmoke,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.imageUrl.isNotEmpty
                  ? Image.network(widget.imageUrl,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder())
                  : _imgPlaceholder(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.productName,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (widget.brand.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(widget.brand,
                        style: GoogleFonts.poppins(fontSize: 12, color: grey)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _imgPlaceholder() => Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
            color: const Color(0xFFF2E8EA),
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.spa_outlined, color: wine, size: 28),
      );

  // ── Directions card ───────────────────────────────────────────────────────

  Widget _buildDirectionsCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2E8EA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: wine.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: wine, size: 16),
                const SizedBox(width: 6),
                Text('How to use',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: wine)),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.directionsOfUse,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: darkText, height: 1.5)),
          ],
        ),
      );

  // ── Schedule card ─────────────────────────────────────────────────────────

  Widget _buildScheduleCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: line),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alarm_rounded, color: wine, size: 18),
                const SizedBox(width: 8),
                Text('Reminder Schedule',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: darkText)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Tap a time to edit it',
                style: GoogleFonts.poppins(fontSize: 12, color: grey)),
            const SizedBox(height: 16),

            if (_slots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text('No reminder times set.',
                      style: GoogleFonts.poppins(fontSize: 13, color: grey)),
                ),
              ),

            ..._slots.asMap().entries.map((e) => _buildTimeSlotRow(e.key)),

            const SizedBox(height: 12),
            Container(height: 1, color: line),
            const SizedBox(height: 12),

            // Add time slot button
            GestureDetector(
              onTap: () => setState(() => _slots
                  .add(_TimeSlot(time: const TimeOfDay(hour: 8, minute: 0)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: wine.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_rounded, color: wine, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text('Add Reminder Time',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: wine)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildTimeSlotRow(int i) {
    final slot = _slots[i];
    final dayLabel =
        slot.dayOfWeek != null ? _dayNames[slot.dayOfWeek!] : 'Every Day';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Day chip
          GestureDetector(
            onTap: () => _pickDay(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color:
                    slot.dayOfWeek != null ? wine.withOpacity(0.1) : whiteSmoke,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        slot.dayOfWeek != null ? wine.withOpacity(0.3) : line),
              ),
              child: Text(dayLabel,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: slot.dayOfWeek != null ? wine : grey,
                      fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(width: 8),

          // Time chip
          GestureDetector(
            onTap: () => _pickTime(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: whiteSmoke,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: wine),
                  const SizedBox(width: 5),
                  Text(_fmt12h(slot.time),
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: darkText)),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Enable toggle
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: slot.enabled,
              onChanged: (v) =>
                  setState(() => _slots[i] = slot.copyWith(enabled: v)),
              activeColor: wine,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          // Remove button
          GestureDetector(
            onTap: () => setState(() => _slots.removeAt(i)),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.close_rounded, size: 15, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time slot data class ──────────────────────────────────────────────────────

class _TimeSlot {
  final TimeOfDay time;
  final int? dayOfWeek; // null = every day
  final bool enabled;

  const _TimeSlot({
    required this.time,
    this.dayOfWeek,
    this.enabled = true,
  });

  _TimeSlot copyWith({
    TimeOfDay? time,
    int? dayOfWeek,
    bool? enabled,
    bool clearDay = false,
  }) =>
      _TimeSlot(
        time: time ?? this.time,
        dayOfWeek: clearDay ? null : (dayOfWeek ?? this.dayOfWeek),
        enabled: enabled ?? this.enabled,
      );
}
